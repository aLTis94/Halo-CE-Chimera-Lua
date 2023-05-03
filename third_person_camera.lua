-- version 2023-04-23
-- third person camera script by aLTis              
-- Use numpad keys to adjust position of the camera. Press end to toggle third person camera.

--CONFIG
	
	enable_third_person_cam = false
	
	-- CAMERA POSITION
		x_offset = 0.05				-- front/back
		y_offset = -0.15			-- left/right
		z_offset = 0.3				-- up/down
		camera_distance_multiplier = 1 -- 1 is default, lower values move camera closer
		camera_offset_amount = 1 	-- should be 1
		no_firing_from_camera = true	-- player will not shoot from camera and will shoot from the gun when in third person (only works in single player)
	
	-- HOTKEYS
		toggle_tp_mouse_key = 2 -- [-1]-disabled, [0]-scroll wheel, [1]-right mouse button, [2]-extra mouse button, [3]-extra mouse button 2
		switch_directions_mouse_key = 0 -- [-1]-disabled, [0]-scroll wheel, [1]-right mouse button, [2]-extra mouse button, [3]-extra mouse button 2
		
	-- ZOOM
		third_person_zoom = true	-- stays in third person when zoomed in
		hide_scope_masks = true		-- only crosshair will be visible when zoomed in
		smooth_zoom = true			-- if above is enabled then makes the camera zoom in smoothly
		smooth_zoom_speed = 0.15	-- change how fast smooth zoom changes fov
	
	-- RETICLE
		hide_reticle_hud = false
		hide_multitex_overlay_hud = true -- hides stuff like dynamic reticles in some maps (if above is true)
		adjust_reticle_position = true	-- changes where the reticle is based on your camera offset
		adjust_reticle_amount = 4		-- how far reticle moves
		
		second_reticle = false 		-- adds a fake reticle that shows where your bullets will actually land
		second_reticle_bigass = true -- same as above but for bigass v3
		turn_reticle_red = false		-- turns reticle red when aimint at an enemy. not accurate!!!
		reticle_type = 8			-- changes the bitmap. from 1 to 13
		reticle_dot = true			-- use a dot instead of a bitmap chosen above
		reticle_radius = 0.0075
		reticle_brightness = 10
		reticle_remove_when_cannot_fire = true -- hides the reticle while reloading, throwing grenade, etc
		
		reticle_color_red = 255 	-- 0 to 255
		reticle_color_green = 0 	-- 0 to 255
		reticle_color_blue = 0 		-- 0 to 255
		reticle_color_alpha = 30 	-- 0 to 255
		
		reticle_occlusion = 1		-- occlusion radius (just like for lens flares)
		reticle_fade_time = 0.99999 		-- bigger values leave trail and lower values flicker
		reticle_distance = 5000 		-- very high values make movement more responsive but objects that are not bsp might get ignored
		reticle_timer = 0.2		-- better don't touch this :v
		reticle_count = 10 			-- increasing the count will increase the brightness
		reticle_wiggle = 0.0045		-- makes the reticles move around uwu
		
		reticle_rotation_prediction_scale = 1
		reticle_movement_prediction_scale = 1.5
	
	-- FIXES
		fix_tp_animations = true 	-- fixes wrong animations playing when you see yourself in third person in multiplayer games
		fix_turning_while_jumping = true -- fixes weird animations that play when you jump and turn around
		
	-- SOUND
		play_fp_sounds_in_tp = true	-- when in third person it will still play fp reloading and other sounds
		sound_volume_modifier = 0.6 -- how much more quiet the sounds will be in third person
		
	-- OTHER
		raise_camera_when_crouching = false -- normally the camera goes a bit too low when you crouch, this is supposed to fix it. doesn't work perfectly well
		raise_camera_amount = 0.09
		raise_camera_speed = 0.03
		
		remove_camera_shake = true 	-- removes camera shake when firing weapons
		
	debug_messages = false
--END OF CONFIG

--todo
--animations get broken in some custom maps like snowcast (fixed?)
--reload animation doesn't play sometimes
--some lights appear where dynamic crosshair is if second reticle is enabled

--v1.1 changes:
-- fixed crashes (hopefully)
-- fixed a bug that happened when playing on any map after playing on bigass
-- fixed dynamic reticle disappearing after teleporting
-- fixed animation bug that sometimes happened after switching weapons
-- added a dot dynamic reticle type that can be used instead of bitmaps
-- dynamic reticle can now be removed when the player cannot fire
-- dynamic reticle should be more responsive
-- removed sniper zoom hud stuff when third person zoom is enabled

--v1.2 changes:
-- camera now autocenters if it's about to get inside of BSP to avoid exploits (on servers only!)
-- added some hotkeys you can use to adjust camera position and turn on/off third person camera
-- fixed reload animation playing when picking up a new weapon if previous one required reloading
-- made first person animation sounds play in third person
-- improved the way scope masks are removed, should remove all stuff now
-- reticle position now automatically changes based on your camera view which makes shooting at long range much easier
-- fixed a crash related to removal of camera shake (no idea why it crashed in the first place)

-- 2021-01-09 changes:
-- fixed some issues related to second reticle (red dot)
-- fixed ammo icon appearing on the player in blood_covenant map
-- fixed some issues related to scripts getting reloaded while in third person

-- 2021-03-07 changes:
-- small fix for maps compiled using Invader

-- 2021-08-21 changes:
-- added no_firing_from_camera variable

-- 2023-04-19 changes:
-- second reticle in bigass will now turn red if aiming at an enemy and green if ally

-- 2023-04-23 changes:
-- fixed compability with balltze

--don't touch this stuff >:v
clua_version = 2.042

local CONTROL_POINTS = {
	[0] = {0.1048, 1e-007, 0.910952},
	[1] = {-0.38677, 1e-008, 0.853915},
	[2] = {-0.800739, -5e-008, 0.704265},
	[3] = {-1.05944, -9e-008, 0.293576},
	[4] = {-1.06693, -1.1e-007, -0.163176},
	[5] = {-0.873712, -7e-008, -0.452989},
	[6] = {-0.57649, -2e-008, -0.513794},
	[7] = {-0.400083, 0, -0.527226},
	[8] = {-0.287233, -1e-008, -0.528429},
}

local CAMERA = {
	["scripted"] = 22192,
	["first_person"] = 30400,
	["devcam"] = 30704,
	["vehicle"] = 31952,
	["death"] = 23776,
}

local ANIMATION_STATES = {
	[0] = 0,
	[4] = 8,
	[5] = 9,
	[6] = 10,
	[7] = 11,
}

local camera_address = 0x647498
local keyboard_input_address = 0x64C550
local mouse_input_address = 0x64C73C + 13
local announcer_address = 0x64C020
local fp_anim_address = 0x40000EB8

local sqrt = math.sqrt
local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local find = string.find


set_callback("tick", "OnTick")
set_callback("map load", "OnMapLoad")
set_callback("precamera", "OnCamera")
set_callback("unload", "OnUnload")
set_callback("command", "OnCommand")

local third_person_camera = false
local grenade_throw_frame = 5
local replacement_frame = 10
local dynamic_offset_amount = camera_offset_amount
local map_is_protected = false
local find_camera_track = true
local bigassv3 = false
local current_fov = 1.4

function OnMapLoad()
	if debug_messages then
		console_out("If you encounter a glitch or a crash then tell aLTis")
	end
	reticle_radius_address = nil
	reticle_wiggle_address = nil
	
	DEFAULT_SOUND_VOLUMES = nil
	SCOPE_MASKS = nil
	RETICLE_POSITIONS = nil
	
	sound_address = nil
	check_gun = nil
	protected_camera_track = nil
	find_camera_track = true
	map_is_protected = false
	set_timer(600, "ChangeCameraTrack")
	set_timer(700, "RemoveCameraShake")
end

