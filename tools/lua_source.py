"""Small, dependency-free Lua lexer and structural helpers.

This is intentionally not a complete Lua parser.  It preserves enough
structure for static UI extraction without executing source code.
"""
from dataclasses import dataclass
import re

@dataclass(frozen=True)
class Token:
    kind: str; value: str; start: int; end: int; line: int

@dataclass(frozen=True)
class Field:
    key: object; value_start: int; value_end: int; start: int; end: int

@dataclass(frozen=True)
class Call:
    name: str; start: int; end: int; args: list

_kw = set("and break do else elseif end false for function goto if in local nil not or repeat return then true until while".split())

def _long_open(s, i):
    m = re.match(r"\[(=*)\[", s[i:])
    return (len(m.group(1)), m.end()) if m else None

def _decode_short(raw):
    body = raw[1:-1]
    out = bytearray()
    i = 0
    escapes = {'a':'\a', 'b':'\b', 'f':'\f', 'n':'\n', 'r':'\r',
               't':'\t', 'v':'\v', '\\':'\\', '"':'"', "'":"'"}
    while i < len(body):
        if body[i] != '\\':
            out.extend(body[i].encode('utf-8'))
            i += 1
            continue
        i += 1
        if i >= len(body):
            raise ValueError('Unterminated escape')
        x = body[i]
        i += 1
        if x in escapes:
            out.extend(escapes[x].encode('utf-8'))
        elif x == 'z':
            while i < len(body) and body[i].isspace():
                i += 1
        elif x in '\r\n':
            if x == '\r' and i < len(body) and body[i] == '\n':
                i += 1
            out.append(10)
        elif x == 'x':
            digits = body[i:i+2]
            if not re.fullmatch(r'[0-9a-fA-F]{2}', digits):
                raise ValueError('Invalid hexadecimal escape')
            out.append(int(digits, 16))
            i += 2
        elif x == 'u' and i < len(body) and body[i] == '{':
            end = body.index('}', i)
            out.extend(chr(int(body[i+1:end], 16)).encode('utf-8'))
            i = end + 1
        elif x.isdigit():
            match = re.match(r'\d{0,2}', body[i:])
            digits = x + match.group()
            i += len(digits) - 1
            out.append(int(digits))
        else:
            raise ValueError('Unsupported Lua escape: ' + x)
    # Lua strings are byte sequences; preserve non-UTF-8 bytes without loss.
    return out.decode('utf-8', errors='surrogateescape')

