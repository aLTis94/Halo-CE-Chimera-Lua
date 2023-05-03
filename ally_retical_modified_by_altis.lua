-- Ally reticle color enabler by IceCrow14 v.2.1
-- This script will change your current weapon reticle's color to green whenever you aim at an allied player (doesn't work for NPCs)

--CONFIG
	
	local use_in_same_vehicle = true
	local sensitivity = 0.028 -- Max
	local baseline_sensitivity = 0.003 -- Minimum for distance scaling.
	
--END OF CONFIG

-- [[ Modified by Devieth ]] --
-- [[ Modified by aLTis ]] --

-- Changes by aLTis:
--	More accurate (based on position of each bone)
--	Works on protected maps
--	Works in vehicles
--	Doesn't turn green through walls
--	Works with reticles that use multiple bitmaps
--	Fixes a glitch where reticles became permamently green after reloading Chimera lua

--	2.1 changes:
--	Added support for holograms in Bigass V3
--	Fixed reticle in vehicles without a weapon
--	Reticle no longer turns green when aiming at teammates inside the same vehicle (optional variable use_in_same_vehicle)
--	Possibly fixed that could occur if your teammate has a biped with a different skeleton

-- Known issues:
--	Name of the player you're aiming at appears faster than before

-- To do:
--	Make it work on SP?

clua_version = 2.042

set_callback("tick","OnTick")
set_callback("precamera", "OnCamera")
set_callback("map load","OnGameStart")
set_callback("unload", "OnUnload")

local color_addresses = {}
local r_values = {}
local g_values = {}
local b_values = {}
local current_tag_ID = 0
local object_table = read_dword(read_dword(0x401194))

-- should speed up the script a bit
local abs = math.abs
local sqrt = math.sqrt
local floor = math.floor
local insert = table.insert

function OnGameStart()
	color_addresses = {}
	r_values = {}
	g_values = {}
	b_values = {}
	current_tag_ID = 0
	GetHoloTags()
end

function OnUnload() -- reset to default colors if chimera lua was reloaded
	dl_player = get_dynamic_player()
	if dl_player then
		local obj_ID = read_dword(dl_player + 0x118)
		local obj_ma = get_object(obj_ID)
		local vehicle = get_object(read_dword(dl_player + 0x11C))
		if vehicle then
			obj_ma = get_object(read_dword(vehicle + 0x2F8))
		end
		if obj_ma and read_word(obj_ma + 0xB4) == 2 then
			local obj_tag_ID = read_dword(obj_ma)
			if obj_tag_ID == current_tag_ID then
				for i = 1,#color_addresses do
					write_byte(color_addresses[i], b_values[i])
					write_byte(color_addresses[i] + 0x1, g_values[i])
					write_byte(color_addresses[i] + 0x2, r_values[i])
				end
			end
		end
	end
end

function OnTick()
	if server_type == "none" then return end
	local gametype_team_play = read_byte(0x68CC48 + 0x34)
	if gametype_team_play == 0 then return end
	dl_player = get_dynamic_player()
	if dl_player then -- [[ Removed "~= nil", 0 and nil are both considered "false" (continued this for ever other occurrence.) ]] --
		local obj_ID = read_dword(dl_player + 0x118) -- [[ Changed this (reduced lines.) ]] --
		local obj_ma = get_object(obj_ID)
		local vehicle = get_object(read_dword(dl_player + 0x11C)) -- makes it work in vehicles too
		if vehicle then
			local vehicle_weapon = get_object(read_dword(vehicle + 0x2F8))
			if vehicle_weapon then	--	Only assign vehicle's weapon if it has one to begin with
				obj_ma = vehicle_weapon
			end
		end
		
		if obj_ma and read_word(obj_ma + 0xB4) == 2 then
			local obj_tag_ID = read_dword(obj_ma)
			local obj_tag_ma = get_tag(obj_tag_ID)
			if obj_tag_ID ~= current_tag_ID then
				local tag_data = read_dword(obj_tag_ma + 0x14)
				local hud_ui_dpdc = read_dword(tag_data + 0x480)
				local hud_ui_dpdc_path = read_dword(tag_data + 0x480 + 0xC) -- using tag id instead of string to make this work on protected maps
				CheckTags(obj_ma, hud_ui_dpdc_path, 0)
				current_tag_ID = obj_tag_ID
			elseif obj_tag_ID then -- TESTING! If the weapon's data has already been registered...
				local friendly_targeted = TargetPlayer()
				-- For Bigass V3 holograms
				if friendly_targeted == false and string.find(map, "bigass") then
					friendly_targeted = BigassHolograms()
				end
				
				if friendly_targeted then
					for i = 1,#color_addresses do
						write_byte(color_addresses[i], 0)
						write_byte(color_addresses[i] + 0x1, 255)
						write_byte(color_addresses[i] + 0x2, 0)
					end
				else
					for i = 1,#color_addresses do
						write_byte(color_addresses[i], b_values[i])
						write_byte(color_addresses[i] + 0x1, g_values[i])
						write_byte(color_addresses[i] + 0x2, r_values[i])
					end
				end
			end
		end
	end
