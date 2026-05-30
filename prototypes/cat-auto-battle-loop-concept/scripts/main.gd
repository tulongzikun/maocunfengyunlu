# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the explore→recruit→battle→reset loop feel promising?
# Date: 2026-05-27
#
# Greybox prototype testing the core loop:
# Explore village → Recruit a cat → Auto-battle → Loop reset (team persists)
#
# How to test:
# 1. Click around the village to move your cat
# 2. Walk near Old Tom (gray cat) — dialogue triggers
# 3. Walk near Whiskers (white cat) by the building — offer fish to recruit
# 4. Walk to the Dark Alley (red zone) — triggers auto-battle
# 5. Watch the battle play out
# 6. Click "Reset Loop" — observe that Whiskers stays in your team

extends Node2D

# ============================================================
# Game State
# ============================================================
var player_pos: Vector2 = Vector2(80, 420)
var target_pos: Vector2 = Vector2(80, 420)
var move_speed: float = 250.0
var is_moving: bool = false

var loop_count: int = 1
var recruited_cats: Array[String] = []  # names of recruited cats
var has_fish: bool = true  # player always starts with a fish

var in_dialogue: bool = false
var in_battle: bool = false
var battle_finished: bool = false
var dialogue_step: int = 0

# ============================================================
# Cat Stats (hardcoded for prototype)
# ============================================================
var ally_stats = null
var enemy_stats = {"name": "Shadow Rat", "hp": 25, "max_hp": 25, "atk": 6, "def": 1, "spd": 3}

func make_whiskers():
	return {"name": "Whiskers", "hp": 30, "max_hp": 30, "atk": 5, "def": 3, "spd": 4}

func make_stray():
	return {"name": "Stray", "hp": 22, "max_hp": 22, "atk": 7, "def": 1, "spd": 5}

# ============================================================
# Node References (created in _ready)
# ============================================================
var player_sprite: ColorRect
var buildings: Array[ColorRect] = []
var old_tom: ColorRect
var old_tom_label: Label
var whiskers_cat: ColorRect
var whiskers_label: Label
var dark_alley: ColorRect
var alley_label: Label

# UI nodes
var dialogue_panel: Panel
var dialogue_text: Label
var dialogue_btn: Button

var battle_panel: Panel
var battle_title: Label
var ally_name_label: Label
var ally_hp_bar_bg: ColorRect
var ally_hp_bar: ColorRect
var enemy_name_label: Label
var enemy_hp_bar_bg: ColorRect
var enemy_hp_bar: ColorRect
var battle_log: Label
var battle_timer: Timer

var team_panel: Panel
var team_label: Label

var loop_reset_btn: Button
var loop_info: Label

# ============================================================
# Build Scene
# ============================================================
func _ready():
	_setup_background()
	_setup_buildings()
	_setup_npcs()
	_setup_battle_zone()
	_setup_player()
	_setup_ui()
	_setup_battle_ui()
	_setup_loop_ui()
	_update_team_display()
	_update_loop_display()

func _setup_background():
	var bg = ColorRect.new()
	bg.color = Color(0.18, 0.15, 0.12)  # dark warm brown — village ground
	bg.size = Vector2(800, 600)
	bg.position = Vector2.ZERO
	add_child(bg)

func _setup_buildings():
	var building_data = [
		{"pos": Vector2(100, 200), "size": Vector2(120, 60), "color": Color(0.35, 0.28, 0.22), "name": "Tavern"},
		{"pos": Vector2(300, 250), "size": Vector2(80, 40), "color": Color(0.32, 0.25, 0.20), "name": "Shop"},
		{"pos": Vector2(500, 180), "size": Vector2(100, 70), "color": Color(0.38, 0.30, 0.24), "name": "Old Mill"},
		{"pos": Vector2(650, 280), "size": Vector2(90, 50), "color": Color(0.33, 0.26, 0.21), "name": "Shrine"},
		{"pos": Vector2(200, 350), "size": Vector2(110, 55), "color": Color(0.30, 0.24, 0.19), "name": "Bakery"},
	]
	for b in building_data:
		var rect = ColorRect.new()
		rect.color = b["color"]
		rect.size = b["size"]
		rect.position = b["pos"]
		add_child(rect)
		buildings.append(rect)
		# Rooftop indicator (clickable platform)
		var roof = ColorRect.new()
		roof.color = Color(0.45, 0.35, 0.25)
		roof.size = Vector2(b["size"].x + 20, 10)
		roof.position = Vector2(b["pos"].x - 10, b["pos"].y - 14)
		add_child(roof)
		# Label
		var lbl = Label.new()
		lbl.text = b["name"]
		lbl.position = Vector2(b["pos"].x + 5, b["pos"].y - 30)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
		lbl.add_theme_font_size_override("font_size", 11)
		add_child(lbl)

