extends Node3D
const W = ["AK-47", "Desert Eagle", "Shotgun", "Sniper", "Rocket Launcher", "Grenades", "Grenade Launcher", "Smoke Grenade", "Flashbang"]
const COLORS = [Color("344e41"), Color("425d78"), Color("713f46"), Color("887457"), Color("363840"), Color("c7c7c7")]
const HAIR = ["Short", "Buzz cut", "Spiked", "Bald"]
var maps = []
var art = preload("res://hd_art.gd").new()
var graphics: OptionButton
var flash_time = 0.0
var muzzle: Node3D
var quality = 1
var preview: Node3D
var preview_phase = 0.0
var preview_ui: Control
var previewing = false
var socket = WebSocketPeer.new()
var connecting = false
var connection_age = 0.0
var authenticated = false
var player_id = ""
var token = ""
var world: Node3D
var effects: Node3D
var camera: Camera3D
var gun: Node3D
var canvas: CanvasLayer
var menu: Control
var hud: Control
var status: Label
var board: Label
var lobby: Label
var name_edit: LineEdit
var url_edit: LineEdit
var code_edit: LineEdit
var map_pick: OptionButton
var outfit_pick: OptionButton
var hair_pick: OptionButton
var start_btn: Button
var join_btn: Button
var hp_label: Label
var clock_label: Label
var ammo_label: Label
var alive_label: Label
var notice_label: Label
var flash_rect: ColorRect
var cross: Label
var touch_labels = []
var zone_nodes = []
var avatars = {}
var targets = {}
var state = {}
var me = {}
var materials = {}
var active = false
var finished = false
var yaw = 0.0
var pitch = 0.0
var weapon = 0
var fire = false
var reload_time = 0.0
var send_time = 0.0
var move = Vector2.ZERO
var left_id = -1
var right_id = -1
var fire_id = -1
var left_origin = Vector2.ZERO
var last_pos = Vector3.ZERO
var last_notice = 0.0
var recoil = 0.0
var sound: AudioStreamPlayer
var gunshot: AudioStreamWAV
var config = ConfigFile.new()
func _ready():
	maps = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps.json"))
	config.load("user://profile.cfg")
	quality = clampi(int(config.get_value("profile","quality",1)),0,2)
	token = str(config.get_value("profile", "token", ""))
	world = Node3D.new()
	add_child(world)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 78
	camera.position = Vector3(0, 1.65, 16)
	gun = Node3D.new()
	camera.add_child(gun)
	gun.position = Vector3(.30, -.28, -.62)
	gun.hide()
	canvas = CanvasLayer.new()
	add_child(canvas)
	make_menu()
	make_hud()
	build_map(0)
	sound = AudioStreamPlayer.new()
	add_child(sound)
	gunshot = AudioStreamWAV.new()
	gunshot.format = AudioStreamWAV.FORMAT_16_BITS
	gunshot.mix_rate = 22050
	var samples = PackedByteArray()
	samples.resize(4400 * 2)
	for i in range(4400):
		var t = float(i) / 22050.0
		var v = (randf_range(-1,1)*0.7 + sin(t*400.0)*0.3)*exp(-t*30.0)*18000.0
		samples.encode_s16(i*2,int(v))
	gunshot.data = samples
	sound.stream = gunshot