class Source:
    def __init__(self, text):
        self.text=text; self.tokens=self._lex(); self.pairs=self._pairs(); self.blocks=self._blocks()

    def _lex(self):
        s=self.text; out=[]; i=0; line=1; n=len(s)
        while i<n:
            c=s[i]
            if c in ' \t\r': i+=1; continue
            if c=='\n': line+=1; i+=1; continue
            if s.startswith('--',i):
                j=i+2; lo=_long_open(s,j)
                if lo:
                    eq,k=lo; close=']'+('='*eq)+']'; p=s.find(close,j+k)
                    if p<0: raise ValueError('Unterminated Lua comment')
                    chunk=s[i:p+len(close)]; line+=chunk.count('\n'); i=p+len(close); continue
                p=s.find('\n',j); i=n if p<0 else p; continue
            if c in "'\"":
                q=c; j=i+1; closed=False
                while j<n:
                    if s[j]=='\\': j+=2; continue
                    if s[j]==q: j+=1; closed=True; break
                    j+=1
                if not closed: raise ValueError('Unterminated Lua string')
                out.append(Token('string',_decode_short(s[i:j]),i,j,line)); line+=s[i:j].count('\n'); i=j; continue
            lo=_long_open(s,i)
            if lo:
                eq,k=lo; close=']'+('='*eq)+']'; p=s.find(close,i+k)
                if p<0: raise ValueError('Unterminated Lua long string')
                j=p+len(close); value=re.sub(r'^\r?\n', '', s[i+k:p]); out.append(Token('string',value,i,j,line)); line+=s[i:j].count('\n'); i=j; continue
            m=re.match(r'[A-Za-z_]\w*',s[i:])
            if m:
                v=m.group(); out.append(Token('keyword' if v in _kw else 'identifier',v,i,i+len(v),line)); i+=len(v); continue
            m=re.match(r'(?:0[xX](?:[0-9a-fA-F]+(?:\.(?!\.)[0-9a-fA-F]*)?|\.[0-9a-fA-F]+)(?:[pP][+-]?\d+)?|(?:\d+(?:\.(?!\.)\d*)?|\.\d+)(?:[eE][+-]?\d+)?)',s[i:])
            if m:
                v=m.group(); out.append(Token('number',v,i,i+len(v),line)); i+=len(v); continue
            op=next((op for op in ('...','..','==','~=','<=','>=','//','<<','>>','::') if s.startswith(op,i)),c)
            out.append(Token('symbol',op,i,i+len(op),line)); i+=len(op)
        return out

    def _pairs(self):
        p={}; st=[]; opens={'(':')','[':']','{':'}'}
        for i,t in enumerate(self.tokens):
            if t.kind != 'symbol': continue
            if t.value in opens: st.append((t.value,i))
            elif t.value in (')',']','}'):
                if st and opens[st[-1][0]]==t.value:
                    _,j=st.pop(); p[j]=i; p[i]=j
                else: raise ValueError('Unmatched Lua bracket at line '+str(t.line))
        if st: raise ValueError('Unclosed Lua bracket at line '+str(self.tokens[st[-1][1]].line))
        return p

    def _blocks(self):
        """Pair Lua block keywords for skipping callback function bodies."""
        result={}; stack=[]
        for i,t in enumerate(self.tokens):
            if t.kind!='keyword': continue
            v=t.value
            if v in ('function','if','for','while','repeat'):
                stack.append([v,i,v in ('for','while')])
            elif v=='do':
                if stack and stack[-1][2]: stack[-1][2]=False
                else: stack.append(['do',i,False])
            elif v in ('end','until') and stack:
                expected='repeat' if v=='until' else None
                if (stack[-1][0]=='repeat') == (expected=='repeat'):
                    _,j,_=stack.pop(); result[j]=i
        return result

    def expression(self,start_token,end_exclusive): return self.text[self.tokens[start_token].start:self.tokens[end_exclusive-1].end] if end_exclusive>start_token else ''
    def split(self,start,end,separator=','):
        out=[]; last=start; i=start
        while i<end:
            t=self.tokens[i]
            close=self.pairs.get(i) if t.kind=='symbol' and t.value in ('(','[','{') else self.blocks.get(i)
            if close is not None and i<close<end: i=close+1; continue
            if t.kind=='symbol' and t.value==separator: out.append((last,i)); last=i+1
            i+=1
        if last<end: out.append((last,end))
        return out

    def table_fields(self,start,end):
        if start<end and self.tokens[start].kind=='symbol' and self.tokens[start].value=='{': start+=1
        if end>start and self.tokens[end-1].kind=='symbol' and self.tokens[end-1].value=='}': end-=1
        fields=[]; idx=1
        parts=[]
        for a,b in self.split(start,end): parts.extend(self.split(a,b,';'))
        for a,b in parts:
            if a>=b: continue
            eq=None
            if a+1<b and self.tokens[a].kind=='identifier' and self.tokens[a+1].value=='=': eq=a+1
            elif self.tokens[a].value=='[' and self.pairs.get(a,a)>=a and self.pairs.get(a,a)+1<b and self.tokens[self.pairs[a]+1].value=='=': eq=self.pairs[a]+1
            if eq is not None:
                if eq-a>=3 and self.tokens[a].value=='[' and self.tokens[eq-1].value==']':
                    key=self.literal_concat(a+1,eq-1)
                    if key is None:
                        key=int(self.tokens[a+1].value) if eq-a==3 and self.tokens[a+1].value.isdigit() else self.expression(a+1,eq-1)
                elif eq-a==1: key=self.tokens[a].value
                else: key=self.expression(a,eq)
                vs=eq+1
            else: key=idx; idx+=1; vs=a
            fields.append(Field(key,vs,b,a,b))
        return fields

    def calls(self):
        out=[]; ts=self.tokens; i=0
        while i<len(ts):
            if ts[i].value=='function':
                i+=1
                while i<len(ts) and (ts[i].kind=='identifier' or ts[i].value in ('.',':')): i+=1
                continue
            if ts[i].kind not in ('identifier',): i+=1; continue
            j=i; parts=[ts[j].value]
            while j+2<len(ts) and ts[j+1].value in ('.',':') and ts[j+2].kind=='identifier': parts += [ts[j+1].value,ts[j+2].value]; j+=2
            if j+1<len(ts) and ts[j+1].kind=='symbol' and ts[j+1].value=='(':
                close=self.pairs.get(j+1)
                if close is not None: out.append(Call(''.join(parts),i,close+1,self.split(j+2,close)))
            elif j+1<len(ts) and ts[j+1].kind=='string':
                out.append(Call(''.join(parts),i,j+2,[(j+1,j+2)]))
            elif j+1<len(ts) and ts[j+1].kind=='symbol' and ts[j+1].value=='{':
                close=self.pairs.get(j+1)
                if close is not None: out.append(Call(''.join(parts),i,close+1,[(j+1,close+1)]))
            i=j+1
        return out

    def literal_concat(self,start,end):
        vals=[]; i=start
        while i<end:
            if self.tokens[i].kind=='symbol' and self.tokens[i].value=='(': 
                c=self.pairs.get(i)
                if c is None or c>=end:return None
                v=self.literal_concat(i+1,c); i=c+1
            elif self.tokens[i].kind=='string': v=self.tokens[i].value; i+=1
            else:return None
            if v is None:return None
            vals.append(v)
            if i<end:
                if self.tokens[i].value!='..': return None
                i+=1
        if not vals or (end>start and self.tokens[end-1].kind=='symbol' and self.tokens[end-1].value=='..'): return None
        return ''.join(vals)

    def strings(self,start=0,end=None):
        return [t.value for t in self.tokens[start:(end if end is not None else len(self.tokens))] if t.kind=='string']
