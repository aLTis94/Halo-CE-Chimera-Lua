clua_version = 2.042

--TAG LOCATIONS (ignore these and move on to CONFIG)
	local ar_name = "bourrin\\weapons\\assault rifle"
	local br_name = "altis\\weapons\\br_spec_ops\\br_spec_ops"
	local shotgun_name = "cmt\\weapons\\human\\shotgun\\shotgun"
	local dmr_name = "bourrin\\weapons\\dmr\\dmr"
	local ma5k_name = "altis\\weapons\\br\\br"
	local spartan_laser_name = "halo reach\\objects\\weapons\\support_high\\spartan_laser\\spartan laser"
	local rl_name = "bourrin\\weapons\\badass rocket launcher\\bourrinrl"
	local gauss_name = "weapons\\gauss sniper\\gauss sniper"
	local sniper_name = "altis\\weapons\\sniper\\sniper"
	local pistol_name = "reach\\objects\\weapons\\pistol\\magnum\\magnum"
	local odst_pistol_name = "halo3\\weapons\\odst pistol\\odst pistol"
	local binoculars_name = "altis\\weapons\\binoculars\\binoculars"
	local knife_name = "altis\\weapons\\knife\\knife"
	local armor_room_name = "altis\\scenery\\armor_room\\armor_room"

	local ar_tag = read_dword(get_tag("weap", ar_name) + 0xC)
	local br_tag = read_dword(get_tag("weap", br_name) + 0xC)
	local shotgun_tag = read_dword(get_tag("weap", shotgun_name) + 0xC)
	local dmr_tag = read_dword(get_tag("weap", dmr_name) + 0xC)
	local ma5k_tag = read_dword(get_tag("weap", ma5k_name) + 0xC)
	local spartan_laser_tag = read_dword(get_tag("weap", spartan_laser_name) + 0xC)
	local rl_tag = read_dword(get_tag("weap", rl_name) + 0xC)
	local gauss_tag = read_dword(get_tag("weap", gauss_name) + 0xC)
	local sniper_tag = read_dword(get_tag("weap", sniper_name) + 0xC)
	local pistol_tag = read_dword(get_tag("weap", pistol_name) + 0xC)
	local odst_pistol_tag = read_dword(get_tag("weap", odst_pistol_name) + 0xC)
	local binoculars_tag = read_dword(get_tag("weap", binoculars_name) + 0xC)
	local knife_tag = read_dword(get_tag("weap", knife_name) + 0xC)
	local armor_room_tag = read_dword(get_tag("vehi", armor_room_name) + 0xC)

	globals_tag = read_dword(get_tag("matg", "globals\\globals") + 0x14)