func label_at(parent: Node, value: String, pos: Vector2, size: Vector2, font_size: int=23) -> Label:
	var l = Label.new()
	l.text = value
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("f1f4f8"))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
func rectangle(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r = ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r
func btn(parent: Node, title: String, pos: Vector2, size: Vector2, action: Callable) -> Button:
	var b = Button.new()
	b.text = title
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size",22)
	parent.add_child(b)
	b.pressed.connect(action)
	return b
func field(parent: Node, value: String, pos: Vector2, size: Vector2, hint: String) -> LineEdit:
	var e = LineEdit.new()
	e.position = pos
	e.size = size
	e.text = value
	e.placeholder_text = hint
	e.add_theme_font_size_override("font_size",22)
	parent.add_child(e)
	return e
func pick(parent: Node, values: Array, pos: Vector2, size: Vector2) -> OptionButton:
	var o = OptionButton.new()
	o.position = pos
	o.size = size
	o.add_theme_font_size_override("font_size",22)
	for val in values:
		o.add_item(str(val))
	parent.add_child(o)
	return o
func make_menu():
	menu = Control.new()
	canvas.add_child(menu)
	rectangle(menu,Vector2.ZERO,Vector2(1280,720),Color(0.035,0.06,0.105,.88))
	rectangle(menu,Vector2(42,116),Vector2(680,550),Color("142235"))
	rectangle(menu,Vector2(742,116),Vector2(496,550),Color("142235"))
	label_at(menu,"CLOSE QUARTERS  /  HD",Vector2(45,14),Vector2(900,61),48)
	label_at(menu,"LAST STANDING   /   2–4 PLAYERS   /   5 MINUTES",Vector2(48,77),Vector2(900,33),20)
	label_at(menu,"PLAYER PROFILE",Vector2(65,126),Vector2(600,33),24)
	name_edit = field(menu,str(config.get_value("profile","name","Player")),Vector2(65,166),Vector2(630,47),"Player name")
	name_edit.max_length = 20
	outfit_pick = pick(menu,["Forest fatigues","Blue uniform","Crimson jacket","Sand tactical","Urban black","Arctic white"],Vector2(65,225),Vector2(320,48))
	hair_pick = pick(menu,HAIR,Vector2(395,225),Vector2(300,48))
	outfit_pick.select(clampi(int(config.get_value("profile","outfit",0)),0,5))
	hair_pick.select(clampi(int(config.get_value("profile","hair",0)),0,3))
	label_at(menu,"SERVER ADDRESS (WSS)",Vector2(65,284),Vector2(600,30),18)
	var default_url = ""
	if FileAccess.file_exists("res://server_url.txt"):
		default_url = FileAccess.get_file_as_string("res://server_url.txt").strip_edges()
	url_edit = field(menu,str(config.get_value("profile","url",default_url)),Vector2(65,315),Vector2(630,45),"wss://your-game-server.example")
	var map_names = []
	for m in maps:
		map_names.append(m.name)
	map_pick = pick(menu,map_names,Vector2(65,378),Vector2(330,48))
	code_edit = field(menu,"",Vector2(405,378),Vector2(290,48),"Room code (e.g. ARENA1)")
	code_edit.max_length = 12
	join_btn = btn(menu,"CONNECT / JOIN ROOM",Vector2(65,441),Vector2(630,55),join_room)
	start_btn = btn(menu,"START MATCH (HOST)",Vector2(65,505),Vector2(402,49),start_match)
	start_btn.disabled = true
	btn(menu,"LEAVE ROOM",Vector2(477,505),Vector2(218,49),leave_room)
	status = label_at(menu,"Create or enter a room code. Share it with friends.",Vector2(65,569),Vector2(630,72),18)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	graphics = pick(menu,["Performance","HD","Ultra"],Vector2(1030,25),Vector2(206,47))
	graphics.select(quality)
	graphics.item_selected.connect(set_graphics)
	label_at(menu,"Graphics / Poly Haven CC0 assets",Vector2(885,77),Vector2(365,26),15)
	btn(menu,"3D PREVIEW",Vector2(790,25),Vector2(225,47),start_preview)
	label_at(menu,"ROOM / LEADERBOARD",Vector2(762,130),Vector2(450,36),24)
	lobby = label_at(menu,"Not connected",Vector2(762,179),Vector2(450,135),20)
	lobby.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board = label_at(menu,"Connect to see global player rankings.",Vector2(762,330),Vector2(450,310),18)
	board.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
func start_preview():
	if connecting or authenticated or active:
		status.text="Leave the multiplayer room before opening the offline preview."
		return
	build_map(map_pick.selected)
	var spawn=maps[map_pick.selected].spawns[0]
	var origin=Vector3(float(spawn[0]),0,float(spawn[1]))
	var direction=Vector3(-origin.x,0,-origin.z).normalized()
	camera.position=origin+Vector3(0,1.48,0)
	preview=art.character(world,COLORS[outfit_pick.selected],hair_pick.selected)
	preview.position=origin+direction*2.5
	preview.rotation.y=atan2(direction.x,direction.z)
	camera.look_at(preview.position+Vector3(0,1.12,0))
	previewing=true
	preview_phase=0.0
	menu.hide()
	gun.hide()
	preview_ui=Control.new()
	canvas.add_child(preview_ui)
	rectangle(preview_ui,Vector2.ZERO,Vector2(1280,66),Color(.035,.06,.105,.84))
	label_at(preview_ui,"OFFLINE GRAPHICS PREVIEW   /   "+str(maps[map_pick.selected].name),Vector2(26,12),Vector2(950,44),23)
	btn(preview_ui,"BACK",Vector2(1080,8),Vector2(175,48),end_preview)
	label_at(preview_ui,"Character animation showcase   •   idle / run / firing / reload",Vector2(26,650),Vector2(1100,50),22)
func end_preview():
	previewing=false
	if is_instance_valid(preview_ui): preview_ui.queue_free()
	build_map(map_pick.selected)
	camera.position=Vector3(0,1.65,16)
	camera.rotation=Vector3.ZERO
	menu.show()
func make_hud():
	hud = Control.new()
	canvas.add_child(hud)
	rectangle(hud,Vector2(0,0),Vector2(1280,69),Color(0.02,.05,.08,.8))
	hp_label = label_at(hud,"HP 100",Vector2(24,12),Vector2(250,48),28)
	clock_label = label_at(hud,"05:00",Vector2(530,9),Vector2(220,50),34)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alive_label = label_at(hud,"ALIVE 4",Vector2(1000,12),Vector2(260,48),26)
	ammo_label = label_at(hud,"",Vector2(390,651),Vector2(500,57),26)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label = label_at(hud,"",Vector2(280,81),Vector2(720,68),25)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross = label_at(hud,"+",Vector2(615,326),Vector2(50,60),36)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for spec in [["MOVE",Vector2(45,495),Vector2(225,180)],["FIRE",Vector2(1050,490),Vector2(185,115)],["RELOAD",Vector2(1050,615),Vector2(185,75)],["WEAPON  >",Vector2(850,615),Vector2(185,75)],["EXIT",Vector2(25,76),Vector2(110,50)]]:
		rectangle(hud,spec[1],spec[2],Color(.05,.12,.18,.58))
		var l = label_at(hud,spec[0],spec[1],spec[2],23)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	flash_rect = rectangle(hud,Vector2.ZERO,Vector2(1280,720),Color(1,1,1,0))
	hud.hide()
func texture_for(key: String, suffix: String) -> Texture2D:
	for directory in ["online", "hd"]:
		for ext in [".jpg", ".png", ".jpeg"]:
			var path="res://assets/"+directory+"/"+key+"_"+suffix+ext
			if ResourceLoader.exists(path): return load(path) as Texture2D
	return null
func mat(key: String) -> StandardMaterial3D:
	if materials.has(key): return materials[key]
	var m=StandardMaterial3D.new()
	var diffuse=texture_for(key,"diff")
	var file="res://assets/"+key+".jpg"
	if diffuse!=null: m.albedo_texture=diffuse
	elif ResourceLoader.exists(file): m.albedo_texture=load(file)
	m.roughness=.83
	var normal=texture_for(key,"nor")
	if normal!=null:
		m.normal_enabled=true
		m.normal_texture=normal
		m.normal_scale=.65
	var rough=texture_for(key,"rough")
	if rough!=null: m.roughness_texture=rough
	if key in ["metal","server","machine"]: m.metallic=.45
	m.uv1_triplanar=true
	m.uv1_world_triplanar=true
	m.uv1_scale=Vector3(.45,.45,.45)
	materials[key]=m
	return m
func set_graphics(index: int):
	quality=index
	config.set_value("profile","quality",quality)
	config.save("user://profile.cfg")
	if not active: build_map(map_pick.selected)
func apply_graphics():
	get_viewport().msaa_3d=Viewport.MSAA_DISABLED if quality==0 else (Viewport.MSAA_2X if quality==1 else Viewport.MSAA_4X)
	get_viewport().scaling_3d_scale=.75 if quality==0 else (1.0 if quality==1 else 1.15)
func color_mat(c: Color, glow: bool=false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = .65
	if c.a < 1:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow:
		m.emission_enabled = true
		m.emission = Color(c.r,c.g,c.b)
		m.emission_energy_multiplier = .8
	return m
func box(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi
func build_map(index: int):
	for child in world.get_children():
		world.remove_child(child)
		child.queue_free()
	avatars.clear()
	targets.clear()
	zone_nodes.clear()
	var m = maps[index]
	apply_graphics()
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("192c42")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("d9e6fa")
	e.ambient_light_energy = .53
	e.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	e.glow_enabled = quality>0
	e.glow_intensity = .25
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-30,0)
	light.light_energy = .50
	light.shadow_enabled = true
	world.add_child(light)
	box(world,Vector3(0,-.13,0),Vector3(40,.25,40),mat(m.theme))
	for b in m.boxes:
		var h = float(b.h)
		var p = Node3D.new()
		world.add_child(p)
		p.position=Vector3(b.x,0,b.z)
		var size=Vector3(b.w,h,b.d)
		if not art.prop(p,str(b.m),size,mat(b.m)):
			box(p,Vector3(0,h/2,0),size,mat(b.m))
		if b.m=="wall":
			box(p,Vector3(0,.12,0),Vector3(b.w+.035,.24,b.d+.035),art.mat(Color("414c53")))
			box(p,Vector3(0,h-.10,0),Vector3(b.w+.035,.08,b.d+.035),art.mat(Color("aeb7b6")))
	# Overhead structure and luminous ceiling strips, without blocking the playable plane.
	var lum = color_mat(Color("e3f3ff"),true)
	var trim = color_mat(Color("343e4b"))
	for z in [-15,-5,5,15]:
		box(world,Vector3(0,3.65,z),Vector3(39,.20,.18),trim)
		for x in [-14,-5,5,14]:
			box(world,Vector3(x,3.51,z),Vector3(2.4,.07,.24),lum)
	if quality>0:
		for x in [-12,0,12]:
			for z in [-12,0,12]:
				var fixture=OmniLight3D.new()
				fixture.position=Vector3(x,3.30,z)
				fixture.omni_range=14.0
				fixture.light_energy=1.15
				fixture.light_color=Color("f5e9d4") if index in [2,3] else Color("dce9ff")
				fixture.shadow_enabled=quality==2 and x==0 and z==0
				world.add_child(fixture)
	var ceiling = box(world,Vector3(0,3.95,0),Vector3(40,.15,40),color_mat(Color("667383")))
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var zone_mat = color_mat(Color(.15,.68,1,.30),true)
	for i in range(4):
		zone_nodes.append(box(world,Vector3.ZERO,Vector3.ONE,zone_mat))
	update_zone(20)
	effects = Node3D.new()
	world.add_child(effects)
func update_zone(z: float):
	if zone_nodes.size() != 4:
		return
	for i in range(4):
		var n = zone_nodes[i]
		n.visible = z < 19.95
		if i < 2:
			n.position = Vector3(z*(1 if i==0 else -1),1.5,0)
			n.scale = Vector3(.08,3.0,z*2)
		else:
			n.position = Vector3(0,1.5,z*(1 if i==2 else -1))
			n.scale = Vector3(z*2,3.0,.08)
func avatar(p: Dictionary) -> Node3D:
	return art.character(world,COLORS[clampi(int(p.skin.get("clothes",0)),0,5)],int(p.skin.get("hair",0)))
func update_gun():
	for ch in gun.get_children():
		gun.remove_child(ch)
		ch.queue_free()
	art.weapon(gun,weapon)
	var gloves=art.mat(Color("242a2c"))
	art.oval(gun,Vector3(.10,-.17,.04),Vector3(.13,.22,.20),gloves)
	art.oval(gun,Vector3(-.10,-.09,-.30),Vector3(.12,.15,.19),gloves)
	muzzle=Node3D.new()
	gun.add_child(muzzle)
	muzzle.position=Vector3(0,.02,-float([.75,.33,.86,1.04,.85,.25,.68,.25,.25][weapon]))
	art.oval(muzzle,Vector3.ZERO,Vector3(.11,.12,.21),color_mat(Color("ffbd58"),true))
	var light=OmniLight3D.new()
	light.light_color=Color("ffc66e")
	light.light_energy=1.7
	light.omni_range=3.5
	muzzle.add_child(light)
	muzzle.hide()
func send_message(m: Dictionary):
	if socket.get_ready_state()==WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(m))
func join_room():
	var address = url_edit.text.strip_edges()
	var code = code_edit.text.strip_edges().to_upper()
	if not (address.begins_with("wss://") or address.begins_with("ws://")) or code.length()<3:
		status.text = "Enter a valid ws/wss address and a room code (3–12 letters/numbers)."
		return
	if connecting:
		return
	if authenticated:
		send_message({"type":"join","code":code,"map":map_pick.selected})
		return
	config.set_value("profile","name",name_edit.text)
	config.set_value("profile","url",address)
	config.set_value("profile","outfit",outfit_pick.selected)
	config.set_value("profile","hair",hair_pick.selected)
	config.save("user://profile.cfg")
	socket = WebSocketPeer.new()
	var err = socket.connect_to_url(address)
	if err != OK:
		status.text = "Connection failed: " + str(err)
		return
	connecting = true
	connection_age = 0.0
	status.text = "Connecting to game server…"
func start_match():
	send_message({"type":"start"})
func leave_room():
	send_message({"type":"leave"})
	if socket.get_ready_state()==WebSocketPeer.STATE_OPEN:
		socket.close()
	socket = WebSocketPeer.new()
	connecting = false
	authenticated = false
	state.clear()
	me.clear()
	active = false
	finished = false
	fire = false
	left_id = -1
	right_id = -1
	fire_id = -1
	move = Vector2.ZERO
	gun.hide()
	hud.hide()
	menu.show()
	start_btn.disabled = true
	join_btn.disabled = false
	lobby.text = "Not connected"
	status.text = "Choose an arena and room code to join again."
func show_board(rows: Array):
	board.text = "RANK   PLAYER   /   POINTS   /   WINS\n\n"
	for i in range(mini(rows.size(),8)):
		var r = rows[i]
		board.text += "%02d   %s   /   %d   /   %d\n" % [i+1,r.name,int(r.points),int(r.wins)]
func begin(s: Dictionary):
	active = true
	finished = false
	menu.hide()
	hud.show()
	gun.show()
	build_map(int(s.map))
	weapon = 0
	update_gun()
	for p in s.players:
		if p.id==player_id:
			yaw = float(p.yaw)
			pitch = 0.0
			camera.position = Vector3(p.x,1.65,p.z)
			camera.rotation = Vector3(pitch,yaw,0)
			break
func receive(m: Dictionary):
	match str(m.get("type","")):
		"hello":
			authenticated = true
			connecting = false
			player_id = str(m.id)
			token = str(m.token)
			config.set_value("profile","token",token)
			config.save("user://profile.cfg")
			show_board(m.leaderboard)
			send_message({"type":"join","code":code_edit.text.strip_edges().to_upper(),"map":map_pick.selected})
		"joined":
			status.text = "Joined room " + str(m.code) + ". Share the code and arena."
			join_btn.disabled = true
		"leaderboard":
			show_board(m.rows)
		"error":
			status.text = str(m.message)
		"closed":
			leave_room()
			show_board(m.rows)
		"state":
			state = m
			if m.phase=="lobby":
				lobby.text = "%s  |  %d/4 players\n" % [m.code,m.players.size()]
				for p in m.players:
					lobby.text += str(p.name) + (" (host)" if p.id==m.host else "") + "\n"
				start_btn.disabled = m.host!=player_id or m.players.size()<2
			elif m.phase=="match":
				if not active and not finished:
					begin(m)
				update_state(m)
			elif m.phase=="ended" and not finished:
				update_state(m)
				finished = true
				active = false
				gun.hide()
				hud.hide()
				menu.show()
				start_btn.disabled = true
				status.text = "Match finished. Leave room to play again."
				var winner = "No survivor"
				for p in m.players:
					if p.id==m.winner:
						winner = str(p.name)
				lobby.text = ("VICTORY!" if m.winner==player_id else "Winner: "+winner)+"\nKills: %d  |  Damage: %d" % [int(me.get("kills",0)),int(me.get("damage",0))]
				send_message({"type":"leaderboard"})
func update_state(m: Dictionary):
	var count = 0
	for p in m.players:
		if p.alive:
			count += 1
		if p.id==player_id:
			me = p
			continue
		if not avatars.has(p.id):
			avatars[p.id] = avatar(p)
			avatars[p.id].position = Vector3(p.x,0,p.z)
		var a = avatars[p.id]
		a.set_meta("dead",not p.alive)
		a.set_meta("reload",float(p.reload))
		if int(a.get_meta("weapon"))!=int(p.weapon):
			var held: Node3D=a.get_meta("held")
			for child in held.get_children():
				held.remove_child(child)
				child.queue_free()
			art.weapon(held,int(p.weapon))
			a.set_meta("weapon",int(p.weapon))
		targets[p.id] = Vector3(p.x,0,p.z)
		a.rotation.y = float(p.yaw)
	var secs = int(m.remaining)
	clock_label.text = "%02d:%02d" % [int(secs/60.0),secs%60]
	clock_label.modulate = Color("ff906b") if secs<=60 else Color.WHITE
	hp_label.text = "HP %d" % int(ceil(float(me.get("hp",0))))
	alive_label.text = "ALIVE %d" % count
	update_zone(float(m.zone))
	if not me.is_empty():
		ammo_label.text = "%s   %d / %d" % [W[weapon],int(me.ammo[weapon]),int(me.reserve[weapon])]
		if float(me.reload)>0:
			ammo_label.text += "  • RELOADING"
		flash_rect.color = Color(1,1,1,clampf(float(me.flash)/2,0,1))
		if not me.alive:
			gun.hide()
			fire = false
			notice_label.text = "ELIMINATED — wait for match results"
		elif abs(float(me.x))>float(m.zone) or abs(float(me.z))>float(m.zone):
			notice_label.text = "OUTSIDE SAFE ZONE — MOVE TO CENTER"
		elif last_notice<=0:
			notice_label.text = "ZONE SHRINKING" if secs<=60 else ""
	for event in m.events:
		if event.kind=="shot" and event.id==player_id:
			sound.play()
			recoil = .13
			flash_time = .07
		elif event.kind=="shot" and avatars.has(event.id):
			avatars[event.id].set_meta("shot",1.0)
		elif event.kind=="elimination" and bool(me.get("alive",false)):
			notice_label.text = "%s eliminated by %s" % [event.name,event.by]
			last_notice = 2.5
	for ch in effects.get_children():
		effects.remove_child(ch)
		ch.queue_free()
	for e in m.effects:
		var n = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		var radius = 3.8 if e.kind=="smoke" else (1.4 if e.kind=="blast" else .13)
		sphere.radius = radius
		sphere.height = radius*2
		n.mesh = sphere
		var col = Color(.66,.70,.75,.85) if e.kind=="smoke" else (Color(1,.55,.15,.65) if e.kind=="blast" else Color("d3a850"))
		n.material_override = color_mat(col,e.kind=="blast")
		n.position = Vector3(e.x,1.3 if e.kind=="smoke" else .45,e.z)
		effects.add_child(n)
		if e.kind=="smoke":
			for j in range(6):
				var angle=float(j)*TAU/6.0
				var cloud=art.oval(effects,Vector3(float(e.x)+cos(angle)*1.8,1.15+float(j%3)*.4,float(e.z)+sin(angle)*1.8),Vector3(3.5,2.7,3.5),color_mat(Color(.65,.69,.72,.48)))
				cloud.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func _process(delta):
	if previewing and is_instance_valid(preview):
		preview_phase+=delta
		var cycle=fmod(preview_phase,12.0)
		preview.rotation.y+=delta*.30
		preview.set_meta("reload",1.0 if cycle>9 else 0.0)
		if cycle>6 and cycle<9: preview.set_meta("shot",abs(sin(cycle*9)))
		art.animate(preview,delta,4.0 if cycle>3 and cycle<6 else 0.0)
		return
	if connecting or authenticated:
		if connecting:
			connection_age += delta
			if connection_age > 15:
				leave_room()
				status.text = "Connection or sign-in timed out. Check the server address."
				return
		socket.poll()
		var ready = socket.get_ready_state()
		if ready==WebSocketPeer.STATE_OPEN:
			if connecting and not authenticated and not socket.has_meta("hello_sent"):
				socket.set_meta("hello_sent",true)
				send_message({"type":"hello","name":name_edit.text,"token":token,"clothes":outfit_pick.selected,"hair":hair_pick.selected})
			while socket.get_available_packet_count()>0:
				var parsed = JSON.parse_string(socket.get_packet().get_string_from_utf8())
				if parsed is Dictionary:
					receive(parsed)
		elif ready==WebSocketPeer.STATE_CLOSED:
			leave_room()
			status.text = "Disconnected. Check server address and network, then reconnect."
	if not active:
		return
	last_notice = maxf(0,last_notice-delta)
	for id in targets:
		if avatars.has(id):
			var before: Vector3=avatars[id].position
			avatars[id].position = before.lerp(targets[id],minf(delta*15,1))
			art.animate(avatars[id],delta,before.distance_to(avatars[id].position)/maxf(delta,.001))
	if not me.is_empty():
		camera.position = camera.position.lerp(Vector3(me.x,1.65,me.z),minf(delta*16,1))
	camera.rotation = Vector3(pitch,yaw,0)
	recoil = move_toward(recoil,0,delta*1.4)
	flash_time=maxf(0,flash_time-delta)
	if is_instance_valid(muzzle): muzzle.visible=flash_time>0 and not weapon in [5,7,8]
	var bob=sin(Time.get_ticks_msec()*.012)*move.length()*.018
	gun.position = Vector3(.30,-.28+bob,-.62+recoil)
	gun.rotation.x=lerpf(gun.rotation.x,-.55 if float(me.get("reload",0))>0 else recoil*.28,minf(delta*10,1))
	reload_time = maxf(0,reload_time-delta)
	send_time += delta
	if send_time>=.05:
		send_time = 0
		var v = move
		if not OS.has_feature("mobile"):
			v += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		v = v.limit_length(1)
		send_message({"type":"input","x":v.x,"z":v.y,"yaw":yaw,"pitch":pitch,"weapon":weapon,"fire":fire,"reload":reload_time>0})
func change_weapon():
	weapon = (weapon+1)%W.size()
	update_gun()
func aim(relative: Vector2):
	yaw -= relative.x*.0045
	pitch = clampf(pitch-relative.y*.0045,-1.15,1.15)
func pressed_at(pos: Vector2, index: int):
	if Rect2(25,76,110,50).has_point(pos):
		leave_room()
		return
	if Rect2(1050,490,185,115).has_point(pos):
		fire_id = index
		fire = true
	elif Rect2(1050,615,185,75).has_point(pos):
		reload_time = .25
	elif Rect2(850,615,185,75).has_point(pos):
		change_weapon()
	elif pos.x<460 and pos.y>200 and left_id==-1:
		left_id = index
		left_origin = pos
		move = Vector2.ZERO
	elif right_id==-1:
		right_id = index
func release_at(index: int):
	if index==left_id:
		left_id = -1
		move = Vector2.ZERO
	if index==right_id:
		right_id = -1
	if index==fire_id:
		fire_id = -1
		fire = false
func _input(event):
	if not active:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			pressed_at(event.position,event.index)
		else:
			release_at(event.index)
	elif event is InputEventScreenDrag:
		if event.index==left_id:
			move = ((event.position-left_origin)/75.0).limit_length(1)
		elif event.index==right_id:
			aim(event.relative)
	elif not OS.has_feature("mobile"):
		if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			aim(event.relative)
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed and Rect2(25,76,110,50).has_point(event.position):
				leave_room()
			else:
				fire = event.pressed
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode==KEY_R:
				reload_time = .25
			elif event.physical_keycode==KEY_Q:
				change_weapon()
			elif event.physical_keycode==KEY_ESCAPE:
				leave_room()
