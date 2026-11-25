extends RefCounted
# Original articulated character and environment detail; no external dependency.
var cache: Dictionary = {}
func mat(c: Color, metal: float=0.0, rough: float=.72) -> StandardMaterial3D:
	var key = str(c)+str(metal)+str(rough)
	if cache.has(key): return cache[key]
	var m = StandardMaterial3D.new()
	m.albedo_color=c
	m.metallic=metal
	m.roughness=rough
	cache[key]=m
	return m
func part(parent: Node3D, mesh: Mesh, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var n=MeshInstance3D.new()
	n.mesh=mesh
	n.position=pos
	n.scale=size
	n.material_override=material
	parent.add_child(n)
	return n
func cube(p: Node3D, at: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
	var mesh=BoxMesh.new()
	mesh.size=Vector3.ONE
	return part(p,mesh,at,size,m)
func oval(p: Node3D, at: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
	var mesh=SphereMesh.new()
	mesh.radius=.5
	mesh.height=1.0
	mesh.radial_segments=20
	mesh.rings=10
	return part(p,mesh,at,size,m)
func tube(p: Node3D, at: Vector3, size: Vector3, m: Material, taper: float=.8) -> MeshInstance3D:
	var mesh=CylinderMesh.new()
	mesh.top_radius=.5*taper
	mesh.bottom_radius=.5
	mesh.height=1.0
	mesh.radial_segments=16
	return part(p,mesh,at,size,m)
func pivot(p: Node3D, at: Vector3) -> Node3D:
	var n=Node3D.new()
	p.add_child(n)
	n.position=at
	return n
func character(p: Node3D, outfit: Color, hair: int) -> Node3D:
	var root=pivot(p,Vector3.ZERO)
	var body=pivot(root,Vector3.ZERO)
	var uniform=mat(outfit)
	var skin=mat(Color("b78568"),0,.56)
	var dark=mat(Color("23282a"),0,.76)
	var vest=mat(outfit.darkened(.36),0,.84)
	var buckle=mat(Color("6a7479"),.65,.35)
	var hairmat=mat(Color("251f1b"))
	oval(body,Vector3(0,1.12,0),Vector3(.49,.62,.30),uniform)
	oval(body,Vector3(0,.85,0),Vector3(.43,.30,.31),uniform)
	oval(body,Vector3(0,1.20,-.04),Vector3(.49,.40,.31),vest)
	cube(body,Vector3(0,.89,0),Vector3(.43,.075,.32),dark)
	cube(body,Vector3(0,.89,-.17),Vector3(.085,.062,.025),buckle)
	for x in [-.15,0.0,.15]:
		cube(body,Vector3(x,1.10,-.17),Vector3(.115,.16,.072),vest)
		cube(body,Vector3(x,1.16,-.21),Vector3(.095,.04,.025),dark)
	for x in [-.17,.17]:
		cube(body,Vector3(x,1.35,-.07),Vector3(.08,.11,.26),dark)
	oval(body,Vector3(0,1.2,.17),Vector3(.38,.42,.22),vest)
	tube(body,Vector3(0,1.46,0),Vector3(.13,.16,.13),skin)
	var head=pivot(body,Vector3(0,1.49,0))
	oval(head,Vector3(0,.14,0),Vector3(.265,.34,.26),skin)
	oval(head,Vector3(0,.055,-.025),Vector3(.205,.17,.21),skin)
	oval(head,Vector3(0,.135,-.139),Vector3(.055,.065,.06),skin)
	for x in [-.067,.067]:
		oval(head,Vector3(x,.175,-.119),Vector3(.05,.026,.019),mat(Color("e5dfd6")))
		oval(head,Vector3(x,.175,-.13),Vector3(.023,.023,.012),dark)
		oval(head,Vector3(x,.202,-.117),Vector3(.060,.014,.025),hairmat)
	for x in [-.13,.13]: oval(head,Vector3(x,.13,0),Vector3(.043,.08,.055),skin)
	oval(head,Vector3(0,.082,-.128),Vector3(.079,.015,.025),mat(Color("775043")))
	if hair!=3:
		oval(head,Vector3(0,.265,.015),Vector3(.276,.10 if hair==1 else .16,.267),hairmat)
		if hair==2:
			for x in [-.075,0.0,.075]:
				var tuft=tube(head,Vector3(x,.33,-.015),Vector3(.084,.13,.085),hairmat,.15)
				tuft.rotation.z=x*3
	var legs: Array[Node3D]=[]
	var knees: Array[Node3D]=[]
	var arms: Array[Node3D]=[]
	var elbows: Array[Node3D]=[]
	for sign_value in [-1.0,1.0]:
		var thigh=pivot(body,Vector3(sign_value*.13,.83,0))
		oval(thigh,Vector3(0,-.19,0),Vector3(.235,.43,.24),uniform)
		cube(thigh,Vector3(sign_value*.09,-.15,0),Vector3(.095,.19,.17),vest)
		var knee=pivot(thigh,Vector3(0,-.40,0))
		oval(knee,Vector3(0,-.16,0),Vector3(.185,.35,.19),uniform)
		oval(knee,Vector3(0,0,-.075),Vector3(.18,.17,.09),dark)
		oval(knee,Vector3(0,-.36,-.045),Vector3(.205,.17,.32),dark)
		cube(knee,Vector3(0,-.435,-.045),Vector3(.205,.045,.30),dark)
		legs.append(thigh)
		knees.append(knee)
		var arm=pivot(body,Vector3(sign_value*.265,1.32,0))
		oval(arm,Vector3(0,-.13,0),Vector3(.21,.34,.22),uniform)
		var elbow=pivot(arm,Vector3(0,-.27,0))
		oval(elbow,Vector3(0,-.115,0),Vector3(.155,.29,.16),uniform)
		oval(elbow,Vector3(0,-.27,0),Vector3(.115,.16,.14),dark)
		arms.append(arm)
		elbows.append(elbow)
	var held=pivot(body,Vector3(.13,1.14,-.36))
	weapon(held,0)
	root.set_meta('body',body)
	root.set_meta('legs',legs)
	root.set_meta('knees',knees)
	root.set_meta('arms',arms)
	root.set_meta('elbows',elbows)
	root.set_meta('held',held)
	root.set_meta('weapon',0)
	root.set_meta('phase',0.0)
	root.set_meta('shot',0.0)
	root.set_meta('reload',0.0)
	root.set_meta('dead',false)
	return root
func animate(root: Node3D, delta: float, speed: float):
	var body: Node3D=root.get_meta('body')
	var phase: float=root.get_meta('phase')
	phase+=delta*(2.0+speed*2.2)
	root.set_meta('phase',phase)
	var shot: float=maxf(0.0,float(root.get_meta('shot'))-delta*4.0)
	root.set_meta('shot',shot)
	var reload: float=float(root.get_meta('reload'))
	var dead: bool=root.get_meta('dead')
	body.rotation.z=lerpf(body.rotation.z,1.50 if dead else 0.0,minf(1,delta*7))
	var amp=clampf(speed/4.0,0,1)
	body.position.y=lerpf(body.position.y,-.67 if dead else abs(sin(phase))*.055*amp,minf(1,delta*10))
	var legs: Array=root.get_meta('legs')
	var knees: Array=root.get_meta('knees')
	var arms: Array=root.get_meta('arms')
	var elbows: Array=root.get_meta('elbows')
	for i in range(2):
		var swing=sin(phase+float(i)*PI)*amp
		legs[i].rotation.x=swing*.62
		knees[i].rotation.x=maxf(0,-swing)*.65
		arms[i].rotation.x=-.95+swing*.10+shot*.18+(.42 if reload>0 else 0.0)
		arms[i].rotation.z=(-.15 if i==0 else .15)
		elbows[i].rotation.x=-.73+shot*.20
	var held: Node3D=root.get_meta('held')
	held.rotation.x=shot*.12+(.55 if reload>0 else 0.0)
	held.position.z=-.36+shot*.045
func weapon(p: Node3D, w: int):
	var black=mat(Color('252a2e'),.35,.43)
	var steel=mat(Color('616a70'),.75,.31)
	var grip=mat(Color('353a36'),0,.87)
	var accent=mat(Color('79604a'),0,.68)
	if w in [5,7,8]:
		oval(p,Vector3(0,0,-.05),Vector3(.15,.22,.15),grip if w==5 else steel)
		tube(p,Vector3(0,.11,-.05),Vector3(.09,.06,.09),steel)
		cube(p,Vector3(.05,.06,-.05),Vector3(.035,.13,.035),black)
		for y in [-.06,0.0,.06]: tube(p,Vector3(0,y,-.05),Vector3(.156,.014,.156),black)
		return
	var length: float=[.73,.31,.85,1.02,.82,.25,.67,.25,.25][w]
	cube(p,Vector3(0,0,-length*.29),Vector3(.14,.14,length*.56),black)
	var barrel=tube(p,Vector3(0,.015,-length*.73),Vector3(.075,.075 if w==1 else length*.45,.075),steel)
	barrel.rotation.x=PI/2
	cube(p,Vector3(0,-.105,-.035),Vector3(.09,.17,.12),grip)
	cube(p,Vector3(0,.09,-length*.27),Vector3(.10,.028,length*.49),steel)
	if w!=1:
		cube(p,Vector3(0,-.01,.12),Vector3(.12,.13,.24),grip)
		for i in range(7): cube(p,Vector3(0,.082,-.13-i*.028),Vector3(.105,.019,.014),black)
	if w in [0,2,6]:
		var magazine=cube(p,Vector3(0,-.135,-.22),Vector3(.10,.20,.14),steel)
		magazine.rotation.x=.17
	if w==0:
		cube(p,Vector3(0,0,-.34),Vector3(.15,.13,.21),accent)
	if w==3:
		var scope=tube(p,Vector3(0,.15,-.26),Vector3(.12,.30,.12),black)
		scope.rotation.x=PI/2
	if w==4 or w==6:
		var launcher=tube(p,Vector3(0,.015,-length*.38),Vector3(.18,length*.65,.18),grip)
		launcher.rotation.x=PI/2
	cube(p,Vector3(0,.1,-length*.88),Vector3(.025,.065,.025),steel)
	cube(p,Vector3(0,.095,-.045),Vector3(.09,.045,.035),black)
func mesh_bounds(n: Node3D, xform: Transform3D, all_bounds: Array[AABB]):
	var t=xform*n.transform
	if n is MeshInstance3D and n.mesh!=null:
		all_bounds.append(t*n.get_aabb())
	for child in n.get_children():
		if child is Node3D: mesh_bounds(child,t,all_bounds)
func online_prop(parent: Node3D, key: String, size: Vector3) -> bool:
	var path='res://assets/online/'+key+'/model.gltf'
	if not ResourceLoader.exists(path): return false
	var scene=load(path) as PackedScene
	if scene==null: return false
	var model=scene.instantiate() as Node3D
	if model==null: return false
	var bounds: Array[AABB]=[]
	mesh_bounds(model,Transform3D.IDENTITY,bounds)
	if bounds.is_empty():
		model.free()
		return false
	var a=bounds[0]
	for b in bounds: a=a.merge(b)
	if minf(a.size.x,minf(a.size.y,a.size.z))<.001:
		model.free()
		return false
	var wrapper=pivot(parent,Vector3.ZERO)
	wrapper.scale=size/a.size*.98
	var anchor=pivot(wrapper,-Vector3(a.get_center().x,a.position.y,a.get_center().z))
	anchor.add_child(model)
	return true
func prop(p: Node3D, key: String, size: Vector3, base: Material) -> bool:
	var w=size.x
	var h=size.y
	var d=size.z
	var steel=mat(Color('6e797e'),.7,.33)
	var black=mat(Color('272d31'),.25,.5)
	var white=mat(Color('dedbd0'))
	var blue=mat(Color('456e79'))
	var yellow=mat(Color('d3a52d'))
	var wood=mat(Color('775b42'))
	if key in ['desk','sofa','crate'] and online_prop(p,key,size):
		return true
	match key:
		'desk':
			cube(p,Vector3(0,h*.69,0),Vector3(w,h*.09,d),wood)
			for x in [-w*.42,w*.42]: cube(p,Vector3(x,h*.34,0),Vector3(w*.09,h*.68,d*.80),steel)
			for x in [-w*.24,w*.24]:
				cube(p,Vector3(x,h*.78,0),Vector3(w*.14,h*.045,d*.36),black)
				cube(p,Vector3(x,h*.85,.10),Vector3(w*.027,h*.18,d*.08),steel)
				cube(p,Vector3(x,h*.89,.13),Vector3(w*.35,h*.22,d*.045),black)
				cube(p,Vector3(x,h*.89,.095),Vector3(w*.32,h*.18,d*.015),blue)
		'bed':
			cube(p,Vector3(0,h*.43,0),Vector3(w*.96,h*.10,d*.88),steel)
			cube(p,Vector3(0,h*.56,0),Vector3(w*.94,h*.20,d*.85),white)
			cube(p,Vector3(0,h*.68,-d*.29),Vector3(w*.69,h*.10,d*.20),white)
			cube(p,Vector3(0,h*.68,d*.12),Vector3(w*.96,h*.07,d*.55),blue)
			for z in [-d*.44,d*.44]:
				cube(p,Vector3(0,h*.81,z),Vector3(w*.96,h*.36,d*.055),steel)
			for x in [-w*.38,w*.38]:
				for z in [-d*.31,d*.31]:
					tube(p,Vector3(x,h*.20,z),Vector3(.06,h*.40,.06),steel)
					var wheel=tube(p,Vector3(x,.10,z),Vector3(.13,.05,.13),black)
					wheel.rotation.z=PI/2
		'sofa':
			cube(p,Vector3(0,h*.31,0),Vector3(w,h*.48,d),base)
			cube(p,Vector3(0,h*.73,d*.35),Vector3(w,h*.54,d*.30),base)
			for x in [-w*.44,w*.44]: oval(p,Vector3(x,h*.60,0),Vector3(w*.15,h*.40,d*.92),base)
			for x in [-w*.26,0.0,w*.26]: oval(p,Vector3(x,h*.57,-d*.10),Vector3(w*.28,h*.19,d*.66),base)
		'machine','server':
			cube(p,Vector3(0,h*.50,0),Vector3(w*.97,h,d*.97),base)
			cube(p,Vector3(0,h*.59,-d*.495),Vector3(w*.65,h*.60,.025),black)
			for i in range(7):
				cube(p,Vector3(0,h*(.34+i*.075),-d*.50),Vector3(w*.57,h*.029,.035),steel)
				cube(p,Vector3(w*.22,h*(.34+i*.075),-d*.522),Vector3(.035,.035,.02),yellow if i%3==0 else blue)
			for x in [-w*.42,w*.42]: cube(p,Vector3(x,h*.50,-d*.49),Vector3(w*.055,h*.98,.025),steel)
		'glass':
			# Solid frosted partitions preserve the original server-side occlusion rules.
			cube(p,Vector3(0,h*.50,0),size,mat(Color('9aafb4'),.25,.30))
			for y in [.05,h-.05,h*.5]: cube(p,Vector3(0,y,0),Vector3(w,.055,d+.018),steel)
			for i in range(5): cube(p,Vector3(-w*.48+i*w*.24,h*.50,0),Vector3(.045,h,d+.025),steel)
		'art':
			cube(p,Vector3(0,h*.50,0),size,base)
			for z in [-1.0,1.0]:
				cube(p,Vector3(0,h*.63,z*(d*.50+.014)),Vector3(w*.67,h*.49,.035),wood)
				cube(p,Vector3(0,h*.63,z*(d*.50+.036)),Vector3(w*.59,h*.43,.012),white)
				for i in range(3):
					var v=cube(p,Vector3((i-1)*w*.13,h*(.59+i*.035),z*(d*.50+.045)),Vector3(w*.16,h*.22,.009),[blue,yellow,black][i])
					v.rotation.z=(i-1)*.26
		'crate':
			cube(p,Vector3(0,h*.50,0),size,wood)
			for x in [-w*.43,w*.43]: cube(p,Vector3(x,h*.50,-d*.50),Vector3(w*.10,h,.035),steel)
			for y in [.06,h-.06]: cube(p,Vector3(0,y,-d*.50),Vector3(w,.11,.04),steel)
		_: return false
	return true
