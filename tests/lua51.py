# Syntax that LuaJIT accepts but the game's Lua 5.1 does not.
import sys, glob, os, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dupkeys import tokens
BS = chr(92)
for pattern in sys.argv[1:]:
    for path in sorted(glob.glob(pattern)):
        src = open(path, encoding='utf-8', errors='replace').read()
        toks = list(tokens(src))
        name = os.path.basename(os.path.dirname(path)) + "/" + os.path.basename(path)
        for i, (kind, val, line) in enumerate(toks):
            nxt = toks[i + 1] if i + 1 < len(toks) else ('', '', 0)
            if kind == 'name' and val == 'goto':
                print(name, line, 'goto')
            if kind == 'op' and val == '::':
                print(name, line, 'label')
            if kind == 'op' and val in '&|':
                print(name, line, 'bit operator', val)
            if kind == 'op' and val == '~' and nxt[1] != '=':
                print(name, line, 'bit operator ~')
            if kind == 'op' and val == '/' and nxt[1] == '/' and nxt[2] == line:
                print(name, line, 'integer division //')
            if kind == 'op' and val in '<>' and nxt[1] == val:
                print(name, line, 'shift operator')
            if kind == 'str' and not val.startswith('[['):
                for m in re.finditer(re.escape(BS) + r'(.)', val):
                    c = m.group(1)
                    if c not in 'abfnrtv"\'0123456789\n' + BS:
                        print(name, line, 'string escape ' + BS + c)
            if kind == 'num' and re.match(r'0[xX].*[pP.]', val):
                print(name, line, 'hex float', val)
        if any(ord(ch) > 127 for ch in src):
            bad = sorted(set(ch for ch in src if ord(ch) > 127))
            print(name, 'non-ASCII characters:', ' '.join('U+%04X' % ord(ch) for ch in bad[:12]))
        if src.startswith('﻿'):
            print(name, 'starts with a byte order mark')
