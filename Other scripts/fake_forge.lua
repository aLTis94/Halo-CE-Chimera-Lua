
-- FAKE FORGE 0.2 BY aLTis

-- Client script for the fake forge.

clua_version = 2.042

--CONFIG
	prefix = "r" -- what rcon messages start with
--END OF CONFIG

--NOTES

set_callback("rcon message", "OnRcon")
set_callback("unload", "OnUnload")
set_callback("precamera", "OnCamera")
set_callback("map load", "OnMapLoad")
set_callback("tick", "OnTick")

-- MISC
netgame_flag_counter = 3
seconds_counter = 0
messages_per_second = 0
block_rcon_command_failed = false
SPAWNED_OBJECTS = {}
sky_id = 1

--don't touch these!
ctf_flag_red = 0x40492F1C
ctf_flag_blue = 0x40492FB0
koth_globals = 0x64BDF0
race_locs = 0x68C848

function OnTick()
	seconds_counter = seconds_counter + 1
	if seconds_counter == 30 then
		--console_out("Received messages per second: "..messages_per_second)
		messages_per_second = 0
		seconds_counter = 0
	end
end

function OnMapLoad()
	fake_forge_enabled = false
	SCENERY_OBJECTS = {}
	KOTH_HILL = nil
	sky_id = 1
	netgame_flag_counter = 3
	write_float(0x637BE4, 0.003565)
end

