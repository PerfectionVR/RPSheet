import re, glob, collections, os
d = collections.defaultdict(list)
for folder in "Core Data Sheet Actions UI Options Wizard Integrations".split():
    for p in glob.glob(folder + "/*.lua"):
        name = folder + "/" + os.path.basename(p)
        for n, line in enumerate(open(p, encoding='utf-8', errors='replace'), 1):
            m = re.match(r'function ([A-Za-z_]+[.:][A-Za-z0-9_.:]+)\s*\(', line)
            if m:
                d[m.group(1)].append("%s:%d" % (name, n))
            m = re.match(r'((?:ns|R|RPSheet|UI|Opt|W|Kit|Levels|Util|L)\.[A-Za-z0-9_]+)\s*=\s*function', line)
            if m:
                d[m.group(1)].append("%s:%d" % (name, n))
for k, v in sorted(d.items()):
    if len(v) > 1:
        print(k, v)
