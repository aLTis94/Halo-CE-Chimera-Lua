--CONFIG
	player_height = 0.64
	player_buffness = 0.8
	player_head_size = 0.95
	player_voice_pitch = 1.2
	change_player_speed = true
--END OF CONFIG

clua_version = 2.042

DIALOG = {
	"sound\\dialog\\chief\\deathquiet",
	"sound\\dialog\\chief\\deathviolent",
}

set_callback("tick", "OnTick")
set_callback("map load", "OnMapLoad")

previous_weapon = nil

function OnTick()
	if server_type ~= "none" then return false end
	local camera_mode = read_short(0x647498)
	local player = get_dynamic_player()
	if player ~= nil then
		biped_name = GetName(player)
	end
	
	if biped_name == nil then return false end
	local object_table = read_u32(read_u32(0x401192 + 2))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
    for i=0,object_count-1 do
        local object = read_dword(first_object + i * 0xC + 0x8)
        if object ~= 0 and object ~= 0xFFFFFFFF then
			local object_type = read_word(object + 0xB4)
			local name = GetName(object)
			if object_type == 0 and string.find(name, "cyborg") ~= nil then
				player = object
				if camera_mode ~= 22192 then
					write_float(player + 0xB0, player_height)
					
					-- change camera height and collision
					if name == biped_name then
						local tag = get_tag(read_dword(player))
						if tag ~= nil then
							tag = read_dword(tag + 0x14)
							write_float(tag + 0x400, 0.62*player_height)
							write_float(tag + 0x404, 0.35*player_height)
							write_float(tag + 0x424, 0.7*player_height)
							write_float(tag + 0x428, 0.5*player_height)
							write_float(tag + 0x42C, 0.2*player_height)
							write_float(tag + 0x458, 0.08*player_height)
						end
					end
				end
				
				local node_address = player + 0x550
				for i=0,18 do
					write_float(node_address + i*0x34, player_buffness)
					if camera_mode == 22192 then
						for j=0,2 do
							if i ~= 0 then
								local pelvis_axis = read_float(node_address + 0x28 + j*4)
								local axis = read_float(node_address + i*0x34 + 0x28 + j*4)
								local distance = axis - pelvis_axis
								write_float(node_address + i*0x34 + 0x28 + j*4, axis - distance * (1 - player_height))
							elseif j == 2 then
								local pelvis_axis = read_float(node_address + 0x28 + j*4)
								write_float(node_address + 0x30, pelvis_axis - (1 - player_height)*0.13)
							end
							if j == 2 then
								write_float(node_address + i*0x34 + 0x30, read_float(node_address + i*0x34 + 0x30) - (1 - player_height)*0.17)
							end
						end
						
						if i == 12 then
							write_float(node_address + i*0x34, player_head_size)
						elseif i == 18 then
							local object = get_object(read_dword(player + 0x118))
							if object ~= nil then
								local object_type = read_word(object + 0xB4)
								local tag = get_tag(read_dword(object))
								if tag ~= nil then
									tag = read_dword(tag + 0x14)
									local model_tag = get_tag(read_dword(tag + 0x28 + 0xC))
									if model_tag ~= nil then
										model_tag = read_dword(model_tag + 0x14)
										local node_count = read_dword(model_tag + 0xB8)
										local weap_node_address = object + 0x340
										if object_type == 6 then
											weap_node_address = object + 0x1F8
										end
										for i=0,node_count-1 do
											for j=0,2 do
												local axis = read_float(weap_node_address + i*0x34 + 0x28 + j*4)
												local pelvis_axis = read_float(node_address + 0x28 + j*4)
												local distance = axis - pelvis_axis
												write_float(weap_node_address + i*0x34 + 0x28 + j*4, axis - distance * (1 - player_height))
												if j == 2 then
													write_float(weap_node_address + i*0x34 + 0x30, read_float(weap_node_address + i*0x34 + 0x30) - (1 - player_height)*0.17)
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
	end
end

function OnMapLoad()
	if server_type ~= "none" then return false end
	local scenario_tag_index = read_word(0x40440004)
	local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
	local scenario_data = read_dword(scenario_tag + 0x14)
	local references_count = read_dword(scenario_data + 0x4B4)
	local references_address = read_dword(scenario_data + 0x4B8)
	for i=0,references_count-1 do
		local address = references_address + i*40 + 0x18
		local name = read_string(read_dword(address + 0x4))
		if string.find(name, "chief") ~= nil or string.find(name, "che_") ~= nil then
			local tag = get_tag(read_dword(address + 0xC))
			if tag ~= nil then
				tag = read_dword(tag + 0x14)
				write_float(tag + 0x44, player_voice_pitch)
				write_float(tag + 0x5C, player_voice_pitch)
			end
		end
	end
	
	for id,name in pairs (DIALOG) do
		local tag = get_tag("snd!", name)
		if tag ~= nil then
			tag = read_dword(tag + 0x14)
			write_float(tag + 0x44, player_voice_pitch)
			write_float(tag + 0x5C, player_voice_pitch)
		end
	end
	
	-- change walking speed
	if change_player_speed then
		local tag = get_tag("matg", "globals\\globals")
		if tag ~= nil then
			tag = read_dword(tag + 0x14)
			local info = read_dword(tag + 0x174)
			write_float(info + 0x2C, 0.512*player_height)
			
			write_float(info + 0x34, 2.25*player_height)
			write_float(info + 0x38, 2*player_height)
			write_float(info + 0x3C, 2*player_height)
		
			write_float(info + 0x44, 0.9*player_height)
			write_float(info + 0x48, 0.65*player_height)
			write_float(info + 0x4C, 0.6*player_height)
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
