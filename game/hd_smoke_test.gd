extends SceneTree
func _initialize():
	call_deferred("run_checks")
func run_checks():
	var scene=load("res://main.tscn") as PackedScene
	var client=scene.instantiate()
	root.add_child(client)
	await process_frame
	for i in range(5):
		client.build_map(i)
		await process_frame
		print("Arena constructed: ",client.maps[i].name)
	for i in range(6):
		for h in range(4):
			var actor=client.art.character(client.world,Color(["344e41","425d78","713f46","887457","363840","c7c7c7"][i]),h)
			client.art.animate(actor,.016,4.0)
			actor.set_meta("reload",1.0)
			actor.set_meta("shot",1.0)
			client.art.animate(actor,.016,0.0)
			actor.set_meta("dead",true)
			client.art.animate(actor,.016,0.0)
			actor.free()
	for i in range(9):
		client.weapon=i
		client.update_gun()
	client.start_preview()
	await process_frame
	client.end_preview()
	await process_frame
	print("HD scene construction checks completed")
	quit()
