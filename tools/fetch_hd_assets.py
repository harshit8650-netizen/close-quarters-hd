#!/usr/bin/env python3
"""Fetch a small CC0 asset selection at build time. No network calls in the game."""
import json, urllib.request, urllib.parse, pathlib, sys, hashlib, time
ROOT=pathlib.Path(__file__).resolve().parents[1]/'game/assets/online'; ROOT.mkdir(parents=True,exist_ok=True)
UA='CloseQuartersHD/2.0 (build asset downloader)'
MODELS={'desk':'metal_office_desk','sofa':'sofa_02','crate':'wooden_crate_01'}
TEXTURES={'factory':'concrete_floor_worn_001','wall':'painted_plaster_wall','hospital':'floor_tiles_06','home':'raw_wooden_floor_01','gallery':'marble_01'}

def read(url):
 for i in range(3):
  try:
   with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':UA}),timeout=35) as r:
    return r.read(80*1024*1024+1)
  except Exception:
   if i==2: raise
   time.sleep(2**i)

def info(slug): return json.loads(read('https://api.polyhaven.com/files/'+slug))
def urls(obj):
 if isinstance(obj,dict):
  if isinstance(obj.get('url'),str): yield obj['url']
  for v in obj.values(): yield from urls(v)
 elif isinstance(obj,list):
  for v in obj: yield from urls(v)
def save(url,path):
 data=read(url)
 if len(data)>80*1024*1024: raise ValueError('Asset exceeds limit')
 path.parent.mkdir(parents=True,exist_ok=True); path.write_bytes(data); return hashlib.sha256(data).hexdigest()
manifest=[]
for key,slug in MODELS.items():
 try:
  d=info(slug); options=d['gltf']; res=options.get('1k') or options.get('2k') or next(iter(options.values())); links=list(dict.fromkeys(urls(res))); main=next(u for u in links if urllib.parse.urlsplit(u).path.endswith('.gltf')); dest=ROOT/key; dest.mkdir(exist_ok=True)
  model=json.loads(read(main)); hashes={}
  for entry in model.get('buffers',[])+model.get('images',[]):
   uri=entry.get('uri','');
   if not uri or uri.startswith('data:'): continue
   rel=pathlib.PurePosixPath(urllib.parse.unquote(uri));
   if rel.is_absolute() or '..' in rel.parts: raise ValueError('Unsafe glTF path')
   matching=next((u for u in links if pathlib.PurePosixPath(urllib.parse.unquote(urllib.parse.urlsplit(u).path)).name==rel.name),None)
   hashes[uri]=save(matching or urllib.parse.urljoin(main,uri),dest/rel)
  (dest/'model.gltf').write_text(json.dumps(model)); manifest.append({'key':key,'slug':slug,'type':'model','source':'https://polyhaven.com/a/'+slug,'license':'CC0','sha256_dependencies':hashes}); print('Downloaded model',slug,flush=True)
 except Exception as e: print('Fallback model',slug,repr(e),flush=True)
for key,slug in TEXTURES.items():
 try:
  d=info(slug); hashes={}
  for component,aliases in [('diff',['diff','diffuse']),('nor',['nor_gl','normal']),('rough',['rough','roughness'])]:
   obj=next(d[a] for a in aliases if a in d); options=obj.get('2k') or obj.get('1k'); link=next(u for u in urls(options) if urllib.parse.urlsplit(u).path.lower().endswith(('.jpg','.jpeg','.png'))); ext=pathlib.PurePosixPath(urllib.parse.urlsplit(link).path).suffix.lower(); hashes[component]=save(link,ROOT/(key+'_'+component+ext))
  manifest.append({'key':key,'slug':slug,'type':'texture','source':'https://polyhaven.com/a/'+slug,'license':'CC0','sha256':hashes}); print('Downloaded texture',slug,flush=True)
 except Exception as e: print('Fallback texture',slug,repr(e),flush=True)
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)); print('Online asset packs available:',len(manifest),'of',len(MODELS)+len(TEXTURES))
if '--strict' in sys.argv and len(manifest)<len(MODELS)+len(TEXTURES): sys.exit(1)
