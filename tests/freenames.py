# Names a file uses without declaring them anywhere in it (a local lost when a file was
# split, a typo): file-level approximation, so a name declared in another function of
# the same file is not reported.
import sys, glob, os, re, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dupkeys import tokens

KEYWORDS = set("and break do else elseif end false for function if in local nil not or repeat return then true until while goto".split())
LUA = set("""_G _VERSION assert collectgarbage error getmetatable ipairs next pairs pcall print rawequal rawget rawset select setmetatable
tonumber tostring type unpack xpcall string table math os coroutine bit date time strsplit strtrim strjoin strsub strlen strfind strmatch strlower
strupper strrep format gsub tinsert tremove wipe tContains CopyTable Mixin max min floor ceil abs random sort debugstack geterrorhandler
loadstring setfenv getfenv debugprofilestop strbyte strchar tostringall hooksecurefunc securecallfunction issecurevariable""".split())

def scan(path):
    src = open(path, encoding='utf-8', errors='replace').read()
    toks = list(tokens(src))
    declared = set()
    uses = collections.defaultdict(list)
    n = len(toks)
    # declarations
    i = 0
    while i < n:
        kind, val, line = toks[i]
        if kind == 'name' and val == 'local':
            j = i + 1
            if j < n and toks[j][1] == 'function':
                if j + 1 < n: declared.add(toks[j + 1][1])
            else:
                while j < n and toks[j][0] == 'name' and toks[j][1] not in KEYWORDS:
                    declared.add(toks[j][1]); j += 1
                    if j < n and toks[j][1] == ',': j += 1
                    else: break
        elif kind == 'name' and val == 'function':
            # parameters: skip the name part up to '('
            j = i + 1
            while j < n and toks[j][1] != '(':
                j += 1
            j += 1
            while j < n and toks[j][1] != ')':
                if toks[j][0] == 'name': declared.add(toks[j][1])
                j += 1
            # method definitions have self
            k = i + 1
            while k < n and toks[k][1] != '(':
                if toks[k][1] == ':': declared.add('self')
                k += 1
        elif kind == 'name' and val == 'for':
            j = i + 1
            while j < n and toks[j][0] == 'name' and toks[j][1] not in KEYWORDS:
                declared.add(toks[j][1]); j += 1
                if j < n and toks[j][1] == ',': j += 1
                else: break
        i += 1
    # uses
    brace = []  # stack of '{' / '(' / '['
    key_position = False
    for i, (kind, val, line) in enumerate(toks):
        if kind == 'op':
            if val in '{([': brace.append(val)
            elif val in '})]' and brace: brace.pop()
            continue
        if kind != 'name' or val in KEYWORDS: continue
        prev = toks[i - 1][1] if i > 0 else ''
        nxt = toks[i + 1][1] if i + 1 < n else ''
        if prev in ('.', ':') and toks[i - 1][0] == 'op': continue
        if prev == 'goto' or prev == '::': continue
        if nxt == '=' and brace and brace[-1] == '{' and prev in ('{', ',', ';'): continue  # a table key
        if val in declared or val in LUA: continue
        uses[val].append(line)
    return uses

total = collections.defaultdict(list)
for pattern in sys.argv[1:]:
    for path in sorted(glob.glob(pattern)):
        for name, lines in scan(path).items():
            total[name].append("%s/%s:%s" % (os.path.basename(os.path.dirname(path)), os.path.basename(path), ",".join(map(str, lines[:4]))))
for name in sorted(total):
    print("%-34s %s" % (name, "  ".join(total[name][:6]) + ("  ...(%d files)" % len(total[name]) if len(total[name]) > 6 else "")))
