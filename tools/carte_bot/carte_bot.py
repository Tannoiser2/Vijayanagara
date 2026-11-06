import sys, os, json
sys.path.insert(0,'/home/claude/work/tools')
from carte import righe, disegna_righe, font, icone
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
SRC='/home/claude/work/bot/'
W,H=750,1050
COL={'D':((206,206,176),(44,44,40)),'B':((196,236,232),(18,52,52)),'V':((246,226,170),(70,52,10)),'M':((246,234,214),(70,30,20))}
TESTA="(finché {R} < 1d6, o fino a 0 per la Ribellione, o dopo «I signori del Deccan»)"
def sfondo(cid,f):
    im=Image.open(SRC+f'c_{cid}.png').convert('RGB').resize((W,H))
    im=im.filter(ImageFilter.GaussianBlur(40))
    base={'D':(58,60,52),'B':(26,92,90),'V':(170,128,30),'M':(70,36,24)}[f]
    im=Image.blend(im,Image.new('RGB',(W,H),base),0.55)
    # grana leggera della carta
    import random
    rnd=random.Random(hash(cid))
    gr=Image.effect_noise((W,H),18).convert('RGB')
    im=Image.blend(im,Image.composite(im,gr,Image.new('L',(W,H),230)),0.25)
    m=Image.new('L',(W,H),0); ImageDraw.Draw(m).rounded_rectangle((0,0,W-1,H-1),radius=34,fill=255)
    out=Image.new('RGBA',(W,H),(0,0,0,0)); out.paste(im,(0,0),m)
    return out
def blocco_testo(img,x0,x1,y,parti,s,col,lh=1.18,simula=False):
    d=ImageDraw.Draw(img); f={'r':font('CrimsonPro-Regular.ttf',s),'b':font('CrimsonPro-Bold.ttf',s),'i':font('CrimsonPro-Italic.ttf',s),'bi':font('CrimsonPro-BoldItalic.ttf',s)}
    for st,t,ind in parti:
        fo=f[st]
        for ws,w in righe(t,fo,s,x1-x0-ind):
            if not simula: disegna_righe(img,d,[(ws,w)],fo,s,x0+ind+w/2,y,col,s*lh)
            y+=s*lh
    return y
def disegna(cid,f,el,out):
    img=sfondo(cid,f); d=ImageDraw.Draw(img)
    chiaro,scuro=COL[f]
    if f!='M':
        fl=icone[f]
        h=46; w=int(fl.width*h/fl.height); img.alpha_composite(fl.resize((w,h),Image.LANCZOS),(30,26))
    else:
        w=0; d.text((30,30),'MONGOLI',font=font('ElMessiri-Bold.ttf',30),fill=(230,90,70),stroke_width=2,stroke_fill=(20,10,8)); w=150
    d.text((40+w,24),cid,font=font('ElMessiri-Bold.ttf',40),fill=(250,246,236),stroke_width=3,stroke_fill=(20,16,10))
    if f in 'BV':
        blocco_testo(img,300,735,22,[('b',TESTA,0)],20,(250,246,236))
    elif f=='D':
        d.text((560,30),'(Risorse: tutte)',font=font('CrimsonPro-Bold.ttf',24),fill=(250,246,236))
    # misura e riduce la dimensione finché ci sta
    for s in range(34,14,-1):
        y=self_y=86
        ok=True
        y=layout(img,el,s,chiaro,scuro,True)
        if y<H-50: break
    layout(img,el,s,chiaro,scuro,False)
    img.convert('RGB').save(out,quality=90)
def layout(img,el,s,chiaro,scuro,simula):
    d=ImageDraw.Draw(img); y=96; x0,x1=34,W-34
    for ie,e in enumerate(el):
        t=e[0]
        dopo_ramo = ie+1<len(el) and el[ie+1][0]=='ramo'
        if t=='q':
            testo=e[1]; no=e[2] if len(e)>2 else ''
            hh=blocco_testo(img,x0+14,x1-14,0,[('r',testo,0)],s+1,(0,0,0),simula=True)
            if not simula:
                d.rectangle((x0,y,x1,y+hh+12),fill=(28,24,20))
                blocco_testo(img,x0+14,x1-14,y+6,[('r',testo,0)],s+1,(244,238,224))
            y+=hh+16
            if not simula and not dopo_ramo:
                d.text((x0+6,y),'SÌ',font=font('CrimsonPro-Bold.ttf',s),fill=(40,140,40),stroke_width=2,stroke_fill=(250,250,250))
            if dopo_ramo and not no:
                continue
            if no:
                fo=font('CrimsonPro-Bold.ttf',s); tx='NO: '+no
                yy=blocco_testo(img,x0+90,x1-6,y,[('b',tx,0)],s-1,(170,20,20),simula=True)
                if not simula:
                    yb=blocco_testo(img,x0+90,x1-6,y,[('b',tx,0)],s-1,(170,20,20),simula=True)
                    d.rounded_rectangle((x0+80,y-2,x1,yb+4),radius=8,fill=(252,246,236),outline=(170,20,20),width=2)
                    blocco_testo(img,x0+90,x1-6,y,[('b',tx,0)],s-1,(170,20,20))
                y=yy+10
            else:
                y+=s*1.3
        elif t in ('box','ramo'):
            tag=e[1] if t=='ramo' else ''
            parti=e[2] if t=='ramo' else e[1]
            ind=34 if tag else 0
            hh=blocco_testo(img,x0+14+ind,x1-14,0,parti,s,(0,0,0),simula=True)
            if not simula:
                d.rounded_rectangle((x0+ind,y,x1,y+hh+14),radius=10,fill=chiaro+(235,) if False else chiaro,outline=(20,16,12),width=3)
                if tag:
                    c=(40,140,40) if tag=='SÌ' else (170,20,20)
                    d.text((x0,y+4),tag,font=font('CrimsonPro-Bold.ttf',s),fill=c,stroke_width=2,stroke_fill=(250,250,250))
                blocco_testo(img,x0+14+ind,x1-14,y+7,parti,s,(30,24,18))
            y+=hh+24
        elif t=='stop':
            if not simula:
                cx,cy,r=W//2,y+4,22
                import math
                pts=[(cx+r*math.cos(math.pi/8+i*math.pi/4),cy+r*math.sin(math.pi/8+i*math.pi/4)) for i in range(8)]
                d.polygon(pts,fill=(200,30,30),outline=(250,250,250))
                fo=font('CrimsonPro-Bold.ttf',15); d.text((cx-fo.getlength('STOP')/2,cy-10),'STOP',font=fo,fill=(255,255,255))
            y+=36
    return y
