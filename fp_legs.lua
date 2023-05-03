clua_version = 2.042

-- First person legs script by aLTis (altis94@gmail.com, aLTis#3828)
-- 2023-04-28

--CONFIG
	debug_mode = false			-- makes legs visible in third person
	
	fp_legs_enabled = true

	tag_type = "bipd" 			-- for spv3 use "weap", else use "bipd"
	offset_from_camera = 7 		-- recommended 4-7, depends on player's FOV
	dynamic_offset = 0			-- adds to the above value depending on how low the player is aiming (se to 0 to disable)
	velocity_offset = 0 		-- from 0 to 1. How close legs stay behind the player when player moves
	torso_offset = 1.2 		-- how far back is the torso of the body. higher means less clipping in but worse shadow (should be 1.2)
	biped_radius = 10 			-- render radius
	biped_collision_radius = 0.002 -- too low will make legs disappear, too high will let you melee your own legs
	biped_z_offset = 0 			-- idk
	
	-- list the maps in which you don't want this script to run. Some bipeds have different skeletons (it doesn't work on protected maps)
	BLACKLIST = {
		["precipice"] = true,
	}
--END OF CONFIG

--CHANGELOG:
-- 2023-04-28
-- fixed a bug that showed damage effects if you entered a vehicle sometimes
-- fixed a bug that sometimes showed you legs in third person for a second when you spawn

--todo:
--disable for flying bipeds?

fp_legs_vehicle_timer = 0
new_biped = true
previous_biped_tag_id = nil
node_count = 18

set_callback("tick", "OnTick")
set_callback("map load", "OnMapLoad")
set_callback("unload", "OnUnload")
set_callback("command", "OnCommand")

local new_chimera = false
if build > 0 then
	new_chimera = true
	velocity_offset = 1
end


if tag_type == "bipd" then
	object_tag_type = 0
else
	object_tag_type = 2
end

function OnMapLoad()
	new_biped = true
	protected_map = MapIsProtected()
end

function OnCommand(message)
	message = string.lower(message)
	if message == "fp_legs 1" then
		if fp_legs_enabled == false then
			fp_legs_enabled = true
			console_out("FP legs enabled")
			return false
		else
			console_out("FP legs are already enabled")
			return false
		end
	end
	
	if message == "fp_legs 0" then
		if fp_legs_enabled == true then
			fp_legs_enabled = false
			console_out("FP legs disabled")
			if legs_biped ~= nil then
				if get_object(legs_biped) ~= nil then
					delete_object(legs_biped)
				end
			end
			return false
		else
			console_out("FP legs are already disabled")
			return false
		end
	end
end