func _setup_npcs():
	# Old Tom — friendly NPC cat near the tavern
	old_tom = ColorRect.new()
	old_tom.color = Color(0.55, 0.55, 0.55)  # gray cat
	old_tom.size = Vector2(24, 18)
	old_tom.position = Vector2(250, 240)
	add_child(old_tom)
	old_tom_label = Label.new()
	old_tom_label.text = "Old Tom"
	old_tom_label.position = Vector2(235, 218)
	old_tom_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	old_tom_label.add_theme_font_size_override("font_size", 10)
	add_child(old_tom_label)

	# Whiskers — recruitable cat near the Old Mill
	whiskers_cat = ColorRect.new()
	whiskers_cat.color = Color(0.9, 0.85, 0.75)  # cream/white cat
	whiskers_cat.size = Vector2(24, 18)
	whiskers_cat.position = Vector2(530, 210)
	add_child(whiskers_cat)
	whiskers_label = Label.new()
	whiskers_label.text = "Whiskers"
	whiskers_label.position = Vector2(515, 188)
	whiskers_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	whiskers_label.add_theme_font_size_override("font_size", 10)
	add_child(whiskers_label)

func _setup_battle_zone():
	dark_alley = ColorRect.new()
	dark_alley.color = Color(0.6, 0.12, 0.12, 0.55)  # red-tinted danger zone
	dark_alley.size = Vector2(160, 100)
	dark_alley.position = Vector2(600, 420)
	add_child(dark_alley)
	alley_label = Label.new()
	alley_label.text = "Dark Alley\n(battle)"
	alley_label.position = Vector2(630, 455)
	alley_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
	alley_label.add_theme_font_size_override("font_size", 11)
	add_child(alley_label)

func _setup_player():
	player_sprite = ColorRect.new()
	player_sprite.color = Color(1.0, 0.65, 0.2)  # orange/amber cat
	player_sprite.size = Vector2(20, 14)
	player_sprite.position = player_pos
	add_child(player_sprite)

func _setup_ui():
	# Dialogue panel (hidden initially)
	dialogue_panel = Panel.new()
	dialogue_panel.size = Vector2(700, 100)
	dialogue_panel.position = Vector2(50, 480)
	dialogue_panel.visible = false
	add_child(dialogue_panel)
	# Style the panel
	var dp_style = StyleBoxFlat.new()
	dp_style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	dp_style.border_width_left = 2
	dp_style.border_width_right = 2
	dp_style.border_width_top = 2
	dp_style.border_width_bottom = 2
	dp_style.border_color = Color(0.5, 0.4, 0.3)
	dialogue_panel.add_theme_stylebox_override("panel", dp_style)

	dialogue_text = Label.new()
	dialogue_text.size = Vector2(660, 50)
	dialogue_text.position = Vector2(70, 495)
	dialogue_text.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	dialogue_text.add_theme_font_size_override("font_size", 14)
	dialogue_text.visible = false
	add_child(dialogue_text)

	dialogue_btn = Button.new()
	dialogue_btn.text = "Continue"
	dialogue_btn.size = Vector2(120, 30)
	dialogue_btn.position = Vector2(600, 540)
	dialogue_btn.visible = false
	dialogue_btn.pressed.connect(_on_dialogue_continue)
	add_child(dialogue_btn)

	# Team panel (top-right)
	team_panel = Panel.new()
	team_panel.size = Vector2(180, 60)
	team_panel.position = Vector2(610, 10)
	var tp_style = StyleBoxFlat.new()
	tp_style.bg_color = Color(0.1, 0.08, 0.06, 0.9)
	tp_style.border_width_left = 1; tp_style.border_width_right = 1
	tp_style.border_width_top = 1; tp_style.border_width_bottom = 1
	tp_style.border_color = Color(0.4, 0.35, 0.25)
	team_panel.add_theme_stylebox_override("panel", tp_style)
	add_child(team_panel)

	team_label = Label.new()
	team_label.text = "Team: none"
	team_label.position = Vector2(620, 18)
	team_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	team_label.add_theme_font_size_override("font_size", 12)
	add_child(team_label)

