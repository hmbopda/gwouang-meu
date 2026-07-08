((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,B,F,E,C={
bOY(d){return new C.vd(d,null)},
vd:function vd(d,e){this.d=d
this.a=e},
Ug:function Ug(d,e){this.a=d
this.b=e},
Uf:function Uf(d,e,f,g,h,i,j,k,l){var _=this
_.w=d
_.x=e
_.y=f
_.z=g
_.Q=h
_.as=i
_.at=j
_.ax=k
_.ay=l
_.ch=!0
_.CW=!1
_.cx=null
_.cy=!1
_.dy=_.dx=_.db=null
_.fr=!0
_.fx=!1
_.fy=!0
_.go="PARENT"
_.d=$
_.c=_.a=null},
b8I:function b8I(d,e,f){this.a=d
this.b=e
this.c=f},
b8J:function b8J(d,e){this.a=d
this.b=e},
b8v:function b8v(d){this.a=d},
b8w:function b8w(d){this.a=d},
b8u:function b8u(d){this.a=d},
b8A:function b8A(){},
b8B:function b8B(){},
b8C:function b8C(d){this.a=d},
b8z:function b8z(d){this.a=d},
b8D:function b8D(d){this.a=d},
b8y:function b8y(d){this.a=d},
b8E:function b8E(d){this.a=d},
b8F:function b8F(d){this.a=d},
b8x:function b8x(d){this.a=d},
b8G:function b8G(d){this.a=d},
b8H:function b8H(){},
b8K:function b8K(d){this.a=d},
b8L:function b8L(d){this.a=d},
b8M:function b8M(d){this.a=d},
b8N:function b8N(d,e){this.a=d
this.b=e},
b8O:function b8O(d){this.a=d}},D
J=c[1]
A=c[0]
B=c[2]
F=c[39]
E=c[40]
C=a.updateHolder(c[14],C)
D=c[53]
C.vd.prototype={
a0(){var x=$.at()
return new C.Uf(new A.bg(null,y.o),new A.bc(B.Q,x),new A.bc(B.Q,x),new A.bc(B.Q,x),new A.bc(B.Q,x),new A.bc(B.Q,x),new A.bc(B.Q,x),new A.bc(B.Q,x),new A.bc(B.Q,x))}}
C.Ug.prototype={
N(){return"_InviteErrorKind."+this.b}}
C.Uf.prototype={
az(){this.aP()
this.BD()},
BD(){var x=0,w=A.u(y.v),v=1,u=[],t=this,s,r,q,p,o,n
var $async$BD=A.p(function(d,e){if(d===1){u.push(e)
x=v}for(;;)switch(x){case 0:v=3
s=t.gbR().aj(0,$.eE(),y.c)
x=6
return A.o(s.Fl(t.a.d),$async$BD)
case 6:r=e
q=y.A.a(J.as(r,"person"))
t.G(new C.b8I(t,r,q))
v=1
x=5
break
case 3:v=2
n=u.pop()
p=A.a9(n)
t.G(new C.b8J(t,p))
x=5
break
case 2:x=1
break
case 5:return A.r(null,w)
case 1:return A.q(u.at(-1),w)}})
return A.t($async$BD,w)},
l(){var x=this,w=x.x,v=w.S$=$.at()
w.K$=0
w=x.y
w.S$=v
w.K$=0
w=x.z
w.S$=v
w.K$=0
w=x.Q
w.S$=v
w.K$=0
w=x.as
w.S$=v
w.K$=0
w=x.at
w.S$=v
w.K$=0
w=x.ax
w.S$=v
w.K$=0
w=x.ay
w.S$=v
w.K$=0
x.aA()},
v(d){var x=null,w=A.m(d).ax.a===B.l?B.o:B.p
return A.hO(x,w.b,A.a1(A.b([B.cb,A.a8(A.h3(!0,A.b7(A.ku(new A.dJ(D.Rc,this.asm(w),x),x,B.C,D.a_6,x,B.aw),x,x),B.a6,!1),1)],y.u),B.k,x,B.d,B.f),x,x)},
asm(d){var x=this,w=null
if(x.ch)return A.a1(A.b([A.aX(A.fh(w,d.r,w,w,w,w,w,3,w,w),44,44),B.c3,A.k("OUVERTURE DE L'INVITATION",w,w,w,w,A.bK(d.as,11,B.i,2),w,w,w)],y.u),B.k,w,B.d,B.F)
if(x.dx!=null)return x.asr(d)
return x.asv(d)},
aud(d){var x=d.toLowerCase()
if(B.c.n(x,"expir"))return D.ayG
if(B.c.n(x,"accept"))return D.ayH
return D.ayI},
a26(d){var x=B.c.a3(d)
if(B.c.bS(x,"Exception:"))x=B.c.a3(B.c.cG(x,10))
return x.length===0?"Une erreur inattendue est survenue.":x},
asr(d){var x,w=this,v=w.dx
v.toString
switch(w.aud(v).a){case 0:return w.aKT(d,"Ce lien n'est plus valide : les invitations expirent au bout de 30 jours. Demandez \xe0 votre proche de vous envoyer une nouvelle invitation depuis son arbre.",D.a0U,d.w,d.x,d.r,"Invitation expir\xe9e")
case 1:return w.aKU(d,"Se connecter","Cette invitation a d\xe9j\xe0 \xe9t\xe9 utilis\xe9e. Si c'\xe9tait vous, connectez-vous pour retrouver votre place dans la lign\xe9e.",B.d2,B.c1,B.dd,d.ch,new C.b8v(w),"Invitation d\xe9j\xe0 accept\xe9e")
case 2:v=d.CW
x=w.dx
x.toString
return w.To(d,"R\xe9essayer",w.a26(x),v,B.f6,B.bJ,B.bI,v,new C.b8w(w),"Une erreur est survenue")}},
To(d,e,f,g,h,i,j,k,l,m){var x,w,v=null,u=A.C(20),t=A.aD(d.ax,B.n,1),s=A.aD(j,B.n,1)
s=A.I(v,A.ae(h,k,1,v,34),B.e,v,v,new A.Q(i,v,s,v,v,v,B.aj),v,72,v,v,v,v,72)
x=A.k(m,v,v,v,v,A.c8(d.z,24,B.E,v,v),B.af,v,v)
w=y.u
x=A.b([s,B.cw,x,B.J,A.k(f,v,v,v,v,A.D(g==null?d.Q:g,14.5,B.i,1.55,v),B.af,v,v)],w)
if(e!=null){s=A.lU(B.u,v,v,B.ah,new A.by(A.C(14),B.r),v,v)
B.b.E(x,A.b([B.hD,A.aX(A.rf(A.k(e,v,v,v,v,A.D(B.ah,15.5,B.E,v,v),v,v,v),l,s),54,1/0)],w))}return A.I(v,A.a1(x,B.k,v,B.d,B.F),B.e,v,v,new A.Q(d.d,v,t,u,v,v,B.q),v,v,v,D.a_a,v,v,v)},
aKT(d,e,f,g,h,i,j){return this.To(d,null,e,null,f,g,h,i,null,j)},
aKU(d,e,f,g,h,i,j,k,l){return this.To(d,e,f,null,g,h,i,j,k,l)},
gaDB(){if(this.go==="SPOUSE"){var x=this.db
return x!=null?x+" vous a enregistr\xe9\xb7e comme conjoint\xb7e dans son arbre g\xe9n\xe9alogique.":"Vous avez \xe9t\xe9 enregistr\xe9\xb7e comme conjoint\xb7e dans un arbre g\xe9n\xe9alogique."}x=this.db
return x!=null?x+" vous a ajout\xe9\xb7e \xe0 son arbre g\xe9n\xe9alogique.":"Un membre de votre famille vous a ajout\xe9\xb7e \xe0 son arbre g\xe9n\xe9alogique."},
asv(a2){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g=this,f=null,e=a2.w,d=a2.x,a0=A.aD(d,B.n,1),a1=a2.r
a0=A.b7(A.I(B.I,A.ae(B.dl,a1,1,f,34),B.e,f,f,new A.Q(e,f,a0,f,f,f,B.aj),f,72,f,f,f,f,72),f,f)
x=A.b7(A.k("INVITATION \xb7 GWANG MEU",f,f,f,f,A.bK(a1,11,B.i,2.5),f,f,f),f,f)
w=a2.z
v=A.k("Vous \xeates invit\xe9\xb7e \xe0 rejoindre la lign\xe9e",f,f,f,f,A.c8(w,27,B.E,1.2,f),B.af,f,f)
u=A.k(g.gaDB(),f,f,f,f,A.D(a2.Q,14.5,B.i,1.5,f),B.af,f,f)
t=a2.as
s=A.k("V\xe9rifiez et corrigez vos informations ci-dessous.",f,f,f,f,A.D(t,12.5,B.i,f,f),B.af,f,f)
r=A.C(20)
q=a2.ax
p=A.aD(q,B.n,1)
o=A.a8(A.k("VOS INFORMATIONS",f,f,f,f,A.bK(a1,11,B.i,2),f,f,f),1)
n=A.C(99)
d=A.aD(d,B.n,1)
m=g.go==="SPOUSE"?"CONJOINT\xb7E":"LIGN\xc9E"
l=y.u
n=A.X(A.b([o,A.I(f,A.k(m,f,f,f,f,A.bK(a1,10,B.x,1.5),f,f,f),B.e,f,f,new A.Q(e,f,d,n,f,f,B.q),f,f,f,B.pO,f,f,f)],l),B.k,B.d,B.f,0,f)
d=g.a3p(a2,g.x,B.cE,"Pr\xe9nom *",new C.b8A())
e=g.a3p(a2,g.y,F.f8,"Nom *",new C.b8B())
m=g.H0(a2,g.z,D.a0L,"Nom de jeune fille")
o=g.H0(a2,g.Q,B.dj,"Clan / grande famille")
k=g.H0(a2,g.as,E.mc,"Totem")
j=g.H0(a2,g.at,E.qL,"Langue maternelle")
i=A.I(f,f,B.e,q,f,f,f,1,f,f,f,f,f)
h=g.db
h=h!=null?"Connaissez-vous "+h+" ?":"Connaissez-vous la personne \xe0 l'origine de cette invitation ?"
w=A.b([n,B.d7,d,B.J,e,B.J,m,B.J,o,B.J,k,B.J,j,E.nT,i,B.cw,A.k(h,f,f,f,f,A.D(w,14.5,B.x,f,f),f,f,f),B.b_,A.k("Cette information nous aide \xe0 v\xe9rifier l'authenticit\xe9 des liens familiaux.",f,f,f,f,A.D(t,12.5,B.i,1.4,f),f,f,f),B.aZ,A.X(A.b([A.a8(g.a22(a2,B.d2,"Oui, je le\xb7la connais",new C.b8C(g),g.cx===!0),1),B.a9,A.a8(g.a22(a2,D.a0W,"Non",new C.b8D(g),g.cx===!1),1)],l),B.k,B.d,B.f,0,f)],l)
if(g.cy){e=a2.CW
B.b.E(w,A.b([B.J,A.X(A.b([A.ae(B.f6,e,f,f,16),B.aC,A.a8(A.k("Veuillez r\xe9pondre \xe0 cette question avant de continuer.",f,f,f,f,A.D(e,12.5,B.i,f,f),f,f,f),1)],l),B.k,B.d,B.f,0,f)],l))}if(g.fy)B.b.E(w,A.b([E.nT,A.I(f,f,B.e,q,f,f,f,1,f,f,f,f,f),B.cw,A.k("VOTRE COMPTE",f,f,f,f,A.bK(a1,11,B.i,2),f,f,f),B.b7,A.k("Cr\xe9ez votre acc\xe8s pour rejoindre l'arbre familial.",f,f,f,f,A.D(t,12.5,B.i,f,f),f,f,f),B.aZ,g.awX(a2,g.ax,B.eD,B.eO,"Email *",new C.b8E(g)),B.J,g.awY(a2,g.ay,B.jY,"Mot de passe *",g.fr,new C.b8F(g),new C.b8G(g))],l))
e=A.b([a0,B.d7,x,B.a5,v,B.J,u,B.b7,s,B.hD,A.I(f,A.a1(w,B.bL,f,B.d,B.f),B.e,f,f,new A.Q(a2.d,f,p,r,f,f,B.q),f,f,f,B.bd,f,f,f),B.cw],l)
d=g.dy
if(d!=null){a0=A.C(14)
a1=A.aD(B.bI,B.n,1)
x=a2.CW
B.b.E(e,A.b([A.I(f,A.X(A.b([A.ae(B.f6,x,1,f,20),B.a9,A.a8(A.k(d,f,f,f,f,A.D(x,13.5,B.i,1.45,f),f,f,f),1)],l),B.z,B.d,B.f,0,f),B.e,f,f,new A.Q(B.bJ,f,a1,a0,f,f,B.q),f,f,f,B.cQ,f,f,f),B.ac],l))}d=g.CW?f:g.gaL3()
a0=A.lU(B.u,B.u.bx(0.55),f,B.ah,new A.by(A.C(14),B.r),f,f)
e.push(A.aX(A.rf(g.CW?B.OC:A.k("Confirmer et rejoindre la lign\xe9e",f,f,f,f,A.D(B.ah,16,B.E,f,f),f,f,f),d,a0),54,f))
e.push(B.aZ)
e.push(A.k("En confirmant, vos informations seront reli\xe9es \xe0 cet arbre familial.",f,f,f,f,A.D(a2.at,12,B.i,f,f),B.af,f,f))
return A.lV(f,A.a1(e,B.bL,f,B.d,B.f),g.w)},
H1(d,e,f,g,h,i,j,k){var x,w,v,u,t=null,s=new C.b8H(),r=A.D(d.z,14.5,B.i,t,t),q=A.D(d.Q,14,B.i,t,t),p=A.D(d.r,12,B.i,t,t),o=d.as,n=A.ae(f,o,t,t,20)
if(j!=null){x=i?"Afficher le mot de passe":"Masquer le mot de passe"
o=A.fN(t,t,A.ae(i?B.m8:B.xU,o,t,t,20),t,t,j,t,t,x)}else o=t
x=s.$1(d.ax)
w=s.$2(B.u,1.5)
v=d.CW
u=s.$1(v)
s=s.$2(v,1.5)
return A.cT(!1,e,B.u,A.iG(t,t,t,B.bN,t,t,t,t,!0,x,t,u,t,A.D(v,12,B.i,t,t),t,d.e,!0,t,t,p,t,w,s,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,q,h,!0,!0,!1,t,n,t,t,t,t,t,t,o,t,t,t,t,t),t,t,g,t,1,i,t,t,t,r,B.S,k)},
a3p(d,e,f,g,h){return this.H1(d,e,f,B.eN,g,!1,null,h)},
H0(d,e,f,g){return this.H1(d,e,f,B.eN,g,!1,null,null)},
awX(d,e,f,g,h,i){return this.H1(d,e,f,g,h,!1,null,i)},
awY(d,e,f,g,h,i,j){return this.H1(d,e,f,B.eN,g,h,i,j)},
a22(d,e,f,g,h){var x,w,v=null,u=h?d.w:d.e,t=A.C(14),s=A.C(14),r=A.C(14),q=h?d.x:d.ax
q=A.aD(q,B.n,h?1.5:1)
x=h?d.r:d.Q
x=A.ae(e,x,h?1:0,v,18)
w=h?B.E:B.ad
return A.bS(!1,B.D,!0,t,A.bM(!1,s,!0,A.I(v,A.X(A.b([x,B.a0,new A.dV(1,B.aR,A.k(f,1,B.K,v,v,A.D(h?d.r:d.Q,13.5,w,v,v),v,v,v),v)],y.u),B.k,B.aJ,B.f,0,v),B.e,v,B.e5,new A.Q(v,v,q,r,v,v,B.q),v,v,v,B.ez,v,v,v),v,!0,v,v,v,v,v,v,v,v,v,g,v,v,v,v,v,v,v),B.e,u,0,v,v,v,v,v,B.Z)},
xp(){var x=0,w=A.u(y.v),v,u=2,t=[],s=[],r=this,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3
var $async$xp=A.p(function(a4,a5){if(a4===1){t.push(a5)
x=u}for(;;)switch(x){case 0:r.G(new C.b8K(r))
if(!r.w.gU().k9()){x=1
break}if(r.cx==null){r.G(new C.b8L(r))
x=1
break}r.G(new C.b8M(r))
u=4
x=r.fy?7:8
break
case 7:q=B.c.a3(r.ax.a.a)
p=r.ay.a.a
o=!1
u=10
j=$.hh().b
j===$&&A.a()
x=13
return A.o(j.gfq().al4(q,p),$async$xp)
case 13:n=a5
if(n.a==null)o=!0
u=4
x=12
break
case 10:u=9
a1=t.pop()
j=A.a9(a1)
if(j instanceof A.lK){m=j
if(m.b==="422"||B.c.n(m.a.toLowerCase(),"already registered"))o=!0
else throw a1}else throw a1
x=12
break
case 9:x=4
break
case 12:x=o?14:15
break
case 14:u=17
j=$.hh().b
j===$&&A.a()
x=20
return A.o(j.gfq().wa(q,p),$async$xp)
case 20:u=4
x=19
break
case 17:u=16
a2=t.pop()
if(A.a9(a2) instanceof A.lK){j=A.fj("Ce compte existe d\xe9j\xe0. Veuillez saisir le mot de passe correct ou utiliser une autre adresse email.")
throw A.f(j)}else throw a2
x=19
break
case 16:x=4
break
case 19:case 15:case 8:l=r.gbR().aj(0,$.eE(),y.c)
j=r.a.d
h=B.c.a3(r.x.a.a)
g=B.c.a3(r.y.a.a)
f=B.c.a3(r.z.a.a)
f=f.length!==0?f:null
e=B.c.a3(r.Q.a.a)
e=e.length!==0?e:null
d=B.c.a3(r.as.a.a)
d=d.length!==0?d:null
a0=B.c.a3(r.at.a.a)
a0=a0.length!==0?a0:null
x=21
return A.o(l.Je(j,A.ar(["firstName",h,"lastName",g,"maidenName",f,"clan",e,"totem",d,"nativeLanguage",a0,"knowsInviter",r.cx],y.w,y.b)),$async$xp)
case 21:j=r.c
if(j!=null){j=j.Z(y.q).f
h=A.C(14)
j.df(A.dG(null,null,null,B.R,B.bP,B.B,null,A.k("Bienvenue ! Votre compte a \xe9t\xe9 cr\xe9\xe9 et reli\xe9 \xe0 votre fiche g\xe9n\xe9alogique.",null,null,null,null,A.D(B.y,14,B.x,null,null),null,null,null),null,B.ax,null,null,null,null,null,null,null,new A.by(h,B.r),null,null))
h=r.c
h.toString
A.d5(h).hk(0,"/home/feed",null)}s.push(6)
x=5
break
case 4:u=3
a3=t.pop()
k=A.a9(a3)
if(r.c!=null)r.G(new C.b8N(r,k))
s.push(6)
x=5
break
case 3:s=[2]
case 5:u=2
if(r.c!=null)r.G(new C.b8O(r))
x=s.pop()
break
case 6:case 1:return A.r(v,w)
case 2:return A.q(t.at(-1),w)}})
return A.t($async$xp,w)}}
var z=a.updateTypes(["a2<~>()"])
C.b8I.prototype={
$0(){var x,w,v,u=this.a,t=this.b,s=J.ap(t)
u.db=A.aA(s.i(t,"inviterName"))
x=this.c
if(x!=null){w=J.ap(x)
v=w.i(x,"firstName")
if(v==null)v=""
u.x.scq(0,v)
v=w.i(x,"lastName")
if(v==null)v=""
u.y.scq(0,v)
v=w.i(x,"maidenName")
if(v==null)v=""
u.z.scq(0,v)
v=w.i(x,"clan")
if(v==null)v=""
u.Q.scq(0,v)
v=w.i(x,"totem")
if(v==null)v=""
u.as.scq(0,v)
x=w.i(x,"nativeLanguage")
if(x==null)x=""
u.at.scq(0,x)}x=s.i(t,"email")
if(x==null)x=""
u.ax.scq(0,x)
t=A.aA(s.i(t,"invitationType"))
u.go=t==null?"PARENT":t
t=$.hh().b
t===$&&A.a()
t=t.gfq().c
t=(t==null?null:t.r)==null
u.fx=!t
u.fy=t
u.ch=!1},
$S:0}
C.b8J.prototype={
$0(){var x=this.a
x.dx=A.j(this.b)
x.ch=!1},
$S:0}
C.b8v.prototype={
$0(){var x=this.a.c
x.toString
return A.d5(x).hk(0,"/auth",null)},
$S:0}
C.b8w.prototype={
$0(){var x=this.a
x.G(new C.b8u(x))
x.BD()},
$S:0}
C.b8u.prototype={
$0(){var x=this.a
x.dx=null
x.ch=!0},
$S:0}
C.b8A.prototype={
$1(d){return d==null||d.length===0?"Champ requis":null},
$S:13}
C.b8B.prototype={
$1(d){return d==null||d.length===0?"Champ requis":null},
$S:13}
C.b8C.prototype={
$0(){var x=this.a
return x.G(new C.b8z(x))},
$S:0}
C.b8z.prototype={
$0(){var x=this.a
x.cx=!0
x.cy=!1},
$S:0}
C.b8D.prototype={
$0(){var x=this.a
return x.G(new C.b8y(x))},
$S:0}
C.b8y.prototype={
$0(){var x=this.a
x.cy=x.cx=!1},
$S:0}
C.b8E.prototype={
$1(d){if(!this.a.fy)return null
if(d==null||d.length===0)return"Champ requis"
if(!B.c.n(d,"@"))return"Email invalide"
return null},
$S:13}
C.b8F.prototype={
$0(){var x=this.a
return x.G(new C.b8x(x))},
$S:0}
C.b8x.prototype={
$0(){var x=this.a
return x.fr=!x.fr},
$S:0}
C.b8G.prototype={
$1(d){if(!this.a.fy)return null
if(d==null||d.length<6)return"6 caract\xe8res minimum"
return null},
$S:13}
C.b8H.prototype={
$2(d,e){return new A.dA(4,A.C(14),new A.aB(d,e,B.n,-1))},
$1(d){return this.$2(d,1)},
$S:94}
C.b8K.prototype={
$0(){return this.a.dy=null},
$S:0}
C.b8L.prototype={
$0(){return this.a.cy=!0},
$S:0}
C.b8M.prototype={
$0(){return this.a.CW=!0},
$S:0}
C.b8N.prototype={
$0(){var x=this.a
return x.dy=x.a26(A.j(this.b))},
$S:0}
C.b8O.prototype={
$0(){return this.a.CW=!1},
$S:0};(function installTearOffs(){var x=a._instance_0u
x(C.Uf.prototype,"gaL3","xp",0)})();(function inheritance(){var x=a.inherit,w=a.inheritMany
x(C.vd,A.kc)
x(C.Ug,A.nq)
x(C.Uf,A.jF)
w(A.hm,[C.b8I,C.b8J,C.b8v,C.b8w,C.b8u,C.b8C,C.b8z,C.b8D,C.b8y,C.b8F,C.b8x,C.b8K,C.b8L,C.b8M,C.b8N,C.b8O])
w(A.ev,[C.b8A,C.b8B,C.b8E,C.b8G,C.b8H])})()
A.fE(b.typeUniverse,JSON.parse('{"vd":{"S":[],"c":[]},"Uf":{"a4":["vd"]}}'))
var y={c:A.a6("mX"),u:A.a6("z<c>"),o:A.a6("bg<mV>"),w:A.a6("h"),q:A.a6("k0"),b:A.a6("@"),A:A.a6("aU<h,@>?"),v:A.a6("~")};(function constants(){D.Rc=new A.aq(0,520,0,1/0)
D.a_6=new A.V(24,36,24,36)
D.a_a=new A.V(28,36,28,32)
D.a0L=new A.av(59966,"MaterialSymbolsOutlined","material_symbols_icons",!1)
D.a0U=new A.av(59996,"MaterialSymbolsOutlined","material_symbols_icons",!1)
D.a0W=new A.av(59645,"MaterialSymbolsOutlined","material_symbols_icons",!0)
D.ayG=new C.Ug(0,"expired")
D.ayH=new C.Ug(1,"alreadyAccepted")
D.ayI=new C.Ug(2,"generic")})()};
(a=>{a["T7Qd/5ml3wSDoTqhRG7QWKGQ/so="]=a.current})($__dart_deferred_initializers__);