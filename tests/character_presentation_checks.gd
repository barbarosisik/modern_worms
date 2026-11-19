extends SceneTree

const STEP := 1.0 / 60.0
# Tip points on the imported blaster meshes, in their source coordinates.
const ROCKET_MUZZLE := Vector3(0.0, 0.004, -0.195)
const SHOTGUN_MUZZLE := Vector3(0.0, 0.078, -0.32005)

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var miska := CampaignActor.new("Miska")
	var nova := CampaignActor.new("Nova")
	root.add_child(miska)
	root.add_child(nova)
	var miska_coat := _coat(miska)
	var nova_coat := _coat(nova)
	_expect(miska_coat != nova_coat, "The cats are distinct even with the same coat choice.")
	nova.set_outfit(2)
	_expect(_coat(nova) != nova_coat and _coat(miska) == miska_coat, "Choosing one coat does not recolor the other cat.")
	if nova._cartoon:
		_expect(nova._model.find_child("NovaBow", true, false) != null, "Nova keeps the bow after changing coat.")
	for actor in [miska, nova]:
		_check_mounts(actor)
		_check_recovery(actor)

	nova.celebrate()
	paused = true
	await process_frame
	await process_frame
	_expect(nova._victory_time > 0.0 and paused, "Victory presentation runs while the match stays paused.")
	for i in range(180):
		await process_frame
	_expect(not nova.is_processing() and nova._clip == nova._idle, "Victory plays once and returns to idle.")
	paused = false
	var rig := "upright" if nova._cartoon else "CC0 fallback"
	miska.free()
	nova.free()
	for failure in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("PASS: character identity, both aim directions, recoil, reactions and paused victory (%s)" % rig)
	quit(0 if _failures.is_empty() else 1)


func _check_mounts(actor: CampaignActor) -> void:
	var head := actor._model.find_child("head_geo", true, false) as MeshInstance3D
	for facing: float in [1.0, -1.0]:
		var paw_name := "socket_hand_r" if facing > 0.0 else "socket_hand_l"
		var paw := actor._model.find_child(paw_name, true, false) as Node3D
		for weapon in [ArtilleryShot.Weapon.ROCKET, ArtilleryShot.Weapon.GRENADE, ArtilleryShot.Weapon.SHOTGUN]:
			for angle in [AimControls.MIN_ANGLE, 0.0, AimControls.MAX_ANGLE]:
				actor.equip(angle, weapon, true, true)
				for i in range(12):
					actor.pose(facing, 0.0, STEP)
				var view := actor._weapon_views[weapon]
				_expect(view.is_visible_in_tree(), "The selected weapon is visible while aiming.")
				if paw != null:
					var separation := actor._weapon_pivot.global_position.distance_to(paw.global_position)
					_expect(separation < 0.025, "The equipped weapon tracks the near paw in both directions.")
				if weapon == ArtilleryShot.Weapon.GRENADE:
					continue
				var expected := Vector3(cos(deg_to_rad(angle)) * facing, sin(deg_to_rad(angle)), 0.0)
				var barrel := -view.global_basis.z.normalized()
				_expect(expected.dot(barrel) > 0.995, "The barrel follows the requested shot direction.")
				if head != null:
					var tip := ROCKET_MUZZLE if weapon == ArtilleryShot.Weapon.ROCKET else SHOTGUN_MUZZLE
					_expect(not head.get_aabb().has_point(head.to_local(view.to_global(tip))),
						"The muzzle clears the head: %s, facing %s, angle %s." % [weapon, facing, angle])


func _check_recovery(actor: CampaignActor) -> void:
	actor.fire_animation(-1.0, 30.0, ArtilleryShot.Weapon.SHOTGUN)
	actor.equip(0.0, ArtilleryShot.Weapon.ROCKET, false, false)
	actor.pose(1.0, 0.0, STEP)
	_expect(actor._weapon_views[ArtilleryShot.Weapon.SHOTGUN].is_visible_in_tree()
		and actor._weapon_pivot.global_basis.x.x < 0.0, "Recoil keeps the fired weapon and direction across a turn change.")
	actor.hurt_animation()
	actor.pose(1.0, 0.0, STEP)
	_expect(not actor._weapon_pivot.visible, "Hurt interrupts the weapon pose.")
	for i in range(80):
		actor.pose(1.0, 2.0, STEP)
	_expect(actor._clip == actor._walk and actor._animation.is_playing(), "Hurt ends and walking resumes.")
	for i in range(100):
		actor.pose(1.0, 0.0, STEP, false)
	if not actor._jump.is_empty():
		_expect(actor._clip == actor._jump and not actor._animation.is_playing(), "A long fall does not loop the jump clip.")
	actor.pose(1.0, 0.0, STEP)
	_expect(actor._clip == actor._idle, "Landing returns to idle.")


func _coat(actor: CampaignActor) -> Color:
	var mesh := actor._model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	return (mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_color


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
