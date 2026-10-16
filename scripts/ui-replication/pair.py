# pair.py out.png left.png x0,y0,x1,y1 right.png x0,y0,x1,y1 [labelL] [labelR]
import sys
from PIL import Image, ImageDraw
out,l,lb,r,rb=sys.argv[1:6]; ll=sys.argv[6] if len(sys.argv)>6 else 'DEMO'; rl=sys.argv[7] if len(sys.argv)>7 else 'APP (current)'
def crop(p,b):
    x0,y0,x1,y1=map(int,b.split(',')); return Image.open(p).convert('RGB').crop((x0,y0,x1,y1))
a=crop(l,lb); b=crop(r,rb)
h=max(a.height,b.height)+24; w=a.width+b.width+16
s=Image.new('RGB',(w,h),'white'); d=ImageDraw.Draw(s)
s.paste(a,(0,24)); s.paste(b,(a.width+16,24)); d.text((4,6),ll,fill='red'); d.text((a.width+20,6),rl,fill='blue')
s.save(out)