function OnTick()
	if fp_legs_enabled == false then return false end
	if protected_map == nil then
		protected_map = MapIsProtected()
	end
	if (script_type == "global" and BLACKLIST[map]) or protected_map then return false end
	local player = get_dynamic_player()
	if  player ~= nil and read_float(player + 0xE0) ~= 0 then
		
		-- Check if camera is in first person
		if debug_mode == false then
			local camera = read_i16(0x647498)
			local camera_interpolation = read_float(0x647494) -- changes when entering/leaving vehicle but also when you spawn sometimes
			if camera ~= 30400 or camera_interpolation > 0 then
				fp_legs_vehicle_timer = 1
			elseif fp_legs_vehicle_timer > 0 then
				fp_legs_vehicle_timer = fp_legs_vehicle_timer - 1
			end
		end
		
		-- Remove duplicate bipeds caused by checkpoints and cutscenes
		if server_type == "none" then
			local object_table = read_dword(read_dword(0x401192 + 2))
			local object_count = read_u16(object_table + 0x2E)
			local first_object = read_dword(object_table + 0x34)
			for i=0,object_count-1 do
				local ID = read_u16(first_object + i*12)*0x10000 + i
				local object = read_dword(first_object + i * 0xC + 0x8)
				if object ~= 0 then
					local object_type = read_u16(object + 0xB4)
					if object_type == object_tag_type and ID ~= legs_biped then
						if read_bit(object + 0x10, 24) == 1 and read_dword(object) == legs_tag then
							write_f32(object + 0x64, -100)
							set_timer(33, "DeleteObject", ID)
						end
					end
				end
			end
		end
		
		local player_vehicle = read_dword(player + 0x11C)
		
		if player_vehicle == 0xFFFFFFFF and fp_legs_vehicle_timer == 0 then
			local x = read_float(player + 0x5C)
			local y = read_float(player + 0x60)
			local z = read_float(player + 0x64)
			local x_vel = read_float(player + 0x68)
			local y_vel = read_float(player + 0x6C)
			local z_vel = read_float(player + 0x70)
			local player_biped_name = GetName(player)
			local player_biped_tag_id = read_dword(player)
			if get_tag(player_biped_tag_id) == nil then return false end
			legs_tag = player_biped_tag_id
			
			local biped_tag = read_dword(get_tag(player_biped_tag_id) + 0x14)
			local biped_model = read_dword(biped_tag + 0x28 + 0xC)
			if biped_model == 0xFFFFFFFF then
				protected_map = true
				return
			end
			
			local biped_tag_thingy = get_tag(biped_model)
			if biped_tag_thingy == nil then
				return
			end
			
			local model_tag = read_dword(biped_tag_thingy + 0x14)
			node_count = read_i16(model_tag + 0x1C+4)
			--console_out(node_count)
			if node_count ~= 16 and node_count ~= 18 and node_count ~= 19 and node_count ~= 25 then
				return false
			end
			
			if read_bit(biped_tag + 0x2F4, 2) == 1 then return end -- if biped is flying
			
			write_dword(biped_tag + 0xA0 + 0xC, 0xFFFFFFFF) --removes creation effect
			
			-- if map was switched then change the biped
			if new_biped then
				local tag = get_tag(player_biped_tag_id)
				if tag ~= nil then
					local tag_data = read_dword(tag + 0x14)
					write_f32(tag_data + 0x104, biped_radius)
					
					local model_id = read_dword(tag_data + 0x28 + 0xC)
					tag = get_tag(model_id)
					if tag ~= nil then
						--console_out("changed LOD info for "..read_string(read_dword(tag_data + 0x28 + 0x4)))
						tag_data = read_dword(tag + 0x14)
						write_float(tag_data + 0x18, 0)
						write_float(tag_data + 0x14, 0)
						write_float(tag_data + 0x10, 0)
						write_float(tag_data + 0x0C, 0)
						write_float(tag_data + 0x08, 0)
					end
					
					new_biped = false
				end
			end
			
			if tag_type == "weap" then
				local current_cluster = read_dword(player + 0x98) --should use actual cluster, not some location ID
				if current_cluster ~= previous_cluster then
					if legs_biped ~= nil then
						local legs = get_object(legs_biped)
						if legs ~= nil then
							delete_object(legs_biped)
						end
						legs_biped = nil
					end
				end
				previous_cluster = current_cluster
			end
			
			-- spawn legs if they don't exist
			if legs_biped == nil then
				
				if previous_biped_tag_id ~= player_biped_tag_id then
					new_biped = true
				end
				
				if new_chimera then
					legs_biped = spawn_object(player_biped_tag_id, x, y, z + biped_z_offset)
				else
					legs_biped = spawn_object(tag_type, player_biped_name, x, y, z + biped_z_offset)
				end
				previous_biped_tag_id = player_biped_tag_id
			end
			
			
			local legs = get_object(legs_biped)
			if legs ~= nil then
				
				--Check if biped changed
				if player_biped_tag_id ~= read_dword(legs) then
					set_timer(33, "DeleteObject", legs_biped)
					legs_biped = nil
					return
				end
				
				if object_tag_type == 0 then
					write_word(legs + 0x2F4, 0xFFFF) -- fixes ready sound being played when legs spawn
					
					--Remove weapon
					local weapon_ID = read_dword(legs + 0x118)
					local weapon = get_object(weapon_ID)
					if weapon ~= nil then
						write_f32(weapon + 0x64, -100)
						set_timer(33, "DeleteObject", weapon_ID)
					end
					
					--Make legs invisible to AI
					write_float(legs + 0x2E0, 0)
					write_float(legs + 0x2E4, 0)
				end
				
				--Make sure the biped can be moved
				write_bit(legs + 0x10, 23, 0)
				
				--Change legs biped's radius to remove collision (affects LODs too)
				write_float(legs + 0xAC, biped_collision_radius)
				
				--Change legs biped object scale to remove other collision (idk don't ask ok)
				write_float(legs + 0xB0, 0.01)
				
				--Set location stuff which makes sure the object doesn't derender when switching clusters
				write_dword(legs + 0x98, read_dword(player + 0x98))
				write_word(legs + 0x9C, read_word(player + 0x9C))
				write_float(legs + 0xA0, x)
				write_float(legs + 0xA4, y)
				write_float(legs + 0xA8, z)
				
				--Remove shadow (doesn't work?)
				write_bit(legs + 0x10, 18, 1)
				
				--Copy shields
				write_float(legs + 0xE4, read_float(player + 0xE4))
				write_float(legs + 0xE8, read_float(player + 0xE8))
				write_float(legs + 0xF4, read_float(player + 0xF4))
				write_float(legs + 0xF8, 0)
				write_float(legs + 0x124, read_float(player + 0x124))
				write_float(legs + 0x13C, read_float(player + 0x13C))
				
				--Make deathless and not collideable
				write_bit(legs + 0x10, 24, 1)
				write_bit(legs + 0x106, 11, 1)--does not take damage
				write_bit(legs + 0x10, 0, 0)
				write_bit(legs + 0x10, 7, 0)
				write_float(legs + 0xD8, 100000)--max health
				write_float(legs + 0xDC, 100000)--max shields
				write_float(legs + 0xE0, 1000)--health
				write_float(legs + 0xE4, 1000)--shields
				
				--Make invisible if player has camo
				if object_tag_type == 0 then
					write_float(legs + 0x37C, read_float(player + 0x37C))
				end
				
				--Change colors
				for i=0,23 do
					local offset = 0x188 + i*4
					write_float(legs + offset, read_float(player + offset))
				end
				
				--Change permutations
				for i=0,7 do
					local offset = 0x180 + i
					write_char(legs + offset, read_char(player + offset))
				end
				
				--No collision
				write_bit(legs + 0x4CC, 3, 1)
				
				--Change team
				write_word(legs + 0xB8, read_word(player + 0xB8))
				
				--Get player aiming direction and calculate legs offset
				local z_aim = read_float(player + 0x238)
				if z_aim > 0 then
					z_aim = 0
				end
				z_aim = dynamic_offset + dynamic_offset*z_aim+offset_from_camera
				--console_out(z_aim)
				local x_offset = -(read_float(player + 0x224)/z_aim) + x_vel*velocity_offset
				local y_offset = -(read_float(player + 0x228)/z_aim) + y_vel*velocity_offset
				--local x_offset = -(read_float(player + 0x224)/offset_from_camera) + x_vel*velocity_offset
				--local y_offset = -(read_float(player + 0x228)/offset_from_camera) + y_vel*velocity_offset
				local z_offset = z_vel*velocity_offset
				
				--Adjust height when crouch jumping to avoid clipping
				if read_u8(player + 0x2A0) == 3 and read_bit(player + 0x4CC, 0) == 1 then
					z_offset = z_offset - 0.15
				end
				
				--Check if player has teleported
				--It removes legs_biped after teleportation because it doesn't render properly
				if GetDistance(player, legs) > 2 then
					set_timer(33, "DeleteObject", legs_biped)
					legs_biped = nil
					return
				elseif GetDistance(player, legs) > 0.5 then --Change position and velocity of the legs biped
					write_float(legs + 0x5C, x - read_float(player + 0x224)*0.2)
					write_float(legs + 0x60, y - read_float(player + 0x228)*0.2)
					write_float(legs + 0x64, z + biped_z_offset)
				end
				write_float(legs + 0x68, x_vel)
				write_float(legs + 0x6C, y_vel)
				write_float(legs + 0x70, z_vel)
				
				--Copy node info
				local node_info = 0x550
				local legs_test = legs
				if object_tag_type ~= 0 then
					legs_test = legs - (0x550 - 0x340)
				end
				CopyNodeInfo(player, legs_test, node_info, x_offset, y_offset, z_offset) -- pelvis
				CopyNodeInfo(player, legs_test, node_info+0x34, x_offset, y_offset, z_offset)
				CopyNodeInfo(player, legs_test, node_info+0x34*2, x_offset, y_offset, z_offset)
				CopyNodeInfo(player, legs_test, node_info+0x34*3, x_offset, y_offset, z_offset, torso_offset) -- above pelvis?
				CopyNodeInfo(player, legs_test, node_info+0x34*4, x_offset, y_offset, z_offset)
				CopyNodeInfo(player, legs_test, node_info+0x34*5, x_offset, y_offset, z_offset)
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*6, 0, x_offset, y_offset, z_offset, torso_offset) -- torso
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*7, 0, x_offset, y_offset, z_offset) -- pelvis is slightly more offset
				CopyNodeInfo(player, legs_test, node_info+0x34*8, x_offset, y_offset, z_offset) -- left foot
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*9, 0, x_offset, y_offset, z_offset)
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*10, 0, x_offset, y_offset, z_offset)
				CopyNodeInfo(player, legs_test, node_info+0x34*11, x_offset, y_offset, z_offset) -- right foot
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*12, 0, x_offset, y_offset, z_offset) -- head
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*13, 0, x_offset, y_offset, z_offset)
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*14, 0, x_offset, y_offset, z_offset)
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*15, 0, x_offset, y_offset, z_offset)
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*16, 0, x_offset, y_offset, z_offset)
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*17, 0, x_offset, y_offset, z_offset)
				CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*18, 0, x_offset, y_offset, z_offset)
				if node_count == 19 then
					CopyNodeInfo(player + node_info+0x34*3, legs_test + node_info+0x34*19, 0, x_offset, y_offset, z_offset)
					write_float(legs_test + node_info+0x34*19, 0)
				end
				if node_count == 25 then
					CopyNodeInfo(player, legs_test, node_info+0x34*12, x_offset, y_offset, z_offset)
					CopyNodeInfo(player, legs_test, node_info+0x34*15, x_offset, y_offset, z_offset)
					write_float(legs_test + node_info+0x34*19, 0)
					write_float(legs_test + node_info+0x34*20, 0)
					write_float(legs_test + node_info+0x34*21, 0)
					write_float(legs_test + node_info+0x34*22, 0)
					write_float(legs_test + node_info+0x34*23, 0)
					write_float(legs_test + node_info+0x34*24, 0)
					write_float(legs_test + node_info+0x34*25, 0)
				else
					write_float(legs_test + node_info+0x34*12, 0)
					write_float(legs_test + node_info+0x34*15, 0)
				end
				write_float(legs_test + node_info+0x34*6, 0)
				write_float(legs_test + node_info+0x34*7, 0)
				write_float(legs_test + node_info+0x34*9, 0)
				write_float(legs_test + node_info+0x34*10, 0)
				write_float(legs_test + node_info+0x34*13, 0)
				write_float(legs_test + node_info+0x34*14, 0)
				write_float(legs_test + node_info+0x34*16, 0)
				write_float(legs_test + node_info+0x34*17, 0)
				write_float(legs_test + node_info+0x34*18, 0)
			else
				legs_biped = nil
			end
		else
			-- If player is in a vehicle
			if legs_biped ~= nil then
				local legs = get_object(legs_biped)
				if legs then
					write_float(legs + 0x64, -300)
				end
				set_timer(33, "DeleteObject", legs_biped)
				legs_biped = nil
			end
		end
	else
		-- If player is dead
		if legs_biped ~= nil then
			local legs = get_object(legs_biped)
			if legs ~= nil then
				set_timer(33, "DeleteObject", legs_biped)
			end
			legs_biped = nil
		end
	end