func _setup_battle_ui():
	# Battle panel (hidden initially, covers screen)
	battle_panel = Panel.new()
	battle_panel.size = Vector2(800, 600)
	battle_panel.position = Vector2.ZERO
	battle_panel.visible = false
	battle_panel.z_index = 10
	var bp_style = StyleBoxFlat.new()
	bp_style.bg_color = Color(0.08, 0.05, 0.08, 0.98)
	battle_panel.add_theme_stylebox_override("panel", bp_style)
	add_child(battle_panel)

	battle_title = Label.new()
	battle_title.text = "COMBAT"
	battle_title.position = Vector2(350, 30)
	battle_title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	battle_title.add_theme_font_size_override("font_size", 28)
	battle_title.z_index = 11
	battle_title.visible = false
	add_child(battle_title)

	# Ally cat display
	ally_name_label = Label.new()
	ally_name_label.position = Vector2(100, 120)
	ally_name_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	ally_name_label.add_theme_font_size_override("font_size", 16)
	ally_name_label.z_index = 11; ally_name_label.visible = false
	add_child(ally_name_label)

	ally_hp_bar_bg = ColorRect.new()
	ally_hp_bar_bg.color = Color(0.3, 0.1, 0.1)
	ally_hp_bar_bg.size = Vector2(200, 16)
	ally_hp_bar_bg.position = Vector2(100, 150)
	ally_hp_bar_bg.z_index = 11; ally_hp_bar_bg.visible = false
	add_child(ally_hp_bar_bg)
	ally_hp_bar = ColorRect.new()
	ally_hp_bar.color = Color(0.2, 0.8, 0.3)
	ally_hp_bar.size = Vector2(200, 16)
	ally_hp_bar.position = Vector2(100, 150)
	ally_hp_bar.z_index = 12; ally_hp_bar.visible = false
	add_child(ally_hp_bar)

	# Enemy cat display
	enemy_name_label = Label.new()
	enemy_name_label.position = Vector2(500, 120)
	enemy_name_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	enemy_name_label.add_theme_font_size_override("font_size", 16)
	enemy_name_label.z_index = 11; enemy_name_label.visible = false
	add_child(enemy_name_label)

	enemy_hp_bar_bg = ColorRect.new()
	enemy_hp_bar_bg.color = Color(0.3, 0.1, 0.1)
	enemy_hp_bar_bg.size = Vector2(200, 16)
	enemy_hp_bar_bg.position = Vector2(500, 150)
	enemy_hp_bar_bg.z_index = 11; enemy_hp_bar_bg.visible = false
	add_child(enemy_hp_bar_bg)
	enemy_hp_bar = ColorRect.new()
	enemy_hp_bar.color = Color(0.8, 0.2, 0.2)
	enemy_hp_bar.size = Vector2(200, 16)
	enemy_hp_bar.position = Vector2(500, 150)
	enemy_hp_bar.z_index = 12; enemy_hp_bar.visible = false
	add_child(enemy_hp_bar)

	# Battle log
	battle_log = Label.new()
	battle_log.size = Vector2(600, 200)
	battle_log.position = Vector2(100, 200)
	battle_log.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	battle_log.add_theme_font_size_override("font_size", 13)
	battle_log.z_index = 11; battle_log.visible = false
	add_child(battle_log)

	# Battle timer for stepping through turns
	battle_timer = Timer.new()
	battle_timer.wait_time = 0.8
	battle_timer.one_shot = false
	add_child(battle_timer)

func _setup_loop_ui():
	loop_info = Label.new()
	loop_info.position = Vector2(10, 10)
	loop_info.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	loop_info.add_theme_font_size_override("font_size", 16)
	add_child(loop_info)

	loop_reset_btn = Button.new()
	loop_reset_btn.text = "Reset Loop"
	loop_reset_btn.size = Vector2(140, 36)
	loop_reset_btn.position = Vector2(10, 550)
	loop_reset_btn.visible = false
	loop_reset_btn.pressed.connect(_on_loop_reset)
	add_child(loop_reset_btn)

