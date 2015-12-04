import json
import re

re_pat = re.compile('\$(\d)(0*)')
with open('es.json', 'rt') as f:
    data = json.load(f)
data['rules'] = tuple((re.compile(r+'$'), p) for r,p in data['rules'])
globals().update(data)

def num(n):
    n = n.lstrip('0') or '0'
    if n in ex: return ex[n]
    for r, p in rules:
        m = r.match(n)
        if not m: continue
        return re_pat.sub(lambda s:num(m.group(int(s.group(1)))+s.group(2)), p)
    raise RuntimeError("couldn't say %r"%n)

for i in xrange(100):
    print i, num(str(i))