end

function CheckTags(obj_ma, hud_ui_dpdc_path, count)
	if hud_ui_dpdc_path ~= 0xFFFFFFFF and count < 6 then
		local hui_tag_ma = get_tag(hud_ui_dpdc_path)
		if hui_tag_ma then
			local hui_tag_data = read_dword(hui_tag_ma + 0x14)
			
			CheckTags(obj_ma, read_dword(hui_tag_data + 0xC), count + 1) -- in case child tags have reticles too
			
			local crosshairs_rfx_count = read_dword(hui_tag_data + 0x84)
			--console_out("Weapon picked up "..GetName(obj_ma))
			--console_out(crosshairs_rfx_count.." crosshairs")
			for j=0,crosshairs_rfx_count-1 do -- Now using all crosshairs
				local crosshairs_rfx_size = 104
				local crosshairs_rfx = read_dword(hui_tag_data + 0x84 + 4) + j*104
				local ch_ols_rfx_count = read_dword(crosshairs_rfx + 0x34)
				if ch_ols_rfx_count > 0 then
					local ch_ols_rfx = read_dword(crosshairs_rfx + 0x34 + 4)
					local dchc_ma = ch_ols_rfx + 0x24 -- Default crosshair color Color byte address
					local dcb = read_byte(dchc_ma) -- Color byte format: B, G, R, A
					local dcg = read_byte(dchc_ma + 0x1)
					local dcr = read_byte(dchc_ma + 0x2)
					local dcalpha = read_byte(dchc_ma + 0x3)
					local offset_x = read_short(ch_ols_rfx)
					local offset_y = read_short(ch_ols_rfx + 0x2)
					-- TESTING!
					if (dcb==0 and dcg==0 and dcr==0) == false and abs(offset_x) < 50 and abs(offset_y) < 50 then -- ignore zoom masks
						local stored = false
						for i = 1,#color_addresses do
							if color_addresses[i] == dchc_ma then
								stored = true
							end
						end
						if stored == false then
							insert(r_values,dcr)
							insert(g_values,dcg)
							insert(b_values,dcb)
							insert(color_addresses,dchc_ma) -- ONLY THE ADDRESS FOR THE BLUE VALUE WILL BE ADDED
						end
					end
				end
			end
		end
	end
end

function BigassHolograms()
	if holo_tags == nil then
		GetHoloTags()
		return false
	else
		local object_count = read_word(object_table + 0x2E)
		local first_object = read_dword(object_table + 0x34)
		
		for i=0,object_count-1 do
			local object = read_dword(first_object + i * 0xC + 0x8)
			if object ~= 0 then
				if read_word(object + 0xB4) == 1 then
					local meta_id = read_dword(object)
					if holo_tags[meta_id] == 1 then
						
						if read_float(dl_player + 0x1D0)==read_float(object + 0x1D0) and read_float(dl_player + 0x1D4)==read_float(object + 0x1D4) and read_float(dl_player + 0x1D8)==read_float(object + 0x1D8) then
							--console_out("color match")
							if IsLookingAt(object, 0x5C0) then
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end