# ============================================================
# Input
# ============================================================
func _input(event):
	if in_dialogue or in_battle:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		target_pos = event.position
		is_moving = true

# ============================================================
# Process
# ============================================================
func _process(delta):
	if is_moving and not in_dialogue and not in_battle:
		var dir = target_pos - player_pos
		if dir.length() < 4.0:
			player_pos = target_pos
			is_moving = false
			_check_interactions()
		else:
			player_pos += dir.normalized() * move_speed * delta
		player_sprite.position = player_pos

# ============================================================
# Interaction Checks
# ============================================================
func _check_interactions():
	# Check if near the battle zone
	var alley_center = dark_alley.position + dark_alley.size / 2
	if player_pos.distance_to(alley_center) < 120:
		if recruited_cats.size() > 0:
			_start_battle()
		else:
			_show_dialogue("The Dark Alley looks dangerous...\nI should find an ally before going in there.")
		return

	# Check if near Whiskers (recruitable cat)
	if player_pos.distance_to(whiskers_cat.position + Vector2(12, 9)) < 70:
		if "Whiskers" in recruited_cats:
			_show_dialogue("Whiskers: \"Ready for another round, friend?\"\n(Whiskers is already in your team.)")
		else:
			_start_whiskers_dialogue()
		return

	# Check if near Old Tom
	if player_pos.distance_to(old_tom.position + Vector2(12, 9)) < 70:
		_start_tom_dialogue()
		return

# ============================================================
# Dialogue System
# ============================================================
func _show_dialogue(text: String):
	in_dialogue = true
	dialogue_panel.visible = true
	dialogue_text.visible = true
	dialogue_text.text = text
	dialogue_btn.visible = true
	dialogue_btn.text = "OK"
	dialogue_step = 0

func _on_dialogue_continue():
	if dialogue_step == 0:
		# Recruit confirmation for Whiskers
		if _near_whiskers() and not "Whiskers" in recruited_cats:
			_recruit_whiskers()
			return
		_close_dialogue()
	elif dialogue_step == 1:
		# Second step for Tom's dialogue about Whiskers
		dialogue_text.text = "Old Tom: \"Bring her a fish from the market.\nShe can't resist a fresh catch.\""
		dialogue_btn.text = "Got it"
		dialogue_step = 2
	elif dialogue_step == 2:
		_close_dialogue()

func _close_dialogue():
	in_dialogue = false
	dialogue_step = 0
	dialogue_panel.visible = false
	dialogue_text.visible = false
	dialogue_btn.visible = false

func _near_whiskers() -> bool:
	return player_pos.distance_to(whiskers_cat.position + Vector2(12, 9)) < 70

func _start_tom_dialogue():
	dialogue_step = 1
	_show_dialogue("Old Tom: \"You look like you're preparing for something.\nThere's a tough cat named Whiskers by the Old Mill.\nShe knows how to handle herself in a fight.\"")
	dialogue_btn.text = "Tell me more"

func _start_whiskers_dialogue():
	_show_dialogue("Whiskers: \"Hey there. I hear you're looking for allies.\"\n\n[You have a fresh fish.]\n[Offer Fish to recruit Whiskers?]")
	dialogue_btn.text = "Offer Fish"

func _recruit_whiskers():
	recruited_cats.append("Whiskers")
	ally_stats = make_whiskers()
	has_fish = false
	whiskers_cat.color = Color(0.4, 0.7, 0.4)  # turns green — recruited
	whiskers_label.text = "Whiskers (Team)"
	_update_team_display()
	_show_dialogue("Whiskers accepts the fish!\n\n\"Alright, I'm in. Lead the way.\"\n\nWhiskers joined your team!\n\n(Head to the Dark Alley to test your team in battle.)")
	dialogue_btn.text = "Let's go!"

# ============================================================
# Auto-Battle System
# ============================================================
var battle_turn: int = 0
var battle_messages: Array[String] = []
var battle_ally_hp: int = 0
var battle_ally_max: int = 0
var battle_enemy_hp: int = 0
var battle_enemy_max: int = 0
var battle_ally = null
var battle_enemy = null

