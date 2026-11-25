"""Deterministic offline fallback textures for the game (original procedural work)."""
from PIL import Image
import numpy as np
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'game/assets/hd'; P.mkdir(exist_ok=True)
N=1024; rng=np.random.default_rng(128); y,x=np.mgrid[:N,:N]

def noise(n):
 a=Image.fromarray(np.uint8(rng.uniform(0,255,(n,n)))); return np.array(a.resize((N,N),Image.Resampling.BICUBIC),dtype=float)/255-.5

def write(name,base,kind):
 broad=noise(24); fine=noise(256); grain=rng.normal(0,1,(N,N)); h=.5+broad*.2+fine*.07+grain*.009
 if kind=='tile':
  seam=(np.minimum(x%256,255-x%256)<3)|(np.minimum(y%256,255-y%256)<3); h[seam]-=.24
 elif kind=='wood':
  seam=np.minimum(y%128,127-y%128)<2; h+=.025*np.sin(x*.025+y*.34+broad*8); h[seam]-=.16
 elif kind=='metal': h+=.02*np.sin(y*1.6)+fine*.02
 elif kind=='marble': h+=.05*np.sin(x*.015+y*.019+broad*8)
 elif kind=='fabric': h+=.025*(np.sin(x*1.6)+np.sin(y*1.6))
 col=np.clip(np.array(base)[None,None,:]+(h-.5)[:,:,None]*115+grain[:,:,None]*2,0,255).astype('uint8')
 Image.fromarray(col).save(P/(name+'_diff.jpg'),quality=91)
 dy,dx=np.gradient(h); normal=np.stack([-dx*7,-dy*7,np.ones_like(h)],-1); normal/=np.linalg.norm(normal,axis=-1,keepdims=True); Image.fromarray(np.uint8((normal*.5+.5)*255)).save(P/(name+'_nor.png'))
 rough=np.clip(180+broad*35+fine*15,0,255).astype('uint8'); Image.fromarray(rough).save(P/(name+'_rough.jpg'),quality=88)
for n,c,k in [('office',(113,122,125),'tile'),('factory',(98,102,104),'concrete'),('gallery',(176,172,163),'marble'),('home',(119,91,64),'wood'),('hospital',(171,184,181),'tile'),('wall',(171,175,171),'concrete'),('marble',(165,160,151),'marble'),('metal',(99,108,116),'metal'),('machine',(81,101,96),'metal'),('fabric',(94,103,92),'fabric')]: write(n,c,k)
