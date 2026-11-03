import re,os,sys
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from png import read_png
T=os.path.expanduser('~/Downloads/Free-Undead-Tileset-Top-Down-Pixel-Art/Tiled_files/')
src=open(T+'Undead_land.tmx').read()
SHEETS={'Ground_rocks':'Ground_rocks.png','Water_detilazation2':'water_detilazation_v2.png','Water_detilazation':'water_detilazation.png','water_coasts':'water_coasts.png','Objects':'Objects.png','Objects_animated':'Objects_animated.png','Objects_animated2':'Objects_animated2.png','Objects_animated3':'Objects_animated3.png','details':'details.png'}
firsts=sorted((int(g),n or 'Water_detilazation2') for g,n in re.findall(r'<tileset firstgid="(\d+)"(?: name="([^"]*)")?',src))
def local(g):
    g&=0x1fffffff; b=None
    for f,n in firsts:
        if g>=f: b=(n,g-f)
    return b
def layers():
    out=[]
    for m in re.finditer(r'<layer id="\d+" name="([^"]+)"[^>]*>(.*?)</layer>',src,re.S):
        cells={}
        for ch in re.finditer(r'<chunk x="(-?\d+)" y="(-?\d+)" width="(\d+)" height="(\d+)">(.*?)</chunk>',m.group(2),re.S):
            x,y,w,h=map(int,ch.groups()[:4]); vals=[int(v) for v in ch.group(5).replace('\n','').split(',') if v.strip()]
            for i,v in enumerate(vals):
                if v: cells[(x+i%w,y+i//w)]=local(v)
        out.append((m.group(1),cells))
    return out
_img={}
def sheet(n):
    if n not in _img: _img[n]=read_png(T+SHEETS[n])
    return _img[n]
def tilepix(n,i):
    w,h,rows=sheet(n); cols=w//16; tx,ty=(i%cols)*16,(i//cols)*16
    return [r[tx*4:(tx+16)*4] for r in rows[ty:ty+16]]
