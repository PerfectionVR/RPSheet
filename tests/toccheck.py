# The load list against the files on disk, with exact case.
import os, sys
wt, libs = sys.argv[1], sys.argv[2]
def exact(root, rel):
    cur = root
    for part in rel.split('/'):
        if part not in os.listdir(cur):
            return False
        cur = os.path.join(cur, part)
    return True
listed = []
for raw in open(os.path.join(wt, 'RPSheet.toc'), encoding='utf-8'):
    line = raw.strip()
    if not line or line.startswith('#'):
        continue
    rel = line.replace('\\', '/')
    if rel.startswith('Libs/'):
        if not exact(os.path.dirname(libs), rel):
            print('LIB PATH not found with this exact case:', line)
        continue
    listed.append(rel)
    if not exact(wt, rel):
        print('FILE not found with this exact case:', line)
    if raw.rstrip('\r\n') != raw.rstrip('\r\n').rstrip():
        print('trailing space:', repr(raw))
seen = set()
for rel in listed:
    if rel.lower() in seen:
        print('LISTED TWICE:', rel)
    seen.add(rel.lower())
for folder in 'Core Data Sheet Actions UI Options Wizard Integrations'.split():
    for name in os.listdir(os.path.join(wt, folder)):
        if name.endswith('.lua') and (folder + '/' + name) not in listed:
            print('NOT LISTED:', folder + '/' + name)
print(len(listed), 'files listed')
