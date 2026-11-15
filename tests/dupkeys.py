# Finds a key written twice in one table constructor, and a table field assigned twice
# at the top level of a file (X["name"] = ... / X.name = ...), in the given Lua files.
import re, sys, glob, os

def tokens(src):
    i, n, line = 0, len(src), 1
    while i < n:
        c = src[i]
        if c == '\n':
            line += 1; i += 1; continue
        if c in ' \t\r':
            i += 1; continue
        if src.startswith('--', i):
            m = re.match(r'--\[(=*)\[', src[i:])
            if m:
                end = src.find(']' + m.group(1) + ']', i)
                end = n if end < 0 else end + len(m.group(1)) + 2
                line += src.count('\n', i, end); i = end; continue
            end = src.find('\n', i)
            i = n if end < 0 else end
            continue
        m = re.match(r'\[(=*)\[', src[i:])
        if m:
            end = src.find(']' + m.group(1) + ']', i)
            end = n if end < 0 else end + len(m.group(1)) + 2
            yield ('str', src[i:end], line)
            line += src.count('\n', i, end); i = end; continue
        if c in '"\'':
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == '\\': j += 1
                j += 1
            yield ('str', src[i + 1:j], line); i = j + 1; continue
        m = re.match(r'[A-Za-z_][A-Za-z0-9_]*', src[i:])
        if m:
            yield ('name', m.group(0), line); i += len(m.group(0)); continue
        m = re.match(r'0[xX][0-9a-fA-F]+|\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+', src[i:])
        if m:
            yield ('num', m.group(0), line); i += len(m.group(0)); continue
        for op in ('...', '..', '==', '~=', '<=', '>=', '::'):
            if src.startswith(op, i):
                yield ('op', op, line); i += len(op); break
        else:
            yield ('op', c, line); i += 1

OPEN = {'function', 'do', 'then', 'repeat'}
def scan(path):
    src = open(path, encoding='utf-8', errors='replace').read()
    toks = list(tokens(src))
    out = []
    stack = []   # entries: ('{', keys dict, expecting_key) or ('(', ) or ('block',)
    top = {}     # top-level field assignments
    depth_block = 0
    i = 0
    while i < len(toks):
        kind, val, line = toks[i]
        cur = stack[-1] if stack else None
        if kind == 'op' and val == '{':
            stack.append(['{', {}, True]); i += 1; continue
        if kind == 'op' and val == '}':
            while stack and stack[-1][0] != '{': stack.pop()
            if stack: stack.pop()
            i += 1; continue
        if kind == 'op' and val in '([':
            # a bracketed key at the start of a table field
            if val == '[' and cur and cur[0] == '{' and cur[2]:
                if i + 3 < len(toks) and toks[i + 1][0] in ('str', 'num') and toks[i + 2][1] == ']' and toks[i + 3][1] == '=':
                    key = toks[i + 1][1]
                    if key in cur[1]:
                        out.append((line, 'key %r twice in one table (first at line %d)' % (key, cur[1][key])))
                    cur[1][key] = line
                    cur[2] = False
                    i += 4; continue
            stack.append([val]); i += 1; continue
        if kind == 'op' and val in ')]':
            want = '(' if val == ')' else '['
            while stack and stack[-1][0] not in (want, '{'): stack.pop()
            if stack and stack[-1][0] == want: stack.pop()
            i += 1; continue
        if kind == 'name' and val in ('function', 'do', 'repeat', 'if'):
            stack.append(['block']); i += 1; continue
        if kind == 'name' and val in ('end', 'until'):
            while stack and stack[-1][0] not in ('block', '{'): stack.pop()
            if stack and stack[-1][0] == 'block': stack.pop()
            i += 1; continue
        if cur and cur[0] == '{':
            if kind == 'op' and val in ',;':
                cur[2] = True; i += 1; continue
            if cur[2] and kind == 'name' and i + 1 < len(toks) and toks[i + 1][1] == '=' and val not in ('function',):
                if val in cur[1]:
                    out.append((line, 'key %r twice in one table (first at line %d)' % (val, cur[1][val])))
                cur[1][val] = line
                cur[2] = False
                i += 2; continue
            cur[2] = False
        if not stack and kind == 'name':
            # top level:  A.b.c = / A["x"] = / A.b["x"] =
            j = i + 1
            path_ = [val]
            while j < len(toks):
                if toks[j][1] == '.' and j + 1 < len(toks) and toks[j + 1][0] == 'name':
                    path_.append(toks[j + 1][1]); j += 2
                elif toks[j][1] == '[' and j + 2 < len(toks) and toks[j + 1][0] in ('str', 'num') and toks[j + 2][1] == ']':
                    path_.append('[' + toks[j + 1][1] + ']'); j += 3
                else:
                    break
            if j < len(toks) and toks[j][1] == '=' and len(path_) > 1 and (i == 0 or toks[i - 1][1] not in ('local', ',', '.')):
                key = '.'.join(path_)
                if key in top:
                    out.append((line, '%s assigned twice at file level (first at line %d)' % (key, top[key])))
                top[key] = line
                i = j + 1; continue
        i += 1
    return out

for pattern in sys.argv[1:]:
    for path in sorted(glob.glob(pattern)):
        for line, text in scan(path):
            print('%s:%d: %s' % (os.path.basename(path), line, text))
