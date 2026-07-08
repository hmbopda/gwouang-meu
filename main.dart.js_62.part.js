((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,D,B={
CG(d){return new B.K7(d,new B.avG(d),E.Sr,null,"chatMessagesNotifierProvider",null,null)},
iA:function iA(){this.a=this.b=this.d=$},
avI:function avI(){},
ae1:function ae1(){},
a_A:function a_A(){},
K7:function K7(d,e,f,g,h,i,j){var _=this
_.fy=d
_.CW=_.ch=$
_.y=e
_.e=f
_.f=g
_.a=h
_.b=i
_.c=j},
avG:function avG(d){this.a=d},
avH:function avH(){},
aff:function aff(d,e,f,g,h,i,j,k,l,m){var _=this
_.kv$=d
_.go=e
_.hD$=f
_.hP$=g
_.hr$=h
_.hc$=i
_.h0$=j
_.c=$
_.d=k
_.e=$
_.r=l
_.y=_.x=_.w=null
_.z=m
_.CW=_.ch=_.ay=_.ax=_.at=_.as=_.Q=null
_.fx=_.dy=_.dx=_.db=_.cy=_.cx=!1
_.fy=null},
aqd:function aqd(){},
RC:function RC(d,e,f,g,h,i,j,k){var _=this
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
D=c[25]
B=a.updateHolder(c[18],B)
E=c[76]
B.iA.prototype={
v(d){return this.aOO(d)},
aOO(d){var x=0,w=A.u(y.I),v,u=this
var $async$v=A.p(function(e,f){if(e===1)return A.q(f,w)
for(;;)switch(x){case 0:u.d=d
v=u.GY()
x=1
break
case 1:return A.r(v,w)}})
return A.t($async$v,w)},
GY(){var x=0,w=A.u(y.I),v,u=this,t,s,r,q,p
var $async$GY=A.p(function(d,e){if(d===1)return A.q(e,w)
for(;;)switch(x){case 0:q=u.a
q===$&&A.a()
t=q.aj(0,$.eD(),y.L)
q=u.d
q===$&&A.a()
p=J
x=3
return A.o(t.kP(0,"/api/v1/chat/groups/"+q+"/messages",A.ar(["limit",50],y.N,y.z)),$async$GY)
case 3:s=p.as(e,"data")
r=y._.b(s)?s:[]
q=J.bs(r,new B.avI(),y.W)
q=A.Y(q,q.$ti.h("al.E"))
v=q
x=1
break
case 1:return A.r(v,w)}})
return A.t($async$GY,w)},
w5(d){return this.ak9(d)},
ak9(d){var x=0,w=A.u(y.H),v=this,u,t,s,r
var $async$w5=A.p(function(e,f){if(e===1)return A.q(f,w)
for(;;)switch(x){case 0:r=v.a
r===$&&A.a()
u=r.aj(0,$.eD(),y.L)
t=v.d
t===$&&A.a()
s=y.N
x=2
return A.o(u.hK("/api/v1/chat/groups/"+t+"/messages",A.ar(["content",d],s,s)),$async$w5)
case 2:r.ld()
x=3
return A.o(v.ghQ(),$async$w5)
case 3:return A.r(null,w)}})
return A.t($async$w5,w)},
fh(d){var x=0,w=A.u(y.H),v=this,u
var $async$fh=A.p(function(e,f){if(e===1)return A.q(f,w)
for(;;)switch(x){case 0:u=v.a
u===$&&A.a()
u.ld()
x=2
return A.o(v.ghQ(),$async$fh)
case 2:return A.r(null,w)}})
return A.t($async$fh,w)}}
B.ae1.prototype={}
B.a_A.prototype={
$1(d){return B.CG(d)},
nN(d){return B.CG(d.fy)},
gku(){return null},
glN(){return null}}
B.K7.prototype={
vQ(d){return d.v(this.fy)},
cf(d){var x=null
return new B.aff(!1,new A.cb(A.b9(0,x,!1,y.y),y.s),new A.cb(A.b9(0,x,!1,y.A),y.p),x,x,x,x,this,A.dm(x,x,x,y.M,y.K),A.b([],y.j))},
k(d,e){if(e==null)return!1
return e instanceof B.K7&&e.fy===this.fy},
gB(d){return D.bu2(D.WI(D.WI(0,A.em(A.G(this))),C.c.gB(this.fy)))}}
B.avH.prototype={}
B.aff.prototype={}
B.aqd.prototype={}
B.RC.prototype={
j(d){var x=this
return"ChatMessageModel(id: "+x.a+", groupId: "+x.b+", senderId: "+x.c+", senderName: "+A.j(x.d)+", senderAvatarUrl: "+A.j(x.e)+", content: "+x.f+", type: "+x.r+", createdAt: "+A.j(x.w)+")"},
k(d,e){var x,w,v=this
if(e==null)return!1
if(v!==e){x=!1
if(J.ah(e)===A.G(v))if(e instanceof B.RC){w=e.a===v.a
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
gB(d){var x=this
return A.a5(A.G(x),x.a,x.b,x.c,x.d,x.e,x.f,x.r,x.w,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a,C.a)},
cT(){var x=this,w=x.w
w=w==null?null:w.ii()
return A.ar(["id",x.a,"groupId",x.b,"senderId",x.c,"senderName",x.d,"senderAvatarUrl",x.e,"content",x.f,"type",x.r,"createdAt",w],y.N,y.z)},
$idd:1,
gT(d){return this.a},
gFM(){return this.c},
gtO(){return this.d},
glU(d){return this.f},
gde(d){return this.r},
gft(){return this.w}}
var z=a.updateTypes(["dd(@)","iA()"])
B.avI.prototype={
$1(d){var x,w,v,u,t,s,r,q,p="createdAt"
y.P.a(d)
x=J.ap(d)
w=A.ax(x.i(d,"id"))
v=A.ax(x.i(d,"groupId"))
u=A.ax(x.i(d,"senderId"))
t=A.aA(x.i(d,"senderName"))
s=A.aA(x.i(d,"senderAvatarUrl"))
r=A.ax(x.i(d,"content"))
q=A.aA(x.i(d,"type"))
if(q==null)q="TEXT"
return new B.RC(w,v,u,t,s,r,q,x.i(d,p)==null?null:A.jG(A.ax(x.i(d,p))))},
$S:z+0}
B.avG.prototype={
$0(){var x=new B.iA()
x.b=this.a
return x},
$S:z+1};(function inheritance(){var x=a.mixin,w=a.inherit,v=a.inheritMany
w(B.ae1,A.dk)
w(B.iA,B.ae1)
w(B.avI,A.ev)
w(B.a_A,A.dU)
w(B.K7,A.ei)
w(B.avG,A.hm)
v(A.w,[B.avH,B.RC])
w(B.aqd,A.ka)
w(B.aff,B.aqd)
x(B.aqd,B.avH)})()
A.fE(b.typeUniverse,JSON.parse('{"iA":{"dk":["i<dd>"],"eu":["i<dd>"],"dk.0":"i<dd>"},"K7":{"ei":["iA","i<dd>"],"mI":["iA","i<dd>"],"c2":["ag<i<dd>>"],"bZ":[],"c1":["ag<i<dd>>"],"cY":[],"c2.0":"ag<i<dd>>","ei.0":"iA","ei.T":"i<dd>","c1.0":"ag<i<dd>>"},"ae1":{"dk":["i<dd>"],"eu":["i<dd>"]},"a_A":{"dU":["ag<i<dd>>"],"bZ":[],"cY":[]},"aff":{"ka":["iA","i<dd>"],"dM":["iA","i<dd>"],"nL":["iA","i<dd>"],"ha":["iA","i<dd>"],"cg":["i<dd>"],"eT":["ag<i<dd>>"],"b5":["ag<i<dd>>"],"d7":["ag<i<dd>>"],"b5.0":"ag<i<dd>>","cg.T":"i<dd>","ha.T":"i<dd>","dM.0":"iA","dM.T":"i<dd>"},"RC":{"dd":[]}}'))
var y=(function rtii(){var x=A.a6
return{L:x("k8"),W:x("dd"),j:x("z<b5<w?>>"),I:x("i<dd>"),_:x("i<@>"),P:x("aU<h,@>"),K:x("w"),M:x("b5<w?>"),s:x("cb<iA>"),p:x("cb<a2<i<dd>>>"),N:x("h"),z:x("@"),y:x("dP<iA>?"),A:x("dP<a2<i<dd>>>?"),H:x("~")}})();(function constants(){E.Sr=new B.a_A()})()};
(a=>{a["mmFkYh+BFykZrEPnv+6GdmHBtNc="]=a.current})($__dart_deferred_initializers__);