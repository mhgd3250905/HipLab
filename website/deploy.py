"""Deploy website/dist to Cloudflare (preview only; never attaches custom domains or routes).

python3 website/build.py
TARGET=pages  python3 website/deploy.py   # default: Pages direct upload -> https://<NAME>.pages.dev
TARGET=worker python3 website/deploy.py   # Worker with assets embedded as modules -> <NAME>.<sub>.workers.dev
NAME defaults to hiplab-preview. Auth: CLOUDFLARE_API_TOKEN (Pages:Edit, or Workers Scripts:Edit for worker).
In Hark the account token is injected by the egress proxy for api.cloudflare.com; the proxy also overwrites the
Pages upload JWT, so the JWT-authenticated asset calls go out without the proxy (DIRECT=1, default).
Needs: pip install blake3 (Pages asset hashes, same as wrangler).
"""
import os, sys, json, gzip, uuid, base64, urllib.request, urllib.error
ACCOUNT = os.environ.get('CF_ACCOUNT', '36f7672020cfc6c515e198c5786d99da')
NAME = os.environ.get('NAME', os.environ.get('WORKER', 'hiplab-preview')); TARGET = os.environ.get('TARGET', 'pages')
B = f'https://api.cloudflare.com/client/v4/accounts/{ACCOUNT}'
H = {'User-Agent': 'curl/8.5.0'}
if os.environ.get('CLOUDFLARE_API_TOKEN'): H['Authorization'] = 'Bearer ' + os.environ['CLOUDFLARE_API_TOKEN']
HERE = os.path.dirname(os.path.abspath(__file__)); D = os.path.join(HERE, 'dist')
CT = {'.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
      '.webp': 'image/webp', '.png': 'image/png', '.jpg': 'image/jpeg', '.woff2': 'font/woff2', '.json': 'application/json', '.txt': 'text/plain; charset=utf-8'}
DIRECT = urllib.request.build_opener(urllib.request.ProxyHandler({}))

def call(method, url, body=None, ctype=None, auth=None):
    h = dict(H)
    if ctype: h['Content-Type'] = ctype
    if auth: h['Authorization'] = 'Bearer ' + auth
    req = urllib.request.Request(url, data=body, headers=h, method=method)
    op = DIRECT if (auth and os.environ.get('DIRECT', '1') == '1') else urllib.request.build_opener()
    try:
        with op.open(req, timeout=180) as r: return r.status, json.loads(r.read() or b'{}')
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b'{}')

def multipart(fields):
    bd = uuid.uuid4().hex; out = b''
    for name, (fn, data, ct) in fields.items():
        if isinstance(data, str): data = data.encode()
        disp = f'form-data; name="{name}"' + (f'; filename="{fn}"' if fn else '')
        out += f'--{bd}\r\nContent-Disposition: {disp}\r\nContent-Type: {ct}\r\n\r\n'.encode() + data + b'\r\n'
    return out + f'--{bd}--\r\n'.encode(), f'multipart/form-data; boundary={bd}'


