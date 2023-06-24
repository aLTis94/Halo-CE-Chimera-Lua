-- version 2023-04-23
-- third person camera script by aLTis              
-- Use numpad keys to adjust position of the camera. Press end to toggle third person camera.

--CONFIG
	
	enable_third_person_cam = false -- default setting for when you start the game
	
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
		smooth_zoom_speed = 0.08	-- change how fast smooth zoom changes fov
	
	-- RETICLE
		second_reticle = true 		 --	another reticle that shows where shots will actually land (for most multiplayer maps)
		second_reticle_bigass = true -- another reticle that shows where shots will actually land (for bigass v3)
		
		hide_reticle_hud = true
		hide_multitex_overlay_hud = true -- hides stuff like dynamic reticles in some maps (if above is true)
		adjust_reticle_position = true	-- changes where the reticle is based on your camera offset
		adjust_reticle_amount = 4		-- how far reticle moves
	
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
--fix when third_person_zoom = false
--should cancel weapon animations when switching weapon
--animations get broken in some custom maps like snowcast (fixed?)
--reload animation doesn't play sometimes

--CHANGELOG
-- 2023-04-19 changes:
-- second reticle in bigass will now turn red if aiming at an enemy and green if ally

-- 2023-04-23 changes:
-- fixed compability with balltze

-- 2023-05-12
-- replaced second reticle with a better alternative
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
local mouse_input_address = 0x64C73C
local announcer_address = 0x64C020
local fp_anim_address = 0x40000EB8
local hud_address = 0x400007F4

local sqrt = math.sqrt
local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local find = string.find

local pi = math.pi
local atan = math.atan
local tan = math.tan
local sin = math.sin
local cos = math.cos
local rad = math.rad

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
local offset_amount = 0.37 -- was 33
local PROJECTILE = {}

local changed = false
local needle_found = false

function OnMapLoad()
	if debug_messages then
		console_out("If you encounter a glitch or a crash then tell aLTis")
	end
	
	DEFAULT_SOUND_VOLUMES = nil
	SCOPE_MASKS = nil
	RETICLE_POSITIONS = nil
	
	sound_address = nil
	check_gun = nil
	protected_camera_track = nil
	find_camera_track = true
	map_is_protected = false
	changed = false
	needle_found = false
	PROJECTILE = {}
	set_timer(600, "ChangeCameraTrack")
	set_timer(700, "RemoveCameraShake")
end

function OnCamera(x, y, z, fov, x1, y1, z1, x2, y2, z2)
	player = get_dynamic_player()
	
	-- HOTKEYS
	local chat_is_open = read_byte(0x0064E788)
	if chat_is_open == 0 and console_is_open() == false and player ~= nil then
		if read_byte(keyboard_input_address + 85) == 1 or (toggle_tp_mouse_key ~= -1 and read_byte(mouse_input_address + 13 + toggle_tp_mouse_key) == 1) then
			if enable_third_person_cam then
				OnCommand("tp 0")
			else
				OnCommand("tp 1")
			end
		end
		if enable_third_person_cam then
			if read_byte(keyboard_input_address + 99) == 1 or (switch_directions_mouse_key ~= -1 and read_byte(mouse_input_address + 13 + switch_directions_mouse_key) == 1) then
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
		
			if reticle_is_red then
				write_dword(hud_address+216, 1)
			else
				write_dword(hud_address+216, 0)
			end
		
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
					
					-- SECOND RETICLE
					if (needle_found or bigassv3) and player_x ~= nil then
						
						for projectile_spawn_time, proj in pairs (PROJECTILE) do
							local time_since_spawn = ticks() - projectile_spawn_time
							local object = get_object(proj)
							if time_since_spawn > 1 then
								if object then
									
									local bitmap = 0
									local color = GetReticleColor(object)
									local x2 = read_float(object + 0x2B0+0x28)
									local y2 = read_float(object + 0x2B0+0x2C)
									local z2 = read_float(object + 0x2B0+0x30)
									local parent = get_object(read_dword(object + 0x11C))
									if parent then
										local node = parent + 0x550 + read_dword(object + 0x120) * 0x34
										--console_out(read_dword(object + 0x120))
										x2 = read_float(node+0x28)
										y2 = read_float(node+0x2C)
										z2 = read_float(node+0x30)
									else
										--local dist = sqrt((x2-player_x)*(x2-player_x) + (y2-player_y)*(y2-player_y) + (z2-player_z)*(z2-player_z))
										local dist = read_float(object + 0x250)
										if dist < 1 then
											bitmap = 1
										end
										
										--console_out(dist)
									end
									
									FindProjectilePosition(x-x2, y-y2, z-z2, bitmap, color)
									delete_object(proj)
								else
									--console_out(time_since_spawn)
									FindProjectilePosition(x - player_x - camera_x1*offset_amount, y - player_y - camera_y1*offset_amount, z - player_z - camera_z1*offset_amount, 1)
								end
								
								PROJECTILE[projectile_spawn_time] = nil
							else
								--console_out(time_since_spawn)
							end
						end
						
						SpawnProjectile()
					end
					
					
					
					previous_zoom_level = zoom_level
					current_fov = new_fov
					return x, y, z, new_fov, x1, y1, z1, x2, y2, z2
				else
					DeleteProjectiles()
				end
				
			else
				DeleteProjectiles()
				if check_gun ~= nil then
					local object = get_object(check_gun)
					if object ~= nil then
						delete_object(check_gun)
					end
					check_gun = nil
				end
			end
		end
	end
	return x, y, z, fov, x1, y1, z1, x2, y2, z2