function OnCamera(x, y, z, fov, x1, y1, z1, x2, y2, z2)
	local player = get_dynamic_player()
	
	-- HOTKEYS
	local chat_is_open = read_byte(0x0064E788)
	if chat_is_open == 0 and console_is_open() == false and player ~= nil then
		if read_byte(keyboard_input_address + 85) == 1 or (toggle_tp_mouse_key ~= -1 and read_byte(mouse_input_address + toggle_tp_mouse_key) == 1) then
			if enable_third_person_cam then
				OnCommand("tp 0")
			else
				OnCommand("tp 1")
			end
		end
		if enable_third_person_cam then
			if read_byte(keyboard_input_address + 99) == 1 or (switch_directions_mouse_key ~= -1 and read_byte(mouse_input_address + switch_directions_mouse_key) == 1) then
				y_offset = y_offset*-1
			elseif read_byte(keyboard_input_address + 101) > 0 then
				camera_distance_multiplier = camera_distance_multiplier - 0.005
				if camera_distance_multiplier < 0 then
					camera_distance_multiplier = 0
				end
			elseif read_byte(keyboard_input_address + 100) > 0 then
				camera_distance_multiplier = camera_distance_multiplier + 0.005
				if camera_distance_multiplier > 1.2 then
					camera_distance_multiplier = 1.2
				end
			elseif read_byte(keyboard_input_address + 94) > 0 then
				y_offset = y_offset + 0.005
				if y_offset > 0.4 then
					y_offset = 0.4
				end
			elseif read_byte(keyboard_input_address + 96) > 0 then
				y_offset = y_offset - 0.005
				if y_offset < -0.4 then
					y_offset = -0.4
				end
			elseif read_byte(keyboard_input_address + 98) > 0 then
				z_offset = z_offset + 0.005
				if z_offset > 0.35 then
					z_offset = 0.35
					z_offset = 0.35
				end
			elseif read_byte(keyboard_input_address + 92) > 0 then
				z_offset = z_offset - 0.005
				if z_offset < -0.4 then
					z_offset = -0.4
				end
			end
		end
	end

	if enable_third_person_cam == false then return end
	if third_person_camera then
		
		current_fov = fov
		camera_x1 = x1
		camera_y1 = y1
		camera_z1 = z1
		camera_x2 = x2
		camera_y2 = y2
		camera_z2 = z2
		
		if check_gun ~= nil then
			local object = get_object(check_gun)
			if object ~= nil and player ~= nil then
				local player_x, player_y = read_float(player + 0x5C), read_float(player + 0x60)
				local test_x, test_y = read_float(object + 0x5C), read_float(object + 0x60)
				local dist = sqrt((player_x-test_x)*(player_x-test_x) + (player_y-test_y)*(player_y-test_y))
				if dist > 3 then
					delete_object(check_gun)
					check_gun = nil
				else
					local aim_x = read_float(player + 0x23C)*y_offset*1.5
					local aim_y = read_float(player + 0x240)*y_offset*1.5
					local check_x = player_x-aim_y
					local check_y = player_y+aim_x
					write_float(object + 0x5C, check_x)
					write_float(object + 0x60, check_y)
					write_float(object + 0x64, z)
					write_float(object + 0x68, 0)
					write_float(object + 0x6C, 0)
					write_float(object + 0x70, 0)
					
					write_dword(object + 0x98, read_dword(player + 0x98)) -- cluster thingy
					write_dword(object + 0x204, 0xF000000) -- respawn timer
					write_bit(object + 0x10, 18, 1) -- no shadows
					write_bit(object + 0x1F4, 2, 1) -- remove collision
					write_float(object + 0xAC, 0.00001) -- bounding radius
					write_bit(object + 0x10, 0, 1)-- ghost mode
					
					-- move nodes away in case equipment has lens flares or whatever
					for j=0,2 do
						write_float(object + 0x294 + 0x30 + 0x34*j, -100)
					end
					
					local obj_is_inside_bsp = read_bit(object + 0x10, 21)
					if obj_is_inside_bsp == 1 then
						camera_offset_amount = camera_offset_amount - 0.2
						if camera_offset_amount < 0 then
							camera_offset_amount = 0
						end
					elseif camera_offset_amount < 1 then
						camera_offset_amount = camera_offset_amount + 0.05
						if camera_offset_amount > 1 then
							camera_offset_amount = 1
						end
					end
				end
			else
				check_gun = nil
			end
		end
		
		
		if raise_camera_when_crouching then
			if player ~= nil then
				local crouch = read_float(player + 0x50C)
				new_z = z + crouch * raise_camera_amount
				if wanted_z == nil then
					wanted_z = z
				end
				
				if wanted_z > new_z then
					wanted_z = wanted_z - raise_camera_speed
					if wanted_z < new_z then
						wanted_z = new_z
					end
					new_z = wanted_z
				elseif wanted_z < new_z then
					wanted_z = wanted_z + raise_camera_speed
					if wanted_z > new_z then
						wanted_z = new_z
					end
					new_z = wanted_z
				end
				z = new_z
			end
		end
		
		if third_person_zoom then
			
			new_fov = fov
			dynamic_offset_amount = camera_offset_amount
			
			if reticle_radius_address ~= nil and reticle_wiggle_address ~= nil then
				write_float(reticle_wiggle_address, reticle_wiggle)
				write_float(reticle_radius_address, reticle_radius)
				write_float(reticle_radius_address + 4, reticle_radius)
			end
			
			if player ~= nil then
				
				local magnification_level = 1
				local vehicle = get_object(read_dword(player + 0x11C))
				if vehicle == nil then
					local zoom_level = read_u8(player + 0x320)
					if zoom_level < 255 then
						local weapon_slot = read_byte(player + 0x2F4)
						local weapon_id = read_dword(player + 0x2F8 + weapon_slot * 4)
						local object = get_object(weapon_id)
						if object ~= nil then
							local weap_tag = get_tag(read_dword(object))
							if weap_tag ~= nil then
								weap_tag = read_dword(weap_tag + 0x14)
								if zoom_level > 1 then
									zoom_level = 1
								end
								
								magnification_level = read_float(weap_tag + 0x3DC + 4*zoom_level)
								if magnification_level == 0 then
									magnification_level = 1
								end
								
								if reticle_radius_address ~= nil and reticle_wiggle_address ~= nil then
									write_float(reticle_wiggle_address, reticle_wiggle/magnification_level)
									write_float(reticle_radius_address, reticle_radius/magnification_level)
									write_float(reticle_radius_address + 4, reticle_radius/magnification_level)
								end
								
								if fov ~= fov/magnification_level and magnification_level ~= 0 then
									new_fov = fov/magnification_level
									dynamic_offset_amount = camera_offset_amount - magnification_level*0.019
								end
							end
						end
					end
					
					if smooth_zoom then
						if wanted_fov == nil then
							wanted_fov = fov
						end
						
						if wanted_fov > new_fov then
							wanted_fov = wanted_fov - smooth_zoom_speed
							if wanted_fov < new_fov then
								wanted_fov = new_fov
							end
							new_fov = wanted_fov
						elseif wanted_fov < new_fov then
							wanted_fov = wanted_fov + smooth_zoom_speed
							if wanted_fov > new_fov then
								wanted_fov = new_fov
							end
							new_fov = wanted_fov
						end
					end
					
					-- RETICLE OFFSET
					if adjust_reticle_position and player ~= nil then
						local vehicle = get_object(read_dword(player + 0x11C))
						if vehicle == nil then
							AdjustReticlePosition((z_offset-0.05)*adjust_reticle_amount*1.33*magnification_level,y_offset*adjust_reticle_amount*magnification_level)
						else
							AdjustReticlePosition(0,0)
						end
					end
					
					previous_zoom_level = zoom_level
					current_fov = new_fov
					return x, y, z, new_fov, x1, y1, z1, x2, y2, z2
				end
			elseif check_gun ~= nil then
				local object = get_object(check_gun)
				if object ~= nil then
					delete_object(check_gun)
				end
				check_gun = nil
			end
		end
	end
	return x, y, z, fov, x1, y1, z1, x2, y2, z2
end

function ToggleScopeMasks(enable)
	if third_person_zoom and hide_scope_masks then
		if SCOPE_MASKS == nil then
			FindScopeMasks()
		end
		
		for address, default_value in pairs (SCOPE_MASKS) do
			if enable then
				write_dword(address, default_value)
			else
				write_dword(address, 0)
			end
		end
	end
