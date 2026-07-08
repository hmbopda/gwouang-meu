((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,D,B={
Cd(d){return new B.JG(d,new B.auS(d),E.Tr,null,"chatMessagesNotifierProvider",null,null)},
iu:function iu(){this.a=this.b=this.d=$},
auU:function auU(){},
adk:function adk(){},
ZS:function ZS(){},
JG:function JG(d,e,f,g,h,i,j){var _=this
_.fy=d
_.CW=_.ch=$
_.y=e
_.e=f
_.f=g
_.a=h
_.b=i
_.c=j},
auS:function auS(d){this.a=d},
auT:function auT(){},
aey:function aey(d,e,f,g,h,i,j,k,l,m){var _=this
_.l1$=d
_.go=e
_.im$=f
_.io$=g
_.hJ$=h
_.hw$=i
_.hm$=j
_.c=$
_.d=k
_.e=$
_.r=l
_.y=_.x=_.w=null
_.z=m
_.CW=_.ch=_.ay=_.ax=_.at=_.as=_.Q=null
_.fx=_.dy=_.dx=_.db=_.cy=_.cx=!1
_.fy=null},
apx:function apx(){},
Rc:function Rc(d,e,f,g,h,i,j,k){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j
_.w=k}},E
J=c[1]
A=c[0]
C=c[2]
D=c[24]
B=a.updateHolder(c[18],B)
E=c[61]
B.iu.prototype={
C(d){return this.aNy(d)},
aNy(d){var x=0,w=A.u(y.I),v,u=this
var $async$C=A.p(function(e,f){if(e===1)return A.q(f,w)
for(;;)switch(x){case 0:u.d=d
v=u.GB()
x=1
break
case 1:return A.r(v,w)}})
return A.t($async$C,w)},
GB(){var x=0,w=A.u(y.I),v,u=this,t,s,r,q,p
var $async$GB=A.p(function(d,e){if(d===1)return A.q(e,w)
for(;;)switch(x){case 0:q=u.a
q===$&&A.a()
t=q.al(0,$.eN(),y.L)
q=u.d
q===$&&A.a()
p=J
x=3
return A.n(t.kI(0,"/api/v1/chat/groups/"+q+"/messages",A.an(["limit",50],y.N,y.z)),$async$GB)
case 3:s=p.az(e,"data")
r=y._.b(s)?s:[]
q=J.bz(r,new B.auU(),y.W)
q=A.Y(q,q.$ti.h("al.E"))
v=q
x=1
break
case 1:return A.r(v,w)}})
return A.t($async$GB,w)},
vS(d){return this.ajl(d)},
ajl(d){var x=0,w=A.u(y.H),v=this,u,t,s,r
var $async$vS=A.p(function(e,f){if(e===1)return A.q(f,w)
for(;;)switch(x){case 0:r=v.a
r===$&&A.a()
u=r.al(0,$.eN(),y.L)
t=v.d
t===$&&A.a()
s=y.N
x=2
return A.n(u.hC("/api/v1/chat/groups/"+t+"/messages",A.an(["content",d],s,s)),$async$vS)
case 2:r.l8()
x=3
return A.n(v.gl5(),$async$vS)
case 3:return A.r(null,w)}})
return A.t($async$vS,w)},
fs(d){var x=0,w=A.u(y.H),v=this,u
var $async$fs=A.p(function(e,f){if(e===1)return A.q(f,w)
for(;;)switch(x){case 0:u=v.a
u===$&&A.a()
u.l8()
x=2
return A.n(v.gl5(),$async$fs)
case 2:return A.r(null,w)}})
return A.t($async$fs,w)}}
B.adk.prototype={}
B.ZS.prototype={
$1(d){return B.Cd(d)},
oU(d){return B.Cd(d.fy)},
gkZ(){return null},
gmo(){return null}}
B.JG.prototype={
zz(d){return d.C(this.fy)},
cl(d){var x=null
return new B.aey(!1,new A.ck(A.bc(0,x,!1,y.y),y.s),new A.ck(A.bc(0,x,!1,y.A),y.p),x,x,x,x,this,A.dF(x,x,x,y.M,y.K),A.b([],y.j))},
k(d,e){if(e==null)return!1
return e instanceof B.JG&&e.fy===this.fy},
gA(d){return D.bBq(D.bh4(D.bh4(0,A.ex(A.C(this))),C.c.gA(this.fy)))}}
B.auT.prototype={}
B.aey.prototype={}
B.apx.prototype={}
B.Rc.prototype={
j(d){var x=this
return"ChatMessageModel(id: "+x.a+", groupId: "+x.b+", senderId: "+x.c+", senderName: "+A.i(x.d)+", senderAvatarUrl: "+A.i(x.e)+", content: "+x.f+", type: "+x.r+", createdAt: "+A.i(x.w)+")"},
k(d,e){var x,w,v=this
if(e==null)return!1
if(v!==e){x=!1
if(J.ad(e)===A.C(v))if(e instanceof B.Rc){w=e.a===v.a
if(w||w){w=e.b===v.b
if(w||w){w=e.c===v.c
if(w||w){w=e.d==v.d
if(w||w){w=e.e==v.e
if(w||w){w=e.f===v.f
if(w||w){w=e.r===v.r
if(w||w){x=e.w
w=v.w
x=x==w||J.d(x,w)}}}}}}}}}else x=!0
return x},
gA(d){var x=this
return A.a3(A.C(x),x.a,x.b,x.c,x.d,x.e,x.f,x.r,x.w,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
cY(){var x=this,w=x.w
w=w==null?null:w.iw()
return A.an(["id",x.a,"groupId",x.b,"senderId",x.c,"senderName",x.d,"senderAvatarUrl",x.e,"content",x.f,"type",x.r,"createdAt",w],y.N,y.z)},
$id9:1,
gT(d){return this.a},
gFq(){return this.c},
gtt(){return this.d},
glK(d){return this.f},
gd4(d){return this.r},
gfn(){return this.w}}
var z=a.updateTypes(["d9(@)","iu()"])
B.auU.prototype={
$1(d){var x,w,v,u,t,s,r,q,p="createdAt"
y.P.a(d)
x=J.au(d)
w=A.ar(x.i(d,"id"))
v=A.ar(x.i(d,"groupId"))
u=A.ar(x.i(d,"senderId"))
t=A.aC(x.i(d,"senderName"))
s=A.aC(x.i(d,"senderAvatarUrl"))
r=A.ar(x.i(d,"content"))
q=A.aC(x.i(d,"type"))
if(q==null)q="TEXT"
return new B.Rc(w,v,u,t,s,r,q,x.i(d,p)==null?null:A.jy(A.ar(x.i(d,p))))},
$S:z+0}
B.auS.prototype={
$0(){var x=new B.iu()
x.b=this.a
return x},
$S:z+1};(function inheritance(){var x=a.mixin,w=a.inherit,v=a.inheritMany
w(B.adk,A.d7)
w(B.iu,B.adk)
w(B.auU,A.er)
w(B.ZS,A.f_)
w(B.JG,A.ea)
w(B.auS,A.hk)
v(A.x,[B.auT,B.Rc])
w(B.apx,A.jY)
w(B.aey,B.apx)
x(B.apx,B.auT)})()
A.h9(b.typeUniverse,JSON.parse('{"iu":{"d7":["j<d9>"],"eY":["j<d9>"],"d7.0":"j<d9>"},"JG":{"ea":["iu","j<d9>"],"nu":["iu","j<d9>"],"c6":["ah<j<d9>>"],"cr":[],"ce":["ah<j<d9>>"],"di":[],"c6.0":"ah<j<d9>>","ea.0":"iu","ea.T":"j<d9>","ce.0":"ah<j<d9>>"},"adk":{"d7":["j<d9>"],"eY":["j<d9>"]},"ZS":{"f_":["ah<j<d9>>"],"cr":[],"di":[]},"aey":{"jY":["iu","j<d9>"],"ei":["iu","j<d9>"],"nv":["iu","j<d9>"],"hx":["iu","j<d9>"],"ci":["j<d9>"],"eZ":["ah<j<d9>>"],"ba":["ah<j<d9>>"],"dt":["ah<j<d9>>"],"ba.0":"ah<j<d9>>","ci.T":"j<d9>","hx.T":"j<d9>","ei.0":"iu","ei.T":"j<d9>"},"Rc":{"d9":[]}}'))
var y=(function rtii(){var x=A.ac
return{L:x("kU"),W:x("d9"),j:x("A<ba<x?>>"),I:x("j<d9>"),_:x("j<@>"),P:x("b0<h,@>"),K:x("x"),M:x("ba<x?>"),s:x("ck<iu>"),p:x("ck<a2<j<d9>>>"),N:x("h"),z:x("@"),y:x("e7<iu>?"),A:x("e7<a2<j<d9>>>?"),H:x("~")}})();(function constants(){E.Tr=new B.ZS()
E.q2=new A.V(16,10,16,10)})()};
(a=>{a["C7mv1PWjRM3Uy9msFp2Ek8baVGE="]=a.current})($__dart_deferred_initializers__);