end

function CopyNodeInfo(address, address2, offset, x, y, z, torso_offset) -- copies node info from address to adddress2
	address = address + (offset or 0x0)
	address2 = address2 + (offset or 0x0)
	write_float(address2 + 0x0,read_float(address + 0x0))
	write_float(address2 + 0x4,read_float(address + 0x4))
	write_float(address2 + 0x8,read_float(address + 0x8))
	write_float(address2 + 0xC,read_float(address + 0xC))
	write_float(address2 + 0x10,read_float(address + 0x10))
	write_float(address2 + 0x14,read_float(address + 0x14))
	write_float(address2 + 0x18,read_float(address + 0x18))
	write_float(address2 + 0x1C,read_float(address + 0x1C))
	write_float(address2 + 0x20,read_float(address + 0x20))
	write_float(address2 + 0x24,read_float(address + 0x24))
	if torso_offset ~= nil then
		write_float(address2 + 0x28,read_float(address + 0x28) + x*	torso_offset)
		write_float(address2 + 0x2C,read_float(address + 0x2C) + y*torso_offset)
	else
		write_float(address2 + 0x28,read_float(address + 0x28) + x)
		write_float(address2 + 0x2C,read_float(address + 0x2C) + y)
	end
	write_float(address2 + 0x30,read_float(address + 0x30) + z)
end

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end

function DeleteObject(ID)
	local object = get_object(tonumber(ID))
	if object ~= nil then
		delete_object(tonumber(ID))
	end
	ID = nil
	return false
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
	return math.sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
end

function MapIsProtected()
	if new_chimera and get_tag("tagc", "kinnet\\reference_bitmap") == nil then
		return false
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

function OnUnload()
	if legs_biped ~= nil then
		if get_object(legs_biped) ~= nil then
			delete_object(legs_biped)
		end
	end
end