end

function FindScopeMasks()
	if third_person_zoom and hide_scope_masks then
		SCOPE_MASKS = {}
		local tag_array = read_dword(0x40440000)
		local tag_count = read_dword(0x4044000C)
		for i = 0,tag_count - 1 do
			local tag = tag_array + i * 0x20
			local tag_class = read_dword(tag)
			if tag_class == 0x77656170 then
				local meta_id = read_dword(tag + 0xC)
				local weap_tag = get_tag(meta_id)
				if weap_tag ~= nil then
					weap_tag = read_dword(weap_tag + 0x14)
					hud_tag = get_tag(read_dword(weap_tag + 0x480 + 0xC))
					if hud_tag ~= nil then
						hud_tag = read_dword(hud_tag + 0x14)
						local screen_effect_address = hud_tag + 0xAC
						SCOPE_MASKS[screen_effect_address] = read_dword(screen_effect_address)
						
						local crosshair_count = read_dword(hud_tag + 0x84)
						local crosshair_address = read_dword(hud_tag + 0x88)
						for i=0,crosshair_count-1 do
							local address = crosshair_address + i*104
							local type = read_dword(address)
							if type == 0 or type == 1 then
								local overlay_count = read_dword(address + 0x34)
								local overlay_address = read_dword(address + 0x38)
								local removed = false
								for i=0,overlay_count-1 do
									local address2 = overlay_address + i*104
									local x_offset = read_short(address2)
									local y_offset = read_short(address2 + 2)
									if abs(x_offset) > 30 or abs(y_offset) > 30 then
										local overlays_address = address + 0x34
										SCOPE_MASKS[overlays_address] = read_dword(overlays_address)
										removed = true
									end
								end
								
								if removed == false then
									local bitmap_tag = get_tag(read_dword(address + 0x24 + 0xC))
									if bitmap_tag ~= nil then
										bitmap_tag = read_dword(bitmap_tag + 0x14)
										local bitmap = read_dword(bitmap_tag + 0x64)
										if read_word(bitmap_tag) ~= 3 then
											local width = read_short(bitmap + 0x04)
											if width > 256 then
												local overlays_address = address + 0x34
												SCOPE_MASKS[overlays_address] = read_dword(overlays_address)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return false
end

FindScopeMasks()

function SetFiringSource()
	if no_firing_from_camera and server_type == "none" then
		player = get_dynamic_player()
		if player ~= nil then
			local camera_mode = read_short(camera_address)
			local player_biped_tag = get_tag(read_dword(player))
			if player_biped_tag ~= nil then
				player_biped_tag = read_dword(player_biped_tag + 0x14)
				if camera_mode == CAMERA.first_person then
					write_bit(player_biped_tag + 0x17C, 3, 1)
				else
					write_bit(player_biped_tag + 0x17C, 3, 0)
				end
			end
		end
	end
end