--CONFIG
	
	--Keyboard keys reference:
	--17="1", 18="2", 19="3", 20="4", 2="5", 22="6", 23="7", 24="8", 25="9", 26="10", 27="Minus", 28="Equal", 30="Tab", 31="Q", 32="W", 33="E", 34="R", 35="T", 36="Y", 37="U", 38="I", 39="O", 40="P", 43="Backslash",
	--44="Caps Lock", 45="A", 46="S", 47="D", 48="F", 49="G", 50="H", 51="J", 52="K", 53="L", 56="Enter", 57="Shift", 58="Z", 59="X", 60="C", 61="V", 62="B", 63="N", 64="M", 69="Ctrl",71="Alt",72="Space",
	
	--Controller keys reference:
	--0="A", 1="B", 2="X", 3="Y", 4="LB", 5="RB", 6="Back", 7="Start", 8="Left Stick", 9="Right Stick", 100="D-pad up", 102="D-pad right", 104="D-pad down", 106="D-pad left",
	
	--CUSTOM CONTROLS
		local key_aa = 60
		local key_sprint = 57
		local key_emote = 62
		local key_voice = 61
		local key_put_away = 51
		
		local key_controller_aa = 102
		local key_controller_sprint = 8
		local key_controller_emote = 104
		local key_controller_voice = 106
		
		local key_sprint_hold = true
		local key_spam_timer_aa = 10 -- to prevent spamming
		local key_spam_timer_sprint = 20 -- to prevent spamming
		local key_spam_timer_voice = 30 -- to prevent spamming
		local cursor_offset_x = 11
		local cursor_offset_y = 14
		local cursor_sensitivity = 1.5
	
	--SCREEN BLUR
		local blur_screen_on_join = true
		local join_blur_timer = 60
	
	--GAUSS SHOCKWAVE RIPPLE / BUBBLE SHIELD REFRACTION
		local use_refractions = true
		local shockwave_max_scale = 40
		local shockwave_increase_size_rate = 3.5
		local refraction_amount = 8
		
		local bubble_shield_scale = 0.99 -- scale of the refraction object (should be lower than 1)
		local bubble_shield_refraction_amount = 0.1
		local bubble_shield_min_distance = 1.75 -- inside of the bubble shield
		local bubble_shield_min_refraction = 0.1 -- refraction inside of the bubble shield
		local bubble_shield_lifetime = 10 * 30
	
	--TREES
		local TREES = {
			"altis\\scenery\\bush\\bush",
			"altis\\scenery\\trees\\trees",
			"altis\\scenery\\treeb\\treeb",
			"custom tags\\scenery\\trees\\oak_tree\\oak_tree",
		}
	
	--MINES
		local fix_double_mines = true -- fixes double tripmine bug
	
	-- DYNAMIC RETICLES
		local use_new_dynamic_reticles = true
	
	--BINOCULARS
		local binoculars_highlights = true -- adds highlights around players when zoomed in
		local BIPEDS = {
			["default"] = "bourrin\\halo reach\\spartan\\male\\mp masterchief",
			["female"] = "bourrin\\halo reach\\spartan\\female\\female",
			["marine"] = "bourrin\\halo reach\\marine-to-spartan\\mp test",
			["odst"] = "bourrin\\halo reach\\spartan\\male\\odst",
			["specops"] = "bourrin\\halo reach\\spartan\\male\\spec_ops",
			["koslovik"] = "bourrin\\halo reach\\spartan\\male\\koslovik",
			["altis"] = "bourrin\\halo reach\\spartan\\male\\haunted",
			["sbb"] = "bourrin\\halo reach\\spartan\\male\\117",
			["linda"] = "bourrin\\halo reach\\spartan\\male\\linda",
			["fmarine"] = "bourrin\\halo reach\\marine-to-spartan\\mp female",
			["flood"] = "characters\\floodcombat_human\\player\\flood player",
		}
		
	--BACKPACK WEAPONS
		local use_backpack_weapons = true
		local backpack_weapon_render_distance = 30
		local BACKPACK_WEAPONS_OFFSETS = {
			[ar_name.."_preview"] = {
				["x"] = -11,
				["y"] = 10,
				["z"] = -50,
				["rot1"] = -1,
				["rot2"] = 1,
				["rot3"] = -1,
				["node"] = 0x688,
			},
			[pistol_name.."_preview"] = {
				["x"] = -22,
				["y"] = -16,
				["z"] = -60,
				["rot1"] = 1,
				["rot2"] = -1,
				["rot3"] = -1,
				["node"] = 0x5B8,
			},
			[br_name.."_preview"] = {
				["x"] = -13,
				["y"] = 10,
				["z"] = -40,
				["rot1"] = -1,
				["rot2"] = 1,
				["rot3"] = -1,
				["node"] = 0x688,
			},
			[dmr_name.."_preview"] = {
				["x"] = -13,
				["y"] = 10,
				["z"] = -50,
				["rot1"] = -1,
				["rot2"] = 1,
				["rot3"] = -1,
				["node"] = 0x688,
			},
			[shotgun_name.."_preview"] = {
				["x"] = -100,
				["y"] = 10,
				["z"] = -100,
				["rot1"] = -1,
				["rot2"] = 1,
				["rot3"] = -1,
				["node"] = 0x688,
			},
			[ma5k_name.."_preview"] = {
				["x"] = -15,
				["y"] = 10,
				["z"] = -30,
				["rot1"] = -1,
				["rot2"] = 1,
				["rot3"] = -1,
				["node"] = 0x688,
			},
			[odst_pistol_name.."_preview"] = {
				["x"] = -23,
				["y"] = -16,
				["z"] = -60,
				["rot1"] = 1,
				["rot2"] = -1,
				["rot3"] = -1,
				["node"] = 0x5B8,
			},
			[binoculars_name.."_preview"] = {
				["x"] = -10,
				["y"] = 25,
				["z"] = -14,
				["rot1"] = 1,
				["rot2"] = 1,
				["rot3"] = 1,
				["node"] = 0x5B8,
			},
			[gauss_name.."_preview"] = {
				["x"] = -9,
				["y"] = 10,
				["z"] = -30,
				["rot1"] = -1,
				["rot2"] = 1,
				["rot3"] = -1,
				["node"] = 0x688,
			},
			[rl_name.."_preview"] = {
				["x"] = -9,
				["y"] = 9,
				["z"] = -30,
				["rot1"] = -1,
				["rot2"] = 1,
				["rot3"] = -1,
				["node"] = 0x688,
			},
			[spartan_laser_name.."_preview"] = {
				["x"] = 100,
				["y"] = 9,
				["z"] = -30,
				["rot1"] = -1,
				["rot2"] = 1,
				["rot3"] = -1,
				["node"] = 0x688,
			},
			[sniper_name.."_preview"] = {
				["x"] = -17,
				["y"] = 10,
				["z"] = -500,
				["rot1"] = -1,
				["rot2"] = 1,
				["rot3"] = -1,
				["node"] = 0x688,
			},
			[knife_name.."_preview"] = {
				["x"] = -24,
				["y"] = -35,
				["z"] = 16,
				["rot1"] = 1,
				["rot2"] = -1,
				["rot3"] = -1,
				["node"] = 0x584,
			},
		}
	
		local use_backpack_aa = true -- armor abilities on the back
		local aa_preview_tag = "armor_abilities\\pickup\\preview\\armor_ability_preview"
		local BACKPACK_AA_COLORS = {
			[6242] = 0,
			[23926] = 0.8,
			[2081] = 0.4,
			[52013] = 0.12,
			[11443] = 0.65,
		}
	
	--FP HANDS
		local switch_fp_hands = true	--	switched spartan hands to marine hands when using marine armor
		local new_biped_name = "bourrin\\halo reach\\marine-to-spartan\\mp test" -- biped which has different fp arms
		local new_biped_name_alt = "bourrin\\halo reach\\marine-to-spartan\\mp female" -- biped which has different fp arms
		local fp_hands_new_name = "bourrin\\halo reach\\marine-to-spartan\\fp\\fp" -- different fp hands for that biped
	
	--DYNAMIC SHADOWS
		local use_dynamic_shadow_direction_for_forge = false -- disable this to slightly increase performance on forge
		local use_dynamic_shadows = false
		local scenery_shadows = false	--	doesn't work well when there are many objects, also impacts performance a lot
		local max_scenery_radius = 10 -- if you don't want large objects to cast shadows then lower this
		local shadow_render_distance = 5 --world units (applies to weapons, equipment, devices)
		local scenery_shadow_render_distance = 15 --world units
		local unit_shadow_render_distance = 30 -- world units (applies to bipeds and vehicles)
		
	--CUBEMAPS
		local use_cubemap_switching = true -- switches cubemaps for some shaders when entering different areas of the map or switching TOD (unfinished)
		local TOD = {
			[0] = "altis\\bitmaps\\stuff\\bitmaps\\cubemap",
			[1] = "weapons\\assault rifle\\fp\\bitmaps\\diffuse gunmetal",
			[2] = "detail_and_cube_maps\\b40_cubemap_outside",
			[3] = "altis\\bitmaps\\stuff\\bitmaps\\cubemap",
			[4] = "altis\\bitmaps\\stuff\\bitmaps\\cubemap",
		}
		
		
		--supported classes: soso, schi, scex, sgla
		--schi and scex only switch the first bitmap in the struct
		local SHADERS_TO_SWITCH = {
			["bourrin\\weapons\\dmr\\shaders\\dmr_scope_test"] = "schi",
			["vehicles\\newhog\\shaders\\windshield"] = "sgla",
			["altis\\vehicles\\mortargoose\\shaders\\windbrake"] = "sgla",
			["vehicles\\le_falcon\\shaders\\glass"] = "sgla",
			["levels\\test\\chillout\\shaders\\chillout glass"] = "sgla",
			["altis\\weapons\\binoculars\\shaders\\glass"] = "schi",
			["altis\\vehicles\\forklift\\shaders\\forklift-glass"] = "sgla",
			["forge\\halo4\\shaders\\unsc_glass"] = "sgla",
		}
		
		local CUBEMAP_LOCATIONS = {
			[0] = {
				["name"] = "altis\\bitmaps\\stuff\\bitmaps\\cubemap_red_base",
				["x"] = -129.534,
				["y"] = -67.9791,
				["z"] = -4,
				["radius"] = 7,
			},
			[1] = {
				["name"] = "altis\\bitmaps\\stuff\\bitmaps\\cubemap_blue_base",
				["x"] = 150.626,
				["y"] = 38.0363,
				["z"] = -4,
				["radius"] = 7,
			}
		}
		
	--BASES SHADOW FIX
		local SHADOW_FIX_LOCATIONS = {
		["red base"] = {
			["x"] = -129.534,
			["y"] = -67.9791,
			["z"] = -4,
			["dist"] = 11,
			["height"] = 2.9,
			["y_truck"] = 65,
			["height_truck"] = 1.1,
		},
		["blue base"] = {
			["x"] = 150,
			["y"] = 38,
			["z"] = -4,
			["dist"] = 11,
			["height"] = 2.9,
			["y_truck"] = 34,
			["height_truck"] = 1.1,
		},
	}
	--POTATO MODE
		local remove_scenery_on_distance = false
		local remove_scenery_distance = 180
		local remove_scenery_max_scale = 6 -- object bigger than this won't be removed on distance
	
	--MISC
		
		local use_alt_idle_anims = true
		local ALT_ANIMS = {
			[259] = 1,
			[271] = 2,
			[272] = 3,
			[273] = 4,
			[274] = 5,
			[275] = 6,
		}
		
		local use_ready_anims = true
		local WEAPON_READY_ANIMS = {
			[ar_tag] = 276,
			[br_tag] = 276,
			[dmr_tag] = 276,
			[shotgun_tag] = 276,
			[ma5k_tag] = 276,
			[rl_tag] = 276,
			[spartan_laser_tag] = 276,
			[gauss_tag] = 278,
			[sniper_tag] = 278,
			[pistol_tag] = 277,
			[odst_pistol_tag] = 277,
			[binoculars_tag] = 277,
			[knife_tag] = 279,
		}
		
		local PUT_AWAY = {
			[dmr_tag] = {
				["idle"] = 1,
				["putaway"] = 6,
				["frame"] = 12-3,
			},
			[gauss_tag] = {
				["idle"] = 1,
				["putaway"] = 5,
				["frame"] = 15-3,
			},
			[shotgun_tag] = {
				["idle"] = 5,
				["putaway"] = 10,
				["frame"] = 10-3,
			},
			[sniper_tag] = {
				["idle"] = 1,
				["putaway"] = 7,
				["frame"] = 40-3,
			},
			[br_tag] = {
				["idle"] = 1,
				["putaway"] = 5,
				["frame"] = 15-3,
			},
			[binoculars_tag] = {
				["idle"] = 1,
				["putaway"] = 5,
				["frame"] = 30-3,
			},
			[ar_tag] = {
				["idle"] = 1,
				["putaway"] = 9,
				["frame"] = 34-3,
			},
		}
		
		local TEAMS = { -- for navpoints only
			[0] = "default",
			[1] = "player",
			[2] = "human",
			[3] = "covenant",
			[4] = "flood",
			[5] = "sentinel",
			[6] = "unused6",
			[7] = "unused7",
			[8] = "unused8",
			[9] = "unused9",
			[10] = "default10", --idk if these work at all
			[11] = "default11",
			[12] = "default12",
			[13] = "default13",
			[14] = "default14",
			[15] = "default15",
			[16] = "default16",
		}
		
		local SKIES = {
			[1] = "sky\\pit\\pit",
			[2] = "altis\\sky\\night\\night",
			[3] = "altis\\sky\\snow\\snow",
			[4] = "altis\\sky\\custom\\sweet sunrise",
			[5] = "altis\\sky\\custom\\sweet sunrise2",
		}
		
		local SCENERY_NOT_TO_REMOVE = {
			["altis\\scenery\\ffs\\i hate all of you"] = true,
			["altis\\scenery\\fuck_this_shit\\i hate bigass"] = true,
		}
		
		local flood_grenade_id = read_dword(get_tag("proj", "characters\\floodcombat_human\\player\\projectile\\projectile") + 0xC)
		
		local FORGE_COLOR_PERMUTATIONS = { -- might have wrong names idk
			[0] = {255,255,255}, 	-- default
			[1] = {175,175,175}, 	-- grey
			[2] = {10,10,10},		-- black
			[3] = {72,144,255},		-- light blue
			[4] = {110,113,255},	-- blue
			[5] = {255,100,100},	-- light red
			[6] = {220,20,10},		-- red
			[7] = {255,231,72},		-- yellow
			[8] = {239,162,41},		-- orange
			[9] = {74,255,93},		-- green
			[10] = {162,200,136},	-- light green
			[11] = {206,88,255},	-- light brown
			[12] = {206,175,255},	-- purple
			[13] = {255,173,136},	-- pink
			[14] = {30,233,240},	-- cyan
			[15] = {255,150,150},	-- very light red (for trees)
		}
		
		local VOICE_LINES = {
			[5] = "cvr",
			[4] = "foundfoe",
			[3] = "newordr_advance",
			[2] = "join_stayback",
			[1] = "warn",
			[0] = "entervcl",
			[9] = "ok",
			[8] = "prs",
			[7] = "thnk",
			[6] = "scrn",
			[11] = "newordr_entervcl",
		}
			
		local BIPED_VOICE_PITCH = {
			["bourrin\\halo reach\\spartan\\male\\mp masterchief"] = 0.5,
			["bourrin\\halo reach\\spartan\\female\\female"] = 0.2,
			["bourrin\\halo reach\\marine-to-spartan\\mp test"] = 1,
			["bourrin\\halo reach\\spartan\\male\\odst"] = 0.7,
			["bourrin\\halo reach\\spartan\\male\\spec_ops"] = 0.4,
			["bourrin\\halo reach\\spartan\\male\\koslovik"] = 0.2,
			["bourrin\\halo reach\\spartan\\male\\haunted"] = 0.65,
			["bourrin\\halo reach\\spartan\\male\\117"] = 0,
			["bourrin\\halo reach\\spartan\\male\\linda"] = 0.8,
			["bourrin\\halo reach\\marine-to-spartan\\mp female"] = 0.7,
		}
		
	--DEBUG
	
		local debug_console = false -- prints all messages that were sent by the server
		local debug_msg_per_s = false -- prints how many rcon messages per second were recieved (even if they don't show up)
		
--END OF CONFIG

set_callback("tick", "OnTick")
set_callback("frame", "OnFrame")
set_callback("rcon message", "OnRcon")
set_callback("command", "OnCommand")
set_callback("unload", "OnUnload")
set_callback("precamera", "OnCamera")

-- MISC
local messages_per_second = 0
local MINES = {}
local SPAWNED_OBJECTS = {}
local SCENERY_OBJECTS = {}
local HOLOGRAMS = {}
local previous_tod = -1
local grenade_type = 1
local vehicle_camera = nil
local taco = false
local frames = 0
local ticks = 0
local fps = 60
local player_damaged_timer = 0
local player_dead = 0
local player_health = 0
local camera_x = 0
local camera_y = 0
local camera_z = 0
local armor_room_camera_timer = 0
local forkball = false
local sky_id = 1
local forge_shadow_update_timer = 0
local red_reticle_timer = 0
local custom_keys = false
local key_aa_timer = 0
local key_sprint_timer = 0
local key_voice_timer = 0
local started_sprinting = false
local safe_zones_fixed = false
local emotes_enabled = false
local voice_enabled = false
local nightvision = false

local flashlight_effect = read_dword(read_dword(read_dword(get_tag("effe", "weapons\\assault rifle\\effects\\flashlight") + 0x14) + 0x34 + 4) + 0x2C + 4) + 0x18 + 0xC
local flashlight_sound = read_dword(get_tag("snd!", "sound\\sfx\\weapons\\assault rifle\\flashlight") + 0xC)
local nv_on_sound = read_dword(get_tag("snd!", "sound\\sfx\\weapons\\sniper rifle\\sniper_nightscope_on") + 0xC)
local nv_off_sound = read_dword(get_tag("snd!", "sound\\sfx\\weapons\\sniper rifle\\sniper_nightscope_off") + 0xC)

--don't touch these!
local ctf_flag_red = 0x40492F1C
local ctf_flag_blue = 0x40492FB0
local object_table = read_dword(read_dword(0x401194))
local keyboard_input_address = 0x64C550
local mouse_input_address = 0x64C73C
local local_player = read_dword(0x815918)
local game_state_address = 0x400002E8
local fp_anim_address = 0x40000EB8

local scenario_tag_index = read_word(0x40440004)
local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
local scenario_data = read_dword(scenario_tag + 0x14)

local rand = math.random
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin
local rad = math.rad
local pi = math.pi
local floor = math.floor
local ceil = math.ceil
local smatch = string.gmatch
local find = string.find
local tinsert = table.insert
local abs = math.abs

local last_sound = nil
local vc_id = read_dword(get_tag("weap", "altis\\effects\\vc_icon\\vc0") + 0xC)
local VC = {}
for i=0,15 do -- CHANGE LATER
	VC[i] = {}
	VC[i].timer = 0
end

--BACKPACK WEAPONS
local BACKPACK_WEAPONS = {}
local ARMOR_ABILITIES = {}
for i=0,15 do
	BACKPACK_WEAPONS[i] = {}
	for k=0,1 do
		BACKPACK_WEAPONS[i][k] = {}
		BACKPACK_WEAPONS[i][k].id = nil
		BACKPACK_WEAPONS[i][k].name = nil
	end
	ARMOR_ABILITIES[i] = {}
	ARMOR_ABILITIES[i].id = nil
	ARMOR_ABILITIES[i].aatype = nil
end

-- READY ANIMS
local PLAYER_WEAPONS = {}

-- FP HANDS
local fp_hands_default_id = nil
local fp_hands_default_class = nil
local fp_hands_new_id = nil
local fp_hands_new_class = nil

function InitializeSettings()

	-- change settings if they were set using a script
	if get_global("settings_changed") then
		console_out("Settings changed")
		key_sprint_hold = get_global("key_sprint_hold")
		switch_fp_hands = get_global("switch_fp_hands")
		blur_screen_on_join = get_global("blur_screen_on_join")
		use_backpack_weapons = get_global("use_backpack_weapons")
		backpack_weapon_render_distance = get_global("backpack_weapon_render_distance")
		use_backpack_aa = get_global("use_backpack_aa")
		use_refractions = get_global("use_refractions")
		use_new_dynamic_reticles = get_global("use_new_dynamic_reticles")
		binoculars_highlights = get_global("binoculars_highlights")
		use_cubemap_switching = get_global("use_cubemap_switching")
		use_ready_anims = get_global("use_ready_anims")
		remove_scenery_on_distance = get_global("remove_scenery_on_distance")
		remove_scenery_distance = get_global("remove_scenery_distance")
		
		if blur_screen_on_join == false then
			execute_script("cinematic_screen_effect_stop")
			execute_script("fade_in 0 0 0 1")
		end
	end

	-- DYNAMIC RETICLES
	
	WEAPON_HUDS = {
		[ma5k_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\internal stuff\\hud test 3") + 0x14),
		[pistol_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\pistol") + 0x14),
		[ar_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\ar 32") + 0x14),
		[odst_pistol_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\socom") + 0x14),
		[br_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\battle rifle") + 0x14),
		[spartan_laser_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\spartan laser") + 0x14),
		[dmr_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\dmr") + 0x14),
		[rl_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\rocket launcher") + 0x14),
		[gauss_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\gauss rifle") + 0x14),
		[sniper_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\sniper rifle") + 0x14),
		[binoculars_tag] = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\resupply infinite") + 0x14),
	}
	
	WEAPON_RETICLES = {
		[ma5k_tag] = {
			["initial"] = 5,
			["additional"] = 18,
		},
		[pistol_tag] = {
			["initial"] = 5,
			["additional"] = 9,
		},
		[ar_tag] = {
			["initial"] = 12,
			["additional"] = 10,
		},
		[odst_pistol_tag] = {
			["initial"] = 4,
			["additional"] = 13,
		},
		[br_tag] = {
			["initial"] = 5,
			["additional"] = 2.8,
		},
		[gauss_tag] = {
			["initial"] = 6,
			["additional"] = 9,
		},
	}
	
	WEAPON_SCOPES = {
		[br_tag] = {
			[5] = {["mult"] = 0.05},
			[6] = {["mult"] = 0.05},
			[7] = {["mult"] = 0.15},
		},
		[dmr_tag] = {
			[5] = {["mult"] = 0.05},
			[6] = {["mult"] = 0.05},
			[7] = {["mult"] = 0.05},
		},
		[sniper_tag] = {
			[4] = {["mult"] = 0.05},
			[5] = {["mult"] = 0.05},
			[6] = {["mult"] = 0.16},
		},
		[gauss_tag] = {
			[5] = {["mult"] = 0.05},
			[6] = {["mult"] = 0.05},
			[7] = {["mult"] = 0.16},
		},
		[rl_tag] = {
			[2] = {["mult"] = 0.05},
			[3] = {["mult"] = 0.05},
			[4] = {["mult"] = 0.16},
		},
		[odst_pistol_tag] = {
			[5] = {["mult"] = 0.2},
			[6] = {["mult"] = 0.2},
		},
		[spartan_laser_tag] = {
			[3] = {["mult"] = 0.05},
			[4] = {["mult"] = 0.05},
			[5] = {["mult"] = 0.05},
		},
		[pistol_tag] = {
			[5] = {["mult"] = 0.07},
			[6] = {["mult"] = 0.07},
		},
		[binoculars_tag] = {
			[1] = {["mult"] = 0.02},
			[2] = {["mult"] = 0.02},
			[3] = {["mult"] = 0.02},
		},
	}
		
	for meta_id,initial_scales in pairs (WEAPON_SCOPES) do
		local weapon_hud = WEAPON_HUDS[meta_id]
		local reticle_address = read_dword(weapon_hud + 0x88)
		for id,initial_scale in pairs (initial_scales) do
			local struct = reticle_address + id * 104
			local reticle_overlay_address = read_dword(struct + 0x38)
			initial_scale[0] = read_float(reticle_overlay_address + 0x04)
			initial_scale[1] = read_float(reticle_overlay_address + 0x08)
			--console_out(initial_scale[0].." "..initial_scale[1])
		end
	end
		
	if use_new_dynamic_reticles then
		local pistol_tag_data = read_dword(get_tag("weap", pistol_name) + 0x14)
		local m6s_tag_data = read_dword(get_tag("weap", odst_pistol_name) + 0x14)
		local br_tag_data = read_dword(get_tag("weap", br_name) + 0x14)
		local dmr_tag_data = read_dword(get_tag("weap", dmr_name) + 0x14)
		
		-- change heat loss (since guerilla doesn't allow values above 1)
		write_float(pistol_tag_data + 0x35C, 1.9)
		write_float(m6s_tag_data + 0x35C, 2.5)
		write_float(br_tag_data + 0x35C, 3)
		write_float(dmr_tag_data + 0x35C, 4)
		
		dmr_reticle_additional_pos = 2
		dmr_reticle_initial_scale = 0.25
		dmr_reticle_additional_scale = 0.36
		--dmr_hud = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\dmr") + 0x14)
		local dmr_hud2 = read_dword(get_tag("wphi", "bourrin\\hud\\jesse dynamic dmr") + 0x14)
		
		-- disables multitex overlays
		write_dword(dmr_hud2 + 0x60, 0) 
		write_dword(WEAPON_HUDS[ma5k_tag] + 0x60, 0)
	end
	
	local knife_tag = get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\knife")
	if knife_tag then
		knife_tag = read_dword(knife_tag + 0x14)
		nightvision_address = read_dword(knife_tag + 0xAC + 4)
	end
	
	-- GAUSS SHOCKWAVE
	if use_refractions then
		shockwave_tag = read_dword(get_tag("vehi", "altis\\effects\\shockwave\\shockwave") + 0xC)
		bubble_shield_tag = read_dword(get_tag("vehi", "armor_abilities\\bubble_shield\\deployed\\refraction") + 0xC)
		write_bit((read_dword(get_tag("sgla", "armor_abilities\\bubble_shield\\shaders\\bubble") + 0x14) + 0x28), 2, 0)
		write_short(read_dword(read_dword(read_dword(get_tag("effe", "armor_abilities\\bubble_shield\\create") + 0x14) + 0x34 + 4) + 0x2C + 4) + 0x04, 0)
		write_short(read_dword(read_dword(read_dword(get_tag("effe", "armor_abilities\\bubble_shield\\deployed\\explosion") + 0x14) + 0x34 + 4) + 0x2C + 4) + 0x04, 0)
		write_short(read_dword(read_dword(read_dword(get_tag("effe", "altis\\effects\\shockwave\\shockwave_spawn") + 0x14) + 0x34 + 4) + 0x2C + 4) + 0x04, 0)
		write_short(read_dword(read_dword(read_dword(get_tag("effe", "weapons\\gauss sniper\\effects\\guass explosion new") + 0x14) + 0x34 + 4) + 0x2C + 4) + 0x04, 0)
	end
	return false
end

set_timer(600, "InitializeSettings")

-- check whether hac2 hud scaling is enabled
local aspect_ratio_change = read_float(read_dword(read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\dmr") + 0x14) + 0x64) + 0x28)--(4/3)/(screen_w/screen_h)*0.98

function FixFalconHud() -- fix Falcon ammo hud when using hac_widescreen 1
	local hud_tag = read_dword(get_tag("wphi", "sceny\\ui\\hud\\vehicles\\falcon") + 0x14)
	local meter_address = read_dword(hud_tag + 0x6C + 4)
	local struct = meter_address + 180
	local x = read_word(struct + 0x24)
	if x == 100 then
		write_word(struct + 0x24, 100*aspect_ratio_change)
		write_word(struct + 0x26, 40)
		write_float(struct + 0x28, read_float(struct + 0x28)*aspect_ratio_change)
	end
end

FixFalconHud()

local hologram_tag_red = read_dword(get_tag("vehi", "armor_abilities\\hologram\\hologram_red") + 0xC)
local hologram_tag_blue = read_dword(get_tag("vehi", "armor_abilities\\hologram\\hologram_blue") + 0xC)
local hologram_tag_red_idle = read_dword(get_tag("vehi", "armor_abilities\\hologram\\hologram_idle_red") + 0xC)
local hologram_tag_blue_idle = read_dword(get_tag("vehi", "armor_abilities\\hologram\\hologram_idle_blue") + 0xC)

if fix_double_mines then
	mine_tag_red = read_dword(get_tag("scen", "my_weapons\\trip-mine\\mine_springs red") + 0xC)
	mine_tag_blue = read_dword(get_tag("scen", "my_weapons\\trip-mine\\mine_springs blue") + 0xC)
	mine_tag_default = read_dword(get_tag("scen", "my_weapons\\trip-mine\\mine_springs") + 0xC)
end

if map == "bigass_mod" then
	blur_screen_on_join = false
end

--make invisible walls actually invisible
for i=1,3 do
	local tag = get_tag("scen", "forge\\scenery\\invisible_wall"..i.."\\invisible_wall"..i)
	if tag ~= nil then
		write_float(read_dword(tag + 0x14) + 0x104, 0.1)
		tag = get_tag("mod2", "forge\\scenery\\invisible_wall"..i.."\\invisible_wall"..i)
		write_float(read_dword(tag + 0x14) + 0x08, 900000)
	end
end

function SoundsInitialize()
	local globals_count = read_dword(scenario_data + 0x4A8)
	local globals_address = read_dword(scenario_data + 0x4AC)
	for i=0,globals_count-1 do
		local struct = globals_address + i*92
		if read_word(struct + 0x20) == 24 then
			local name = read_string(struct)
			--console_out(name)
			set_timer(500+i*33, "InitializeASound", name)
		end
	end
end

function InitializeASound(sound)
	execute_script("object_create_anew break")
	execute_script("sound_impulse_start "..sound.." break 1")
	return false
end

SoundsInitialize()

function RemoveSceneryInitialize()
	if remove_scenery_on_distance or true then
		SCENERY_OBJECTS = {}
		
		for i = 0,2 do
			local current_y = -60 + (70*i)
			SCENERY_OBJECTS[current_y] = {}
			for j = 0, 8 do
				current_x = -170 + (42.5*j)
				SCENERY_OBJECTS[current_y][current_x] = {}
				SCENERY_OBJECTS[current_y][current_x].objects = {}
				SCENERY_OBJECTS[current_y][current_x].visible = true
			end
		end
		
		local object_count = read_word(object_table + 0x2E)
		local first_object = read_dword(object_table + 0x34)
		local object_names_count = read_dword(scenario_data + 0x204)
		local object_names_data = read_dword(scenario_data + 0x208)
		
		for i=0,object_count-1 do
			local object = read_dword(first_object + i * 0xC + 0x8)
			if object ~= 0 then
				local object_type = read_word(object + 0xB4)
				if object_type == 6 then
					if read_float(object + 0xAC) < remove_scenery_max_scale then
						local object_name = nil
						local ObjectNameIndex = read_word(object + 0xBA)
						
						if(ObjectNameIndex < object_names_count) then
							object_name = read_string(object_names_data + ObjectNameIndex*36)
						end
					
						if object_name ~= nil then
							local x = read_float(object + 0x5C)
							local y = read_float(object + 0x60)
							local z = read_float(object + 0x64)
							
							local closest_x = nil
							local closest_y = nil
							local closest_x_dist = 10000
							local closest_y_dist = 10000
							
							for current_y, info in pairs (SCENERY_OBJECTS) do
								local dist = (y - current_y)*(y - current_y)
								if dist < closest_y_dist then
									closest_y = current_y
									closest_y_dist = dist
								end
							end
							
							for current_x, info in pairs (SCENERY_OBJECTS[-60]) do
								local dist = (x - current_x)*(x - current_x)
								if dist < closest_x_dist then
									closest_x = current_x
									closest_x_dist = dist
								end
							end
							
							if closest_x ~= nil and closest_y ~= nil then
								SCENERY_OBJECTS[closest_y][closest_x].objects[i] = object_name
							end
						end
					end
				end
			end
		end
		
		--check if any of them are empty and remove them
	end
end

function OnRcon(Message)-- keep in mind maximum number of characters in one message is 80
	messages_per_second = messages_per_second + 1
	
	-- split the MESSAGE string into words
	MESSAGE = {}
	for word in smatch(Message, "([^".."~".."]+)") do 
		tinsert(MESSAGE, word)
	end
	
	if MESSAGE[1] == "red_reticle" then
		write_dword(0x400008CC, 1)
		red_reticle_timer = 2
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "started_sprinting" then
		started_sprinting = true
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "kk" then
		custom_keys = true
		if MESSAGE[2] ~= nil then
			--console_out(Message)
			key_aa = tonumber(MESSAGE[2])
			key_sprint = tonumber(MESSAGE[3])
			key_emote = tonumber(MESSAGE[4])
			key_voice = tonumber(MESSAGE[5])
			
			key_controller_aa = tonumber(MESSAGE[6])
			key_controller_sprint = tonumber(MESSAGE[7])
			key_controller_emote = tonumber(MESSAGE[8])
			key_controller_voice = tonumber(MESSAGE[9])
			
			if MESSAGE[10] ~= nil then
				if MESSAGE[10] == "1" then
					emotes_enabled = true
				else
					emotes_enabled = false
				end
			end
			
			if MESSAGE[11] ~= nil then
				if MESSAGE[11] == "1" then
					voice_enabled = true
				else
					voice_enabled = false
				end
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "choose_keys" then
		custom_keys = true
		waiting_for_a_key = true
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "hud_msg" then
		hud_message(MESSAGE[2])
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "play_chimera_sound" then
		if MESSAGE[3] ~= nil then
			PlaySound(MESSAGE[2], MESSAGE[3])
		else
			PlaySound(MESSAGE[2])
		end
		
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if Message == "|nbgreload" then
		custom_keys = false
		return false
	end
	
	if MESSAGE[1] == "mine" then
		local mine_tag = nil
		if MESSAGE[2] == "def" then
			mine_tag = "my_weapons\\trip-mine\\mine_springs"
		elseif MESSAGE[2] == "red" then
			mine_tag = "my_weapons\\trip-mine\\mine_springs red"
		elseif MESSAGE[2] == "blue" then
			mine_tag = "my_weapons\\trip-mine\\mine_springs blue"
		end
		if mine_tag ~= nil then
			spawn_object("scen", mine_tag, MESSAGE[3], MESSAGE[4], MESSAGE[5])
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "voice" then
		PlaySoundOnPlayer(MESSAGE[2], MESSAGE[3])
		return false
	end
	
	if MESSAGE[1] == "visor_room" then
		local player = get_dynamic_player()
		if player ~= nil then
			local vehicle = read_dword(player + 0x11C)
			if vehicle ~= nil then
				vehicle = get_object(vehicle)
				if vehicle ~= nil then
					local x = read_float(vehicle + 0x5C)
					local y = read_float(vehicle + 0x60)
					local z = read_float(vehicle + 0x64)
					local fake_spartan = FindClosestObject(x, y, z - 0.06, 0, 0)
					if fake_spartan ~= nil then
						fake_spartan = get_object(fake_spartan)
						if fake_spartan ~= nil then
							write_float(fake_spartan + 0x1C4, MESSAGE[2])
							write_float(fake_spartan + 0x1C8, MESSAGE[3])
							write_float(fake_spartan + 0x1CC, MESSAGE[4])
							if MESSAGE[5] == "haunted" then
								if MESSAGE[2] == "0" and MESSAGE[3] == "0" and MESSAGE[4] == "0" then
									write_word(fake_spartan + 0x176, 1)
								else
									write_word(fake_spartan + 0x176, 0)
								end
							end
							if debug_console then
								return true
							else
								return false
							end
						end
					end
				end
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "visor" then
		for i=0,15 do
			local player_info = get_player(i)
			if player_info ~= nil then
				local player_name = read_wide_string(player_info + 0x4, 12)
				if player_name == MESSAGE[5] then
					local player = get_dynamic_player(i)
					if player ~= nil then
						write_float(player + 0x1C4, MESSAGE[2])
						write_float(player + 0x1C8, MESSAGE[3])
						write_float(player + 0x1CC, MESSAGE[4])
						if MESSAGE[6] == "haunted" then
							if MESSAGE[2] == "0" and MESSAGE[3] == "0" and MESSAGE[4] == "0" then
								write_word(player + 0x176, 1)
							else
								write_word(player + 0x176, 0)
							end
						end
						if debug_console then
							return true
						else
							return false
						end
					end
				end
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "logo" then
		for i=0,15 do
			local player_info = get_player(i)
			if player_info ~= nil then
				local player_name = read_wide_string(player_info + 0x4, 12)
				if player_name == MESSAGE[3] then
					local player = get_dynamic_player(i)
					if player ~= nil then
						write_word(player + 0x176, MESSAGE[2])
						if debug_console then
							return true
						else
							return false
						end
					end
				end
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if  MESSAGE[1] == "drone_color" then
		local x = MESSAGE[2]
		local y = MESSAGE[3]
		local z = MESSAGE[4]
		local red = MESSAGE[5]
		local green = MESSAGE[6]
		local blue = MESSAGE[7]
		local object_type = MESSAGE[8]
		SetDroneColor(x, y, z, red, green, blue, object_type)
		return false
	end
	
		-- [2] = default / default_red [3] = x [4] = y [5] = z [6] = team
	if MESSAGE[1] == "nav" then
		if MESSAGE[3] ~= nil and MESSAGE[4] ~= nil and MESSAGE[5] ~= nil and MESSAGE[6] ~= nil then
		execute_script("(deactivate_team_nav_point_flag "..TEAMS[tonumber(MESSAGE[6])].." nav)")
			local scenario_tag_index = read_word(0x40440004)
			local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
			local data = read_dword(scenario_tag + 0x14)
			local reflexive_count = read_dword(data + 0x4E4 + 0)
			local reflexive_address = read_dword(data + 0x4E4 + 4)
			if reflexive_count >= 31 then
				local struct = reflexive_address + 27 * 92
				write_float(struct + 0x24, MESSAGE[3])
				write_float(struct + 0x28, MESSAGE[4])
				write_float(struct + 0x2C, MESSAGE[5])
				execute_script("(activate_team_nav_point_flag "..MESSAGE[2].." "..TEAMS[tonumber(MESSAGE[6])].." nav 0)")
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "remove_nav" then
		for i=0,15 do
			execute_script("(deactivate_team_nav_point_flag "..TEAMS[i].." nav)")
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	-- reload forge stuff
	if MESSAGE[1] == "|nforgereloaded" then
		for ID, info in pairs (SPAWNED_OBJECTS) do
			if get_object(ID) ~= nil then
				delete_object(ID)
			end
		end
		SPAWNED_OBJECTS = {}
		return false
	end
	
	-- spawn forge object
	if MESSAGE[1] == "fs" then
		local meta_id = tonumber(MESSAGE[2])
		local x = tonumber(MESSAGE[3])
		local y = tonumber(MESSAGE[4])
		local z = tonumber(MESSAGE[5])
		local rot1 = tonumber(MESSAGE[6])
		local rot2 = tonumber(MESSAGE[7])
		local rot3 = tonumber(MESSAGE[8])
		local object_type = tonumber(MESSAGE[9])
		local permutation = tonumber(MESSAGE[10])
		
		if meta_id ~= nil and get_tag(meta_id) ~= nil and MESSAGE[5] ~= nil and MESSAGE[8] ~= nil then
			local ID
			local name = read_string(read_dword(get_tag(meta_id) + 0x10))
			if object_type == 6 then
				ID = spawn_object("scen", name, x, y, z)
			elseif object_type == 7 then
				ID = spawn_object("mach", name, x, y, z)
			elseif object_type == 8 then
				ID = spawn_object("ctrl", name, x, y, z)
			elseif object_type == 9 then
				ID = spawn_object("lifi", name, x, y, z)
			end
			if ID ~= nil then
				local object = get_object(ID)
				if object ~= nil then
					SPAWNED_OBJECTS[ID] = {}
					SPAWNED_OBJECTS[ID].shadow = nil
					SPAWNED_OBJECTS[ID].type = object_type
					SPAWNED_OBJECTS[ID].name = name
					SPAWNED_OBJECTS[ID].x = x
					SPAWNED_OBJECTS[ID].y = y
					SPAWNED_OBJECTS[ID].z = z
					SPAWNED_OBJECTS[ID].rot1 = rot1
					SPAWNED_OBJECTS[ID].rot2 = rot2
					SPAWNED_OBJECTS[ID].rot3 = rot3
					SPAWNED_OBJECTS[ID].permutation = permutation
					rot = convert(rot1, rot2, rot3)
					write_float(object + 0x74, rot[1])
					write_float(object + 0x78, rot[2])
					write_float(object + 0x7C, rot[3])
					write_float(object + 0x80, rot[4])
					write_float(object + 0x84, rot[5])
					write_float(object + 0x88, rot[6])
					write_word(object + 0x176, permutation)
					if object_type == 6 and find(name, "cliff") ~= nil then -- only change model permutations for cliffs
						write_char(object + 0x180, permutation)
					end
					
					if permutation ~= 0 and FORGE_COLOR_PERMUTATIONS[permutation] ~= nil then
						write_float(object + 0x1B8, FORGE_COLOR_PERMUTATIONS[permutation][1]/255)
						write_float(object + 0x1BC, FORGE_COLOR_PERMUTATIONS[permutation][2]/255)
						write_float(object + 0x1C0, FORGE_COLOR_PERMUTATIONS[permutation][3]/255)
					end
					
					if MESSAGE[11] ~= nil then
						if tonumber(MESSAGE[11]) == 1 then
							SPAWNED_OBJECTS[ID].shadow = true
							write_bit(object + 0x10, 18, 0)
						end
					end
					
					if object_type >= 7 and object_type <= 9 then
						write_float(object + 0x1FC, 1)
						write_float(object + 0x208, 0)
					end
					
					if debug_console then
						return true
					else
						return false
					end
				else
					console_out("Error! Couldn't create a forge object.")
				end
			end
		end
	end
	
	-- delete forge object
	if MESSAGE[1] == "fd" then
		local meta_id = tonumber(MESSAGE[2])
		local x = tonumber(MESSAGE[3])
		local y = tonumber(MESSAGE[4])
		local z = tonumber(MESSAGE[5])
		if meta_id~=nil and x~=nil and y~=nil and z~=nil then
			for ID,INFO in pairs (SPAWNED_OBJECTS) do
				if INFO.x==x and INFO.y==y and INFO.z==z then
					local object = get_object(ID)
					if object~=nil then
						delete_object(ID)
					end
					SPAWNED_OBJECTS[ID] = nil
					break
				end
			end
		end
		return false
	end
	
	-- get forge object
	if MESSAGE[1] == "fo" then
		local x = tonumber(MESSAGE[2])
		local y = tonumber(MESSAGE[3])
		local z = tonumber(MESSAGE[4])
		
		for ID,INFO in pairs (SPAWNED_OBJECTS) do
			if INFO.x==x and INFO.y==y and INFO.z==z then
				local object = get_object(ID)
				if object~=nil then
					forge_obj_chosen = ID
					break
				end
			end
		end
		
		return false
	end
	
	-- update forge object
	if MESSAGE[1] == "fu" then
		local x = tonumber(MESSAGE[2])
		local y = tonumber(MESSAGE[3])
		local z = tonumber(MESSAGE[4])
		local rot1 = tonumber(MESSAGE[5])
		local rot2 = tonumber(MESSAGE[6])
		local rot3 = tonumber(MESSAGE[7])
		local permutation = tonumber(MESSAGE[8])
		local shadow = tonumber(MESSAGE[9]) == 1
		
		if forge_obj_chosen ~= nil and MESSAGE[5] ~= nil and MESSAGE[8] ~= nil then
			if SPAWNED_OBJECTS[forge_obj_chosen] ~= nil then
				local object = get_object(forge_obj_chosen)
				if object ~= nil then
					SPAWNED_OBJECTS[forge_obj_chosen].x = x
					SPAWNED_OBJECTS[forge_obj_chosen].y = y
					SPAWNED_OBJECTS[forge_obj_chosen].z = z
					SPAWNED_OBJECTS[forge_obj_chosen].rot1 = rot1
					SPAWNED_OBJECTS[forge_obj_chosen].rot2 = rot2
					SPAWNED_OBJECTS[forge_obj_chosen].rot3 = rot3
					SPAWNED_OBJECTS[forge_obj_chosen].permutation = permutation
					SPAWNED_OBJECTS[forge_obj_chosen].shadow = shadow
					rot = convert(rot1, rot2, rot3)
					write_float(object + 0x74, rot[1])
					write_float(object + 0x78, rot[2])
					write_float(object + 0x7C, rot[3])
					write_float(object + 0x80, rot[4])
					write_float(object + 0x84, rot[5])
					write_float(object + 0x88, rot[6])
					write_word(object + 0x176, permutation)
					if find(SPAWNED_OBJECTS[forge_obj_chosen].name, "cliff") ~= nil then -- only change model permutations for cliffs
						write_char(object + 0x180, SPAWNED_OBJECTS[forge_obj_chosen].permutation)
						console_out("set")
					end
					
					if permutation ~= 0 and FORGE_COLOR_PERMUTATIONS[permutation] ~= nil then
						write_float(object + 0x1B8, FORGE_COLOR_PERMUTATIONS[permutation][1]/255)
						write_float(object + 0x1BC, FORGE_COLOR_PERMUTATIONS[permutation][2]/255)
						write_float(object + 0x1C0, FORGE_COLOR_PERMUTATIONS[permutation][3]/255)
					end
					
					console_out("Permutation set to "..permutation)
					
					if debug_console then
						return true
					else
						return false
					end
				end
			end
		end
		console_out("Error! Couldn't update a forge object.")
		return false
	end
	
	-- clear netgame flags
	if MESSAGE[1] == "fclear_netgame_flags" then
		netgame_flag_counter = 3
		local scenario_tag_index = read_word(0x40440004)
		local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
		local scenario_data = read_dword(scenario_tag + 0x14)
		netgame_flag_count = read_dword(scenario_data + 0x378)
		netgame_flags = read_dword(scenario_data + 0x378 + 4)
		
		for i=0,netgame_flag_count do
			local current_flag = netgame_flags + i*148
			if read_word(current_flag + 0x10) ~= 0 then
				write_word(current_flag + 0x10, 5)
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	-- set hill marker
	if MESSAGE[1] == "fhill_marker" then
		--this won't work because script is sandboxed
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "frace" then
		--this won't work because script is sandboxed
		if debug_console then
			return true
		else
			return false
		end
	end
	
	-- set ctf flags
	if MESSAGE[1] == "fctf" then
		local team = tonumber(MESSAGE[2])
		local x = tonumber(MESSAGE[3])
		local y = tonumber(MESSAGE[4])
		local z = tonumber(MESSAGE[5])
		
		if z ~= nil then
			local scenario_tag_index = read_word(0x40440004)
			local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
			local scenario_data = read_dword(scenario_tag + 0x14)
			local netgame_flag_count = read_dword(scenario_data + 0x378)
			local netgame_flags = read_dword(scenario_data + 0x378 + 4)
			
			for i=0,netgame_flag_count do
				local current_flag = netgame_flags + i*148
				if read_word(current_flag + 0x10) == 0 then
					if read_byte(current_flag + 0x12) == team then
						write_float(current_flag, x)
						write_float(current_flag + 4, y)
						write_float(current_flag + 8, z)
					end
				end
			end
			
			if team == 0 then
				--write_float(ctf_flag_red, x)
				--write_float(ctf_flag_red + 4, y)
				--write_float(ctf_flag_red + 8, z)
			elseif team == 1 then
				--write_float(ctf_flag_blue, x)
				--write_float(ctf_flag_blue + 4, y)
				--write_float(ctf_flag_blue + 8, z)
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end

	-- set telporters
	if MESSAGE[1] == "ftpfrom" or MESSAGE[1] == "ftpto" then
		local x = tonumber(MESSAGE[2])
		local y = tonumber(MESSAGE[3])
		local z = tonumber(MESSAGE[4])
		local rot = tonumber(MESSAGE[5])
		local team = tonumber(MESSAGE[6])
		if x ~= nil and team ~= nil and netgame_flag_count ~= nil then
			if netgame_flag_counter <= netgame_flag_count then
				local current_flag = netgame_flags + netgame_flag_counter*148
				write_float(current_flag, x)
				write_float(current_flag + 4, y)
				write_float(current_flag + 8, z)
				write_float(current_flag + 0x0C, rot)
				write_short(current_flag + 0x12, team)
				if MESSAGE[1] == prefix.."tpfrom" then
					write_word(current_flag + 0x10, 6)
				else
					write_word(current_flag + 0x10, 7)
				end
				netgame_flag_counter = netgame_flag_counter + 1
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	-- this changes the sky in the scenario (for all bsps)
	if MESSAGE[1] == "fsky" then
		local sky_id = tonumber(MESSAGE[2])
		local sky_yaw = tonumber(MESSAGE[3])
		local sky_pitch = tonumber(MESSAGE[4])
		local scenario_tag_index = read_word(0x40440004)
		local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
		local scenario_data = read_dword(scenario_tag + 0x14)
		
		local sky_count = read_dword(scenario_data + 0x30)
		local sky_address = read_dword(scenario_data + 0x30 + 4)
		
		for i=0, sky_count - 1 do
			local struct = sky_address + i*16
			local tag = get_tag("sky ", SKIES[sky_id])

			write_dword(struct,read_dword(tag))
			write_dword(struct + 0xC,read_dword(tag + 0xC))
			
			if MESSAGE[3] ~= nil and MESSAGE[4] ~= nil then
				local sky_tag = read_dword(tag + 0x14)
				local light_count = read_dword(sky_tag + 0xC4)
				local light_address = read_dword(sky_tag + 0xC8)
				for j=0, light_count - 1 do
					write_float(light_address + j * 116 + 0x68, sky_yaw)
					write_float(light_address + j * 116 + 0x6C, sky_pitch)
				end
			end
		end
		
		if sky_yaw and sky_pitch ~= nil then
			ForgeShadowDirection(sky_yaw, sky_pitch)
		end
		
		-- for open sauce
		execute_script("structure_bsp_set_sky_set 0 ".. sky_id - 1)
		
		if debug_console then
			return true
		else
			return false
		end
	end
	
	-- change the textures of the terrain shader
	if MESSAGE[1] == "fterrain" then
		local shader = read_dword(get_tag("senv", "altis\\levels\\bigass\\shaders\\bigassgrass") + 0x14)
		local terrain_id = tonumber(MESSAGE[2])
		if terrain_id == 2 then 
			local base_bitmap = get_tag("bitm", "altis\\levels\\bigass\\bitmaps\\ground_sand")
			local bitmap = get_tag("bitm", "altis\\bitmaps\\stuff\\bitmaps\\beach")
			local bitmap_normal = get_tag("bitm", "altis\\bitmaps\\stuff\\bitmaps\\beach_normal")
			local bitmap2 = get_tag("bitm", "levels\\a30\\bitmaps\\detail cliff rock smooth")
			--base map
			write_dword(shader + 0x88,read_dword(base_bitmap))
			write_dword(shader + 0x88 + 0xC,read_dword(base_bitmap + 0xC))
			
			write_short(shader + 0xB0, 01) -- multiply
			--primary detail map
			write_float(shader + 0xB4, 100) -- scale
			write_dword(shader + 0xB8,read_dword(bitmap2))
			write_dword(shader + 0xB8 + 0xC,read_dword(bitmap2 + 0xC))
			
			--secondary detail map
			write_float(shader + 0xC8, 150) -- scale
			write_dword(shader + 0xCC,read_dword(bitmap))
			write_dword(shader + 0xCC + 0xC,read_dword(bitmap + 0xC))
			
			--micro detail map
			write_short(shader + 0xF4, 01) -- multiply
			write_float(shader + 0xF8, 12) -- scale
			write_dword(shader + 0xFC,read_dword(bitmap))
			write_dword(shader + 0xFC + 0xC,read_dword(bitmap + 0xC))
			
			--normal map
			write_float(shader + 0x138, 150) -- scale X
			write_float(shader + 0x138, 150) -- scale Y
			write_dword(shader + 0x128,read_dword(bitmap_normal))
			write_dword(shader + 0x128 + 0xC,read_dword(bitmap_normal + 0xC))
			
			--remove detail objects
			RemoveDetailObjects()
			
		elseif terrain_id == 3 then 
			local bitmap = get_tag("bitm", "altis\\levels\\bigass\\bitmaps\\grass")
			local base_bitmap = get_tag("bitm", "altis\\levels\\bigass\\bitmaps\\ground_neutral")
			--base map
			write_dword(shader + 0x88,read_dword(base_bitmap))
			write_dword(shader + 0x88 + 0xC,read_dword(base_bitmap + 0xC))
			
			--primary detail map
			write_short(shader + 0xB0, 01) -- multiply
			write_float(shader + 0xB4, 3010) -- scale
			write_dword(shader + 0xB8,read_dword(bitmap))
			write_dword(shader + 0xB8 + 0xC,read_dword(bitmap + 0xC))
			
			--micro detail map
			write_short(shader + 0xF4, 0) -- multiply
			write_float(shader + 0xF8, 13) -- scale
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "fgravity" then
		if MESSAGE[2] ~= nil then
			write_float(0x637BE4, tonumber(MESSAGE[2]))
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	-- change the fog for all skies
	if MESSAGE[1] == "ffog" then
		local red = MESSAGE[2]
		local green = MESSAGE[3]
		local blue = MESSAGE[4]
		local density = MESSAGE[5]
		local fade_start = MESSAGE[6]
		local fade_end = MESSAGE[7]
		local remove_sky = MESSAGE[8]
		local move_camera = MESSAGE[9]
		if fade_end ~= nil then
			local scenario_tag_index = read_word(0x40440004)
			local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
			local scenario_data = read_dword(scenario_tag + 0x14)
			
			local sky_count = read_dword(scenario_data + 0x30)
			local sky_address = read_dword(scenario_data + 0x30 + 4)
			
			for i=0, sky_count-1 do
				local struct = sky_address + i*16
				local sky_tag_path = read_string(read_dword(struct + 0x4))
				local sky_tag = read_dword(get_tag("sky ", sky_tag_path) + 0x14)
				
				if remove_sky ~= nil and remove_sky == "1" then
					write_dword(sky_tag, 0xFFFFFFFF)
					write_dword(sky_tag + 0xC, 0xFFFFFFFF)
				end
				
				write_float(sky_tag + 0x58, red)
				write_float(sky_tag + 0x58 + 4, green)
				write_float(sky_tag + 0x58 + 8, blue)
				write_float(sky_tag + 0x6C, density)
				write_float(sky_tag + 0x70, fade_start)
				write_float(sky_tag + 0x74, fade_end)
			end
			
			if move_camera == "1" then
				fog_camera_test = true
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	--apply damage effect to player to set a screen tint
	if MESSAGE[1] == "fscreen_tint" then
		local effect_type = MESSAGE[2]
		local intensity = MESSAGE[3]
		local red = MESSAGE[4]
		local green = MESSAGE[5]
		local blue = MESSAGE[6]
		local hud_tint = MESSAGE[7]
		if blue ~= nil then 
			if hud_tint ~= nil then
				local tag = read_dword(get_tag("unhi", "bourrin\\hud\\h1 symmetrical") + 0x14)
				write_byte(tag + 0x24, 0)
				write_byte(tag + 0x26, 0)
				write_float(tag + 0x28, 500)
				write_float(tag + 0x2C, 500)
				write_byte(tag + 0x58 + 0, floor(blue*255))
				write_byte(tag + 0x58 + 1, floor(green*255))
				write_byte(tag + 0x58 + 2, floor(red*255))
			else
				local tag = read_dword(get_tag("jpt!", "forge\\screen_tint") + 0x14)
				write_word(tag + 0x24, effect_type)
				write_float(tag + 0x44, intensity)
				--0x4C is alpha
				write_float(tag + 0x4C + 4, red)
				write_float(tag + 0x4C + 8, green)
				write_float(tag + 0x4C + 12, blue)
				if intensity ~= 0 then
					screen_tint = true
					write_float(tag + 0x34, 1000)
				else
					screen_tint = false
					write_float(tag + 0x34, 0)
				end
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	-- removes all objects that were spawned via forge
	if MESSAGE[1] == "fremove_spawned_objects" then
		for ID, info in pairs (SPAWNED_OBJECTS) do
			if get_object(ID) ~= nil then
				delete_object(ID)
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	-- removes ALL scenery objects from the map
	if MESSAGE[1] == "fdestroy_all_scenery" then
		execute_script("set forge_mode true")
		for ID, info in pairs (SPAWNED_OBJECTS) do
			if get_object(ID) ~= nil then
				delete_object(ID)
			end
		end
		SPAWNED_OBJECTS = {}
		destroy_all_scenery = true
		local object_count = read_word(object_table + 0x2E)
		local first_object = read_dword(object_table + 0x34)
		
		for i=0,object_count-1 do
			local object = read_dword(first_object + i * 0xC + 0x8)
			if object ~= nil and object ~= 0 then
				local object_type = read_word(object + 0xB4)
				if object_type == 6 then
					if SCENERY_NOT_TO_REMOVE[GetName(object)] == nil then
						delete_object(read_word(first_object + i*12)*0x10000 + i)
					end
				end
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	-- removes ALL device objects from the map
	if MESSAGE[1] == "fdestroy_all_devices" then
		local object_count = read_word(object_table + 0x2E)
		local first_object = read_dword(object_table + 0x34)
		
		for i=0,object_count-1 do
			local object = read_dword(first_object + i * 0xC + 0x8)
			if object ~= nil and object ~= 0 then
				local object_type = read_word(object + 0xB4)
				if object_type == 7 or object_type == 8 or object_type == 9 then
					delete_object(read_word(first_object + i*12)*0x10000 + i)
				end
			end
		end
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "tacoman" then
		OnCommand("taco")
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if Message == "|nforgeball" then
		forkball = true
		if debug_console then
			return true
		else
			return false
		end
	end
	
	if MESSAGE[1] == "fdisable_hud" then
		if MESSAGE[2] == "1" then
			disable_hud = true
		else
			disable_hud = nil
		end
		return false
	end
	
	if Message == "|ndo_you_have_chimera?" then
		execute_script("rcon password i_have_chimera_lol")
		if debug_console then
			return true
		else
			return false
		end
	end
	
    if Message == "rcon command failed" then
        if debug_console then
			return true
		else
			return false
		end
    end
end

function PlaySound(sound, volume)
	if volume == nil then
		execute_script("sound_impulse_start "..sound.." none 1")
	else
		execute_script("sound_impulse_start "..sound.." none "..volume)
	end
end

function PlaySoundReal(sound, i, pitch)
	execute_script("(sound_impulse_start "..sound.." vc"..i.." "..pitch..")")
	execute_script("(set sound_timer (sound_impulse_time "..sound.."))")
	VC[tonumber(i)].timer = tonumber(get_global("sound_timer"))+1
	last_sound = sound
	return false
end

function PlaySoundOnPlayer(name, sound)
	for i=0,15 do
		local player_info = get_player(i)
		if player_info ~= nil then
			local player_name = read_wide_string(player_info + 0x4, 12)
			if player_name == name then
				local player = get_dynamic_player(i)
				if player then
					
					local pitch = BIPED_VOICE_PITCH[GetName(player)]
					
					if local_player_index==nil or i==local_player_index then
						if VC[i].timer < key_spam_timer_voice - 1 then
							--PlaySound(sound)
							PlaySoundReal(sound, i, pitch)
						end
					elseif VC[i].timer < 29 and VC[i].id ~= nil then
						VC[tonumber(i)].timer = 30
						MoveVCToPlayer(i)
						set_timer(33, "PlaySoundReal", sound, i, pitch)
					end
				end
				return
			end
		end
	end
end

function MoveVCToPlayer(i)
	local player = get_dynamic_player(i)
	if VC[i].timer < 1 or player == nil then
		local object = get_object(VC[i].id)
		if object then
			write_float(object + 0x5C, -57.6067)
			write_float(object + 0x60, -195.261)
			write_float(object + 0x64, -110)
			--write_float(object + 0x5C, -120.231)
			--write_float(object + 0x60, -61.8164)
			--write_float(object + 0x64, 1)
		end
	else
		local object = get_object(VC[i].id)
		if object then
			local x, y, z = read_float(player + 0x7E8), read_float(player + 0x7EC), read_float(player + 0x7F0)
			--console_out(read_dword(object + 0x10))
			write_bit(object + 0x8, 0, 0)
			write_bit(object + 0x10, 4, 0)
			write_bit(object + 0x10, 5, 0)
			write_bit(object + 0x10, 10, 0)
			
			write_float(object + 0x5C, x)
			write_float(object + 0x60, y)
			write_float(object + 0x64, z+0.17)
			--write_float(object + 0x20C, x)
			--write_float(object + 0x210, y)
			--write_float(object + 0x214, z+0.17)
			write_float(object + 0x68, read_float(player + 0x68))
			write_float(object + 0x6C, read_float(player + 0x6C))
			write_float(object + 0x70, read_float(player + 0x70))
			--write_dword(object + 0x98, read_dword(player + 0x98))
		end
	end
end

function SoundWeapons(i)
	local player = get_dynamic_player(i)
	if player then
		if VC[i].id then
			local object = get_object(VC[i].id)
			if object then
				write_dword(object + 0x204, 0xF000000)
			else
				VC[i].id = nil
				--console_out("weap is nil", 1, 0, 0)
			end
		else
			execute_script("object_create_anew vc"..i)
			set_timer(33, "FindWeapon", i)
		end
	elseif VC[i].id then
		--console_out("destroying vc", 1, 1,0)
		execute_script("object_destroy vc"..i)
		VC[i].id = nil
	end
end

function FindWeapon(j)
	j = tonumber(j)
	
	if VC[j].id ~= nil then return false end
	
	local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
	
	for i=0,object_count-1 do
        local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 then
			if read_word(object + 0xB4) == 2 and read_dword(object) == vc_id then
				-- stupid way to identify object based on their position on the Y axis...
				local id = floor((170 + read_float(object + 0x60))/-0.1)
				--console_out("weap found "..id.."     "..read_float(object + 0x60), 0, 1, 0)
				if id==j then
					--console_out("it's a match!",0,1,1)
					VC[j].id = read_word(first_object + i*12)*0x10000 + i
					return false
				end
			end
		end
	end
	return false
end

function FindClosestObject(x, y, z, object_type_needed, ai)
	local closest_object = nil
	local closest_distance = 1000
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
	
	for i=0,object_count-1 do
		--local ID = read_word(first_object + i*12)*0x10000 + i
        local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 then
			local object_type = read_word(object + 0xB4)
			if object_type == object_type_needed then
				if object_type_needed == 6 or object_type_needed == 4 or object_type_needed == 2 or read_dword(object + 0x218) == 0xFFFFFFFF then
					local x1 = read_float(object + 0x5C)
					local y1 = read_float(object + 0x60)
					local z1 = read_float(object + 0x64)
					if x1 ~= nil then
						local x_dist = x1 - x
						local y_dist = y1 - y
						local z_dist = z1 - z
						local distance = sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
						if use_host_side_biped == false and distance < 2 and read_dword(object + 0x1F4) == 0xFFFFFFFF then
							write_float(object + 0x64, -100)
						elseif closest_distance > distance then
							closest_distance = distance
							closest_object = read_word(first_object + i*12)*0x10000 + i
						end
					end
				end
			end
		end
	end
	
	return closest_object
end

function OnFrame()
	frames = frames + 1
	
	local player = get_dynamic_player()
	if player then
		CustomKeys(player)
	end
	
	--CUSTOM CONTROLS
	if waiting_for_a_key ~= nil then
		for i = 0,103 do
			local key = read_byte(keyboard_input_address + i)
			if key == 1 then
				execute_script("rcon password key~"..i.."")
				waiting_for_a_key = nil
				break
			end
		end
		
		for i=0,29 do
			local key = GetControllerInput(i)
			if key == 1 then
				execute_script("rcon password key~"..i.."~1")
				waiting_for_a_key = nil
				break
			end
		end
		
		--dpad
		for i=0,3 do
			local j = 100+i*2
			local key = GetControllerInput(j)
			if key == 1 then
				execute_script("rcon password key~"..j.."~1")
				waiting_for_a_key = nil
				break
			end
		end
	end
	
	EmoteWheel()
end

function OnTick()

	ticks = ticks + 1
	if ticks%30 == 29 then
		if debug_msg_per_s then
			console_out("Messages per second: "..messages_per_second, 1, 0, 0)
		end
		messages_per_second = 0
		fps = frames
		--console_out("FPS: "..fps)
		frames = 0
	end
	if ticks == 90 then
		RemoveSceneryInitialize()
	end
	if forge_shadow_update_timer > 0 then
		forge_shadow_update_timer = forge_shadow_update_timer - 1
	end
	
--CHIMERA DETECTION
	if ticks < 100 then
		block_rcon_command_failed = true
	elseif ticks%30 == 1 then
		block_rcon_command_failed = false
	end
	
	HologramsAndRefractions()
	
	if key_aa_timer > 0 then
		key_aa_timer = key_aa_timer - 1
	end
	if key_sprint_timer > 0 then
		key_sprint_timer = key_sprint_timer - 1
	end
	if key_voice_timer > 0 then
		key_voice_timer = key_voice_timer - 1
	end
	
	
--VOICE LINE STUFF
	for i=0,15 do
		if VC[i].timer > 0 then
			VC[i].timer = VC[i].timer - 1
		end
		
		if local_player_index ~= nil and i ~= local_player_index then
			SoundWeapons(i)
			if VC[i].id then
				MoveVCToPlayer(i)
			end
		end
		
		--console_out(VC[i].timer)
		local player = get_dynamic_player(i)
		if player == nil and last_sound ~= nil and VC[i].timer > 0 then
			execute_script("sound_impulse_stop "..last_sound)
			--console_out("stopped sound "..last_sound)
			last_sound = nil
		end
	end

--MISC BIGASS STUFF
	if red_reticle_timer > 0 then
		write_dword(0x400008CC, 1)
		red_reticle_timer = red_reticle_timer - 1
	end
	
	if player_damaged_timer > 0 then
		player_damaged_timer = player_damaged_timer - 1
		if player_damaged_timer == 0 then
			execute_script("cinematic_screen_effect_stop")
		end
	end
	local player = get_dynamic_player()
	local hide_hud = false
	if player ~= nil then
		if player_dead > 0 then
			if join_blur_timer == 0 then
				if player_dead == 15 then
					execute_script("cinematic_screen_effect_start true")
					execute_script("cinematic_screen_effect_set_convolution 7 2 20 0.01 0.5")
				elseif player_dead == 1 then
					execute_script("cinematic_screen_effect_stop")
				end
			end
			
			player_dead = player_dead - 1
		elseif player_health > read_float(player + 0xE0) then
			execute_script("cinematic_screen_effect_start true")
			execute_script("cinematic_screen_effect_set_convolution 5 1 1 0.01 0.2")
			player_damaged_timer = 5
		end
		player_health = read_float(player + 0xE0)
		
		local current_grenade_type = read_byte(player + 0x31D)
		if grenade_type ~= current_grenade_type and player_dead < 10 and ticks > 10 then
			if current_grenade_type == 0 then
				PlaySound("switch_to_claymore")
			else
				PlaySound("switch_to_frag")
			end
		end
		grenade_type = current_grenade_type
		
		local camera = read_i16(0x647498)
		local zoom_level = read_u8(player + 0x320)
		
		-- disable hud in armor room
		local vehicle = read_dword(player + 0x11C)
		if vehicle ~= 0xFFFFFFFF then
			vehicle = get_object(vehicle)
			if vehicle ~= nil then
				local meta_id = read_dword(vehicle)
				if meta_id == armor_room_tag then
					--execute_script("show_hud 0")
					execute_script("hud_show_health 0")
					execute_script("hud_show_motion_sensor 0")
					execute_script("hud_show_shield 0")
					hide_hud = true
					
					-- Set armor room biped color
					for i=0,15 do
						local player = get_dynamic_player(i)
						if player ~= nil then
							local vehicle = read_dword(player + 0x11C)
							if vehicle ~= nil and vehicle ~= 0 then
								vehicle = get_object(vehicle)
								if vehicle ~= nil and read_dword(vehicle) == armor_room_tag then
									local x = read_float(vehicle + 0x5C)
									local y = read_float(vehicle + 0x60)
									local z = read_float(vehicle + 0x64)
									local fake_spartan = FindClosestObject(x, y, z - 0.06, 0, 0)
									if fake_spartan ~= nil then
										fake_spartan = get_object(fake_spartan)
										if fake_spartan ~= nil then
											write_float(fake_spartan + 0x1D0, read_float(player + 0x1D0))
											write_float(fake_spartan + 0x1D4, read_float(player + 0x1D4))
											write_float(fake_spartan + 0x1D8, read_float(player + 0x1D8))
											
											if GetName(fake_spartan) ~= "bourrin\\halo reach\\spartan\\male\\haunted_preview" then
												write_word(fake_spartan + 0x176, read_word(player + 0x176))
											end
										end
									end
								end
							end
						end
					end
				end
				
				if build > 0 then -- fix this later when chimera can edit camera again (it's fixed on Chimera 1.0 yay)
					-- fix zooming on vehicle passenger seats
					if read_word(player + 0x2F0) > 0 and zoom_level < 255 then
						if camera == 31952 then
							vehicle_camera = 1
						end
						write_i16(0x647498, 30400)
					elseif vehicle_camera == 1 then
						write_i16(0x647498, 31952)
					end
				end
			else
				vehicle_camera = 0
			end
		else
			vehicle_camera = 0
		end
	else
		if player_dead < 15 then
			--console_out("player died")
			execute_script("cinematic_screen_effect_stop")
		end
		player_dead = 15
		started_sprinting = false
	end
	if hide_hud == false then
		--execute_script("show_hud 1")
		execute_script("hud_show_health 1")
		execute_script("hud_show_motion_sensor 1")
		execute_script("hud_show_shield 1")
	end
	
--SCREEN BLUR
	if join_blur_timer ~= 0 then
		join_blur_timer = join_blur_timer - 1
		if blur_screen_on_join then
			if join_blur_timer == 59 then
				execute_script("cinematic_screen_effect_start true")
				execute_script("cinematic_screen_effect_set_convolution 7 1 6 0.01 2")
				execute_script("fade_in 0 0 0 700")
			elseif join_blur_timer == 35 then
				execute_script("fade_in 0 0 0 20")
			end
			if join_blur_timer == 0 then
				execute_script("cinematic_screen_effect_stop")
			end
		end
	end
	
	NightVision()
	PutAway()
	DynamicReticles()
	SnowTrees()
	CubemapSwitching()
	BinocularHighlights()
	BackpackWeapons()
	FPHandSwitch()
	TripMines()
	SceneryRemovalOnDistance()
	DynamicShadows()
	Flashlight()
	ReadyAnims()
	AltIdleAnims()
	AssAnimFix()
	Taco()
	ForgeMachines()
	ForgeShadows()
	ForgeScreenTint()
	Forgeball()
	DisableHud()
	SpartanLaserCharge()
	ObjectCleanup()
	FPSwayZ()
	RocketLockOn()
end

function PutAway()
	local player = get_dynamic_player()
	if player ~= nil then
		local weapon_slot = read_byte(player + 0x2F2)	
		local weapon = get_object(read_dword(player + 0x2F8 + 4*weapon_slot))
		if weapon ~= nil then
			local meta_id = read_dword(weapon)
			if PUT_AWAY[meta_id] ~= nil then
				local chat_is_open = read_byte(0x0064E788)
				local input = read_byte(keyboard_input_address + key_put_away)
				local anim = read_word(fp_anim_address + 30)
				if input > 0 and chat_is_open == 0 and console_is_open() == false then
					if anim == PUT_AWAY[meta_id].idle then
						write_word(fp_anim_address + 30, PUT_AWAY[meta_id].putaway)
						write_word(fp_anim_address + 32, 0)
					end
				end
				
				if anim == PUT_AWAY[meta_id].putaway and read_word(fp_anim_address + 32) > PUT_AWAY[meta_id].frame then
					write_word(fp_anim_address + 32, PUT_AWAY[meta_id].frame) -- freeze the animation
				end
			end
		end
	end
end

function NightVisionToggle(player, enable)
	if nightvision_address then
		for weapon, tag_data in pairs (WEAPON_HUDS) do
			if enable then
				write_dword(tag_data + 0xAC, 1)
				write_dword(tag_data + 0xAC+4, nightvision_address)
			else
				write_dword(tag_data + 0xAC, 0)
				write_dword(tag_data + 0xAC+4, 0xFFFFFFFF)
			end
		end
		
		write_bit(player + 0x204, 26, enable)
		if enable then
			write_float(player + 0x348, 1)
		else
			write_float(player + 0x348, 0)
		end
	end
end

function NightVision()
	local player = get_dynamic_player()
	if player ~= nil then
		local flashlight_scale = read_float(player + 0x12C)
		local zoom_level = read_byte(player + 0x320)
	
		if flashlight_scale > 0 and zoom_level ~= 0xFF then
			if nightvision == false then
				NightVisionToggle(player, true)
			end
			nightvision = true
		elseif nightvision then
			NightVisionToggle(player, false)
			nightvision = false
		end
		
		if zoom_level ~= 0xFF then
			if nightvision then
				write_dword(flashlight_effect, nv_off_sound)
			else
				write_dword(flashlight_effect, nv_on_sound)
			end
		else
			write_dword(flashlight_effect, flashlight_sound)
		end
	elseif nightvision then
		NightVisionToggle(player, false)
		nightvision = false
	end
end

function RocketLockOn()
	local player = get_dynamic_player()
	if player ~= nil then
		local weapon_slot = read_byte(player + 0x2F2)	
		local weapon = get_object(read_dword(player + 0x2F8 + 4*weapon_slot))
		if weapon ~= nil and read_dword(weapon) == rl_tag then
			local id = 0
			local charge = read_byte(weapon + 0x261)
			
			--choose id
			if charge == 2 then
				id = 1
			elseif charge == 3 then
				if read_dword(0x400008CC) == 1 then
					id = 3
				else
					id = 2
				end
			end
			
			--set id
			local tag = get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\rocket launcher")
			if tag ~= nil then
				tag = read_dword(tag + 0x14)
				local reticle_address = read_dword(tag + 0x88)
				local reticle_overlay_address = read_dword(reticle_address + 0x38)
				write_word(reticle_overlay_address + 0x46, id)
				--console_out("id to set "..id)
			end
		end
	end
end

function CustomKeys(player)
	if custom_keys then
		local chat_is_open = read_byte(0x0064E788)
		if chat_is_open == 0 and console_is_open() == false then
			
			local vehicle = read_dword(player + 0x11C)
			
			if vehicle == 0xFFFFFFFF then
				local key_aa_pressed = read_byte(keyboard_input_address + key_aa)
				local key_sprint_pressed = read_byte(keyboard_input_address + key_sprint)
				local controller_aa_pressed = GetControllerInput(key_controller_aa)
				local controller_sprint_pressed = GetControllerInput(key_controller_sprint)
				key_aa_pressed = key_aa_pressed + controller_aa_pressed
				key_sprint_pressed = key_sprint_pressed + controller_sprint_pressed
				
				if controller_aa_pressed == 1 or controller_sprint_pressed == 1 then
					if hint_sent == nil then
						console_out("Use command /keys to change your controls!", 0, 1, 0)
						hint_sent = true
					end
				end
				
				if key_aa_pressed == 1 then
					if key_aa_timer == 0 then
						execute_script("rcon password activate_aa")
						key_aa_timer = key_spam_timer_aa
						return
					end
				end
				if key_sprint_pressed == 1 and started_sprinting == false then
					if key_sprint_timer == 0 then
						execute_script("rcon password start_sprinting")
						key_sprint_timer = key_spam_timer_sprint
						--console_out("start")
						return
					end
				end
				if started_sprinting and key_sprint_pressed == 0 then
					execute_script("rcon password stop_sprinting")
					started_sprinting = false
					--console_out("stop")
					return
				end
			end
		end
	end
end

function EmoteWheel()
	if custom_keys == false then return end
	
	local devcam = read_word(0x647498) == 30704
	local chat_is_closed = read_byte(0x0064E788) ~= 0
	local game_paused = read_byte(0x622058) == 0
	local player = get_dynamic_player()
	local vehicle = nil
	if player then vehicle = get_object(read_dword(player + 0x11C)) end
	local tag = get_tag("wphi", "taunts\\wheel_selection")
	local tag2 = get_tag("unhi", "taunts\\wheel_selection")
	local key_pressed_voice = read_byte(keyboard_input_address + key_voice)
	local key_pressed_emote = read_byte(keyboard_input_address + key_emote)
	local key_pressed_voice_controller = GetControllerInput(key_controller_voice)
	local key_pressed_emote_controller = GetControllerInput(key_controller_emote)
	key_pressed_voice = key_pressed_voice + key_pressed_voice_controller > 0
	key_pressed_emote = key_pressed_emote + key_pressed_emote_controller> 0
	local controller_right = GetControllerInput(36)
	local controller_down = GetControllerInput(34)
	
	local controller = false
	if key_pressed_voice_controller > 0 or key_pressed_emote_controller > 0 then
		controller = true
	end
	
	if chat_is_closed or game_paused or player == nil or GetName(player) == "characters\\floodcombat_human\\player\\flood player" or tag == nil or tag2 == nil or devcam or aspect_ratio_change == nil then
		key_pressed_voice = false
		key_pressed_emote = false
	end
	
	if key_pressed_voice then
		local child_obj = get_object(read_dword(player + 0x118))
		if child_obj and find(GetName(child_obj), "sprint") ~= nil then
			key_pressed_voice = false
		end
	end
	
	if vehicle ~= nil or emotes_enabled == false then
		key_pressed_emote = false
	end
	
	if player and (read_float(player + 0x278) ~= 0 or read_float(player + 0x27C) ~= 0) then
		key_pressed_emote = false
	end
	
	if key_voice_timer > 0 or voice_enabled == false or (vehicle ~= nil and GetName(vehicle) == armor_room_name) then
		key_pressed_voice = false
	end
	
	tag = read_dword(tag + 0x14)
	tag2 = read_dword(tag2 + 0x14)
	local overlay_address = read_dword(tag + 0x64) + 0x24
	
	if (key_pressed_emote or key_pressed_voice) then--and (controller == false or (choice == nil or choice == -1)) or controller_right ~= 0)) then
		if emote_wheel_on == nil then
			choice = -1
			PlaySound("forward")
			--execute_script("hud_show_crosshair 0")
			execute_script("player_camera_control 0")
			
			if key_pressed_emote then
				last_key = "emote"
			else
				last_key = "voice"
			end
			
			-- make things visible
			if controller == false then
				write_short(overlay_address + 180*4, cursor_offset_x) -- cursor
				write_short(overlay_address + 180*4+2, cursor_offset_y) -- cursor
				write_short(tag2 + 0x17C, cursor_offset_x) -- cursor
				write_short(tag2 + 0x17C+2, cursor_offset_y) -- cursor
			end
			write_short(overlay_address + 180, 0) -- wheel
			write_short(tag2 + 0x8C, 0) -- wheel
			write_short(tag2 + 0x24, 0) -- choices
			if last_key == "emote" then -- choices
				write_short(overlay_address + 180*2, 2)
			else
				write_short(overlay_address + 180*3, 0)
			end
		end
		emote_wheel_on = true
		
		execute_script("cinematic_screen_effect_start true")
		execute_script("cinematic_screen_effect_set_convolution 1 1 1.5 1 1")
		
		local x = ceil(read_long(mouse_input_address)*cursor_sensitivity*aspect_ratio_change)
		local y = ceil(read_long(mouse_input_address+4)*cursor_sensitivity)
		
		local cursor_x = 0
		local cursor_y = 0
		
		if controller then
			cursor_x = controller_right
			cursor_y = controller_down
		else
			cursor_x = read_short(overlay_address + 180*4) + x - cursor_offset_x
			cursor_y = read_short(overlay_address + 180*4 + 2) - y - cursor_offset_y
		end
		
		if controller == false then
			if cursor_x > 314 then
				cursor_x = 314
			elseif cursor_x < -314 then
				cursor_x = -314
			end
			if cursor_y > 230 then
				cursor_y = 230
			elseif cursor_y < -230 then
				cursor_y = -230
			end
		
			write_short(overlay_address + 180*4, cursor_x + cursor_offset_x)
			write_short(overlay_address + 180*4 + 2, cursor_y + cursor_offset_y)
			write_short(tag2 + 0x17C,  cursor_x + cursor_offset_x)
			write_short(tag2 + 0x17C+2, cursor_y + cursor_offset_y)
		end
		
		local dist = sqrt((cursor_x)*(cursor_x) + (cursor_y*aspect_ratio_change)*(cursor_y*aspect_ratio_change))
		
		local new_choice = -1
		
		if dist > 53 then
			local angle = 0
			if (cursor_x < 0) then
				angle = 270 - (math.atan(-cursor_y*aspect_ratio_change/-cursor_x) * 180/pi)
			else
				angle = 90 + (math.atan(-cursor_y*aspect_ratio_change/cursor_x) * 180/pi)
			end
			new_choice = floor((angle+18)/36)
			if new_choice == 10 then
				new_choice = 0
			end
		end
		if new_choice ~= choice then
			PlaySound("cursor")
		end
		choice = new_choice
		
		-- Highlight selection
		local x2 = 999
		local y2 = 999
		
		if choice > -1 then
			local angle2 = choice/5*pi
			x2 = floor(121*sin(angle2)*aspect_ratio_change)
			y2 = floor(121*cos(angle2))
		end
		
		
		
		write_short(overlay_address, x2)
		write_short(overlay_address + 2, y2)
		write_short(tag2 + 0xF4, x2)
		write_short(tag2 + 0xF6, y2)
		
		
	elseif emote_wheel_on ~= nil then
		emote_wheel_on = nil
		
		if choice ~= nil and choice ~= -1 and player then
			if last_key == "voice" then
				if choice == 0 and vehicle ~= nil and find(GetName(vehicle), "taunt") == nil then
					choice = 11
				end
				
				local gender = "male_"
				local name = GetName(player)
				if name == BIPEDS["female"] or name == BIPEDS["fmarine"] then
					gender = "female_"
				end
				
				execute_script("rcon password voice~"..gender..VOICE_LINES[choice])
				
				key_voice_timer = key_spam_timer_voice
			else
				execute_script("rcon password emote~"..choice)
			end
			choice = nil
		end
		
		execute_script("cinematic_screen_effect_stop")
		execute_script("player_camera_control 1")
		--execute_script("hud_show_crosshair 1")
		
		-- move things away from screen
		write_short(overlay_address, 999)
		write_short(overlay_address + 180, 999)
		write_short(overlay_address + 180*2, 999)
		write_short(overlay_address + 180*3, 999)
		write_short(overlay_address + 180*4, 999) -- cursor
		write_short(tag2 + 0x24, 999) -- cursor
		write_short(tag2 + 0x8C, 999) -- wheel
		write_short(tag2 + 0x17C, 999) -- choices
		write_short(tag2 + 0xF4, 999) -- choices
	end
end

function ObjectCleanup()
	if ticks%90 ~= 1 then return end
	
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	
	for i=0,object_count-1 do
		local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 and read_word(object + 0xB4) == 2 then
			local name = GetName(object)
			if find(name, "_preview") then
				local ID = read_word(first_object + i*12)*0x10000 + i
				local should_remove = true
				
				for i=0,15 do
					if (BACKPACK_WEAPONS[i][0].id==ID or BACKPACK_WEAPONS[i][1].id==ID or ARMOR_ABILITIES[i].id==ID)==false then
						should_remove = false
					end
				end
				
				if should_remove then
					delete_object(ID)
					console_out("Removing broken obj "..name, 1, 0, 0)
				end
			end
		end
	end
end

function BackpackWeapons()
	if use_backpack_weapons then
		for i=0,15 do
			
			if ARMOR_ABILITIES[i].timer ~= nil then
				ARMOR_ABILITIES[i].timer = ARMOR_ABILITIES[i].timer - 1
				if ARMOR_ABILITIES[i].timer < 0 then
					ARMOR_ABILITIES[i].timer = nil
				end
			end
			
			local player = get_dynamic_player(i)
			if player ~= nil and read_float(player + 0xE0) ~= 0 and read_float(player + 0x37C) == 0 and GetObjectDistanceFromCamera(player) < backpack_weapon_render_distance then
				local weapon_slot = read_byte(player + 0x2F2)
				
				local primary_weapon = get_object(read_dword(player + 0x2F8 + 4*weapon_slot))
				if primary_weapon ~= nil then
					local aa_type = read_word(primary_weapon + 0x240)
					if BACKPACK_AA_COLORS[aa_type] ~= nil then
						ARMOR_ABILITIES[i].aatype = aa_type
						ARMOR_ABILITIES[i].timer = 20
					elseif ARMOR_ABILITIES[i].timer == nil then
						ARMOR_ABILITIES[i].aatype = nil
					end
				end
				
				local weapon_slot2 = 0
				if weapon_slot == 1 then
					weapon_slot2 = 0
				else
					weapon_slot2 = 1
				end
				
				local secondary_weapon = {}
				for k=0,1 do
					if k ~= weapon_slot then
						secondary_weapon[k] = get_object(read_dword(player + 0x2F8 + 4*k))
					end
				end
				
				if secondary_weapon[0] ~= nil or secondary_weapon[1] ~= nil or use_backpack_aa then
					local camera = read_i16(0x647498)
					local x = read_float(player + 0x688 + 0x28)
					local y = read_float(player + 0x688 + 0x2C)
					local z = read_float(player + 0x688 + 0x30)
					local vehicle_id = read_dword(player + 0x11C)
					local x_vel = read_float(player + 0x68)
					local y_vel = read_float(player + 0x6C)
					local z_vel = read_float(player + 0x70)
					if vehicle_id ~= 0xFFFFFFFF then
						vehicle = get_object(vehicle_id)
						if vehicle ~= nil then
							x_vel = read_float(vehicle + 0x68)
							y_vel = read_float(vehicle + 0x6C)
							z_vel = read_float(vehicle + 0x70)
						end
					end
					
					local two_backpack_weapons = false
					
					local backpack_aa = nil
					if ARMOR_ABILITIES[i].id ~= nil then
						backpack_aa = get_object(ARMOR_ABILITIES[i].id)
					end
					
					if use_backpack_aa then
						if ARMOR_ABILITIES[i].aatype ~= nil then
							if backpack_aa == nil then
								ARMOR_ABILITIES[i].id = spawn_object("weap", aa_preview_tag, x, y, z)
							end
							
							--make aa ghosted in first person
							if backpack_aa ~= nil then
								if (local_player_index==nil or (local_player_index==i) and camera == 30400) == false then
									write_bit(backpack_aa + 0x10, 0, 0)
								elseif ARMOR_ABILITIES[i].id ~= nil then
									local backpack_aa = get_object(ARMOR_ABILITIES[i].id)
									write_bit(backpack_aa + 0x10, 0, 1)
								end
							end
						elseif ARMOR_ABILITIES[i].id ~= nil then
							if get_object(ARMOR_ABILITIES[i].id) ~= nil then
								delete_object(ARMOR_ABILITIES[i].id)
							end
							ARMOR_ABILITIES[i].id = nil
						end
					end
					--ClearConsole()
					for k=0,1 do
						local backpack_weapon = nil
						if secondary_weapon[k] ~= nil and k ~= weapon_slot then
							if BACKPACK_WEAPONS[i][k] == nil then
								BACKPACK_WEAPONS[i][k] = {}
							end
							
							local secondary_weapon_name = GetName(secondary_weapon[k])
							if BACKPACK_WEAPONS[i][k].id ~= nil then
								backpack_weapon = get_object(BACKPACK_WEAPONS[i][k].id)
							end
							
							if get_tag("weap", secondary_weapon_name.."_preview") ~= nil and ((local_player_index==nil or local_player_index==i) and camera == 30400) == false then
								if (secondary_weapon_name.."_preview" ~= BACKPACK_WEAPONS[i][k].name or backpack_weapon == nil) then
									if BACKPACK_WEAPONS[i][k].id ~= nil then
										local backpack_weapon = get_object(BACKPACK_WEAPONS[i][k].id)
										if backpack_weapon ~= nil then
											delete_object(BACKPACK_WEAPONS[i][k].id)
										end
										BACKPACK_WEAPONS[i][k].id = nil
									end
									BACKPACK_WEAPONS[i][k].id = spawn_object("weap", secondary_weapon_name.."_preview", x, y, z)
								end
							else
								if BACKPACK_WEAPONS[i][k].id ~= nil then
									local backpack_weapon = get_object(BACKPACK_WEAPONS[i][k].id)
									if backpack_weapon ~= nil then
										delete_object(BACKPACK_WEAPONS[i][k].id)
									end
									BACKPACK_WEAPONS[i][k].id = nil
								end
							end
						elseif BACKPACK_WEAPONS[i][k] ~= nil and BACKPACK_WEAPONS[i][k].id ~= nil then
							if get_object(BACKPACK_WEAPONS[i][k].id) ~= nil then
								delete_object(BACKPACK_WEAPONS[i][k].id)
							end
							BACKPACK_WEAPONS[i][k].id = nil
						end
					end
					
					if ARMOR_ABILITIES[i].id ~= nil then
						local backpack_aa = get_object(ARMOR_ABILITIES[i].id)
						if backpack_aa ~= nil then
							--Change color to match the aa type
							if BACKPACK_AA_COLORS[ARMOR_ABILITIES[i].aatype] ~= nil then
								write_float(backpack_aa + 0x134, BACKPACK_AA_COLORS[ARMOR_ABILITIES[i].aatype])
							end
							
							--make it not respawn
							write_dword(backpack_aa + 0x204, 0xF000000)
							
							--Disable shadows
							write_bit(backpack_aa + 0x10, 18, 1)
							
							write_float(backpack_aa + 0x68, 0.01)
							write_float(backpack_aa + 0x6C, 0)
							write_float(backpack_aa + 0x70, 0)
							
							write_float(backpack_aa + 0x5C, x)
							write_float(backpack_aa + 0x60, y)
							write_float(backpack_aa + 0x64, z)
							
							if ARMOR_ABILITIES[i].id ~= nil then
								address = player + 0x550
								
								local offset_from_x = -35
								local offset_from_y = 22.7
								local offset_from_z = 9999
								
								local x_offset = -(read_float(address + 0x4)/offset_from_x)
								local y_offset = -(read_float(address + 0x8)/offset_from_x)
								local z_offset = -(read_float(address + 0xC)/offset_from_x)
								local x_offset1 = -(read_float(address + 0x10)/offset_from_y)
								local y_offset1 = -(read_float(address + 0x14)/offset_from_y)
								local z_offset1 = -(read_float(address + 0x18)/offset_from_y)
								local x_offset2 = -(read_float(address + 0x1C)/offset_from_z)
								local y_offset2 = -(read_float(address + 0x20)/offset_from_z)
								local z_offset2 = -(read_float(address + 0x24)/offset_from_z)
								
								address2 = backpack_aa + 0x340
								CopyNodeInfo(address, address2, 0, x_offset + x_offset1 + x_offset2, y_offset + y_offset1 + y_offset2, z_offset + z_offset1 + z_offset2, 1, 1, 1)
								write_float(address2, 1)
							end
						end
					end
					
					for k=0,1 do
						if BACKPACK_WEAPONS[i][k].id ~= nil then
							local backpack_weapon = get_object(BACKPACK_WEAPONS[i][k].id)
							if backpack_weapon ~= nil then
								BACKPACK_WEAPONS[i][k].name = GetName(backpack_weapon)
				
								--Disable shadows
								write_bit(backpack_weapon + 0x10, 18, 1)
								write_float(backpack_weapon + 0xAC, 0.15)
								
								-- Set ammo for skins
								write_word(backpack_weapon + 0x2C4, read_word(secondary_weapon[k] + 0x2C4))
								
								--make it not respawn
								write_dword(backpack_weapon + 0x204, 0xF000000)
								
								write_float(backpack_weapon + 0x68, x_vel)
								write_float(backpack_weapon + 0x6C, y_vel)
								write_float(backpack_weapon + 0x70, z_vel)
								
								write_float(backpack_weapon + 0x5C, x)
								write_float(backpack_weapon + 0x60, y)
								write_float(backpack_weapon + 0x64, z)
								
								if BACKPACK_WEAPONS[i][k].name ~= nil and BACKPACK_WEAPONS_OFFSETS[BACKPACK_WEAPONS[i][k].name] ~= nil then
									local table = BACKPACK_WEAPONS_OFFSETS[BACKPACK_WEAPONS[i][k].name]
									address = player + table.node
									
									local offset_from_x = table.x
									local offset_from_y = table.y
									local offset_from_z = table.z
									local rot1 = table.rot1
									local rot2 = table.rot2
									local rot3 = table.rot3
									
									
									if k == 0 and BACKPACK_WEAPONS[i][1] ~= nil then
										if BACKPACK_WEAPONS[i][1].id ~= nil and BACKPACK_WEAPONS[i][1].name ~= nil and table.node == BACKPACK_WEAPONS_OFFSETS[BACKPACK_WEAPONS[i][1].name].node then
											if table.node == 0x688 then
												two_backpack_weapons = true
											end
											if table.node == 0x5B8 then
												address = player + 0x584
												if table.y == 25 then
													offset_from_z = 20
												end
											end
										end
									end
									
									if two_backpack_weapons then
										if k == 0 then
											offset_from_z = offset_from_z*0.35---15
										else
											rot2 = -rot2
											rot3 = -rot3
											offset_from_z = -offset_from_z*0.35--15	
										end
									end
									local x_offset = -(read_float(address + 0x4)/offset_from_x)
									local y_offset = -(read_float(address + 0x8)/offset_from_x)
									local z_offset = -(read_float(address + 0xC)/offset_from_x)
									local x_offset1 = -(read_float(address + 0x10)/offset_from_y)
									local y_offset1 = -(read_float(address + 0x14)/offset_from_y)
									local z_offset1 = -(read_float(address + 0x18)/offset_from_y)
									local x_offset2 = -(read_float(address + 0x1C)/offset_from_z)
									local y_offset2 = -(read_float(address + 0x20)/offset_from_z)
									local z_offset2 = -(read_float(address + 0x24)/offset_from_z)
									
									address2 = backpack_weapon + 0x340
									CopyNodeInfo(address, address2, 0, x_offset + x_offset1 + x_offset2, y_offset + y_offset1 + y_offset2, z_offset + z_offset1 + z_offset2, rot1, rot2, rot3)
									write_float(address2, 1)
								end
							end
						end
					end
				else
					for k=0,1 do
						if BACKPACK_WEAPONS[i][k].id ~= nil then
							if get_object(BACKPACK_WEAPONS[i][k].id) ~= nil then
								delete_object(BACKPACK_WEAPONS[i][k].id)
							end
							BACKPACK_WEAPONS[i][k].id = nil
						end
					end
				end
			else
				for k=0,1 do
					if BACKPACK_WEAPONS[i][k].id ~= nil then
						if get_object(BACKPACK_WEAPONS[i][k].id) ~= nil then
							delete_object(BACKPACK_WEAPONS[i][k].id)
						end
						BACKPACK_WEAPONS[i][k].id = nil
					end
				end
				if ARMOR_ABILITIES[i].id ~= nil then
					if get_object(ARMOR_ABILITIES[i].id) ~= nil then
						delete_object(ARMOR_ABILITIES[i].id)
					end
					ARMOR_ABILITIES[i].id = nil
					ARMOR_ABILITIES[i].aatype = nil
				end
			end
		end
	end
end

function CopyNodeInfo(address, address2, offset, x, y, z, rot1, rot2, rot3) -- copies node info from address to adddress2
	address = address + (offset or 0x0)
	address2 = address2 + (offset or 0x0)
	write_float(address2 + 0x0,read_float(address + 0x0))	--scale
	write_float(address2 + 0x4,read_float(address + 0x4)*rot1)	--rotations
	write_float(address2 + 0x8,read_float(address + 0x8)*rot1)
	write_float(address2 + 0xC,read_float(address + 0xC)*rot1)
	write_float(address2 + 0x10,read_float(address + 0x10)*rot2)
	write_float(address2 + 0x14,read_float(address + 0x14)*rot2)
	write_float(address2 + 0x18,read_float(address + 0x18)*rot2)
	write_float(address2 + 0x1C,read_float(address + 0x1C)*rot3)
	write_float(address2 + 0x20,read_float(address + 0x20)*rot3)
	write_float(address2 + 0x24,read_float(address + 0x24)*rot3)
	write_float(address2 + 0x28,read_float(address + 0x28) + x)	--x
	write_float(address2 + 0x2C,read_float(address + 0x2C) + y)	--y
	write_float(address2 + 0x30,read_float(address + 0x30) + z)	--z
end

function DynamicReticles()
	if use_new_dynamic_reticles and WEAPON_RETICLES ~= nil then
		local player = get_dynamic_player()
		if player ~= nil then
			local object = get_object(read_dword(player + 0x118))
			if object ~= nil and read_word(object + 0xB4) == 2 then
				local zoom = read_char(player + 0x320)+2
				if global_zoom ~= nil then
					if global_zoom ~= zoom then
						global_last_zoom = ticks
					end
				end
				global_zoom = zoom
				local zoom_scale = zoom
				if zoom == 2 then
					zoom_scale = zoom*0.85
				end
				local meta_id = read_dword(object)
				local weapon_hud = WEAPON_HUDS[meta_id]
				
				--	This extends the reticle when the weapon is unable to fire
				local ready_timer = read_word(object + 0x23A) + read_word(object + 0x2B2) + read_byte(player + 0x505)
				local grenade_state = read_byte(player + 0x28D)
				local grenade_anim_frame = read_byte(player + 0xD2)
				if grenade_state > 0 and grenade_anim_frame > 0 then
					ready_timer = ready_timer + 36 - grenade_anim_frame
				end
				if ready_timer > 15 then
					ready_timer = 15
				end
				
				if weapon_hud ~= nil then
					local reticle_address = read_dword(weapon_hud + 0x88)
					if WEAPON_RETICLES[meta_id] ~= nil then
						--console_out(read_float(object + 0x23C))
						--console_out("ERROR: "..read_float(object + 0x27C))
						--write_float(object + 0x27C, read_float(object + 0x23C)) -- bungo is dumbo
						local heat = read_float(object + 0x23C)*WEAPON_RETICLES[meta_id].additional + ready_timer/2
						
						for j=0,3 do
							local struct = reticle_address + j * 104
							write_byte(struct, 0)
							local reticle_overlay_address = read_dword(struct + 0x38)
							if j == 0 then
								write_short(reticle_overlay_address, floor((-WEAPON_RETICLES[meta_id].initial - heat)*aspect_ratio_change*zoom_scale))
							elseif j == 1 then
								write_short(reticle_overlay_address, ceil((WEAPON_RETICLES[meta_id].initial + heat)*aspect_ratio_change*zoom_scale))
							elseif j == 2 then
								write_short(reticle_overlay_address + 2, floor((-WEAPON_RETICLES[meta_id].initial - heat)*zoom_scale))
							else
								write_short(reticle_overlay_address + 2, ceil((WEAPON_RETICLES[meta_id].initial + heat)*zoom_scale))
							end
						end
					elseif meta_id == dmr_tag then
						
						local heat = read_float(object + 0x23C) + ready_timer/30
						for j=0,2 do
							local struct = reticle_address + j * 104
							write_byte(struct, 0)
							local reticle_overlay_address = read_dword(struct + 0x38)
							--change scale
							local scale = dmr_reticle_initial_scale + heat*dmr_reticle_additional_scale * zoom_scale
							write_float(reticle_overlay_address + 0x04, scale  *aspect_ratio_change )
							write_float(reticle_overlay_address + 0x08, scale)
							--change position
							local zoom_scale = zoom
							if zoom == 2 then
								zoom_scale = zoom*1.3
							end
							local position = heat*dmr_reticle_additional_pos * zoom_scale
							if j == 0 then
								write_short(reticle_overlay_address, floor(-position*aspect_ratio_change))
								write_short(reticle_overlay_address + 2, ceil(position))
							elseif j == 1 then
								write_short(reticle_overlay_address + 2, floor(-position))
							else
								write_short(reticle_overlay_address, ceil(position*aspect_ratio_change))
								write_short(reticle_overlay_address + 2, ceil(position))
							end
						end
					elseif meta_id == spartan_laser_tag then
						local charge = 0.07 + read_float(object + 0x124)*0.96*pi
						local x = 20 * sin(charge)*aspect_ratio_change
						local y = 20 * cos(charge)
						local reticle_overlay_address = read_dword(reticle_address + 0x38)
						write_short(reticle_overlay_address, floor(x))
						write_short(reticle_overlay_address+2, floor(y))
					end
					
					
					
					
					
					--	Animate weapon scopes
					if WEAPON_SCOPES[meta_id] ~= nil then
						local heat = read_float(object + 0x23C)^3
						
						if global_last_zoom ~= nil then
							local amount = ticks - global_last_zoom
							heat = heat - (amount - 7)*0.15*(4-zoom)
							--console_out(amount)
							
							--	Blur the screen when zooming
							if amount > 5 then
								if ticks > 150 then
									execute_script("cinematic_screen_effect_stop")
								end
								global_last_zoom = nil
							elseif amount == 0 and ticks > 150 then
								execute_script("cinematic_screen_effect_start true")
								execute_script("cinematic_screen_effect_set_convolution 10 2 4 0.001 0.23")
							end
						end
						--console_out(heat)
						
						for id,info in pairs (WEAPON_SCOPES[meta_id]) do
							if info.add == nil then
								local struct = reticle_address + id * 104
								info.add = read_dword(struct + 0x38)
							end
							local multiplier = heat * info.mult
							write_float(info.add + 0x04, (info[0] + multiplier))
							write_float(info.add + 0x08, info[1] + multiplier)
						end
					end
				end
			end
		end
	end
end

function SnowTrees()
	local current_tod = get_global("client_tod")
	if current_tod ~= previous_tod then
		for id,name in pairs (TREES) do
			local tag = read_dword(get_tag("scen", name) + 0x14) + 0x28
			local model_tag = nil
			if current_tod == 2 then
				model_tag = get_tag("mod2", name.."_snow")
			else
				model_tag = get_tag("mod2", name)
			end
			write_dword(tag + 0xC, read_dword(model_tag + 0xC))
		end
	end
	
	--Attempt to prevent people from manually changing the bsp
	if ticks%30 == 1 then
		local forge_is_on = false
		for k,v in pairs (SPAWNED_OBJECTS) do
			forge_is_on = true
			break
		end
		if forge_is_on == false then
			execute_script("switch_bsp "..current_tod)
		end
	end
	
	previous_tod = current_tod
end

function SetDroneColor(x, y, z, red, green, blue, object_type)-- maybe set team too??
	object_type = tonumber(object_type)
	local closest_object = FindClosestObject(x, y, z, object_type, 0)
	if closest_object ~= nil then
		local object = get_object(closest_object)
		if object ~= nil then
			write_float(object + 0x1B8, tonumber(red))
			write_float(object + 0x1BC, tonumber(green))
			write_float(object + 0x1C0, tonumber(blue))
		end
	end
end	

function BinocularHighlights()
	if binoculars_highlights then
		local binoculars_zoomed_in = false
		
		local player = get_dynamic_player()
		if player ~= nil then
			local player_weapon_id = read_dword(player + 0x118)
			local player_weapon = get_object(player_weapon_id)
			if player_weapon ~= nil and read_word(player_weapon + 0xB4) == 2 then
				local meta_id = read_dword(player_weapon)
				if meta_id == binoculars_tag then
					local desired_zoom_level = read_u8(player + 0x321)
					if desired_zoom_level ~= 0xFF then
						binoculars_zoomed_in = true
					end
				end
			end
		end
		
		for key, biped_name in pairs (BIPEDS) do
			local biped_tag = get_tag("bipd", biped_name)
			if biped_tag == nil then
				return
			end
			local biped_data = read_dword(biped_tag + 0x14)
			if biped_data == nil then
				return
			end
			local reflexive_address = read_dword(biped_data + 0x144)
			if binoculars_zoomed_in and read_i16(0x647498) == 30400 then
				 write_string8(reflexive_address + 0x10, "")
			else
				write_string8(reflexive_address + 0x10, "test")
			end
		end
	end
end

function HologramsAndRefractions()
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	--console_out(camera_x)
	--console_out(camera_y)
	--console_out(camera_z)
	
	-- Find where player is and decide if shadows need fixing
	local fix_shadows = false
	for name,info in pairs (SHADOW_FIX_LOCATIONS) do
		if camera_z < info.height then
			local x_dist = info.x - camera_x
			local y_dist = info.y - camera_y
			local z_dist = info.z - camera_z
			local distance =  sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
			if distance < info.dist then
				--console_out(distance)
				fix_shadows = name
				break
			end
		end
	end
	
	for i=0,object_count-1 do
		local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 then
			local object_type = read_word(object + 0xB4)
			if object_type == 1 then
				local meta_id = read_dword(object)
				if meta_id == hologram_tag_red or meta_id == hologram_tag_blue then
					local ID = read_word(first_object + i*12)*0x10000 + i
					if HOLOGRAMS[ID] == nil then
						local x = read_float(object + 0x5C)
						local y = read_float(object + 0x60)
						local z = read_float(object + 0x64)
						local closest_player = -1
						local closest_distance = 3
						for j = 0,15 do
							local player = get_dynamic_player(j)
							if player ~= nil then
								local distance = GetDistance(object, player)
								if distance < closest_distance then
									closest_player = j
									closest_distance = distance
								end
							end
						end
						if closest_player ~= nil then
							local player = get_dynamic_player(closest_player)
							if player ~= nil then
								HOLOGRAMS[ID] = {}
								HOLOGRAMS[ID].r = read_float(player + 0x1D0)
								HOLOGRAMS[ID].g = read_float(player + 0x1D4)
								HOLOGRAMS[ID].b = read_float(player + 0x1D8)
								HOLOGRAMS[ID].x = x
								HOLOGRAMS[ID].y = y
								HOLOGRAMS[ID].z = z
								HOLOGRAMS[ID].moving = true
								write_float(object + 0x1D0, HOLOGRAMS[ID].r)
								write_float(object + 0x1D4, HOLOGRAMS[ID].g)
								write_float(object + 0x1D8, HOLOGRAMS[ID].b)
							end
						end
					end
					
				elseif (meta_id == hologram_tag_red_idle or meta_id == hologram_tag_blue_idle) then
					local ID = read_word(first_object + i*12)*0x10000 + i
					if HOLOGRAMS[ID] == nil then
						local x = read_float(object + 0x5C)
						local y = read_float(object + 0x60)
						local z = read_float(object + 0x64)
						local closest_hologram_ID = -1
						local closest_distance = 3
						for ID2, info in pairs (HOLOGRAMS) do
							if info.moving then
								local x_dist = info.x - x
								local y_dist = info.y - y
								local z_dist = info.z - z
								local distance = sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
								if distance < closest_distance then
									closest_hologram_ID = ID2
									closest_distance = distance
								end
							end
						end
						if closest_hologram_ID ~= -1 then
							write_float(object + 0x1D0, HOLOGRAMS[closest_hologram_ID].r)
							write_float(object + 0x1D4, HOLOGRAMS[closest_hologram_ID].g)
							write_float(object + 0x1D8, HOLOGRAMS[closest_hologram_ID].b)
							HOLOGRAMS[ID] = {}
							HOLOGRAMS[ID].moving = false
						end
					end
					
					
				elseif use_refractions and shockwave_tag ~= nil then
					if meta_id == shockwave_tag then
						local shockwave_scale = read_float(object + 0xB0)
						shockwave_scale = shockwave_scale + shockwave_increase_size_rate
						if shockwave_scale > shockwave_max_scale then
							delete_object(read_word(first_object + i*12)*0x10000 + i)
						else
							local x = read_float(object + 0x5C)
							local y = read_float(object + 0x60)
							local z = read_float(object + 0x64)
							local x_dist = (camera_x - x)
							local y_dist = (camera_y - y)
							local z_dist = (camera_z - z)
							local distance = sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
							local rot_x = x_dist / distance
							local rot_y = y_dist / distance
							local rot_z = z_dist / distance
							write_float(object + 0x74, rot_x)
							write_float(object + 0x78, rot_y)
							write_float(object + 0x7C, rot_z*2)
							write_float(object + 0x80, 0)
							write_float(object + 0x84, 0)
							write_float(object + 0x88, 1)
							
							local camo_intensity = (1 - shockwave_scale / shockwave_max_scale)*refraction_amount*distance/8
							write_float(object + 0xB0, shockwave_scale)
							write_float(object + 0x37C, camo_intensity)
						end
						
					-- BUBBLE SHIELD
					elseif meta_id == bubble_shield_tag then
						local timer = read_float(object + 0xE0)
						local x = read_float(object + 0x5C)
						local y = read_float(object + 0x60)
						local z = read_float(object + 0x64)
						local x_dist = (camera_x - x)
						local y_dist = (camera_y - y)
						local z_dist = (camera_z - z)
						local distance = sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
						local camo_intensity = bubble_shield_refraction_amount * distance
						if distance < bubble_shield_min_distance then
							camo_intensity = bubble_shield_min_refraction
						end
						write_float(object + 0x37C, camo_intensity)
						if timer > 0.001 * (bubble_shield_lifetime - 10) then
							write_float(object + 0xB0, (bubble_shield_lifetime - timer * 1000)*0.1 + 0.1)
						else
							write_float(object + 0xB0, bubble_shield_scale)
						end
						if timer == 1 then
							timer = 0
						elseif timer > 0.001 * bubble_shield_lifetime then
							delete_object(read_word(first_object + i*12)*0x10000 + i)
						else
							write_float(object + 0xE0, timer + 0.001)
						end
					end
					
				end
			
			-- SHADOWS IN BASES FIX
			write_bit(object + 0x10, 18, 0)
			if fix_shadows then
				local x = read_float(object + 0x5C)
				local y = read_float(object + 0x60)
				local z = read_float(object + 0x64)
				if SHADOW_FIX_LOCATIONS[fix_shadows].height < z then
					local x_dist = SHADOW_FIX_LOCATIONS[fix_shadows].x - x
					local y_dist = SHADOW_FIX_LOCATIONS[fix_shadows].y - y
					local z_dist = SHADOW_FIX_LOCATIONS[fix_shadows].z - z
					local distance =  sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
					if distance < (SHADOW_FIX_LOCATIONS[fix_shadows].dist + 2) then
						--console_out(GetName(object).." "..distance.." "..z)
						write_bit(object + 0x10, 18, 1)
					end
				elseif SHADOW_FIX_LOCATIONS[fix_shadows].height_truck > camera_z and SHADOW_FIX_LOCATIONS[fix_shadows].height_truck < z and SHADOW_FIX_LOCATIONS[fix_shadows].y_truck > abs(y) then
					local x_dist = SHADOW_FIX_LOCATIONS[fix_shadows].x - x
					local y_dist = SHADOW_FIX_LOCATIONS[fix_shadows].y - y
					local z_dist = SHADOW_FIX_LOCATIONS[fix_shadows].z - z
					local distance =  sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
					if distance < (SHADOW_FIX_LOCATIONS[fix_shadows].dist) then
						--console_out(GetName(object).." "..distance.." "..z)
						write_bit(object + 0x10, 18, 1)
					end
				end
			end
			
			-- FLOOD GRENADE ROTATION FIX
			elseif object_type == 5 and read_dword(object) == flood_grenade_id and read_dword(object+0x11C)==0xFFFFFFFF then
				write_float(object+0x80,0)
				write_float(object+0x84,0)
				write_float(object+0x88,1)
			end
		end
	end
	
	for ID,info in pairs (HOLOGRAMS) do 
		local object = get_object(ID)
		if object == nil then
			HOLOGRAMS[ID] = nil
		else
			HOLOGRAMS[ID].x = read_float(object + 0x5C)
			HOLOGRAMS[ID].y = read_float(object + 0x60)
			HOLOGRAMS[ID].z = read_float(object + 0x64)
		end
	end
end

function TripMines()
	if fix_double_mines and frames == 0 then
		local object_count = read_word(object_table + 0x2E)
		local first_object = read_dword(object_table + 0x34)
		local first_mine
		local x, y, z
		
		for i=0,object_count-1 do
			local ID = read_word(first_object + i*12)*0x10000 + i
			local object = read_dword(first_object + i * 0xC + 0x8)
			if object ~= 0 and read_word(object + 0xB4) == 6 and MINES[ID] == nil then
				local MetaID = read_dword(object)
				if MetaID == mine_tag_red or MetaID == mine_tag_blue or MetaID == mine_tag_default then
					if first_mine == nil then
						first_mine = object
						x = read_float(object + 0x5C)
						y = read_float(object + 0x60)
						z = read_float(object + 0x64)
						MINES[ID] = false
					else
						-- find distance between the first mine that was just spawned and the second
						local x1 = read_float(object + 0x5C)
						local y1 = read_float(object + 0x60)
						local z1 = read_float(object + 0x64)
						local x_dist = x1 - x
						local y_dist = y1 - y
						local z_dist = z1 - z
						local distance = sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
						if distance < 0.06 then
							first_mine = nil
							--console_out("duplicate mine found! distance: "..distance)
							delete_object(ID)
						else
							--console_out("mine found... but not duplicate. distance: "..distance)
							MINES[ID] = false
						end
					end
				end
			end
		end
		
		local mine_count = 0
		for ID,info in pairs (MINES) do
			if get_object(ID) == nil then
				MINES[ID] = nil
			end
			mine_count = mine_count + 1
		end
		--console_out("number of mines: "..mine_count)
	end
end

function DynamicShadows()
	if use_dynamic_shadows then -- need to disable on night mode for better performance
		local player = get_dynamic_player()
		if player ~= nil then
			local x = read_float(player + 0x5C)
			local y = read_float(player + 0x60)
			local z = read_float(player + 0x64)
			
			local vehicle = read_dword(player + 0x11C)
			if vehicle ~= nil and vehicle ~= 0xFFFFFFFF then
				vehicle = get_object(vehicle)
				if vehicle ~= nil then
					x = read_float(vehicle + 0x5C)
					y = read_float(vehicle + 0x60)
					z = read_float(vehicle + 0x64)
				end
			end
			
			local object_count = read_word(object_table + 0x2E)
			local first_object = read_dword(object_table + 0x34)
			
			for i=0,object_count-1 do
				local ID = read_word(first_object + i*12)*0x10000 + i
				local object = read_dword(first_object + i * 0xC + 0x8)
				if object ~= 0 then
					local object_type = read_word(object + 0xB4)
					local x1 = read_float(object + 0x5C)
					local y1 = read_float(object + 0x60)
					local z1 = read_float(object + 0x64)
					if x1 ~= nil then
						local x_dist = x1 - x
						local y_dist = y1 - y
						local z_dist = z1 - z
						local distance = sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
						if object_type == 6 then
							if scenery_shadows then
								if distance < scenery_shadow_render_distance and read_float(object + 0xAC) < max_scenery_radius then
									write_bit(object + 0x10, 18, 0)
								else
									write_bit(object + 0x10, 18, 1)
								end
							else
								write_bit(object + 0x10, 18, 1)
							end
						elseif object_type == 0 or object_type == 1 then
							if distance < unit_shadow_render_distance then
								write_bit(object + 0x10, 18, 0)
							else
								write_bit(object + 0x10, 18, 1)
							end
						else
							if distance < shadow_render_distance then
								write_bit(object + 0x10, 18, 0)
							else
								write_bit(object + 0x10, 18, 1)
							end
						end
					end
				end
			end
		end
	end
end

function ForgeShadowDirection(yaw, pitch)
	if use_dynamic_shadow_direction_for_forge and forge_shadow_update_timer == 0 then
		--console_out("started")
		forge_shadow_update_timer = 110
		local sun_x, sun_y, sun_z = Get3DVectorFromAngles(yaw,pitch)
		-- I need to change this to the current bsp!
		local bsp = get_tag("sbsp", "altis\\levels\\bigass\\bigass")
		if bsp ~= nil then
			bsp = read_dword(bsp + 0x14)
			local lightmap_address = read_dword(bsp + 0x104 + 4)
			-- lightmap with bigass terrain is 18
			local struct = lightmap_address + 18*32
			local material_address = read_dword(struct + 0x14 + 4)
			-- terrain material is 0
			local struct = material_address + 0*256
			local uncompressed_vertices = read_dword(struct + 0xE4)
			local lightmap_vertices = read_dword(struct + 0xC8)
			local lightmap_vertex_address = uncompressed_vertices + 0x38 * lightmap_vertices
			ForgeApplyShadowDirection(sun_x, sun_y, sun_z, lightmap_vertices, lightmap_vertex_address, 0)
		end
	end
end

function ForgeApplyShadowDirection(sun_x, sun_y, sun_z, lightmap_vertices, lightmap_vertex_address, last_vertex_id)
	local sun_x = tonumber(sun_x)
	local sun_y = tonumber(sun_y)
	local sun_z = tonumber(sun_z)
	local lightmap_vertices = tonumber(lightmap_vertices)
	local lightmap_vertex_address = tonumber(lightmap_vertex_address)
	local last_vertex_id = tonumber(last_vertex_id)
	local vertex_counter = 0
	
	for k=last_vertex_id,lightmap_vertices - 1 do
		vertex_counter = vertex_counter + 1
		if vertex_counter < 100 then
			local lightmap_vertex = lightmap_vertex_address + k * 0x14
			write_float(lightmap_vertex, sun_x)
			write_float(lightmap_vertex + 4, sun_y)
			--write_float(lightmap_vertex + 8, sun_z) -- changing z seems to just make objects and shadows darker
		else
			set_timer(33, "ForgeApplyShadowDirection", sun_x, sun_y, sun_z, lightmap_vertices, lightmap_vertex_address, k)
			return false
		end
	end
	--console_out("finished")
	return false
end

function ForgeMachines()
	for ID,info in pairs (SPAWNED_OBJECTS) do
		if info.type == 7 then
			local object = get_object(ID)
			if object ~= nil then
				local x = read_float(object + 0x5C)
				local y = read_float(object + 0x60)
				local z = read_float(object + 0x64)
				
				-- gravlifts and mancannons
				if info.name == "forge\\halo4\\scenery\\gravlift\\gravlift" or info.name == "forge\\halo4\\scenery\\mancannon\\mancannon" then
					local object_count = read_word(object_table + 0x2E)
					local first_object = read_dword(object_table + 0x34)
					for i=0,object_count-1 do
						local ID = read_word(first_object + i*12)*0x10000 + i
						local object2 = read_dword(first_object + i * 0xC + 0x8)
						if object2 ~= 0 then
							local object_type = read_word(object2 + 0xB4)
							if object_type == 1 or object_type == 2 or object_type == 5 or object_type == 0 then
								local x1 = read_float(object2 + 0x5C)
								local y1 = read_float(object2 + 0x60)
								local z1 = read_float(object2 + 0x64)
								local x_dist = x1 - x
								local y_dist = y1 - y
								local z_dist = z1 - z
								local distance = sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
								if distance < 0.65 then
									local push_amount = 0.2
									if info.permutation ~= 0 then
										push_amount = 0.07 + 0.03 * info.permutation
									end
									local rot = convert(info.rot1, info.rot2, info.rot3)
									if object_type == 5 then
										write_float(object2 + 0x68, rot[1]*push_amount*0.15 + read_float(object2 + 0x68))
										write_float(object2 + 0x6C, rot[2]*push_amount*0.15 + read_float(object2 + 0x6C))
										write_float(object2 + 0x70, rot[3]*push_amount*0.15 + read_float(object2 + 0x70))
									else
										write_float(object2 + 0x68, rot[1]*push_amount)
										write_float(object2 + 0x6C, rot[2]*push_amount)
										write_float(object2 + 0x70, rot[3]*push_amount)
									end
								end
							end
						end
					end
				else
					-- other devices
					local should_open = false
					local elevator = read_dword(object + 0x21C)
					local machine_power = read_float(object + 0x208)
					for i=0,15 do
						local player = get_dynamic_player(i)
						if player ~= nil then
							local x1 = read_float(player + 0x5C)
							local y1 = read_float(player + 0x60)
							local z1 = read_float(player + 0x64)
							local x_dist = x1 - x
							local y_dist = y1 - y
							local z_dist = z1 - z
							local distance
							if elevator == 0 then
								distance = GetDistance(object, player)
							else
								distance = sqrt(x_dist*x_dist + y_dist*y_dist)
							end
							if (distance < 2.7 and elevator == 0) or (distance < 0.65 and elevator ~= 0) then
								should_open = true
							end
						end
					end
					
					if should_open then
						if machine_power < 0.98 then
							if elevator == 0 then
								write_float(object + 0x208, machine_power + 0.02)
							else
								write_float(object + 0x208, machine_power + 0.003)
							end
							write_float(object + 0x20C, 1)
						else
							write_float(object + 0x20C, 0)
						end
					elseif machine_power > 0 then
						if elevator == 0 then
							write_float(object + 0x208, machine_power - 0.01)
						else
							write_float(object + 0x208, machine_power - 0.005)
						end
						write_float(object + 0x20C, 1)
					else
						write_float(object + 0x20C, 0)
					end
				end
			end
		end
	end
end

function ForgeShadows()
	for ID,info in pairs (SPAWNED_OBJECTS) do
		if info.shadow then
			local object = get_object(ID)
			if object ~= nil then
				if GetObjectDistanceFromCamera(object) > 40 then
					write_bit(object + 0x10, 18, 1)
				else
					write_bit(object + 0x10, 18, 0)
				end
			end
		end
	end
end

function ForgeScreenTint()
	if screen_tint ~= nil then
		for i=0,15 do
			execute_script("(effect_new_on_object_marker screen_tint (unit (list_get (players) ".. i ..")) \"\")")
			--execute_script("(damage_object  screen_tint_dmg (unit (list_get (players) ".. i .."))")
		end
	end
end

function SceneryRemovalOnDistance()
	if remove_scenery_on_distance and ticks > 30 then
		for current_y, info in pairs (SCENERY_OBJECTS) do
			for current_x, info2 in pairs (SCENERY_OBJECTS[current_y]) do
				if destroy_all_scenery then
					for i, info3 in pairs (SCENERY_OBJECTS[current_y][current_x].objects) do
						execute_script("object_destroy "..info3)
					end
				else
					local distance = sqrt((current_x - camera_x)*(current_x - camera_x) + (current_y - camera_y)*(current_y - camera_y))
					if distance < remove_scenery_distance then
						if SCENERY_OBJECTS[current_y][current_x].visible == false then
							for i, info3 in pairs (SCENERY_OBJECTS[current_y][current_x].objects) do
								execute_script("object_create "..info3)
							end
							SCENERY_OBJECTS[current_y][current_x].visible = true
						end
					elseif SCENERY_OBJECTS[current_y][current_x].visible == true then
						for i, info3 in pairs (SCENERY_OBJECTS[current_y][current_x].objects) do
							execute_script("object_destroy "..info3)
						end
						SCENERY_OBJECTS[current_y][current_x].visible = false
					end
				end
			end
		end
	end
end

function FPHandSwitch()
	if switch_fp_hands then
		local object = get_dynamic_player()
		if object ~= nil then
			local name = GetName(object)
			local fp_hands = read_dword(globals_tag + 0x17C + 4)
			
			if fp_hands_default_id == nil then
				fp_hands_default_id = read_dword(fp_hands + 0xC)
				fp_hands_default_class = read_dword(fp_hands)
				local fp_hands_new = get_tag("mod2", fp_hands_new_name)
				fp_hands_new_id = read_dword(fp_hands_new + 0xC)
				fp_hands_new_class = read_dword(fp_hands_new)
			end
			
			if name == new_biped_name or name == new_biped_name_alt then
				write_u32(fp_hands, fp_hands_new_class)
				write_u32(fp_hands + 0xC, fp_hands_new_id)
			else
				write_u32(fp_hands, fp_hands_default_class)
				write_u32(fp_hands + 0xC, fp_hands_default_id)
			end
		end
	end
end

function Flashlight()
	for i=0,15 do
		local player = get_dynamic_player(i)
		if player ~= nil then
			local flashlight_scale = read_bit(player + 0x204, 19)
			if flashlight_scale == 1 then
				write_float(player + 0x340, 1)
			else
				write_float(player + 0x340, 0)
			end
		end
	end
end

function AltIdleAnims()
	if use_alt_idle_anims then
		for i=0,15 do
			local player = get_dynamic_player(i)
			if player ~= nil then
				local current_base_anim = read_word(player + 0xD0)
				if read_float(player + 0x284) ~= 0 and ALT_ANIMS[current_base_anim] ~= nil then
					write_word(player + 0xD0, 168)
				elseif current_base_anim == 168 or ALT_ANIMS[current_base_anim] ~= nil then
					if read_word(player + 0xD2) == 0 then
						local random_animation = rand(1,6)
						for key,value in pairs (ALT_ANIMS) do
							if value == random_animation then
								write_word(player + 0xD0, key)
							end
						end
					end
				end
			end
		end
	end
end

function ReadyAnims()
	if use_ready_anims then
		for i=0,15 do
			local player = get_dynamic_player(i)
			if player ~= nil then
				local weapon_slot = read_byte(player + 0x2F4)
				local weapon_id = read_dword(player + 0x2F8 + weapon_slot * 4)
				local object = get_object(weapon_id)
				if object ~= nil then 
					local meta_id = read_dword(object)
					if (PLAYER_WEAPONS[i] ~= nil and (PLAYER_WEAPONS[i] ~= meta_id or PLAYER_WEAPONS[i] == -1)) or PLAYER_WEAPONS[i] == nil then
						if WEAPON_READY_ANIMS[meta_id] ~= nil then
							PlayReplacementAnimation(player,WEAPON_READY_ANIMS[meta_id])
						end
					end
					PLAYER_WEAPONS[i] = meta_id
				end
			else
				PLAYER_WEAPONS[i] = -1
			end
		end
	end
end

function PlayReplacementAnimation(player, anim_id)
	write_word(player + 0x2AC, 999)	--resets the animation in case it was already playing
	write_word(player + 0x2AA, anim_id)--changes the animation that is playing
	write_word(player + 0x2A4, 5)	--removes left hand from the weapon
	write_word(player + 0xD4, 5)	--makes animation switch instantly
end

function AssAnimFix()
	for i=0,15 do
		local player = get_dynamic_player(i)
		if player then
			local current_base_animation = read_word(player + 0xD0)
			if current_base_animation == 294 or current_base_animation == 295 then
				write_word(player + 0x2AA, 0x100)
			end
		end
	end
end

function Forgeball()
	if forkball then
		for i=0,15 do
			local player = get_dynamic_player(i)
			if player ~= nil then
				local vehicle = get_object(read_dword(player + 0x11C))
				if vehicle ~= nil then
					write_float(vehicle + 0x1D0, read_float(player + 0x1D0))
					write_float(vehicle + 0x1D4, read_float(player + 0x1D4))
					write_float(vehicle + 0x1D8, read_float(player + 0x1D8))
					write_float(vehicle + 0x1B8, read_float(player + 0x1D0) + 0.25)
					write_float(vehicle + 0x1BC, read_float(player + 0x1D4) + 0.25)
					write_float(vehicle + 0x1C0, read_float(player + 0x1D8) + 0.25)
				end
			end
		end
		
		if player ~= nil then
			local vehicle = get_object(read_dword(player + 0x11C))
			if vehicle ~= nil and GetName(vehicle) == "altis\\vehicles\\forklift\\forklift" then
				
				if read_bit(player + 0x208, 4) > 0 then
					local tag = read_dword(get_tag("vehi", "altis\\vehicles\\forklift\\forklift") + 0x14)
					local reflexive_address = read_dword(tag + 0x2E4 + 4)
					if read_bit(reflexive_address, 4) == 1 then
						write_bit(reflexive_address, 4, 0)
						write_string8(reflexive_address + 0x84, "camera driver")
						write_float(reflexive_address + 0xF0, -1.5708)
						write_float(reflexive_address + 0xF4, 1.5708)
						--console_out("First person camera enabled. Enter the vehicle again!")
					else
						write_bit(reflexive_address, 4, 1)
						write_string8(reflexive_address + 0x84, "")
						write_float(reflexive_address + 0xF0, 0)
						write_float(reflexive_address + 0xF4, 0)
						--console_out("Third person camera enabled. Enter the vehicle again!")
					end
				end
			end
		end
	end
end

function Taco()
	if taco then
		local player = get_dynamic_player()
		if player ~= nil then
			local x = read_float(player + 0x7C0 + 0x28)
			local y = read_float(player + 0x7C0 + 0x2C)
			local z = read_float(player + 0x7C0 + 0x30)
			local x_vel = read_float(player + 0x68)
			local y_vel = read_float(player + 0x6C)
			local z_vel = read_float(player + 0x70)
			local x_rot = read_float(player + 0x224)
			local y_rot = read_float(player + 0x228)
			if mexican == nil then
				mexican = spawn_object("scen", "characters\\cyborg_new\\mexican", x, y, z)
			end
			
			local vehicle = read_dword(player + 0x11C)
			if vehicle ~= nil and vehicle ~= 0xFFFFFFFF then
				vehicle = get_object(vehicle)
				if vehicle ~= nil then
					x_vel = read_float(vehicle + 0x68)
					y_vel = read_float(vehicle + 0x6C)
					z_vel = read_float(vehicle + 0x70)
				end
			end
			
			if read_i16(0x647498) == 30400 then
				z = z + 0.09
			end
			
			local mexican_object = get_object(mexican)
			if mexican_object ~= nil then
				write_float(mexican_object + 0x5C, x + x_vel)
				write_float(mexican_object + 0x60, y + y_vel)
				write_float(mexican_object + 0x64, z + z_vel)
				write_float(mexican_object + 0x74, x_rot)
				write_float(mexican_object + 0x78, y_rot)
			end
		elseif mexican ~= nil then
			local mexican_object = get_object(mexican)
			if mexican_object ~= nil then
				write_float(mexican_object + 0x64, -100)
			end
		end
	end
end

function CubemapSwitching()
	if use_cubemap_switching then
		local wanted_tag = get_tag("bitm", TOD[get_global("client_tod")])
		
		for id, cubemap_info in pairs (CUBEMAP_LOCATIONS) do
			local x_dist = cubemap_info.x - camera_x
			local y_dist = cubemap_info.y - camera_y
			local z_dist = cubemap_info.z - camera_z
			local distance =  sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
			if distance < cubemap_info.radius then
				wanted_tag = get_tag("bitm", cubemap_info.name)
			end
		end
		
		for shader, class in pairs (SHADERS_TO_SWITCH) do
			local tag1 = get_tag(class, shader)
			if tag1 == nil then
				console_out("MISSING CUBEMAP "..shader)
				break
			end
			local tag = read_dword(tag1 + 0x14)
			if class == "soso" then
				write_dword(tag + 0x164,read_dword(wanted_tag))
				write_dword(tag + 0x164 + 0xC,read_dword(wanted_tag + 0xC))
			elseif class == "schi" or class == "scex" then
				write_dword(read_dword(tag + 0x58) + 0x6C, read_dword(wanted_tag))
				write_dword(read_dword(tag + 0x58) + 0x6C + 0xC, read_dword(wanted_tag + 0xC))
			elseif class == "sgla" then
				write_dword(tag + 0xAC,read_dword(wanted_tag))
				write_dword(tag + 0xAC + 0xC,read_dword(wanted_tag + 0xC))
			end
		end
	end
end

function SpartanLaserCharge()
	for i=0,15 do
		local player = get_dynamic_player(i)
		if player then
			local object = get_object(read_dword(player + 0x118))
			if object and read_dword(object) == spartan_laser_tag and read_float(object + 0x124) > 0 then
				local crouch = read_float(player + 0x50C)
				local camera_height = 0.62 - (crouch * (0.62 - 0.52))
				local player_x_vel = read_float(player + 0x68)
				local player_y_vel = read_float(player + 0x6C)
				local player_z_vel = read_float(player + 0x70)
				local aim_x = read_float(player + 0x230)
				local aim_y = read_float(player + 0x234)
				local aim_z = read_float(player + 0x238)
				local x = read_float(player + 0xA0) + aim_y*0.01
				local y = read_float(player + 0xA4) - aim_x*0.01
				local z = read_float(player + 0xA8) + camera_height - 0.37
				--local x =  read_float(object + 0x340 + 0x28) --- aim_x*0.1
				--local y = read_float(object + 0x344 + 0x28) --- aim_y*0.1
				--local z = read_float(object + 0x348 + 0x28)+0.077
				
				local offset_amount = 0.33
				local projectile = spawn_object("proj", "altis\\effects\\spartan_laser", x + player_x_vel +  aim_x*offset_amount, y + player_y_vel + aim_y*offset_amount, z + player_z_vel + aim_z*offset_amount)
				local object = get_object(projectile)
				if object ~= nil then
					local projectile_velocity = 55
					write_float(object + 0x68, aim_x * projectile_velocity)
					write_float(object + 0x6C, aim_y * projectile_velocity)
					write_float(object + 0x70, aim_z * projectile_velocity)
				end
			end
		end
	end
end

function ChimeraSafeZonesFix()
	if safe_zones_fixed then return end
	local tag = get_tag("unhi", "bourrin\\hud\\h1 symmetrical")
	if tag ~= nil then
		tag = read_dword(tag + 0x14)
		
		if read_short(tag + 0x8E) == -175 then
			write_short(tag + 0x17E, read_short(tag + 0x17E) + 25)
			write_short(tag + 0x1E6, read_short(tag + 0x1E6) + 25)
			safe_zones_fixed = true
			
			local TAGS = {
				get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\sprint"),
				get_tag("wphi", "halo reach\\objects\\vehicles\\human\\civilian\\military_truck\\health meter"),
				get_tag("wphi", "sceny\\ui\\hud\\vehicles\\falcon"),
				get_tag("wphi", "sceny\\ui\\hud\\cyborg\\vehicles\\scorpion"),
			}
			
			for j=1,4 do
				tag = TAGS[j]
				if tag ~= nil then
					tag = read_dword(tag + 0x14)
					local static_count = read_dword(tag + 0x60)
					local static_address  =read_dword(tag + 0x64)
					for i=0,static_count-1 do
						local y_address = static_address + i*180 + 0x26
						write_short(y_address, read_short(y_address) + 25)
					end
					local meter_count = read_dword(tag + 0x6C)
					local meter_address  =read_dword(tag + 0x70)
					for i=0,meter_count-1 do
						local y_address = meter_address + i*180 + 0x26
						write_short(y_address, read_short(y_address) + 25)
					end
				end
			end
		end
	end
	
	return false
end

function DisableHud()
	if disable_hud then
		local player=get_dynamic_player()
		if player then
			if GetName(player)~=BIPEDS.flood then
				execute_script("hud_show_crosshair 0")
				execute_script("hud_show_motion_sensor 0")
				--execute_script("hud_show_health 0")
				--execute_script("hud_show_shield 0")
			else
				execute_script("hud_show_crosshair 1")
			end
		end
	end
end

function FPSwayZ()
	local player = get_dynamic_player()
	if player then --and read_bit(player + 0x4CC, 0) == 1 then
		local obj_z_vel = read_float(player + 0x70)*10
		if obj_z_vel > 1 then obj_z_vel = 1 elseif obj_z_vel < -1 then obj_z_vel = -1 end
		if abs(obj_z_vel) < 0.09 then
			obj_z_vel = 0
		end
		--console_out(obj_z_vel)
		--write_float(fp_anim_address + 76, obj_z_vel)
		write_float(fp_anim_address + 84, obj_z_vel)
	end
end

function RemoveDetailObjects()
	local DO = {
		[1] = "altis\\effects\\detail\\grass\\blurry",
		[2] = "altis\\effects\\detail\\grass\\flower",
		[3] = "altis\\effects\\detail\\grass\\grass_field_new",
		[4] = "altis\\effects\\detail\\grass\\small",
		[5] = "altis\\effects\\detail\\grass\\small2",
		[6] = "altis\\effects\\detail\\grass\\sexy\\sexy",
		[7] = "altis\\levels\\kmap\\detail_objects\\dried_grasses",
		[8] = "altis\\levels\\kmap\\detail_objects\\grass1",
		[9] = "altis\\levels\\kmap\\detail_objects\\heather",
	}
	
	for i,name in pairs (DO) do
		local tag = get_tag("dobc", name)
		if tag ~= nil then
			tag = read_dword(tag + 0x14)
			local address = read_dword(tag + 0x44+4)
			local count = read_dword(tag + 0x44)
			for j=0,count-1 do
				local struct = address + j * 96
				write_float(struct + 0x30, 0)
				write_float(struct + 0x34, 0)
				write_float(struct + 0x38, 0)
			end
		end
	end
end

set_timer(1000, "ChimeraSafeZonesFix")

function OnCommand(Command)
	if Command == "taco" then
		taco = true
		return false
	end
	if Command == "disable_shadows" then
		scenery_shadows = false
	return false
	end
	if Command == "enable_shadows" then
		scenery_shadows = true
	return false
	end
end

function OnUnload()
	local object_count = read_word(object_table + 0x2E)
	
	--IF CHIMERA WAS RELOADED
	if object_count ~= 0 then
		local message_sent = false
		for ID, info in pairs (SPAWNED_OBJECTS) do
			if get_object(ID) ~= nil then
				delete_object(ID)
				if message_sent == false then
					execute_script("rcon password chimera_reloaded")
					message_sent = true
				end
			end
		end
		
		if custom_keys then
			execute_script("rcon password i_have_chimera_lol")
		end
		
		if mexican ~= nil then
			local mexican_object = get_object(mexican)
			if mexican_object ~= nil then
				write_float(mexican_object + 0x64, -100)
				write_bit(mexican_object + 0x106, 11, 0)
				write_bit(mexican_object + 0x106, 5, 1)
			end
		end
		
		if use_backpack_weapons then
			for i=0,15 do
				for k=0,1 do
					if BACKPACK_WEAPONS[i][k].id ~= nil then
						local backpack_weapon = get_object(BACKPACK_WEAPONS[i][k].id)
						if backpack_weapon ~= nil then
							delete_object(BACKPACK_WEAPONS[i][k].id)
						end
					end
				end
				
				if ARMOR_ABILITIES[i].id ~= nil then
					if get_object(ARMOR_ABILITIES[i].id) ~= nil then
						delete_object(ARMOR_ABILITIES[i].id)
					end
					ARMOR_ABILITIES[i].id = nil
				end
			end
		end
		
		if remove_scenery_on_distance then
			for current_y, info in pairs (SCENERY_OBJECTS) do
				for current_x, info2 in pairs (SCENERY_OBJECTS[current_y]) do
					if SCENERY_OBJECTS[current_y][current_x].visible == false then
						for i, info3 in pairs (SCENERY_OBJECTS[current_y][current_x].objects) do
							execute_script("object_create "..info3)
						end
					end
				end
			end
		end
		
		for i,info in pairs (VC) do
			if info.id ~= nil and get_object(info.id) ~= nil then
				delete_object(info.id)
			end
			execute_script("object_destroy vc"..i)
		end
		
		if WEAPON_SCOPES ~= nil then
			for k,v in pairs (WEAPON_SCOPES) do
				for id,info in pairs (v) do
					if info.add ~= nil then
						write_float(info.add + 0x04, info[0])
						write_float(info.add + 0x08, info[1])
					end
				end
			end
		end
	end
end

function OnCamera(x, y, z, fov, x1, y1, z1, x2, y2, z2)
	camera_x = x
	camera_y = y
	camera_z = z
	
	local player = get_dynamic_player()
	if player ~= nil then
		local vehicle = read_dword(player + 0x11C)
		if vehicle ~= nil and vehicle ~= 0xFFFFFFFF then
			vehicle = get_object(vehicle)
			if vehicle ~= nil and read_dword(vehicle) == armor_room_tag then
				if GetObjectDistanceFromCamera(vehicle) > 30 then
					armor_room_camera_timer = 150
				end
				if armor_room_camera_timer > 0 then
					execute_script("camera_control 0")
					armor_room_camera_timer = armor_room_camera_timer - 1
					local x = read_float(vehicle + 0x5C)
					local y = read_float(vehicle + 0x60)
					local z = read_float(vehicle + 0x64)
					return x+1.8, y-0.7, z+0.2, fov, -1, 0.4, 0.25, 0, 0, 1
				end
			end
		end
	end
	
	if fog_camera_test ~= nil then
		fog_camera_test = nil
		return 0, 0, 1000, fov, 0, 0, 0, 0, 0, 0
	end
	
	armor_room_camera_timer = 0
end

function GetControllerInput(offset)
	local value = 0
	for controller_id = 0,3 do
		controller_input_address = 0x64D998 + controller_id*0xA0
		if offset >= 30 and offset <= 38 then -- sticks
			value = value + read_long(controller_input_address + offset)
		elseif offset > 96 then -- D-pad
			local value2 = read_word(controller_input_address + 96)
			if value2 == offset-100 then
				value = 1
			end
		else
			value = value + read_byte(controller_input_address + offset)
		end
	end
	--console_out(value)
	return value
end

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end

function GetObjectDistanceFromCamera(object)
	local x = read_float(object + 0x5C)
	local y = read_float(object + 0x60)
	local z = read_float(object + 0x64)
	local vehicle_id = read_dword(object + 0x11C)
	if vehicle_id ~= 0xFFFFFFFF then
		local vehicle = get_object(vehicle_id)
		if vehicle ~= nil then
			x = read_float(vehicle + 0x5C)
			y = read_float(vehicle + 0x60)
			z = read_float(vehicle + 0x64)
		end
	end
	local x_dist = camera_x - x
	local y_dist = camera_y - y
	local z_dist = camera_z - z
	return sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
end

function GetDistance(object, object2)
	local x = read_float(object + 0x5C)
	local y = read_float(object + 0x60)
	local z = read_float(object + 0x64)
	local x1 = read_float(object2 + 0x5C)
	local y1 = read_float(object2 + 0x60)
	local z1 = read_float(object2 + 0x64)
	local x_dist = x1 - x
	local y_dist = y1 - y
	local z_dist = z1 - z
	return sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
end

function rotate(X, Y, alpha)
	local c, s = cos(rad(alpha)), sin(rad(alpha))
	local t1, t2, t3 = X[1]*s, X[2]*s, X[3]*s
	X[1], X[2], X[3] = X[1]*c+Y[1]*s, X[2]*c+Y[2]*s, X[3]*c+Y[3]*s
	Y[1], Y[2], Y[3] = Y[1]*c-t1, Y[2]*c-t2, Y[3]*c-t3
end

function convert(Yaw, Pitch, Roll)
	local F, L, T = {1,0,0}, {0,1,0}, {0,0,1}
	rotate(F, L, Yaw)
	rotate(F, T, Pitch)
	rotate(T, L, Roll)
	return {F[1], -L[1], -T[1], -F[3], L[3], T[3]}
end

function Get3DVectorFromAngles(alpha,beta)
	local x = cos(alpha) * cos(beta)
	local y = sin(alpha) * cos(beta)
	local z = sin(beta)
	return x, y, z, 1
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return floor(num * mult + 0.5) / mult
end

function ClearConsole()
	for i=0,30 do
		console_out(" ")
	end
end

function read_wide_string(address, length)
	local string = ""
	
	for i=0, length do
		local character = read_word(address + i*2)
		if character ~= 0 and character < 256 then
			string = string..read_string(address + i*2)
		end
	end
	
	return string
end