end

function DeleteProjectiles()
	for projectile_spawn_time, proj in pairs (PROJECTILE) do
		local object = get_object(proj)
		if object then
			local obj_type = read_word(object + 0xB4)
			if obj_type == 5 then
				--console_out("deleted projectile")
				delete_object(proj)
			end
		end
		--console_out("removed projectile")
		PROJECTILE[projectile_spawn_time] = nil
	end
end

function GetReticleColor(object)
	local parent = get_object(read_dword(object + 0x11C))
	local color = "blue"
	if parent ~= nil then
		local player_team = read_word(player + 0xB8)
		--console_out(player_team)
		local grandparent = get_object(read_dword(parent + 0x11C))
		if grandparent then
			parent = grandparent
		end
		
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
	
	return color
end

function FindProjectilePosition(x, y, z, bitmap, color)
	--if bitmap == 1 then
	--	SetBigassReticle(0, 0, bitmap, color)
	--	return
	--end
	CalculateFov(new_fov)
	local ssx, ssy = FindSunInScreenSpace(x,y,z, 0, 0, 0, camera_x1, camera_y1, camera_z1, vertical_fov)
	
	local some_offset_idk_lol = 9
	local some_offset_idk_lol2 = 5
	if build > 0 then
		some_offset_idk_lol = 7.5
		some_offset_idk_lol2 = 4.2
	end
	
	ssx = -floor((50-ssx*100)*some_offset_idk_lol)
	ssy = floor((50-ssy*100)*some_offset_idk_lol2)
	
	
	-- ADJUST FOR MOUSE INPUT TO PREDICT RETICLE POSITION
	local chat_is_closed = read_byte(0x0064E788) ~= 1
	local game_paused = read_byte(0x622058) == 1
	
	if chat_is_closed and game_paused and bitmap == 0 then
		local ehh = 1
		local mouse_right = read_long(mouse_input_address)
		local mouse_up = read_long(mouse_input_address+4)
		
		if FML then
			local avg_right = 0
			local avg_up = 0
			for i=0,#FML-1 do
				avg_right = avg_right + i
				if i < #FML then
					FML[i] = FML[i+1]
				else
					FML[i] = mouse_right
				end
				
				if i < #FML2 then
					FML2[i] = FML2[i+1]
				else
					FML2[i] = mouse_up
				end
			end
			mouse_right = (mouse_right + avg_right)/(#FML)
			mouse_up = (mouse_up + avg_up)/(#FML2)
		else
			FML = {}
			FML2 = {}
			for i=0,1 do
				FML[i] = 0;
				FML2[i] = 0;
			end
		end
		
		ssx = floor(ssx + mouse_right*ehh)
		ssy = floor(ssy - mouse_up*ehh)
	end
	
	SetBigassReticle(ssx, ssy, bitmap, color)
end

function SpawnProjectile()
	if player_x == nil then return end
	
	local new_proj
	
	if bigassv3 then
		new_proj = spawn_object("proj", "altis\\effects\\distance_check", player_x + player_x_vel +  camera_x1*offset_amount, player_y + player_y_vel + camera_y1*offset_amount, player_z + player_z_vel + camera_z1*offset_amount)
	else
		new_proj = spawn_object("proj", "weapons\\needler\\needle", player_x +  camera_x1*offset_amount, player_y + camera_y1*offset_amount, player_z + camera_z1*offset_amount)
	end
	local object = get_object(new_proj)
	if object ~= nil then
		local projectile_velocity = 75
		write_float(object + 0x68, camera_x1 * projectile_velocity)
		write_float(object + 0x6C, camera_y1 * projectile_velocity)
		write_float(object + 0x70, camera_z1 * projectile_velocity)
		write_float(object + 0x254, camera_x1 * projectile_velocity)
		write_float(object + 0x258, camera_y1 * projectile_velocity)
		write_float(object + 0x25C, camera_z1 * projectile_velocity)
		--projectile_spawn_time = ticks()
	else
		new_proj = nil
	end
	
	if new_proj then
		PROJECTILE[ticks()] = new_proj
	end
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
				
				DeleteProjectiles()
				SetBigassReticle(9999,9999, 0)
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
				end
			else
				player_x = nil
			end
			
			BigassReticle()
		else
			player_x = nil
		end
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

function BigassReticle()
	if (needle_found == false and bigassv3 == false) or camera_x1 == nil or player_x == nil then return end
	
	local weapon_slot = read_byte(player + 0x2F4)
	local weapon_id = read_dword(player + 0x2F8 + weapon_slot * 4)
	local object = get_object(weapon_id)
	if vehicle ~= nil or object == nil or CheckBigassWeapons(GetName(object)) then
	
		SetBigassReticle(9999,9999, 0)
	--	if projectile ~= nil and get_object(projectile) ~= nil then
	--		delete_object(projectile)
	--		projectile = nil
	--	end
	--elseif projectile ~= nil and get_object(projectile) ~= nil then
	
	--else
		
		
	end
end

function SetBigassReticle(x, z, bitmap, color)
	--if true then return end
	local tag = get_tag("unhi", "bourrin\\hud\\h1 symmetrical")
	local needle = false
	if tag == nil then
		tag = get_tag("unhi", "ui\\hud\\cyborg")
		needle = true
	end
	if tag ~= nil then
		tag = read_dword(tag + 0x14)
		
		--Chimera 1.0 hud scaling fix
		if build > 0 and x ~= 9999 then
			if x > 160 then
				x = 160
			elseif x < -160 then
				x = -160
			end
			
			if z > 165 then
				z = 165
			elseif z < -165 then
				z = -165
			end
		end
		
		if needle then
			x = 298-x
			z = 218+z
		end
		
		write_short(tag + 0x24, x)
		write_short(tag + 0x26, z)
		
		if bigassv3 then
			write_short(tag + 0x78, bitmap)
		end
		
		if color == "red" then
			reticle_is_red = true
		else
			reticle_is_red = false
		end
		
		if bitmap == 0 then
			if color == nil or color == "blue" then
				WriteColor(tag + 0x58, 255, 150, 40, 100)
			elseif color == "red" then
				WriteColor(tag + 0x58, 0, 0, 255, 100)
			else
				WriteColor(tag + 0x58, 0, 255, 0, 100)
			end
		else
			WriteColor(tag + 0x58, 0, 60, 255, 255)
		end
	end
end

function WriteColor(address, blue, green, red, alpha)
	write_byte(address, blue)
	write_byte(address+1, green)
	write_byte(address+2, red)
	if alpha ~= nil then
		write_byte(address+3, alpha)
	end
end

function ReticeHud(show)
	if map_is_protected or (needle_found == false and second_reticle) then 
		show = true
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

function GetBitmapScale(id, bitmap)
	local bitmap_tag = read_dword(bitmap + 0x14)
	local count = read_dword(bitmap_tag + 0x60)
	if id > count then
		return 1
	end
	local address = read_dword(bitmap_tag + 0x64)
	local struct = address + id*48
	return 64/read_word(struct + 0x04)
end

function PrepareNeedlerTags()
	if second_reticle == false or map_is_protected or bigassv3 or needle_found or server_type == "none" then
		return false
	end
	
	local proj_tag = get_tag("proj", "weapons\\needler\\needle")
	local hud_tag = get_tag("unhi", "ui\\hud\\cyborg")
	local bitmap_tag = get_tag("bitm", "ui\\hud\\bitmaps\\combined\\hud_reticles")
	
	local hd_bitmap = false
	if bitmap_tag == nil then
		bitmap_tag = get_tag("bitm", "ui\\hud\\hrx_bitmaps\\hrx_crosshairs\\hrx_crosshairs")
		if bitmap_tag then
			hd_bitmap = true
		end
	end
	
	if proj_tag and hud_tag and bitmap_tag then
		needle_found = true
		--console_out("needler :)")
		local bitmap_scale = GetBitmapScale(7, bitmap_tag)
		
		local tag = read_dword(proj_tag + 0x14)
		hud_tag = read_dword(hud_tag + 0x14)
		local tag_name = read_dword(bitmap_tag + 0x10)
		bitmap_tag = read_dword(bitmap_tag + 0xC)
		write_dword(hud_tag + 0x48 + 0xC, bitmap_tag)
		write_dword(hud_tag + 0x4C, tag_name)
		write_float(hud_tag + 0x28, bitmap_scale) -- width
		write_float(hud_tag + 0x2C, bitmap_scale) -- height
		write_short(hud_tag + 0x24, 298)
		write_short(hud_tag + 0x26, 219)
		write_short(hud_tag + 0x78, 7)
		
		write_dword(tag + 0x28 + 0xC, 0xFFFFFFFF) -- model
		write_dword(tag + 0x140, 0) -- attachments
		write_dword(tag + 0x14C, 0) -- widgets
		write_word(tag + 0x180, 0) -- detonation timer starts
		write_word(tag + 0x182, 0) -- projectile impact noise
		write_dword(tag + 0x18C + 0xC, 0xFFFFFFFF) -- super detonation
		write_dword(tag + 0x1AC + 0xC, 0xFFFFFFFF) -- detonation effect
		write_float(tag + 0x1C4, 0) -- minimum velocity
		write_float(tag + 0x1BC, 0.3) -- timer from
		write_float(tag + 0x1C0, 0.3) -- timer to
		write_float(tag + 0x1C8, 10000) -- max range
		write_float(tag + 0x1EC, 0) -- guided veolicty
		write_dword(tag + 0x204 + 0xC, 0xFFFFFFFF) -- flyby sound
		write_dword(tag + 0x214 + 0xC, 0xFFFFFFFF) -- attached detonation
		write_dword(tag + 0x224 + 0xC, 0xFFFFFFFF) -- impact damage
		
		local response_count = read_dword(tag + 0x240 + 0)
		local response_address = read_dword(tag + 0x240 + 4)
		for i=0,response_count-1 do
			local struct = response_address + i*160
			write_dword(struct + 0x04 + 0xC, 0xFFFFFFFF) -- default effect
			write_dword(struct + 0x3C + 0xC, 0xFFFFFFFF) -- potential effect
			write_float(struct + 0x90, 1) -- initial friction
			write_float(struct + 0x98, 1) -- parallel friction
			write_float(struct + 0x9C, 1) -- perpendicular friction
			if i == 21 or i == 22 then -- if cyborg
				write_word(struct + 0x02, 4) -- default response
				write_word(struct + 0x24, 4) -- potential response
			else
				write_word(struct + 0x02, 2) -- default response
				write_word(struct + 0x24, 2) -- potential response
			end
		end
	else
		--no needler :(
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
		
		DeleteProjectiles()
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
	DeleteProjectiles()
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
		return 
	end
	
	if changed == false then
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
		
		PrepareNeedlerTags()
		
		changed = true
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
	if get_tag("proj", "altis\\effects\\distance_check") ~= nil and second_reticle_bigass then
		bigassv3 = true
	else
		bigassv3 = false
	end
	
	PrepareNeedlerTags()
	
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

function CalculateFov(fov)
	local screen_h = read_word(0x637CF0)
	local screen_w = read_word(0x637CF2)
	aspect_ratio = screen_w/screen_h
	fov = fov*180/pi
	vertical_fov = atan(tan(fov*pi/360) * (1/aspect_ratio)) * 360/pi
	vertical_fov = vertical_fov * 0.9
end

function FindSunInScreenSpace(x, y, z, eye_x, eye_y, eye_z, look_x, look_y, look_z, fovy)
	local view_xy = 0
	local view_w = 1 --1.12
	local view_h = 1 --1.12
		
	local eye = {}
	eye.x = eye_x
	eye.y = eye_y
	eye.z = eye_z
	local lookat = {}
	lookat.x = look_x
	lookat.y = look_y
	lookat.z = look_z
	local view  = new()
	local up = {}
	up.x, up.y, up.z = 0, 0, 1
	local aspect = aspect_ratio
	local near = 0.000001
	local far = 1000000
	view = look_at(view, eye, lookat, up)
	projection = from_perspective(fovy, aspect, near, far)
	viewport = {view_xy, view_xy, view_w, view_h}
	return project(x, y, z, view, projection, viewport)
end

function project(x, y, z, view, projection, viewport)
	local position = { x, y, z, 1 }
	
	mul_vec4(position, view,       position)
	mul_vec4(position, projection, position)
	
	if position[4] ~= 0 then
		position[1] = position[1] / position[4] * 0.5 + 0.5
		position[2] = position[2] / position[4] * 0.5 + 0.5
		position[3] = position[3] / position[4] * 0.5 + 0.5
	end
	
	position[1] = position[1] * viewport[3] + viewport[1]
	position[2] = position[2] * viewport[4] + viewport[2]
	return position[1], position[2], position[3]
end

function mul_vec4(out, a, b)
	local tv4 = { 0, 0, 0, 0 }
	tv4[1] = b[1] * a[1] + b[2] * a[5] + b [3] * a[9]  + b[4] * a[13]
	tv4[2] = b[1] * a[2] + b[2] * a[6] + b [3] * a[10] + b[4] * a[14]
	tv4[3] = b[1] * a[3] + b[2] * a[7] + b [3] * a[11] + b[4] * a[15]
	tv4[4] = b[1] * a[4] + b[2] * a[8] + b [3] * a[12] + b[4] * a[16]

	for i=1, 4 do
		out[i] = tv4[i]
	end
	
	return out
end

function look_at(out, eye, lookat, up)
	eye.x = eye.x - lookat.x
	eye.y = eye.y - lookat.y
	eye.z = eye.z - lookat.z
	local z_axis = normalize(eye)
	local x_axis = normalize(cross(up, z_axis))
	local y_axis = cross(z_axis, x_axis)
	out[1] = x_axis.x
	out[2] = y_axis.x
	out[3] = z_axis.x
	out[4] = 0
	out[5] = x_axis.y
	out[6] = y_axis.y
	out[7] = z_axis.y
	out[8] = 0
	out[9] = x_axis.z
	out[10] = y_axis.z
	out[11] = z_axis.z
	out[12] = 0
	out[13] = 0
	out[14] = 0
	out[15] = 0
	out[16] = 1

  return out
end

function normalize(a)
	if is_zero(a) then
		return new_v3()
	end
	return scale(a, (1 / len(a)))
end

function len(a)
	return sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end

function scale(a, b)
	return new_v3(
		a.x * b,
		a.y * b,
		a.z * b
	)
end

function is_zero(a)
	return a.x == 0 and a.y == 0 and a.z == 0
end

function cross(a, b)
	return new_v3(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

function from_perspective(fovy, aspect, near, far)
	assert(aspect ~= 0)
	assert(near   ~= far)

	local t   = tan(rad(fovy) / 2)
	local out = new()
	out[1]    =  1 / (t * aspect)
	out[6]    =  1 / t
	out[11]   = -(far + near) / (far - near)
	out[12]   = -1
	out[15]   = -(2 * far * near) / (far - near)
	out[16]   =  0
	
	return out
end

function new_v3(x, y, z)
	return {
		x = x or 0,
		y = y or 0,
		z = z or 0
	}
end

function new(m)
	m = m or {
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0
	}
	return m
end