function OnTick()
	SetFiringSource()
	--write_short(camera_address, CAMERA.vehicle)
	if enable_third_person_cam == false then return end
	player = get_dynamic_player()
	
	-- FIX ANIMATIONS
	if player ~= nil and server_type ~= "none" and fix_tp_animations then
		local vehicle = get_object(read_dword(player + 0x11C))
		local health = read_float(player + 0xE0)
		if vehicle == nil and health > 0 then
			local label = ""
			local weapon_slot = read_byte(player + 0x2F4)
			local weapon_id = read_dword(player + 0x2F8 + weapon_slot * 4)
			local object = get_object(weapon_id)
			local switching_weapon = false
			if object ~= nil then
				local weap_tag = get_tag(read_dword(object))
				if weap_tag ~= nil then
					weap_tag = read_dword(weap_tag + 0x14)
					label = read_string(weap_tag + 0x30C)
				end
				if (previous_weapon ~= nil and previous_weapon ~= object) then
					switching_weapon = true
					--console_out("switching")
				end
			end
			local current_unit = read_byte(player + 0x2A0) -- stand, crouch etc
			local current_animation_state = read_byte(player + 0x2A3) -- idle, reloading etc
			local current_base_animation = read_word(player + 0xD0) -- animation id
			local current_animation_frame = read_word(player + 0xD2)
			local animation_tag = get_tag(read_dword(player + 0xCC))
			local current_replacement_animation = read_word(player + 0x2AA)
			local current_replacement_frame = read_word(player + 0x2AC)
			
			--console_out(current_replacement_animation)
			local m_player = get_player()
			--console_out(read_bit(m_player + 0xF5, 5))
			
			-- JUMP ANIMATIONS
			if fix_turning_while_jumping then
				local is_on_ground = read_bit(player + 0x10, 1)
				local player_biped_tag = get_tag(read_dword(player))
				if player_biped_tag ~= nil then
					player_biped_tag = read_dword(player_biped_tag + 0x14)
					if is_on_ground == 1 then
						write_bit(player_biped_tag +  0x2F4, 0, 0)
					else
						write_bit(player_biped_tag +  0x2F4, 0, 1)
					end
				end
			end
			-- CANCEL REPLACEMENT ANIM IF SWITCHING WEAPONS
			if (switching_weapon and current_replacement_animation < 300) or just_switched ~= nil then
				if bigassv3 == false or object == nil or find(GetName(object), "sprint") == nil then
					write_byte(player + 0x2A4, 0)
					write_word(player + 0x2AA, 0x100)
				end
			end
			
			-- RELOAD AND MELEE
			if replacement_frame < 10 then
				replacement_frame = replacement_frame + 1
				--console_out(current_replacement_frame.." "..replacement_frame)
				if current_replacement_frame ~= replacement_frame and previous_replacement_animation < 254 then
					if current_animation_state ~= 33 or switching_weapon then
						if debug_messages then
							console_out(" ")
							console_out("fixed reloading or melee!")
							console_out("wrong frame "..current_replacement_frame..", correct frame "..replacement_frame)
						end
						write_byte(player + 0x2A4, 5)
						write_word(player + 0x2AC, current_replacement_frame)
						if previous_replacement_animation ~= nil then
							write_word(player + 0x2AA, previous_replacement_animation)
							if debug_messages then
								console_out("previous animation "..previous_replacement_animation)
							end
						end
					else
						if debug_messages then
							console_out("cancelling replacement animation")
						end
						write_word(player + 0x2AC, 999)
						replacement_frame = 10
					end
				end
			end
			if current_replacement_frame == 1 or current_replacement_frame == 0 then
				previous_replacement_animation = current_replacement_animation
				replacement_frame = current_replacement_frame
			end
			
			if object ~= nil then
				previous_weapon = object
			end
			
			-- GRENADE THROW
			if grenade_throw_frame < 5 then
				grenade_throw_frame = grenade_throw_frame + 1
				if current_animation_frame ~= grenade_throw_frame then
					if debug_messages then
						console_out("fixed grenade throw!")
					end
					write_byte(player + 0x2A3, 33)
					if previous_base_animation ~= nil then
						write_word(player + 0xD0, previous_base_animation)
					end
				end
			end
			if current_animation_state == 33 then
				if current_animation_frame == 1 or current_animation_frame == 0 then
					previous_base_animation = current_base_animation
					grenade_throw_frame = current_animation_frame
				end
			end
			
			
			if animation_tag ~= nil and ANIMATION_STATES[current_animation_state] ~= nil then
				animation_tag = read_dword(animation_tag + 0x14)
				local unit_address = read_dword(animation_tag + 0x0C + 4)
				local address = unit_address + current_unit * 100
				local unit_name = read_string(address)
				local weapon_count = read_dword(address + 0x58)
				local weapon_address = read_dword(address + 0x58 + 4)
				for j=0,weapon_count - 1 do
					local address = weapon_address + j * 188
					local weapon_name = read_string(address)
					local weapon_type_count = read_dword(address + 0xB0)
					local weapon_type_address = read_dword(address + 0xB0 + 4)
					for k=0,weapon_type_count - 1 do
						local type_address = weapon_type_address + k * 60
						if read_string(type_address) == label then
							write_byte(player + 0x2A1, j)
							
							current_animation_state = ANIMATION_STATES[current_animation_state]
							
							local animation_count = read_dword(address + 0x98)
							local animation_address = read_dword(address + 0x98 + 4)
							for l=0,animation_count - 1 do
								if 26 - l == current_animation_state then
									local address = animation_address + current_animation_state * 2
									local animation_id = read_word(address)
									if animation_id < 300 and current_base_animation < 300 and current_base_animation ~= animation_id then
										if debug_messages then
											console_out(" ")
											console_out("replacing "..current_base_animation.." with "..animation_id)
											console_out("unit "..unit_name.." weapon "..weapon_name)
										end
										write_word(player + 0xD0, animation_id)
									end
									goto fixed
								end
							end
						end
					end
				end
			end
		end
	end
	
	::fixed::
	
	-- 3P CAMERA
	third_person_camera = false
	if enable_third_person_cam then
		ChangeCameraTrack()
		
		if player ~= nil then
			vehicle = get_object(read_dword(player + 0x11C))
			local camera_mode = read_short(camera_address)
			local zoom_level = read_u8(player + 0x320)
			
			BigassReticle()
			
			if vehicle ~= nil then
				if hide_reticle_hud then
					ReticeHud(true)
				end
				if check_gun ~= nil then
					local object = get_object(check_gun)
					if object ~= nil then
						delete_object(check_gun)
					end
					check_gun = nil
				end
				
				if bigassv3 then
					if find(GetName(vehicle), "taunt") then
						write_float(camera_address + 0x150, 0)
						write_float(camera_address + 0x154, 0)
						write_float(camera_address + 0x158, 0)
					end
				end
			else
				if third_person_zoom == false then
					if zoom_level < 255 then
						if hide_reticle_hud then
							ReticeHud(true)
						end
					else
						if hide_reticle_hud then
							ReticeHud(false)
						end
					end
				elseif camera_address ~= nil then
					write_float(camera_address + 28, dynamic_offset_amount)
				end
				
				if hide_reticle_hud and zoom_level == 255 then
					ReticeHud(false)
				end
			end
			
			if zoom_level < 255 and (camera_mode == CAMERA.vehicle or camera_mode == CAMERA.first_person) and third_person_zoom == false then
				write_short(camera_address, CAMERA.first_person)
			elseif vehicle == nil then
				if camera_mode == CAMERA.first_person then
					write_short(camera_address, CAMERA.vehicle)
					write_float(camera_address + 28, dynamic_offset_amount)
					third_person_camera = true
				end
				if camera_mode == CAMERA.vehicle then
					third_person_camera = true
					
					local crouch = read_float(player + 0x50C)
					camera_height = 0.62 - (crouch * (0.62 - 0.35))
					player_x = read_float(player + 0x5C)
					player_y = read_float(player + 0x60)
					player_z = read_float(player + 0x64) + camera_height
					player_x_vel = read_float(player + 0x68)
					player_y_vel = read_float(player + 0x6C)
					player_z_vel = read_float(player + 0x70)
					
					if map_is_protected == false and server_type == "dedicated" then
						if check_gun == nil then
							local tag_name = FindEquip()
							if tag_name ~= nil then
								check_gun = spawn_object("eqip", tag_name, player_x, player_y, player_z+0.1)
								local object = get_object(check_gun)
								if object == nil then
									check_gun = nil
								end
							end
						else
							local object = get_object(check_gun)
							if object == nil then
								check_gun = nil
							end
						end
					end
					
					
					if camera_x1 ~= nil and second_reticle and map_is_protected == false and bigassv3 == false then
						if (reticle_gun == nil or get_object(reticle_gun) == nil) and PrepareReticleTags() then
							reticle_gun = spawn_object("weap", "weapons\\gravity rifle\\gravity rifle", player_x, player_y, player_z)
							local object = get_object(reticle_gun)
							if object ~= nil and server_type ~= "local" then
								if GetName(object) ~= "weapons\\gravity rifle\\gravity rifle" then
									local globals_tag = get_tag("matg", "globals\\globals")
									if globals_tag ~= nil then
										globals_tag = read_dword(globals_tag + 0x14)
										local weapons_count = read_dword(globals_tag + 0x14C)
										local weapons_address = read_dword(globals_tag + 0x14C + 4)
										for k=0,weapons_count - 1 do
											local address = weapons_address + k * 16
											local reticle_gun_tag = get_tag("weap", "weapons\\gravity rifle\\gravity rifle")
											write_dword(address, read_dword(reticle_gun_tag))
											write_dword(address + 0xC, read_dword(reticle_gun_tag + 0xC))
										end
									end
								end
							end
						end
						if reticle_gun ~= nil then
							local object = get_object(reticle_gun)
							if object ~= nil then
								local distance = GetDistance(object, player, camera_height)
								if GetName(object) ~= "weapons\\gravity rifle\\gravity rifle" or distance > 2 then
									RemoveReticleGun()
								else
									if turn_reticle_red and read_dword(0x400008CC) == 1 then
										ReticleColor(true)
									else
										ReticleColor(false)
									end
									
									if reticle_remove_when_cannot_fire and reticle_lifetime_address ~= nil then
										--local unit_able_to_fire = read_byte(player + 0x2B7) == 1
										local weapon_slot = read_byte(player + 0x2F4)
										local weapon_id = read_dword(player + 0x2F8 + weapon_slot * 4)
										local object = get_object(weapon_id)
										if object ~= nil then
											local melee_state = read_bit(object + 0x230, 4)
											local ready_timer = read_word(object + 0x23A)
											local reload_timer = read_word(object + 0x2B2)
											if melee_state == 0 and ready_timer == 0 and reload_timer == 0 then
												write_float(reticle_lifetime_address, reticle_timer)
												write_float(reticle_lifetime_address + 4, reticle_timer)
											else
												write_float(reticle_lifetime_address, 0)
												write_float(reticle_lifetime_address + 4, 0)
											end
										end
									end
									
									--make it not respawn (doesn't work?)
									write_dword(object + 0x204, 0xF000000)
									
									local offset_amount = 0.1
									write_float(object + 0x5C, player_x + camera_x1*offset_amount + player_x_vel*reticle_movement_prediction_scale)
									write_float(object + 0x60, player_y + camera_y1*offset_amount + player_y_vel*reticle_movement_prediction_scale)
									write_float(object + 0x64, player_z + camera_z1*offset_amount + player_z_vel*reticle_movement_prediction_scale)
									write_float(object + 0x68, player_x_vel)
									write_float(object + 0x6C, player_y_vel)
									write_float(object + 0x70, player_z_vel)
									if previous_camera_x1 ~= nil then
										local x_rot_offset = (camera_x1 - previous_camera_x1)*reticle_rotation_prediction_scale
										x_rot_offset = x_rot_offset*x_rot_offset*x_rot_offset*50
										local y_rot_offset = (camera_y1 - previous_camera_y1)*reticle_rotation_prediction_scale
										y_rot_offset = y_rot_offset*y_rot_offset*y_rot_offset*50
										local z_rot_offset = (camera_z1 - previous_camera_z1)*reticle_rotation_prediction_scale
										z_rot_offset = z_rot_offset*z_rot_offset*z_rot_offset*50
										--console_out(x_rot_offset)
										write_float(object + 0x74, camera_x1 + x_rot_offset)
										write_float(object + 0x78, camera_y1 + y_rot_offset)
										write_float(object + 0x7C, camera_z1 + z_rot_offset)
									end
									write_float(object + 0x80, camera_x2)
									write_float(object + 0x84, camera_y2)
									write_float(object + 0x88, camera_z2)
									write_float(object + 0x8C, 0)
									write_float(object + 0x90, 0)
									write_float(object + 0x94, 0)
									previous_camera_x1 = camera_x1
									previous_camera_y1 = camera_y1
									previous_camera_z1 = camera_z1
								end
							end
						end
					end
				end
			end
		end
	end
	
	if third_person_camera == false then
		RemoveReticleGun()
	end
	
	-- SOUNDS
	if play_fp_sounds_in_tp and enable_third_person_cam and player ~= nil then
		local vehicle = get_object(read_dword(player + 0x11C))
		if vehicle == nil then
			local weapon_slot = read_byte(player + 0x2F4)
			local weapon_id = read_dword(player + 0x2F8 + weapon_slot * 4)
			local object = get_object(weapon_id)
			if object ~= nil then
				local weapon_base_anim_frame = read_word(fp_anim_address + 32) -- frame of the base animation
				if weapon_base_anim_frame == 0 then
					local meta_id = read_dword(object)
					local weap_tag = get_tag(meta_id)
					if weap_tag ~= nil then
						weap_tag = read_dword(weap_tag + 0x14)
						local fp_anim_tag = get_tag(read_dword(weap_tag + 0x46C + 0xC))
						if fp_anim_tag ~= nil then
							fp_anim_tag = read_dword(fp_anim_tag + 0x14)
							
							local weapon_base_anim_id = read_word(fp_anim_address + 30) -- ID of the base animation from fp animations tag currently playing
							
							local animations_count = read_dword(fp_anim_tag + 0x74)
							if weapon_base_anim_id < animations_count then
								local animations_address = read_dword(fp_anim_tag + 0x78)
								local playing_anim = animations_address + weapon_base_anim_id*180
								local sound_id = read_word(playing_anim + 0x3C)
								if sound_id ~= 0xFFFF and sound_id < read_dword(fp_anim_tag + 0x54) then
									local sound_meta_id = read_dword(read_dword(fp_anim_tag + 0x58) + sound_id*20 + 0xC)
									PlaySound(sound_meta_id)
								end
							end
						end
					end
				end
			end
		end
	end
end

function RemoveCameraShake()
	if remove_camera_shake and enable_third_person_cam then
		local tag_array = read_dword(0x40440000)
		local tag_count = read_dword(0x4044000C)
		for i = 0,tag_count - 1 do
			local tag = tag_array + i * 0x20
			local tag_class = read_dword(tag)
			if tag_class == 0x77656170 then
				local meta_id = read_dword(tag + 0xC)
				local weap_tag = get_tag(meta_id)
				if weap_tag ~= nil then
					weap_tag = read_dword(weap_tag + 0x14)
					local triggers_count = read_dword(weap_tag + 0x4FC)
					local triggers_address = read_dword(weap_tag + 0x4FC + 4)
					for i=0,triggers_count-1 do
						local trigger_address = triggers_address + i*276
						local firing_effects_count = read_dword(trigger_address + 0x108)
						local firing_effects_address = read_dword(trigger_address + 0x108 + 4)
						if firing_effects_count > 0 then
							local damage_tag = get_tag(read_dword(firing_effects_address + 0x54 + 0xC))
							if damage_tag ~= nil then
								damage_tag = read_dword(damage_tag + 0x14)
								write_float(damage_tag + 0x5C, 0)
								write_float(damage_tag + 0x60, 0)
								write_float(damage_tag + 0x70, 0)
								write_float(damage_tag + 0x74, 0)
								--write_float(damage_tag + 0x98, 0)
								--write_float(damage_tag + 0xA0, 0)
								write_float(damage_tag + 0xA4, 0)
								write_float(damage_tag + 0xA8, 0)
								write_float(damage_tag + 0xAC, 0)
								write_float(damage_tag + 0xCC, 0)
								write_float(damage_tag + 0xD4, 0)
								write_float(damage_tag + 0xD8, 0)
							end
						end
					end
				end
			end
		end
	end
end

RemoveCameraShake()

function AdjustReticlePosition(y,x)
	if adjust_reticle_position and bigassv3 == false then
		if RETICLE_POSITIONS == nil then
			GetReticlePositions()
		end
	
		for address,default_positions in pairs (RETICLE_POSITIONS) do
			if x > 0 then
				x = floor(x) 
			elseif x < 0 then
				x = ceil(x) 
			end
			if y > 0 then
				y = floor(y) 
			elseif y < 0 then
				y = ceil(y) 
			end
			--console_out(x.." "..y)
			write_short(address, default_positions.x + x)
			write_short(address + 2, default_positions.y + y)
		end
	end
end

function GetReticlePositions()
	RETICLE_POSITIONS = {}
	local tag_array = read_dword(0x40440000)
	local tag_count = read_dword(0x4044000C)
	for i = 0,tag_count - 1 do
		local tag = tag_array + i * 0x20
		local tag_class = read_dword(tag)
		if tag_class == 0x77656170 then
			local meta_id = read_dword(tag + 0xC)
			local weap_tag = get_tag(meta_id)
			if weap_tag ~= nil then
				weap_tag = read_dword(weap_tag + 0x14)
				hud_tag = get_tag(read_dword(weap_tag + 0x480 + 0xC))
				if hud_tag ~= nil then
					hud_tag = read_dword(hud_tag + 0x14)
					local crosshair_count = read_dword(hud_tag + 0x84)
					local crosshair_address = read_dword(hud_tag + 0x88)
					for i=0,crosshair_count-1 do
						local address = crosshair_address + i*104
						local overlay_count = read_dword(address + 0x34)
						local overlay_address = read_dword(address + 0x38)
						for i=0,overlay_count-1 do
							local address2 = overlay_address + i*104
							local x_offset = read_short(address2)
							local y_offset = read_short(address2 + 2)
							if abs(x_offset) <= 30 and abs(y_offset) <= 30 then
								RETICLE_POSITIONS[address2] = {}
								RETICLE_POSITIONS[address2].x = read_dword(address2)
								RETICLE_POSITIONS[address2].y = read_dword(address2 + 2)
							end
						end
					end
				end
			end
		end
	end
end

function CheckBigassWeapons(name)
	if name=="altis\\weapons\\sprint\\sprint" or name=="altis\\weapons\\sprint\\sprint_female" or name=="altis\\weapons\\newspaper\\newspaper" or name=="reach\\objects\\weapons\\multiplayer\\flag\\flag" or name=="weapons\\ball\\ball" or name=="altis\\weapons\\knife\\knife" then
		return true
	else
		return false
	end
end

function GetBigassAspectRatio()
	local dmr_hud = read_dword(get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\dmr") + 0x14)
	local static_address = read_dword(dmr_hud + 0x64)
	return read_float(static_address + 0x28)
end

function BigassReticle()
	if bigassv3 == false or second_reticle_bigass == false or camera_x1 == nil or player_x == nil then return end
	
	local weapon_slot = read_byte(player + 0x2F4)
	local weapon_id = read_dword(player + 0x2F8 + weapon_slot * 4)
	local object = get_object(weapon_id)
	if vehicle ~= nil or object == nil or CheckBigassWeapons(GetName(object)) then
	
		SetBigassReticle(999,999, 0)
		if projectile ~= nil and get_object(projectile) ~= nil then
			delete_object(projectile)
			projectile = nil
		end
	elseif projectile ~= nil and get_object(projectile) ~= nil then
		local zoom_level = read_u8(player + 0x320)
		local object = get_object(projectile)
		local distance = GetDistance(object, player, camera_height)
		local min_dist = 1.7
		local bitmap = 0
		local player_team = read_word(player + 0xB8)
		local color = "blue"
		--console_out("player team "..player_team)
		
		if distance > 50 then
			distance = 50
		elseif distance < min_dist then
			distance = min_dist
			bitmap = 1
		end
		
		local parent = get_object(read_dword(object + 0x11C))
		if parent ~= nil then
			if read_word(parent + 0xB4) == 0 then
				bitmap = 0
				local target_team = read_word(parent + 0xB8)
				--console_out("target team "..target_team)
				if player_team ~= target_team then
					color = "red"
				elseif player_team == target_team then
					if player == parent then
						bitmap = 1
					else
						color = "green"
					end
				end
			end
		end
		
		local fov_offset = 1/current_fov*90 - 28
		--console_out(fov_offset)
		distance = sqrt((50 - distance)) * fov_offset * 1.15/distance
		
		if distance < 10 or (abs(y_offset) < 0.1 and abs(z_offset) < 0.25) then
			SetBigassReticle(9999,9999, bitmap)
		else
			local aspect_change = GetBigassAspectRatio()
			local x_offset = floor(distance * y_offset * dynamic_offset_amount *4/3*aspect_change)
			if third_person_zoom == false and zoom_level < 255 then
				x_offset = 0
			end
			--console_out(z_offset)
			local z_offset = floor(distance * z_offset * dynamic_offset_amount*1.5 - distance*camera_distance_multiplier*0.2 )
			
			if y_offset < 0 and x_offset > 0 then
				x_offset = 0
			end
			
			SetBigassReticle(x_offset,z_offset, bitmap, color)
		end
		
		delete_object(projectile)
		projectile = nil
	else
		local offset_amount = 0.37 -- was 33
		projectile = spawn_object("proj", "altis\\effects\\distance_check", player_x + player_x_vel +  camera_x1*offset_amount, player_y + player_y_vel + camera_y1*offset_amount, player_z + player_z_vel + camera_z1*offset_amount)
		local object = get_object(projectile)
		if object ~= nil then
			local projectile_velocity = 55
			write_float(object + 0x68, camera_x1 * projectile_velocity)
			write_float(object + 0x6C, camera_y1 * projectile_velocity)
			write_float(object + 0x70, camera_z1 * projectile_velocity)
			write_float(object + 0x254, camera_x1 * projectile_velocity)
			write_float(object + 0x258, camera_y1 * projectile_velocity)
			write_float(object + 0x25C, camera_z1 * projectile_velocity)
		end
	end
end

function SetBigassReticle(x, z, bitmap, color)
	local tag = get_tag("unhi", "bourrin\\hud\\h1 symmetrical")
	if tag ~= nil then
		tag = read_dword(tag + 0x14)
		write_short(tag + 0x24, x)
		write_short(tag + 0x26, z)
		write_short(tag + 0x78, bitmap)
		
		if bitmap == 0 then
			write_byte(tag + 0x58, 255)
			write_byte(tag + 0x58+1, 150)
			write_byte(tag + 0x58+2, 40)
			write_byte(tag + 0x58+3, 100)
			
			if color ~= nil then
				if color == "blue" then
					write_byte(tag + 0x58, 255)
					write_byte(tag + 0x59, 150)
					write_byte(tag + 0x5A, 40)
				elseif color == "red" then
					write_byte(tag + 0x58, 0)
					write_byte(tag + 0x59, 0)
					write_byte(tag + 0x5A, 255)
				else
					write_byte(tag + 0x58, 0)
					write_byte(tag + 0x59, 255)
					write_byte(tag + 0x5A, 0)
				end
			end
		else
			write_byte(tag + 0x58, 0)
			write_byte(tag + 0x58+1, 0)
			write_byte(tag + 0x58+2, 255)
			write_byte(tag + 0x58+3, 255)
		end
	end
end

function ReticeHud(show)
	if map_is_protected or (second_reticle and reticle_gun == nil) then 
		show = true
		--if map_is_protected then
		--	console_out("protected")
		--else
		--	console_out("reticle gun")
		--end
	end
	if show then
		execute_script("hud_show_crosshair 1")
		--console_out("show")
	else
		--console_out("hide")
		execute_script("hud_show_crosshair 0")
		if hide_multitex_overlay_hud then
			local player = get_dynamic_player()
			if player ~= nil then
				local vehicle = read_dword(player + 0x11C)
				if vehicle == 0xFFFFFFFF then
					local weapon_slot = read_byte(player + 0x2F4)
					local weapon_id = read_dword(player + 0x2F8 + weapon_slot * 4)
					if weapon_id ~= 0xFFFFFFFF then
						local object = get_object(weapon_id)
						if object ~= nil then
							local weap_tag = get_tag(read_dword(object))
							if weap_tag ~= nil then
								weap_tag = read_dword(weap_tag + 0x14)
								hud_tag = get_tag(read_dword(weap_tag + 0x480 + 0xC))
								if hud_tag ~= nil then
									hud_tag = read_dword(hud_tag + 0x14)
									RemoveMultitex(hud_tag)
								end
							end
						end
					end
				end
			end
		end
	end
end

function RemoveMultitex(hud_tag)
	local static_elements_count = read_dword(hud_tag + 0x60)
	local static_elements_address = read_dword(hud_tag + 0x64)
	for j=0,static_elements_count-1 do
		local address = static_elements_address + j*180
		write_dword(address + 0x7C, 0xFFFFFFFF)
		write_dword(address + 0x7C + 0xC, 0xFFFFFFFF)
	end
	local child_tag = get_tag(read_dword(hud_tag + 0xC))
	if child_tag ~= nil then
		RemoveMultitex(read_dword(child_tag + 0x14))
	end
end

function PrepareReticleTags()
	if map_is_protected then
		return false
	end
	
	if bigassv3 then return true end
	
	if (get_tag("weap", "weapons\\gravity rifle\\gravity rifle") == nil or get_tag("effe", "weapons\\assault rifle\\effects\\impact engineer sack") == nil or get_tag("effe", "effects\\coop teleport") == nil) then
		return false
	end
	if hide_reticle_hud then
		ReticeHud(false)
	else
		ReticeHud(true)
	end
	local weap_tag = get_tag("weap", "weapons\\gravity rifle\\gravity rifle")
	if weap_tag ~= nil then
		weap_tag = read_dword(weap_tag + 0x14)
		write_bit(weap_tag + 0x02, 1, 1)
		write_bit(weap_tag + 0x02, 0, 1)
		write_float(weap_tag + 0x20, 0)	-- disable acceleration
		write_string(weap_tag + 0x30C, "disabled") -- make it so player couldn't pick it up
		
		local attachment_count = read_dword(weap_tag + 0x140)
		local attachment_address = read_dword(weap_tag + 0x144)
		if attachment_count > 0 then
			write_word(attachment_address + 0x30, 0)
			local effect_tag = get_tag("effe", "weapons\\assault rifle\\effects\\impact engineer sack")
			if effect_tag ~= nil then
				write_dword(attachment_address, read_dword(effect_tag))
				write_dword(attachment_address + 0xC, read_dword(effect_tag + 0xC))
				effect_tag = read_dword(effect_tag + 0x14)
				write_word(effect_tag, 2)--cannot optimize out
				local locations = read_dword(effect_tag + 0x28 + 4)
				write_string(locations, "")
				local events_count = read_dword(effect_tag + 0x34)
				local events_address = read_dword(effect_tag + 0x38)
				for j=0,events_count-1 do
					local address = events_address + j*68
					write_float(address + 0x08, 0)
					write_float(address + 0x0C, 0)
					write_float(address + 0x10, 0)
					write_float(address + 0x14, 0)
					local particle_count = read_dword(address + 0x38)
					local particle_address = read_dword(address + 0x38 + 4)
					for k=0,particle_count-1 do
						local address = particle_address + k*232
						if j == 0 and k == 0 then
							local particle_tag = get_tag("part", "effects\\particles\\solid\\blood engineer trails")
							if particle_tag ~= nil then
								write_dword(address + 0x54, read_dword(particle_tag))
								write_dword(address + 0x54 + 0xC, read_dword(particle_tag + 0xC))
								particle_tag = read_dword(particle_tag + 0x14)
								
								reticle_lifetime_address = particle_tag + 0x38
								write_float(reticle_lifetime_address, reticle_timer) --lifetime
								write_float(reticle_lifetime_address + 4, reticle_timer) --lifetime
								write_float(particle_tag + 0x44, 0) --fade out time
								
								local physics_tag = get_tag("pphy", "effects\\point physics\\rubber")
								if physics_tag ~= nil then
									write_dword(particle_tag + 0x14, read_dword(physics_tag))
									write_dword(particle_tag + 0x14 + 0xC, read_dword(physics_tag + 0xC))
									physics_tag = read_dword(physics_tag + 0x14)
									write_bit(physics_tag, 0, 0)--flamethrower coll
									write_bit(physics_tag, 5, 1)
									write_float(physics_tag + 0x20, 10000)--density
									write_float(physics_tag + 0x24, 0)--air friction
									write_float(physics_tag + 0x28, 1)--water friction
									write_float(physics_tag + 0x2C, 1)--surface friction
									write_float(physics_tag + 0x30, 0)--elasticity
								end
								
								local effect_tag = get_tag("effe", "effects\\coop teleport")
								if effect_tag ~= nil then
									write_dword(particle_tag + 0x58, read_dword(effect_tag))
									write_dword(particle_tag + 0x58 + 0xC, read_dword(effect_tag + 0xC))
									effect_tag = read_dword(effect_tag + 0x14)
									write_word(effect_tag, 2)--cannot optimize out
									local events_address = read_dword(effect_tag + 0x38)
									write_float(events_address + 0x08, 0)
									write_float(events_address + 0x0C, 0)
									write_float(events_address + 0x10, 0)
									write_float(events_address + 0x14, 0)
									
									local parts_count = read_dword(events_address + 0x2C)
									local parts_address = read_dword(events_address + 0x2C + 4)
									for l=0,parts_count-1 do
										local address = parts_address + l*104
										if l == 1 then
											local light_tag = get_tag("ligh", "effects\\lights\\coop teleport circular")
											if light_tag ~= nil then
												light_tag = read_dword(light_tag + 0x14)
												write_bit(light_tag, 1, 1)--no specular
												write_float(light_tag + 0x04, 0)--radius
												write_float(light_tag + 0x38, reticle_color_alpha/255)
												write_float(light_tag + 0x48, reticle_color_alpha/255)
												write_float(light_tag + 0x38+4, reticle_color_red/255)
												write_float(light_tag + 0x48+4, reticle_color_red/255)
												write_float(light_tag + 0x38+8, reticle_color_green/255)
												write_float(light_tag + 0x48+8, reticle_color_green/255)
												write_float(light_tag + 0x38+12, reticle_color_blue/255)
												write_float(light_tag + 0x48+12, reticle_color_blue/255)
												
												local lens_tag = get_tag("lens", "effects\\lights\\coop teleport circular")
												if lens_tag ~= nil then
													lens_tag = read_dword(lens_tag + 0x14)
													write_float(lens_tag + 0x10, reticle_occlusion)
													local reflection_address = read_dword(lens_tag + 0xC8)
													write_bit(reflection_address, 1, 1)
													write_byte(reflection_address + 0x04, reticle_type) -- bitmap index!
													write_float(reflection_address + 0x28, reticle_radius)--radius
													write_float(reflection_address + 0x2C, reticle_radius)--radius
													reticle_radius_address = reflection_address + 0x28
													write_float(reflection_address + 0x34, reticle_brightness)--brightness
													write_float(reflection_address + 0x38, reticle_brightness)--brightness
													reticle_color_address = reflection_address + 0x40
													--write_float(reflection_address + 0x40, reticle_color_alpha/255)
													--write_float(reflection_address + 0x40+4, reticle_color_red/255)
													--write_float(reflection_address + 0x40+8, reticle_color_green/255)
													--write_float(reflection_address + 0x40+12, reticle_color_blue/255)
													
													local bitmap_tag = get_tag("bitm", "ui\\hud\\bitmaps\\combined\\hud_reticles")
													if reticle_dot == true or bitmap_tag == nil then
														write_dword(lens_tag + 0x20, 0xFFFFFFFF)
														write_dword(lens_tag + 0x20 + 0xC, 0xFFFFFFFF)
													elseif bitmap_tag ~= nil then
														write_dword(lens_tag + 0x20, read_dword(bitmap_tag))
														write_dword(lens_tag + 0x20 + 0xC, read_dword(bitmap_tag + 0xC))
													end
												end
												
												write_float(light_tag + 0xF4, reticle_fade_time) --timer in ticks
												write_word(light_tag + 0xFA, 2)--very late and stuff
											end
										else
											write_dword(address + 0x18, 0xFFFFFFFF)
											write_dword(address + 0x18 + 0xC, 0xFFFFFFFF)
										end
									end
									
									local particle_count = read_dword(events_address + 0x38)
									local particle_address = read_dword(events_address + 0x38 + 4)
									for m=0,particle_count-1 do
										local address = particle_address + m*232
										write_word(address + 0x6C, 0)
										write_word(address + 0x6E, 0)
									end
								end
							end
							write_float(address + 0x0C, 0)
							write_float(address + 0x10, 0)
							write_bit(address + 0x64, 0, 0)
							write_word(address + 0x6C, reticle_count)--count
							write_word(address + 0x6C + 4, reticle_count)--count
							write_float(address + 0x84, reticle_distance)-- velocity
							write_float(address + 0x88, reticle_distance)-- velocity
							write_float(address + 0x8C, reticle_wiggle)
							reticle_wiggle_address = address + 0x8C
							write_float(address + 0xA0, 0.0001)--radius
							write_float(address + 0xA4, 0.0001)--radius
						else
							write_word(address + 0x6C, 0)
							write_word(address + 0x6E, 0)
						end
					end
				end
			end
		end
	end
	return true
end

function ReticleColor(red)
	if reticle_color_address ~= nil then
		if red then
			write_float(reticle_color_address, 0)
			write_float(reticle_color_address+4, 1)
			write_float(reticle_color_address+8, 0)
			write_float(reticle_color_address+12, 0)
		else
			write_float(reticle_color_address, reticle_color_alpha/255)
			write_float(reticle_color_address+4, reticle_color_red/255)
			write_float(reticle_color_address+8, reticle_color_green/255)
			write_float(reticle_color_address+12, reticle_color_blue/255)
		end
	end
end

function RemoveReticleGun()
	if reticle_gun ~= nil then
		if get_object(reticle_gun) ~= nil then
			delete_object(reticle_gun)
		end
		reticle_gun = nil
	end
end

function OnCommand(message)
	local message = string.lower(message)
	if message == "tp 1" then
		enable_third_person_cam = true
		ChangeSoundVolumes(sound_volume_modifier)
		RemoveCameraShake()
		ToggleScopeMasks(false)
		if get_dynamic_player() == nil then
			console_out("Third person camera enabled")
		end
		return false
	elseif message == "tp 0" then
		enable_third_person_cam = false
		if hide_reticle_hud == true then
			ReticeHud(true)
		end
		RemoveReticleGun()
		local player = get_dynamic_player()
		if player ~= nil then
			local camera_mode = read_short(camera_address)
			local vehicle = get_object(read_dword(player + 0x11C))
			if vehicle == nil and camera_mode == CAMERA.vehicle then
				write_word(camera_address, CAMERA.first_person)
			end
		else
			write_word(camera_address, CAMERA.first_person)
		end
		
		ChangeSoundVolumes(1)
		AdjustReticlePosition(0,0)
		SetBigassReticle(9999,9999, 0)
		ToggleScopeMasks(true)
		
		if get_dynamic_player() == nil then
			console_out("Third person camera disabled")
		end
		return false
	end
end

function OnUnload()
	if check_gun ~= nil then
		local object = get_object(check_gun)
		if object ~= nil then
			delete_object(check_gun)
		end
	end
	RemoveReticleGun()
	ToggleScopeMasks(true)
	ChangeSoundVolumes(1)
	AdjustReticlePosition(0,0)
	SetBigassReticle(9999,9999, 0)
end

function PlaySound(meta_id)
	if sound_address == nil then
		GetSoundAddress()
	end
	--console_out("playing sound")
	local replacement_sound = get_tag(meta_id)
	if replacement_sound ~= nil and sound_address ~= nil then
		write_dword(sound_address, read_dword(replacement_sound + 0xC))
		write_dword(announcer_address + 8, 1)
		write_dword(announcer_address + 20, 0)
		write_dword(announcer_address + 80, 2)
	end
end

function GetSoundAddress()
	ChangeSoundVolumes(sound_volume_modifier)
	
	local globals_tag = GetGlobals()
	if globals_tag ~= nil then
		local multiplayer_count = read_dword(globals_tag + 0x164)
		if multiplayer_count > 0 then
			local multiplayer = read_dword(globals_tag + 0x168)
			local sounds_count = read_dword(multiplayer + 0x5C)
			if sounds_count > 0 then
				sound_address = read_dword(multiplayer + 0x60) + 0xC
				--console_out("found sound address")
			end
		end
	end
end

function GetGlobals() -- taken from 002's headshots script
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        if tag_class == 0x6D617467 then
			--console_out("found globals")
            return read_dword(tag + 0x14)
		end
	end
	return nil
end

function ChangeSoundVolumes(amount)
	if DEFAULT_SOUND_VOLUMES == nil then
		GetSoundVolumes()
	end
	
	for address,gain in pairs(DEFAULT_SOUND_VOLUMES) do
		write_float(address, gain*amount)
	end
end

function GetSoundVolumes()
	DEFAULT_SOUND_VOLUMES = {}
	local tag_array = read_dword(0x40440000)
	local tag_count = read_dword(0x4044000C)
	for i = 0,tag_count - 1 do
		local tag = tag_array + i * 0x20
		local tag_class = read_dword(tag)
		if tag_class == 0x77656170 then
			local meta_id = read_dword(tag + 0xC)
			local weap_tag = get_tag(meta_id)
			if weap_tag ~= nil then
				weap_tag = read_dword(weap_tag + 0x14)
				local fp_anim_tag = get_tag(read_dword(weap_tag + 0x46C + 0xC))
				if fp_anim_tag ~= nil then
					fp_anim_tag = read_dword(fp_anim_tag + 0x14)
					local sound_count = read_dword(fp_anim_tag + 0x54)
					local sound_address = read_dword(fp_anim_tag + 0x58)
					for j=0,sound_count-1 do
						local sound_tag = get_tag(read_dword(read_dword(fp_anim_tag + 0x58) + j*20 + 0xC))
						if sound_tag ~= nil then
							local gain_address = read_dword(sound_tag + 0x14) + 0x28
							if DEFAULT_SOUND_VOLUMES[gain_address] == nil then
								local gain = read_float(gain_address)
								DEFAULT_SOUND_VOLUMES[gain_address] = gain
							end
						end
					end
				end
			end
		end
	end
end

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end

function ChangeCameraTrack()
	if enable_third_person_cam == false then 
		ToggleScopeMasks(true)
		return 
	else
		ToggleScopeMasks(false)
	end
	
	if find_camera_track and map_is_protected == false then
		if CheckProtection() then
			map_is_protected = true
			if debug_messages then
				console_out("map is protected")
			end
		else
			map_is_protected = false
		end
	end
	
	if false and map_is_protected then -- disabled for now
		if find_camera_track then
			local tag_array = read_dword(0x40440000)
			local tag_count = read_dword(0x4044000C)
			for i = 0,tag_count - 1 do
				local camera_tag = tag_array + i * 0x20
				local tag_class = read_dword(camera_tag)
				if tag_class == 1953653099 then
					tag = read_dword(camera_tag + 0x14)
					local control_point_count = read_dword(tag + 0x4)
					local control_point_address = read_dword(tag + 0x8)
					if control_point_count > 1 then
						local address = control_point_address
						if read_float(address) > CONTROL_POINTS[0][1] - 0.01 and read_float(address) < CONTROL_POINTS[0][1] + 0.01 then
							protected_camera_track = camera_tag
						end
					end
				end
			end
			find_camera_track = false
		end
	end
	
	if map_is_protected == false then
		local globals_tag = get_tag("matg", "globals\\globals")
		if globals_tag ~= nil then
			globals_tag = read_dword(globals_tag + 0x14)
			local camera_count = read_dword(globals_tag + 0x104)
			if camera_count > 0 then
				local camera_address = read_dword(globals_tag + 0x108)
				local camera_tag = get_tag(read_dword(camera_address + 0xC))
				if camera_tag ~= nil then
					tag = read_dword(camera_tag + 0x14)
					local control_point_count = read_dword(tag + 0x4)
					local control_point_address = read_dword(tag + 0x8)
					for i=0,control_point_count - 1 do
						local address = control_point_address + 60 * i
						write_float(address, CONTROL_POINTS[i][1]*camera_distance_multiplier + x_offset)
						write_float(address + 4, CONTROL_POINTS[i][2]*camera_distance_multiplier + y_offset)
						write_float(address + 8, CONTROL_POINTS[i][3]*camera_distance_multiplier + z_offset)
					end
				end
			end
		end
	end
	
	local player = get_dynamic_player()
	if player ~= nil then
		local player_biped_tag = get_tag(read_dword(player))
		if player_biped_tag ~= nil then
			player_biped_tag = read_dword(player_biped_tag + 0x14)
			local camera_count = read_dword(player_biped_tag + 0x1F4)
			if camera_count > 0 and camera_count < 256 then
				local camera_address = read_dword(player_biped_tag + 0x1F4 + 4)
				local tag = get_tag(read_dword(camera_address + 0xC))
				if tag ~= nil then --or protected_camera_track ~= nil then
					--if map_is_protected then
					--	tag = protected_camera_track
					--end
					tag = read_dword(tag + 0x14)
					local control_point_count = read_dword(tag + 0x4)
					local control_point_address = read_dword(tag + 0x8)
					for i=0,control_point_count - 1 do
						local address = control_point_address + 60 * i
						write_float(address, CONTROL_POINTS[i][1]*camera_distance_multiplier + x_offset)
						write_float(address + 4, CONTROL_POINTS[i][2]*camera_distance_multiplier + y_offset)
						write_float(address + 8, CONTROL_POINTS[i][3]*camera_distance_multiplier + z_offset)
					end
				end
			end
		end
	end
	
	return false
end

function GetDistance(object, object2, camera_height)
	local x = read_float(object + 0x5C)
	local y = read_float(object + 0x60)
	local z = read_float(object + 0x64)
	local x1 = read_float(object2 + 0x5C)
	local y1 = read_float(object2 + 0x60)
	local z1 = read_float(object2 + 0x64) + camera_height
	local vehicle_id = read_u32(object + 0x11C)
	if vehicle_id ~= 0xFFFFFFFF then
		local vehicle = get_object(vehicle_id)
		if vehicle ~= nil then
			-- this part isn't correct but not sure how to improve it...
			--x = read_float(object + 0xA8)
			--y = read_float(object + 0xA4)
			--z = read_float(object + 0xA8)
			--x = read_float(object + 0x5C)
			--y = read_float(object + 0x60)
			--z = read_float(object + 0x64)
			x = read_float(vehicle + 0x5C)
			y = read_float(vehicle + 0x60)
			z = read_float(vehicle + 0x64)
		end
	end
	local x_dist = x1 - x
	local y_dist = y1 - y
	local z_dist = z1 - z
	return sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
end

function FindEquip()
	local tag_array = read_dword(0x40440000)
    local tag_count = read_dword(0x4044000C)
    for i = 0,tag_count - 1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        if tag_class == 0x65716970 then
			return read_string(read_dword(tag + 0x10))
		end
    end
end

function CheckProtection()
	if get_tag("proj", "altis\\effects\\distance_check") ~= nil then
		bigassv3 = true
	else
		bigassv3 = false
	end
	
	local tag_array = read_dword(0x40440000)
    local tag_count = read_dword(0x4044000C)
	if tag_count > 50 then
		tag_count = 50
	end
    for i = 0,tag_count - 1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        local tag_path = read_string(read_dword(tag + 0x10))
        for k = 0,i - 1 do
            local tag_k = tag_array + k * 0x20
            if read_dword(tag_k) == tag_class and read_string(read_dword(tag_k + 0x10)) == tag_path and tag_path ~= "MISSINGNO." then
                return true
            end
        end
    end
    return false
end

function ScriptLoaded() -- check if camera is already in third person when script is unloaded
	local player = get_dynamic_player()
	if player ~= nil and get_object(read_dword(player + 0x11C)) == nil then
		if read_word(camera_address) == CAMERA.vehicle then
			OnCommand("tp 1")
		end
	end
end

ScriptLoaded()