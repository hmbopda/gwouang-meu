((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
bnI(d,e){var x=0,w=B.u(y.Z),v,u,t,s,r
var $async$bnI=B.p(function(f,g){if(f===1)return B.q(g,w)
for(;;)switch(x){case 0:r=J
x=3
return B.o(d.aj(0,$.eD(),y.L).dV(0,"/api/v1/chat/groups/village/"+e),$async$bnI)
case 3:u=r.as(g,"data")
t=y._.b(u)?u:[]
s=J.bs(t,new A.bnJ(),y.K)
s=B.Y(s,s.$ti.h("al.E"))
v=s
x=1
break
case 1:return B.r(v,w)}})
return B.t($async$bnI,w)},
K5(d){return new A.K4(d,new A.avF(d),E.Sq,null,"chatGroupsProvider",null,null)},
bnJ:function bnJ(){},
a_z:function a_z(){},
K4:function K4(d,e,f,g,h,i,j){var _=this
_.fr=d
_.ay=e
_.ch=$
_.e=f
_.f=g
_.a=h
_.b=i
_.c=j},
avF:function avF(d){this.a=d},
K6:function K6(){},
afd:function afd(d,e,f,g,h,i,j,k,l){var _=this
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
aqc:function aqc(){},
aW2(d){var x,w="createdAt",v=J.ap(d),u=B.ax(v.i(d,"id")),t=B.aA(v.i(d,"villageId")),s=B.aA(v.i(d,"familyClan")),r=B.ax(v.i(d,"name")),q=B.aA(v.i(d,"description")),p=B.ax(v.i(d,"type")),o=B.k3(v.i(d,"memberCount"))
o=o==null?null:C.j.dq(o)
if(o==null)o=0
x=B.ax(v.i(d,"createdBy"))
return new A.RB(u,t,s,r,q,p,o,x,v.i(d,w)==null?null:B.jG(B.ax(v.i(d,w))))},
RB:function RB(d,e,f,g,h,i,j,k,l){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i
_.r=j
_.w=k
_.x=l}},E,D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[19],A)
E=c[77]
D=c[25]
A.a_z.prototype={
$1(d){return A.K5(d)},
nN(d){return A.K5(d.fr)},
gku(){return null},
glN(){return null}}
A.K4.prototype={
cf(d){var x=null
return new A.afd(!1,new B.cb(B.b9(0,x,!1,y.b),y.O),x,x,x,x,this,B.dm(x,x,x,y.M,y.C),B.b([],y.j))},
k(d,e){if(e==null)return!1
return e instanceof A.K4&&e.fr===this.fr},
gB(d){return D.bu2(D.WI(D.WI(0,B.em(B.G(this))),C.c.gB(this.fr)))}}
A.K6.prototype={}
A.afd.prototype={}
A.aqc.prototype={}
A.RB.prototype={
j(d){var x=this
return"ChatGroupModel(id: "+x.a+", villageId: "+B.j(x.b)+", familyClan: "+B.j(x.c)+", name: "+x.d+", description: "+B.j(x.e)+", type: "+x.f+", memberCount: "+x.r+", createdBy: "+x.w+", createdAt: "+B.j(x.x)+")"},
k(d,e){var x,w,v=this
if(e==null)return!1
if(v!==e){x=!1
if(J.ah(e)===B.G(v))if(e instanceof A.RB){w=e.a===v.a
if(w||w){w=e.b==v.b
if(w||w){w=e.c==v.c
if(w||w){w=e.d===v.d
if(w||w){w=e.e==v.e
if(w||w){w=e.f===v.f
if(w||w){w=e.r===v.r
if(w||w){w=e.w===v.w
if(w||w){x=e.x
w=v.x
x=x==w||J.d(x,w)}}}}}}}}}}else x=!0
return x},
gB(d){var x=this
return B.a5(B.G(x),x.a,x.b,x.c,x.d,x.e,x.f,x.r,x.w,x.x,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
cT(){var x=this,w=x.x
w=w==null?null:w.ii()
return B.ar(["id",x.a,"villageId",x.b,"familyClan",x.c,"name",x.d,"description",x.e,"type",x.f,"memberCount",x.r,"createdBy",x.w,"createdAt",w],y.N,y.A)},
$ic_:1,
gT(d){return this.a},
gadw(){return this.c},
gbu(d){return this.d},
grN(d){return this.e},
gde(d){return this.f},
ghe(){return this.r},
gft(){return this.x}}
var z=a.updateTypes([])
A.bnJ.prototype={
$1(d){return A.aW2(y.P.a(d))},
$S:323}
A.avF.prototype={
$1(d){return A.bnI(y.z.a(d),this.a)},
$S:324};(function inheritance(){var x=a.mixin,w=a.inheritMany,v=a.inherit
w(B.ev,[A.bnJ,A.avF])
v(A.a_z,B.dU)
v(A.K4,B.f9)
w(B.w,[A.K6,A.RB])
v(A.aqc,B.lL)
v(A.afd,A.aqc)
x(A.aqc,A.K6)})()
B.fE(b.typeUniverse,JSON.parse('{"K4":{"f9":["i<c_>"],"qk":["i<c_>"],"c2":["ag<i<c_>>"],"bZ":[],"c1":["ag<i<c_>>"],"cY":[],"c2.0":"ag<i<c_>>","f9.T":"i<c_>","c1.0":"ag<i<c_>>"},"a_z":{"dU":["ag<i<c_>>"],"bZ":[],"cY":[]},"afd":{"lL":["i<c_>"],"jM":["i<c_>"],"iV":["i<c_>"],"K6":[],"cg":["i<c_>"],"eT":["ag<i<c_>>"],"eS":["i<c_>"],"b5":["ag<i<c_>>"],"d7":["ag<i<c_>>"],"b5.0":"ag<i<c_>>","cg.T":"i<c_>","iV.T":"i<c_>","jM.T":"i<c_>"},"RB":{"c_":[]}}'))
var y=(function rtii(){var x=B.a6
return{L:x("k8"),K:x("c_"),z:x("K6"),j:x("z<b5<w?>>"),Z:x("i<c_>"),_:x("i<@>"),P:x("aU<h,@>"),C:x("w"),M:x("b5<w?>"),O:x("cb<a2<i<c_>>>"),N:x("h"),A:x("@"),b:x("dP<a2<i<c_>>>?")}})();(function constants(){E.Sq=new A.a_z()})()};
(a=>{a["RgN5MFLw2uEDAx5mP0obxaM82a8="]=a.current})($__dart_deferred_initializers__);