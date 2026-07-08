((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,D,B={
bTq(){return new B.qb()},
bqd(d,e){var x=0,w=A.u(y.S),v,u,t,s
var $async$bqd=A.p(function(f,g){if(f===1)return A.q(g,w)
for(;;)switch(x){case 0:u=A
t=y.P
s=J
x=3
return A.o(d.aj(0,$.eD(),y.L).dV(0,"/api/v1/villages/"+e),$async$bqd)
case 3:v=u.Rz(t.a(s.as(g,"data")))
x=1
break
case 1:return A.r(v,w)}})
return A.t($async$bqd,w)},
WJ(d,e){d=d+e&536870911
d=d+((d&524287)<<10)&536870911
return d^d>>>6},
bu3(d){d=d+((d&67108863)<<3)&536870911
d^=d>>>11
return d+((d&16383)<<15)&536870911},
aVo(d){return new B.Rd(d,new B.aVp(d),C.TB,null,"villageDetailProvider",null,null)},
qb:function qb(){this.a=$},
aVC:function aVC(){},
aVD:function aVD(d,e){this.a=d
this.b=e},
ac_:function ac_(){},
Rd:function Rd(d,e,f,g,h,i,j){var _=this
_.fr=d
_.ay=e
_.ch=$
_.e=f
_.f=g
_.a=h
_.b=i
_.c=j},
aVp:function aVp(d){this.a=d},
Re:function Re(){},
apJ:function apJ(d,e,f,g,h,i,j,k,l){var _=this
_.kv$=d
_.hD$=e
_.hP$=f
_.hr$=g
_.hc$=h
_.h0$=i
_.c=$
_.d=j
_.e=$
_.r=k
_.y=_.x=_.w=null
_.z=l
_.CW=_.ch=_.ay=_.ax=_.at=_.as=_.Q=null
_.fx=_.dy=_.dx=_.db=_.cy=_.cx=!1
_.fy=null},
ary:function ary(){}},C
J=c[1]
A=c[0]
D=c[2]
B=a.updateHolder(c[30],B)
C=c[79]
B.qb.prototype={
dC(){var x=0,w=A.u(y.r),v,u=this
var $async$dC=A.p(function(d,e){if(d===1)return A.q(e,w)
for(;;)switch(x){case 0:v=u.aNj()
x=1
break
case 1:return A.r(v,w)}})
return A.t($async$dC,w)},
xx(d){return this.awT(d)},
aNj(){return this.xx(null)},
awT(d){var x=0,w=A.u(y.r),v,u=this,t,s
var $async$xx=A.p(function(e,f){if(e===1)return A.q(f,w)
for(;;)switch(x){case 0:s=u.a
s===$&&A.a()
t=s.aj(0,$.eD(),y.L)
x=d!=null&&d.length!==0?3:4
break
case 3:x=5
return A.o(t.kP(0,"/api/v1/villages/search",A.ar(["q",d],y.N,y.z)),$async$xx)
case 5:v=u.a6O(f)
x=1
break
case 4:x=6
return A.o(t.kP(0,"/api/v1/villages",A.F(y.N,y.z)),$async$xx)
case 6:v=u.a6O(f)
x=1
break
case 1:return A.r(v,w)}})
return A.t($async$xx,w)},
a6O(d){var x,w,v=J.as(d,"data")
if(y._.b(v))x=v
else{y.Y.a(v)
w=v==null?null:J.as(v,"content")
y.g.a(w)
x=w==null?[]:w}w=J.bs(x,new B.aVC(),y.S)
w=A.Y(w,w.$ti.h("al.E"))
return w},
FE(d,e){return this.ajX(0,e)},
ajX(d,e){var x=0,w=A.u(y.H),v=this,u
var $async$FE=A.p(function(f,g){if(f===1)return A.q(g,w)
for(;;)switch(x){case 0:v.gjF().sd3(0,C.Qx)
x=2
return A.o(A.ub(new B.aVD(v,e),y.r),$async$FE)
case 2:u=g
v.gjF().sd3(0,u)
return A.r(null,w)}})
return A.t($async$FE,w)},
fh(d){var x=0,w=A.u(y.H),v=this,u
var $async$fh=A.p(function(e,f){if(e===1)return A.q(f,w)
for(;;)switch(x){case 0:u=v.a
u===$&&A.a()
u.ld()
x=2
return A.o(v.ghQ(),$async$fh)
case 2:return A.r(null,w)}})
return A.t($async$fh,w)},
NS(d,e,f,g,h,i){return this.b_G(d,e,f,g,h,i)},
b_G(d,e,f,g,h,i){var x=0,w=A.u(y.S),v,u=this,t,s,r,q,p,o,n
var $async$NS=A.p(function(j,k){if(j===1)return A.q(k,w)
for(;;)switch(x){case 0:q=u.a
q===$&&A.a()
t=q.aj(0,$.eD(),y.L)
s=A.F(y.N,y.K)
if(e!=null)s.m(0,"description",e)
if(d!=null)s.m(0,"coverImageUrl",d)
if(f!=null)s.m(0,"foundedYear",f)
if(h!=null)s.m(0,"populationEstimate",h)
if(g!=null)s.m(0,"historicalSummary",g)
p=A
o=y.P
n=J
x=3
return A.o(t.vH(0,"/api/v1/villages/"+i,s),$async$NS)
case 3:r=p.Rz(o.a(n.as(k,"data")))
q.ld()
s=B.aVo(i)
q=q.e
q===$&&A.a()
q.dt(s)
v=r
x=1
break
case 1:return A.r(v,w)}})
return A.t($async$NS,w)},
Ko(d,e,f,g,h){return this.aRr(d,e,f,g,h)},
aRr(d,e,f,g,h){var x=0,w=A.u(y.S),v,u=this,t,s,r,q,p,o,n
var $async$Ko=A.p(function(i,j){if(i===1)return A.q(j,w)
for(;;)switch(x){case 0:q=u.a
q===$&&A.a()
t=q.aj(0,$.eD(),y.L)
s=A.F(y.N,y.K)
s.m(0,"name",f)
s.m(0,"country",d)
if(e!=null)s.m(0,"description",e)
if(h!=null)s.m(0,"region",h)
if(g!=null)s.m(0,"primaryDialect",g)
p=A
o=y.P
n=J
x=3
return A.o(t.hK("/api/v1/villages",s),$async$Ko)
case 3:r=p.Rz(o.a(n.as(j,"data")))
q.ld()
v=r
x=1
break
case 1:return A.r(v,w)}})
return A.t($async$Ko,w)}}
B.ac_.prototype={
$1(d){return B.aVo(d)},
nN(d){return B.aVo(d.fr)},
gku(){return null},
glN(){return null}}
B.Rd.prototype={
cf(d){var x=null
return new B.apJ(!1,new A.cb(A.b9(0,x,!1,y.R),y.F),x,x,x,x,this,A.dm(x,x,x,y.M,y.K),A.b([],y.j))},
k(d,e){if(e==null)return!1
return e instanceof B.Rd&&e.fr===this.fr},
gB(d){return B.bu3(B.WJ(B.WJ(0,A.em(A.G(this))),D.c.gB(this.fr)))}}
B.Re.prototype={}
B.apJ.prototype={}
B.ary.prototype={}
var z=a.updateTypes(["qb()"])
B.aVC.prototype={
$1(d){return A.Rz(y.P.a(d))},
$S:165}
B.aVD.prototype={
$0(){return this.a.xx(this.b)},
$S:913}
B.aVp.prototype={
$1(d){return B.bqd(y.a.a(d),this.a)},
$S:914};(function installTearOffs(){var x=a._static_0
x(B,"c1K","bTq",0)})();(function inheritance(){var x=a.mixin,w=a.inherit,v=a.inheritMany
w(B.qb,A.k9)
v(A.ev,[B.aVC,B.aVp])
w(B.aVD,A.hm)
w(B.ac_,A.dU)
w(B.Rd,A.f9)
w(B.Re,A.w)
w(B.ary,A.lL)
w(B.apJ,B.ary)
x(B.ary,B.Re)})()
A.fE(b.typeUniverse,JSON.parse('{"qb":{"k9":["i<aR>"],"dk":["i<aR>"],"eu":["i<aR>"],"dk.0":"i<aR>"},"Rd":{"f9":["aR"],"qk":["aR"],"c2":["ag<aR>"],"bZ":[],"c1":["ag<aR>"],"cY":[],"c2.0":"ag<aR>","f9.T":"aR","c1.0":"ag<aR>"},"ac_":{"dU":["ag<aR>"],"bZ":[],"cY":[]},"apJ":{"lL":["aR"],"jM":["aR"],"iV":["aR"],"Re":[],"cg":["aR"],"eT":["ag<aR>"],"eS":["aR"],"b5":["ag<aR>"],"d7":["ag<aR>"],"b5.0":"ag<aR>","cg.T":"aR","iV.T":"aR","jM.T":"aR"}}'))
var y=(function rtii(){var x=A.a6
return{L:x("k8"),j:x("z<b5<w?>>"),r:x("i<aR>"),_:x("i<@>"),P:x("aU<h,@>"),K:x("w"),M:x("b5<w?>"),F:x("cb<a2<aR>>"),N:x("h"),a:x("Re"),S:x("aR"),z:x("@"),g:x("i<@>?"),Y:x("aU<@,@>?"),R:x("dP<a2<aR>>?"),H:x("~")}})();(function constants(){C.Qx=new A.eZ(!1,null,null,null,A.a6("eZ<i<aR>>"))
C.TB=new B.ac_()})();(function lazyInitializers(){var x=a.lazyFinal
x($,"c9P","u0",()=>{var w=null
return A.xu(B.c1K(),w,w,w,w,"villagesNotifierProvider",A.a6("qb"),y.r)})})()};
(a=>{a["eLkTn4gkybp8LdY+DVCfFqoYaVA="]=a.current})($__dart_deferred_initializers__);