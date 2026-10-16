# stack.py out.png top.png x0,y0,x1,y1 bottom.png x0,y0,x1,y1
import sys
from PIL import Image, ImageDraw
out,t,tb,b,bb=sys.argv[1:6]
def crop(p,bx):
    x0,y0,x1,y1=map(int,bx.split(',')); return Image.open(p).convert('RGB').crop((x0,y0,x1,y1))
a=crop(t,tb); c=crop(b,bb)
w=max(a.width,c.width); s=Image.new('RGB',(w,a.height+c.height+48),'white'); d=ImageDraw.Draw(s)
d.text((4,6),'DEMO',fill='red'); s.paste(a,(0,22)); d.text((4,a.height+28),'APP (current)',fill='blue'); s.paste(c,(0,a.height+46))
s.save(out)