function GetHoloTags()
	local hologram_tag_red = get_tag("vehi", "armor_abilities\\hologram\\hologram_red")
	local hologram_tag_blue = get_tag("vehi", "armor_abilities\\hologram\\hologram_blue")
	local hologram_tag_red_idle = get_tag("vehi", "armor_abilities\\hologram\\hologram_idle_red")
	local hologram_tag_blue_idle = get_tag("vehi", "armor_abilities\\hologram\\hologram_idle_blue")
	if hologram_tag_red and hologram_tag_red_idle then
		holo_tags = {
			[read_dword(hologram_tag_red + 0xC)] = 1,
			[read_dword(hologram_tag_blue + 0xC)] = 1,
			[read_dword(hologram_tag_red_idle + 0xC)] = 1,
			[read_dword(hologram_tag_blue_idle + 0xC)] = 1,
		}
	end
end

function TargetPlayer() -- checks if player name should be displayed to avoid reticle turning green through walls
	m_player = get_player()
	if m_player then
		local target_player = read_dword(m_player + 0x7C)
		if target_player ~= 0xFFFFFFFF then
			return CheckPlayers(target_player%0x100)
		else
			write_dword(m_player + 0x80, 0)
		end
	end
	return false
end

function CheckPlayers(Target)
	if player_x == nil then
		return false
	end
	local m_player = get_player()
	local m_target_player = get_player(Target)
	local m_object = get_dynamic_player()
	local m_target_object = get_dynamic_player(Target)
	if m_target_object and m_object then -- Both players need to be alive.
		if read_byte(m_player + 0x67) ~= read_byte(m_target_player + 0x67) then -- Make sure the target is not the local player.
			if read_byte(m_target_player + 0x20) == read_byte(m_player + 0x20) then -- Make sure they are on the same team
			
				if use_in_same_vehicle then-- Check if both players are inside the same vehicle
					local vehicle = read_dword(m_object + 0x11C)
					local vehicle_target = read_dword(m_target_object + 0x11C)
					if vehicle ~= 0xFFFFFFFF and vehicle == vehicle_target then return false end
					
					
					if IsLookingAt(m_target_object, 0x550) then
						return true
					end
				end
			end
		end
	end
	return false
end

-- [[ IsLookingAt function added by Devieth. ]] --

function IsLookingAt(m_target_object, node_address)
	local biped_tag = read_dword(get_tag(read_dword(m_target_object)) + 0x14)
	local biped_model_tag = read_dword(get_tag(read_dword(biped_tag + 0x28 + 0xC)) + 0x14)
	local node_count = read_word(biped_model_tag + 0x1C)

	for i=0,node_count-1 do
		local target_x, target_y, target_z = read_vector3d(m_target_object + node_address + 0x34*i + 0x28)-- use position of nodes. This will be more accurate and work in vehicles
		local distance = sqrt((target_x - player_x)^2 + (target_y - player_y)^2 + (target_z - player_z)^2) -- 3d distance
		
		if distance > 50 then
			return false
		end

		local local_x = target_x - player_x
		local local_y = target_y - player_y
		local local_z = target_z - player_z

		local point_x = 1 / distance * local_x
		local point_y = 1 / distance * local_y
		local point_z = 1 / distance * local_z

		local x_diff = abs(camera_x - point_x)
		local y_diff = abs(camera_y - point_y)
		local z_diff = abs(camera_z - point_z)

		local average = (x_diff + y_diff + z_diff) / 3
		local scaler = 0
		if distance > 1 then scaler = floor(distance) / 1000 end
		local auto_aim = sensitivity - scaler
		if auto_aim < baseline_sensitivity then auto_aim = baseline_sensitivity end
		if average < auto_aim then
			return true
		end
	end
	return false
end

function OnCamera(x, y, z, fov, x1, y1, z1, x2, y2, z2) -- using camera position instead of player position to make it work in vehicles
	player_x = x
	player_y = y
	player_z = z
	camera_x = x1
	camera_y = y1
	camera_z = z1
end

function read_vector3d(Address) -- [[ Read vector3d function ]] --
	return read_float(Address), read_float(Address+0x4), read_float(Address+0x8)
end

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end