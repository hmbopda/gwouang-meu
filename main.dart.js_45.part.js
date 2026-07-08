((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
bXA(){return new b.G.XMLHttpRequest()},
bXB(){return b.G.document.createElement("img")},
bCU(d,e,f){var x=new A.ahX(d,B.b([],y.v),B.b([],y.l),B.b([],y.u))
x.ar3(d,e,f)
return x},
oi:function oi(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
aKr:function aKr(d,e,f){this.a=d
this.b=e
this.c=f},
aKs:function aKs(d,e){this.a=d
this.b=e},
aKp:function aKp(d,e,f){this.a=d
this.b=e
this.c=f},
aKq:function aKq(d,e,f){this.a=d
this.b=e
this.c=f},
ahX:function ahX(d,e,f,g){var _=this
_.y=d
_.z=!1
_.Q=$
_.as=!1
_.at=$
_.a=e
_.b=f
_.e=_.d=_.c=null
_.f=!1
_.r=0
_.w=!1
_.x=g},
b6m:function b6m(d){this.a=d},
b6n:function b6n(d,e){this.a=d
this.b=e},
b6o:function b6o(d){this.a=d},
b6p:function b6p(d){this.a=d},
b6q:function b6q(d){this.a=d},
AO:function AO(d,e){this.a=d
this.b=e},
bQc(d,e){return new A.EA("HTTP request failed, statusCode: "+d+", "+e.j(0))},
aVL:function aVL(d,e){this.a=d
this.b=e},
EA:function EA(d){this.b=d},
bQh(d,e){var x=new A.a7C(B.b([],y.v),B.b([],y.l),B.b([],y.u))
x.aqP(d,e)
return x},
a7C:function a7C(d,e,f){var _=this
_.a=d
_.b=e
_.e=_.d=_.c=null
_.f=!1
_.r=0
_.w=!1
_.x=f},
aKX:function aKX(d,e){this.a=d
this.b=e},
aEp(d,e,f,g,h){var x=null
return new B.v3(B.bsR(x,x,new A.oi(d,1,x,D.j6)),x,x,e,h,g,x,C.dL,x,f,C.I,C.dQ,!1,x)}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[24],A)
D=c[46]
A.oi.prototype={
Ej(d){return new B.cZ(this,y.i)},
z6(d,e){return A.bCU(this.BA(d,e),d.a,null)},
z7(d,e){return A.bCU(this.BA(d,e),d.a,null)},
BA(d,e){return this.aE5(d,e)},
aE5(d,e){var x=0,w=B.u(y.R),v,u=2,t=[],s=this,r,q,p,o,n
var $async$BA=B.p(function(f,g){if(f===1){t.push(g)
x=u}for(;;)switch(x){case 0:p=new A.aKr(s,e,d)
o=new A.aKs(s,d)
case 3:switch(s.d.a){case 0:x=5
break
case 2:x=6
break
case 1:x=7
break
default:x=4
break}break
case 5:v=p.$0()
x=1
break
case 6:v=o.$0()
x=1
break
case 7:u=9
x=12
return B.o(p.$0(),$async$BA)
case 12:r=g
v=r
x=1
break
u=2
x=11
break
case 9:u=8
n=t.pop()
r=o.$0()
v=r
x=1
break
x=11
break
case 8:x=2
break
case 11:x=4
break
case 4:case 1:return B.r(v,w)
case 2:return B.q(t.at(-1),w)}})
return B.t($async$BA,w)},
B4(d){var x=0,w=B.u(y.p),v,u=this,t,s,r,q,p,o,n
var $async$B4=B.p(function(e,f){if(e===1)return B.q(f,w)
for(;;)switch(x){case 0:s=u.a
r=B.abM().W(s)
q=new B.aj($.aw,y.Z)
p=new B.b3(q,y.x)
o=A.bXA()
o.open("GET",s,!0)
o.responseType="arraybuffer"
o.addEventListener("load",B.it(new A.aKp(o,p,r)))
o.addEventListener("error",B.it(new A.aKq(p,o,r)))
o.send()
x=3
return B.o(q,$async$B4)
case 3:s=o.response
s.toString
t=B.a7i(y.a.a(s),0,null)
if(t.byteLength===0)throw B.f(A.bQc(B.a7(o,"status"),r))
n=d
x=4
return B.o(B.Mj(t),$async$B4)
case 4:v=n.$1(f)
x=1
break
case 1:return B.r(v,w)}})
return B.t($async$B4,w)},
k(d,e){var x=this
if(e==null)return!1
if(J.ah(e)!==B.G(x))return!1
return e instanceof A.oi&&e.a===x.a&&e.b===x.b&&e.d===x.d&&B.IP(e.c,x.c)},
gB(d){var x=this
return B.a5(x.a,x.b,x.d,C.Jc.dZ(0,x.c),C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
j(d){var x=this
return'NetworkImage("'+x.a+'", scale: '+C.h.aD(x.b,1)+", webHtmlElementStrategy: "+x.d.b+", headers: "+B.j(x.c)+")"}}
A.ahX.prototype={
ar3(d,e,f){var x=this
x.e=e
x.y.fi(0,new A.b6m(x),new A.b6n(x,f),y.P)},
gafQ(d){var x=this,w=x.at
return w===$?x.at=new B.j9(new A.b6o(x),new A.b6p(x),new A.b6q(x)):w},
XJ(){var x,w=this
if(w.z){x=w.Q
x===$&&B.a()
x.O(0,w.gafQ(0))}w.as=!0
w.amb()}}
A.AO.prototype={
UV(d){return new A.AO(this.a,this.b)},
l(){},
geV(d){return B.y(B.aE("Could not create image data for this image because access to it is restricted by the Same-Origin Policy.\nSee https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy"))},
DR(d){if(!(d instanceof A.AO))return!1
return J.d(d.a,this.a)&&d.b===this.b},
ghl(d){return 1},
ga_o(){var x=this.a
return C.j.dq(4*x.naturalWidth*x.naturalHeight)},
$ij8:1,
gks(){return this.b}}
A.aVL.prototype={
N(){return"WebHtmlElementStrategy."+this.b}}
A.EA.prototype={
j(d){return this.b},
$icj:1}
A.a7C.prototype={
aqP(d,e){d.fi(0,this.gakr(),new A.aKX(this,e),y.H)}}
var z=a.updateTypes([])
A.aKr.prototype={
$0(){var x=0,w=B.u(y.R),v,u=this,t,s,r
var $async$$0=B.p(function(d,e){if(d===1)return B.q(e,w)
for(;;)switch(x){case 0:t=u.c
s=B
r=B
x=3
return B.o(u.a.B4(u.b),$async$$0)
case 3:v=s.bsv(r.dz(e,y.p),t.a,null,t.b)
x=1
break
case 1:return B.r(v,w)}})
return B.t($async$$0,w)},
$S:322}
A.aKs.prototype={
$0(){var x=0,w=B.u(y.R),v,u=this,t,s,r
var $async$$0=B.p(function(d,e){if(d===1)return B.q(e,w)
for(;;)switch(x){case 0:s=A.bXB()
r=u.b.a
s.src=r
x=3
return B.o(B.hZ(s.decode(),y.X),$async$$0)
case 3:t=A.bQh(B.dz(new A.AO(s,r),y.J),null)
t.e=r
v=t
x=1
break
case 1:return B.r(v,w)}})
return B.t($async$$0,w)},
$S:322}
A.aKp.prototype={
$1(d){var x=this.a,w=x.status,v=w>=200&&w<300,u=w>307&&w<400,t=v||w===0||w===304||u,s=this.b
if(t)s.dk(0,x)
else s.iM(new A.EA("HTTP request failed, statusCode: "+B.j(w)+", "+this.c.j(0)))},
$S:25}
A.aKq.prototype={
$1(d){return this.a.iM(new A.EA("HTTP request failed, statusCode: "+B.j(this.b.status)+", "+this.c.j(0)))},
$S:2}
A.b6m.prototype={
$1(d){var x=this.a
x.z=!0
if(x.as){d.BG()
return}x.Q!==$&&B.b_()
x.Q=d
d.ab(0,x.gafQ(0))},
$S:896}
A.b6n.prototype={
$2(d,e){this.a.oS(B.ci("resolving an image stream completer"),d,this.b,!0,e)},
$S:24}
A.b6o.prototype={
$2(d,e){this.a.FQ(d)},
$S:141}
A.b6p.prototype={
$1(d){this.a.ahC(d)},
$S:143}
A.b6q.prototype={
$2(d,e){this.a.aZp(d,e)},
$S:186}
A.aKX.prototype={
$2(d,e){this.a.oS(B.ci("resolving a single-frame image stream"),d,this.b,!0,e)},
$S:24};(function inheritance(){var x=a.inherit,w=a.inheritMany
x(A.oi,B.ig)
w(B.hm,[A.aKr,A.aKs])
w(B.ev,[A.aKp,A.aKq,A.b6m,A.b6p])
w(B.ih,[A.ahX,A.a7C])
w(B.jE,[A.b6n,A.b6o,A.b6q,A.aKX])
w(B.w,[A.AO,A.EA])
x(A.aVL,B.nq)})()
B.fE(b.typeUniverse,JSON.parse('{"oi":{"ig":["bsA"],"ig.T":"bsA"},"ahX":{"ih":[]},"AO":{"j8":[]},"bsA":{"ig":["bsA"]},"EA":{"cj":[]},"a7C":{"ih":[]}}'))
var y=(function rtii(){var x=B.a6
return{p:x("fI"),J:x("j8"),R:x("ih"),v:x("z<j9>"),u:x("z<~()>"),l:x("z<~(w,bz?)>"),a:x("rz"),P:x("be"),i:x("cZ<oi>"),x:x("b3<ai>"),Z:x("aj<ai>"),X:x("w?"),H:x("~")}})();(function constants(){D.j6=new A.aVL(0,"never")})()};
(a=>{a["g3jtujuqDPtP9Z6dcVcgu0inZfc="]=a.current})($__dart_deferred_initializers__);