function OnRcon(Message)-- keep in mind maximum number of characters in one message is 80
	messages_per_second = messages_per_second + 1
	
	-- split the MESSAGE string into words
	MESSAGE = {}
	for word in string.gmatch(Message, "([^".."~".."]+)") do 
		table.insert(MESSAGE, word)
	end
	
	-- spawn forge object
	if MESSAGE[1] == prefix.."s" then
		fake_forge_enabled = true
		local meta_id = tonumber(MESSAGE[2])
		local x = tonumber(MESSAGE[3])
		local y = tonumber(MESSAGE[4])
		local z = tonumber(MESSAGE[5])
		local rot1 = tonumber(MESSAGE[6])
		local rot2 = tonumber(MESSAGE[7])
		local rot3 = tonumber(MESSAGE[8])
		
		if get_tag(meta_id) ~= nil and MESSAGE[5] ~= nil and MESSAGE[8] ~= nil then
			local ID = spawn_object("scen", read_string(read_dword(get_tag(meta_id) + 0x10)), x, y, z)
			local object = get_object(ID)
			if object ~= nil then
				SPAWNED_OBJECTS[ID] = 1
				rot = convert(rot1, rot2, rot3)
				write_float(object + 0x74, rot[1])
				write_float(object + 0x78, rot[2])
				write_float(object + 0x7C, rot[3])
				write_float(object + 0x80, rot[4])
				write_float(object + 0x84, rot[5])
				write_float(object + 0x88, rot[6])
				
				--scale
				if MESSAGE[9] ~= nil then
					local scale = tonumber(MESSAGE[9])
					write_float(object + 0xB0, scale)
					
					--edit tag data to change the bounding radius of the object
					local tag = get_tag(meta_id)
					if tag ~= nil then
						local tag_data = read_dword(tag + 0x14)
						local current_scale = read_float(tag_data + 0x104)
						if scale*6 > current_scale then
							write_float(tag_data + 0x104, scale*6)
						end
					end
					
					--shader permutation
					if MESSAGE[10] ~= nil then
						write_word(object + 0x176, tonumber(MESSAGE[10]))
						write_char(object + 0x180, tonumber(MESSAGE[10]))
						
						--shadow
						if MESSAGE[11] ~= nil then
							if tonumber(MESSAGE[11]) == 1 then
								write_bit(object + 0x10, 18, 0)
							end
						end
					end
				end
				return false
			else
				console_out("Error! Couldn't create a forge object.")
			end
		end
	end
	
	-- clear netgame flags
	if MESSAGE[1] == prefix.."clear_netgame_flags" then
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
		return false
	end
	
	-- set ctf flags
	if MESSAGE[1] == prefix.."ctf" then
		fake_forge_enabled = true
		local team = tonumber(MESSAGE[2])
		local x = tonumber(MESSAGE[3])
		local y = tonumber(MESSAGE[4])
		local z = tonumber(MESSAGE[5])
		
		if z ~= nil then
			local scenario_tag_index = read_word(0x40440004)
			local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
			local scenario_data = read_dword(scenario_tag + 0x14)
			netgame_flag_count = read_dword(scenario_data + 0x378)
			netgame_flags = read_dword(scenario_data + 0x378 + 4)
			
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
				write_float(ctf_flag_red, x)
				write_float(ctf_flag_red + 4, y)
				write_float(ctf_flag_red + 8, z)
			elseif team == 1 then
				write_float(ctf_flag_blue, x)
				write_float(ctf_flag_blue + 4, y)
				write_float(ctf_flag_blue + 8, z)
			end
		end
		return false
	end
	
	-- set hill marker
	if MESSAGE[1] == prefix.."hill_marker" or MESSAGE[1] == "fhill_marker" then
		local x = tonumber(MESSAGE[2])
		local y = tonumber(MESSAGE[3])
		local z = tonumber(MESSAGE[4])
		local marker_id = tonumber(MESSAGE[5])
		local marker_count = tonumber(MESSAGE[6])
		
		koth_marker_count_address = koth_globals + 0x90
		koth_marker_address = koth_globals + 0x94
		
		write_dword(koth_marker_count_address, marker_count)
		
		if x ~= nil and marker_count ~= nil then
			write_float(koth_marker_address + marker_id*12, x)
			write_float(koth_marker_address+4 + marker_id*12, y)
			write_float(koth_marker_address+8 + marker_id*12, z)
			
			write_float(koth_globals + 0x124 + marker_id*8, x)
			write_float(koth_globals + 0x128 + marker_id*8, y)
		end
		
		if KOTH_HILL == nil then
			KOTH_HILL = {}
			KOTH_HILL.total_x = 0
			KOTH_HILL.total_y = 0
			KOTH_HILL.total_z = 0
		end
		KOTH_HILL.total_x = KOTH_HILL.total_x + x
		KOTH_HILL.total_y = KOTH_HILL.total_y + y
		KOTH_HILL.total_z = KOTH_HILL.total_z + z
		
		if marker_id == marker_count-1 then
			local center_x = KOTH_HILL.total_x/marker_count
			local center_y = KOTH_HILL.total_y/marker_count
			local center_z = KOTH_HILL.total_z/marker_count
			
			write_float(koth_globals + 0x184, center_x)
			write_float(koth_globals + 0x184 + 4, center_y)
			write_float(koth_globals + 0x184 + 8, center_z)
			KOTH_HILL = nil
		end
		
		return false
	end
	
	-- set telporters
	if MESSAGE[1] == prefix.."tpfrom" or MESSAGE[1] == prefix.."tpto" then
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
		return false
	end
	
	-- set race flags
	if MESSAGE[1] == prefix.."race" then
		local x = tonumber(MESSAGE[2])
		local y = tonumber(MESSAGE[3])
		local z = tonumber(MESSAGE[4])
		local team = tonumber(MESSAGE[5])
		if x ~= nil and team ~= nil and netgame_flag_count ~= nil then
			if netgame_flag_counter <= netgame_flag_count then
				local current_flag = netgame_flags + netgame_flag_counter*148
				write_float(current_flag, x)
				write_float(current_flag + 4, y)
				write_float(current_flag + 8, z)
				write_short(current_flag + 0x12, team)
				write_word(current_flag + 0x10, 3)
				netgame_flag_counter = netgame_flag_counter + 1
				
				write_float(race_locs + team*0x20, x)
				write_float(race_locs + team*0x20 + 4, y)
				write_float(race_locs + team*0x20 + 8, z)
			end
		end
		return false
	end
	
	-- this changes the sky in the scenario (for all bsps)
	-- needs fixing
	if false and MESSAGE[1] == prefix.."sky" then
		fake_forge_enabled = true
		local sky_id = tonumber(MESSAGE[2])
		local scenario_tag_index = read_word(0x40440004)
		local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
		local scenario_data = read_dword(scenario_tag + 0x14)
		
		local sky_count = read_dword(scenario_data + 0x30)
		local sky_address = read_dword(scenario_data + 0x30 + 4)
		
		for i=0, sky_count do
			local struct = sky_address + i*16
			local tag = get_tag("sky ", SKIES[sky_id])

			write_dword(struct,read_dword(tag))
			write_dword(struct + 0xC,read_dword(tag + 0xC))
		end
		return false
	end
	
	-- change the textures of the terrain shader
	-- disabled cause it only works in bigass v3
	if false and MESSAGE[1] == prefix.."terrain" then
		fake_forge_enabled = true
		local shader = read_dword(get_tag("senv", "altis\\levels\\bigass\\shaders\\bigassgrass") + 0x14)
		if MESSAGE[2] == "2" then 
			local bitmap = get_tag("bitm", "altis\\bitmaps\\stuff\\bitmaps\\beach")
			local bitmap_normal = get_tag("bitm", "altis\\bitmaps\\stuff\\bitmaps\\beach_normal")
			--base map
			write_dword(shader + 0x88,read_dword(bitmap))
			write_dword(shader + 0x88 + 0xC,read_dword(bitmap + 0xC))
			
			--primary detail map
			write_short(shader + 0xB0, 01) -- multiply
			write_float(shader + 0xB4, 6) -- scale
			write_dword(shader + 0xB8,read_dword(bitmap))
			write_dword(shader + 0xB8 + 0xC,read_dword(bitmap + 0xC))
			
			--micro detail map
			write_short(shader + 0xF4, 01) -- multiply
			write_float(shader + 0xF8, 75) -- scale
			write_dword(shader + 0xFC,read_dword(bitmap))
			write_dword(shader + 0xFC + 0xC,read_dword(bitmap + 0xC))
			
			--normal map
			write_float(shader + 0x124, 75) -- scale
			write_dword(shader + 0x128,read_dword(bitmap_normal))
			write_dword(shader + 0x128 + 0xC,read_dword(bitmap_normal + 0xC))
		elseif MESSAGE[2] == "3" then 
			local bitmap = get_tag("bitm", "altis\\levels\\bigass\\bitmaps\\ground_shortgrass_detail")
			local base_bitmap = get_tag("bitm", "altis\\levels\\bigass\\bitmaps\\ground_neutral")
			--base map
			write_dword(shader + 0x88,read_dword(base_bitmap))
			write_dword(shader + 0x88 + 0xC,read_dword(base_bitmap + 0xC))
			
			--primary detail map
			write_short(shader + 0xB0, 01) -- multiply
			write_float(shader + 0xB4, 1010) -- scale
			write_dword(shader + 0xB8,read_dword(bitmap))
			write_dword(shader + 0xB8 + 0xC,read_dword(bitmap + 0xC))
			
			--micro detail map
			write_short(shader + 0xF4, 0) -- multiply
			write_float(shader + 0xF8, 24) -- scale
		end
		return false
	end
	
	if MESSAGE[1] == prefix.."gravity" then
		if MESSAGE[2] ~= nil then
			write_float(0x637BE4, tonumber(MESSAGE[2]))
		end
		return false
	end
	
	-- change the fog for all skies
	if MESSAGE[1] == prefix.."fog" then
		fake_forge_enabled = true
		local red = MESSAGE[2]
		local green = MESSAGE[3]
		local blue = MESSAGE[4]
		local density = MESSAGE[5]
		local fade_start = MESSAGE[6]
		local fade_end = MESSAGE[7]
		local remove_sky = MESSAGE[8]
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
			
			fog_camera_test = true
		end
		return false
	end
	
	--apply damage effect to player to set a screen tint
	-- disabled cause it only works in bigass v3
	if false and MESSAGE[1] == prefix.."screen_tint" then
		fake_forge_enabled = true
		local effect_type = MESSAGE[2]
		local intensity = MESSAGE[3]
		local red = MESSAGE[4]
		local green = MESSAGE[5]
		local blue = MESSAGE[6]
		if blue ~= nil then 
			local tag = read_dword(get_tag("jpt!", "forge\\screen_tint") + 0x14)
			
			write_word(tag + 0x24, effect_type)
			write_float(tag + 0x44, intensity)
			--0x4C is alpha
			write_float(tag + 0x4C + 4, red)
			write_float(tag + 0x4C + 8, green)
			write_float(tag + 0x4C + 12, blue)
			screen_tint = true
		end
		return false
	end
	
	-- removes all objects that were spawned via forge
	if MESSAGE[1] == prefix.."remove_spawned_objects" then
		fake_forge_enabled = true
		for ID, info in pairs (SPAWNED_OBJECTS) do
			if get_object(ID) ~= nil then
				delete_object(ID)
			end
		end
		return false
	end
	
	-- removes ALL scenery objects from the map
	if MESSAGE[1] == prefix.."destroy_all_scenery" then
		fake_forge_enabled = true
		local object_table = read_u32(read_u32(0x401192 + 2))
		local object_count = read_word(object_table + 0x2E)
		local first_object = read_dword(object_table + 0x34)
		
		for i=0,object_count-1 do
			local object = read_dword(first_object + i * 0xC + 0x8)
			if object ~= nil and object ~= 0 then
				local object_type = read_word(object + 0xB4)
				if object_type == 6 then
					-- add something to not delete armor room?
					delete_object(read_word(first_object + i*12)*0x10000 + i)
				end
			end
		end
		return false
	end
	
	
	-- chimera detection
	
	if Message == "|ngot_chimera?" then
		execute_script("rcon password yee_boi_ive_got_chi_meras")
		block_rcon_command_failed = true
	end
	
end

function OnUnload()
	local object_table = read_u32(read_u32(0x401192 + 2))
	local object_count = read_u16(object_table + 0x2E)
	
	--IF CHIMERA WAS RELOADED
	if object_count ~= 0 and fake_forge_enabled then
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
	end
end

function OnCamera(x, y, z, fov, x1, y1, z1, x2, y2, z2)
	if fog_camera_test ~= nil then
		fog_camera_test = nil
		return 0, 0, 1000, fov, 0, 0, 0, 0, 0, 0
	end
end

function rotate(X, Y, alpha)
	local c, s = math.cos(math.rad(alpha)), math.sin(math.rad(alpha))
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

