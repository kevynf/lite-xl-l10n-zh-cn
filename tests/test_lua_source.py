"""Focused structural extraction tests, independent of Lua execution."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.lua_source import Source


class LuaSourceTests(unittest.TestCase):
    def test_comments_strings_and_offsets(self):
        text = '-- ignored "label" {\n--[=[ x ] } ]=]\nlocal s = [==[\n中文 { end\n]==]\n'
        src = Source(text)
        self.assertEqual(src.strings(), ['中文 { end\n'])
        token = src.tokens[-1]
        self.assertEqual(token.line, 3)
        self.assertEqual(text[token.start:token.end], '[==[\n中文 { end\n]==]')

    def test_escapes(self):
        src=Source(r'''"a\n\t\065\x42\u{4e2d}" "\\z" "a\z  b"''')
        self.assertEqual(src.strings(), ['a\n\tAB中', '\\z', 'ab'])
        self.assertEqual(Source('"a\\\nb"').strings(), ['a\nb'])
        self.assertEqual(Source(r'"\228\184\173"').strings(), ['中'])

    def test_multiline_calls_and_callback_blocks(self):
        src=Source('''command_view:enter(
          "Find", function(a, b)
            if a then for k,v in pairs(b) do f(k,v) end
            elseif b then while a do a = a - 1 end end
            do local x,y = 1,2 end
            repeat a = a + 1 until a > 2
            return a,b
          end, "Tail")''')
        call=next(c for c in src.calls() if c.name=='command_view:enter')
        self.assertEqual(len(call.args),3)
        self.assertEqual(src.literal_concat(*call.args[0]),'Find')
        self.assertTrue(src.expression(*call.args[1]).startswith('function'))
        self.assertEqual(src.literal_concat(*call.args[2]),'Tail')
        self.assertIn('f', [c.name for c in src.calls()])

    def test_table_fields(self):
        src=Source('{ label="标题", ["description"]="解释"; [2]="二", { a=1 }, function() local x,y=1,2 end }')
        fields=src.table_fields(0,len(src.tokens))
        self.assertEqual([f.key for f in fields],['label','description',2,1,2])
        self.assertEqual(src.literal_concat(fields[1].value_start,fields[1].value_end),'解释')
        self.assertTrue(src.expression(fields[3].value_start,fields[3].value_end).startswith('{'))

    def test_calls_exclude_definitions_and_support_sugar(self):
        src=Source('function X:method(a) end\nlocal function f(x) end\nrequire "core"\ncommand.add { ["id"] = function() f() end }\nX:method("ok")')
        calls=src.calls()
        self.assertEqual([c.name for c in calls],['require','command.add','f','X:method'])
        self.assertEqual(src.literal_concat(*calls[0].args[0]),'core')
        self.assertEqual(len(calls[1].args),1)
        self.assertTrue(src.expression(*calls[1].args[0]).startswith('{'))

    def test_static_concat(self):
        for expression, expected in [ ('"a" .. ("b" .. [=[c]=])','abc'), ('"("','('), ('".."','..'), ('"a" .. value',None), ('"a" ..',None), ('',None) ]:
            src=Source(expression)
            self.assertEqual(src.literal_concat(0,len(src.tokens)),expected)

    def test_numbers_and_symbols(self):
        src=Source('0xFF 0x1.fp+2 .5 1..2 ... // ::')
        self.assertEqual([t.value for t in src.tokens],['0xFF','0x1.fp+2','.5','1','..','2','...','//','::'])

    def test_invalid_structure_fails(self):
        for text in ['"oops', "'", '[=[oops', '--[=[oops', 'f({)', '{', '}']:
            with self.subTest(text=text), self.assertRaises(ValueError): Source(text)


if __name__ == '__main__':
    unittest.main()