func _start_battle():
	if recruited_cats.size() == 0:
		return
	in_battle = true
	battle_finished = false
	battle_turn = 0
	battle_messages = []

	battle_ally = ally_stats
	battle_enemy = enemy_stats
	battle_ally_hp = battle_ally["hp"]
	battle_ally_max = battle_ally["max_hp"]
	battle_enemy_hp = battle_enemy["hp"]
	battle_enemy_max = battle_enemy["max_hp"]

	# Show battle UI
	battle_panel.visible = true
	battle_title.visible = true
	ally_name_label.visible = true; ally_name_label.text = battle_ally["name"]
	enemy_name_label.visible = true; enemy_name_label.text = battle_enemy["name"]
	ally_hp_bar_bg.visible = true; ally_hp_bar.visible = true
	enemy_hp_bar_bg.visible = true; enemy_hp_bar.visible = true
	battle_log.visible = true
	battle_log.text = "Battle begins!\n"

	_update_battle_hp_bars()

	battle_messages.append("A " + battle_enemy["name"] + " ambushes you in the alley!")
	battle_messages.append(battle_ally["name"] + " steps forward to face it.")
	battle_log.text = "\n".join(battle_messages)

	# Start turn-based battle
	battle_timer.timeout.connect(_battle_turn)
	battle_timer.start()

func _battle_turn():
	battle_turn += 1
	var new_msgs: Array[String] = []
	new_msgs.append("--- Turn " + str(battle_turn) + " ---")

	# Determine turn order by speed
	var fast_cat = battle_ally if battle_ally["spd"] >= battle_enemy["spd"] else battle_enemy
	var slow_cat = battle_enemy if fast_cat == battle_ally else battle_ally

	# Fast cat acts
	var fast_result = _cat_act(fast_cat, slow_cat, battle_ally_hp if fast_cat == battle_ally else battle_enemy_hp)
	if fast_cat == battle_ally:
		battle_enemy_hp = fast_result["target_hp"]
	else:
		battle_ally_hp = fast_result["target_hp"]
	new_msgs.append(fast_result["msg"])

	# Check if slow cat is dead
	if (fast_cat == battle_ally and battle_enemy_hp <= 0) or (fast_cat == battle_enemy and battle_ally_hp <= 0):
		battle_messages.append_array(new_msgs)
		battle_log.text = "\n".join(battle_messages)
		_update_battle_hp_bars()
		_end_battle()
		return

	# Slow cat acts
	var slow_result = _cat_act(slow_cat, fast_cat, battle_ally_hp if slow_cat == battle_ally else battle_enemy_hp)
	if slow_cat == battle_ally:
		battle_enemy_hp = slow_result["target_hp"]
	else:
		battle_ally_hp = slow_result["target_hp"]
	new_msgs.append(slow_result["msg"])

	battle_messages.append_array(new_msgs)
	# Keep only last 8 lines visible
	if battle_messages.size() > 10:
		battle_messages = battle_messages.slice(battle_messages.size() - 10)

	battle_log.text = "\n".join(battle_messages)
	_update_battle_hp_bars()

	# Check for death
	if battle_ally_hp <= 0 or battle_enemy_hp <= 0:
		_end_battle()

func _cat_act(attacker: Dictionary, defender: Dictionary, attacker_hp: int) -> Dictionary:
	# Roll for dodge (skittish cats have chance)
	if defender["spd"] > attacker["spd"] and randi() % 100 < 25:
		return {"target_hp": defender["hp"] if attacker != battle_ally else battle_enemy_hp,
				"msg": defender["name"] + " dodges " + attacker["name"] + "'s attack!"}

	# Calculate damage
	var base_dmg = attacker["atk"] - defender["def"]
	base_dmg = max(1, base_dmg)
	# Add variance
	var dmg = max(1, base_dmg + randi() % 5 - 2)

	var defender_hp = 0
	if attacker == battle_ally:
		defender_hp = battle_enemy_hp
	else:
		defender_hp = battle_ally_hp
	defender_hp -= dmg

	# Behavior flavor
	var flavor = ""
	var atk_name = attacker["name"]
	var def_name = defender["name"]
	var r = randi() % 3
	if r == 0:
		flavor = atk_name + " pounces at " + def_name + "!"
	elif r == 1:
		flavor = atk_name + " swipes with sharp claws at " + def_name + "!"
	else:
		flavor = atk_name + " hisses and strikes at " + def_name + "!"

	return {"target_hp": defender_hp, "msg": flavor + " (" + str(dmg) + " dmg)"}