def pages():
    import blake3
    st, j = call('GET', f'{B}/pages/projects/{NAME}')
    if st == 404:
        st, j = call('POST', f'{B}/pages/projects', json.dumps({'name': NAME, 'production_branch': 'main'}).encode(), 'application/json')
        print('create project', st, j.get('success'), j.get('errors'))
    manifest, payload = {}, {}
    for url, p in files:
        data = open(p, 'rb').read(); b64 = base64.b64encode(data).decode(); ext = os.path.splitext(p)[1][1:]
        hsh = blake3.blake3((b64 + ext).encode()).hexdigest()[:32]
        manifest[url] = hsh; payload[hsh] = {'key': hsh, 'value': b64, 'base64': True, 'metadata': {'contentType': CT.get('.' + ext, 'application/octet-stream').split(';')[0]}}
    st, j = call('GET', f'{B}/pages/projects/{NAME}/upload-token'); jwt = j['result']['jwt']
    st, j = call('POST', 'https://api.cloudflare.com/client/v4/pages/assets/check-missing', json.dumps({'hashes': list(payload)}).encode(), 'application/json', jwt)
    missing = j.get('result') or []; print('missing', len(missing), 'of', len(payload), j.get('errors'))
    batch, size = [], 0
    def flush(b):
        st, j = call('POST', 'https://api.cloudflare.com/client/v4/pages/assets/upload', json.dumps(b).encode(), 'application/json', jwt)
        if not j.get('success'): sys.exit(f'upload failed {st} {j.get("errors")}')
    for hsh in missing:
        it = payload[hsh]; batch.append(it); size += len(it['value'])
        if size > 20_000_000 or len(batch) >= 500: flush(batch); batch, size = [], 0
    if batch: flush(batch)
    call('POST', 'https://api.cloudflare.com/client/v4/pages/assets/upsert-hashes', json.dumps({'hashes': list(payload)}).encode(), 'application/json', jwt)
    fields = {'manifest': (None, json.dumps(manifest), 'application/json'), 'branch': (None, 'main', 'text/plain'),
              '_headers': ('_headers', '/*\n  X-Robots-Tag: noindex\n  X-Content-Type-Options: nosniff\n/img/*\n  Cache-Control: public, max-age=604800\n/fonts/*\n  Cache-Control: public, max-age=604800\n', 'text/plain')}
    body, ct = multipart(fields)
    st, j = call('POST', f'{B}/pages/projects/{NAME}/deployments', body, ct)
    r = j.get('result') or {}
    print('deployment', st, j.get('success'), j.get('errors'), r.get('id'), r.get('url'))
    print('URL', f'https://{NAME}.pages.dev/')

def worker():
    parts, imports, table = {}, [], []
    for i, (url, p) in enumerate(sorted(files)):
        mod = f'a{i}.bin'; parts[mod] = (mod, open(p, 'rb').read(), 'application/octet-stream')
        imports.append(f'import m{i} from "./{mod}";')
        ext = os.path.splitext(p)[1]
        cc = 'public, max-age=604800' if ext in ('.woff2', '.webp', '.png', '.jpg') else 'public, max-age=300, must-revalidate'
        table.append(f'"{url}":[m{i},"{CT.get(ext, "application/octet-stream")}","{cc}"]')
    worker = '\n'.join(imports) + '\nconst F={' + ','.join(table) + '''};
    export default{async fetch(req){const u=new URL(req.url);let p=decodeURIComponent(u.pathname);
    if(p==="/en")return Response.redirect(u.origin+"/en/",301);
    if(p.endsWith("/"))p+="index.html";
    const e=F[p];
    if(!e)return new Response("Not found",{status:404,headers:{"content-type":"text/plain"}});
    const h={"content-type":e[1],"cache-control":e[2],"x-content-type-options":"nosniff","x-robots-tag":"noindex"};
    if(req.method==="HEAD")return new Response(null,{headers:h});
    return new Response(e[0],{headers:h});}};
    '''
    DIRECT = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    raw = sum(len(v[1]) for v in parts.values())
    print('files', len(files), 'raw', raw, 'gzip est', sum(len(gzip.compress(v[1], 6)) for v in parts.values()))
    meta = {'main_module': 'worker.js', 'compatibility_date': '2026-10-01', 'bindings': []}
    mp = {'metadata': (None, json.dumps(meta), 'application/json'), 'worker.js': ('worker.js', worker, 'application/javascript+module')}
    mp.update(parts)
    body, ct = multipart(mp)
    st, j = call('PUT', f'{B}/workers/scripts/{NAME}', body, ct)
    print('script', st, j.get('success'), j.get('errors'))
    st, j = call('POST', f'{B}/workers/scripts/{NAME}/subdomain', json.dumps({'enabled': True, 'previews_enabled': False}).encode(), 'application/json')
    print('workers.dev', st, j.get('success'), j.get('errors'))
    st, j = call('GET', f'{B}/workers/subdomain')
    sub = (j.get('result') or {}).get('subdomain')
    if sub: print('URL', f'https://{NAME}.{sub}.workers.dev/')

files = [('/' + os.path.relpath(os.path.join(r, f), D).replace(os.sep, '/'), os.path.join(r, f)) for r, _, fs in os.walk(D) for f in sorted(fs)]
pages() if TARGET == 'pages' else worker()