func _end_battle():
	battle_timer.stop()
	battle_finished = true

	if battle_ally_hp <= 0 and battle_enemy_hp <= 0:
		battle_messages.append("\nBOTH CATS FALL! It's a draw...")
	elif battle_ally_hp <= 0:
		battle_messages.append("\n" + battle_ally["name"] + " is defeated! You retreat...")
	else:
		battle_messages.append("\n" + battle_enemy["name"] + " is defeated!")
		battle_messages.append(battle_ally["name"] + " stands victorious!")

	battle_log.text = "\n".join(battle_messages)

	# Show close button after 1 second
	await get_tree().create_timer(1.5).timeout
	_close_battle()

func _close_battle():
	battle_panel.visible = false; battle_title.visible = false
	ally_name_label.visible = false; enemy_name_label.visible = false
	ally_hp_bar_bg.visible = false; ally_hp_bar.visible = false
	enemy_hp_bar_bg.visible = false; enemy_hp_bar.visible = false
	battle_log.visible = false
	in_battle = false

	# Heal ally for next battle
	if ally_stats:
		ally_stats["hp"] = ally_stats["max_hp"]

	# Win: restore fish and show loop button
	if battle_enemy_hp <= 0 and battle_ally_hp > 0:
		has_fish = true
		loop_reset_btn.visible = true
		_show_dialogue("Victory! Whiskers fought bravely.\n\nYou found another fish in the alley.\n\nYou feel the loop's power stirring...\n(Click 'Reset Loop' to start a new loop\nwith your team intact.)")
	else:
		loop_reset_btn.visible = true
		_show_dialogue("The battle was tough...\n\nYou feel the loop's power stirring...\n(Click 'Reset Loop' to try again.)")

func _update_battle_hp_bars():
	var ally_pct = max(0.0, float(battle_ally_hp) / float(battle_ally_max))
	var enemy_pct = max(0.0, float(battle_enemy_hp) / float(battle_enemy_max))
	ally_hp_bar.size = Vector2(200 * ally_pct, 16)
	enemy_hp_bar.size = Vector2(200 * enemy_pct, 16)
	if ally_pct < 0.3:
		ally_hp_bar.color = Color(0.8, 0.2, 0.2)
	if enemy_pct < 0.3:
		enemy_hp_bar.color = Color(0.8, 0.2, 0.2)

# ============================================================
# Loop Reset
# ============================================================
func _on_loop_reset():
	loop_count += 1
	player_pos = Vector2(80, 420)
	target_pos = player_pos
	is_moving = false
	player_sprite.position = player_pos
	battle_finished = false
	loop_reset_btn.visible = false

	# Restore ally HP
	if ally_stats:
		ally_stats["hp"] = ally_stats["max_hp"]

	_update_loop_display()
	_update_team_display()
	_increment_team_power()  # team gets slightly stronger each loop (P4: loops are growth)

	_show_dialogue("LOOP " + str(loop_count) + "\n\nYou wake up in the village again.\nThe countdown is still ticking...\nBut " + ", ".join(recruited_cats) + " is still by your side.\n\n(Your team persists across loops.\nExplore again — recruit another ally?)")

func _increment_team_power():
	# Small bonus each loop — P4: loops are growth
	for cat_name in recruited_cats:
		if ally_stats and ally_stats["name"] == cat_name:
			ally_stats["atk"] += 1
			ally_stats["def"] += 1
			ally_stats["max_hp"] += 3
			ally_stats["hp"] = ally_stats["max_hp"]

func _update_loop_display():
	loop_info.text = "Loop: " + str(loop_count) + "  |  Fish: " + ("Yes" if has_fish else "No")

func _update_team_display():
	if recruited_cats.size() == 0:
		team_label.text = "Team: none"
	else:
		team_label.text = "Team: " + ", ".join(recruited_cats)
		if ally_stats:
			team_label.text += "\nATK:" + str(ally_stats["atk"]) + " DEF:" + str(ally_stats["def"]) + " HP:" + str(ally_stats["hp"])
