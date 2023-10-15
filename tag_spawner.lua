
local keyboard_input_address = 0x64C550
local mouse_input_address = 0x64C73C
--CONFIG

	local scroll_speed = 7 -- lower means faster
	local scroll_start_delay = 13 -- how long to hold before scrolling
	local max_radius = 3 -- furthest distance an object can spawn
	
	local open_menu_key = keyboard_input_address + 17
	local open_info_key = keyboard_input_address + 18
	local devcam_key = keyboard_input_address + 19
	local all_weapons_key = keyboard_input_address + 20
	local all_vehicles_key = keyboard_input_address + 21
	local up_arrow_key = keyboard_input_address + 77
	local down_arrow_key = keyboard_input_address + 78
	local left_arrow_key = keyboard_input_address + 79
	local right_arrow_key = keyboard_input_address + 80
	
--END_OF_CONFIG

clua_version = 2.042

local new_chimera = false
if build > 0 then
	new_chimera = true
end
local camera_address = 0x647498

set_callback("map load", "OnMapLoad")
set_callback("frame", "OnFrame")

function CheckProtection()
	local tag_array = read_dword(0x40440000)
    local tag_count = read_dword(0x4044000C)
	if tag_count > 50 then
		tag_count = 50
	end
    for i = 0,tag_count - 1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
		local name_addr = read_dword(tag + 0x10)
        for k = 0,i - 1 do
            local tag_k = tag_array + k * 0x20
            if read_dword(tag_k) == tag_class and read_dword(tag_k + 0x10) == name_addr then
                return true, name_addr
            end
        end
    end
    return false
end

function Initialize()
	if map == "ui" then
		return false
	end
	map_is_protected, protected_addr = CheckProtection()
	if map_is_protected then
		console_out("Map is protected!")
	end
	menu_is_open = false
	selection1 = 1
	selection2 = 1
	selection_lvl = 0
	TAGS = {
		[1] = {["name"] = "WEAPONS",},
		[2] = {["name"] = "VEHICLES",},
		[3] = {["name"] = "BIPEDS",},
		[4] = {["name"] = "EQUIPMENT",},
		[5] = {["name"] = "SCENERY",},
		[6] = {["name"] = "MACHINE",},
		[7] = {["name"] = "CONTROL",},
		[8] = {["name"] = "LIGHT FIXT",},
		[9] = {["name"] = "BSP",},
	}
	
	local protected_tag_counter = 0
	
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
		local tag_class = read_dword(tag)
		local meta_id = read_dword(tag + 0xC)
		local name_addr = read_dword(tag + 0x10)
		local name = read_string(name_addr)
		if map_is_protected and name_addr == protected_addr then
			name = meta_id
			name_addr = name_addr + protected_tag_counter * 32
			write_dword(tag + 0x10, name_addr)
			write_string(name_addr, name)
			protected_tag_counter = protected_tag_counter + 1
		else
			for word in string.gmatch(name, "([^".."\\".."]+)") do
				name = word
			end
		end
		name = string.upper(name)
		
		local tag_data = read_dword(tag + 0x14)
		if tag_class == 0x77656170 then --weap
			NewTableEntry(1, name, meta_id, tag_data)
		elseif tag_class == 0x76656869 then --vehi
			NewTableEntry(2, name, meta_id, tag_data)
		elseif tag_class == 0x62697064 then --bipd
			NewTableEntry(3, name, meta_id, tag_data)
		elseif tag_class == 0x65716970 then --eqip
			NewTableEntry(4, name, meta_id, tag_data)
		elseif tag_class == 0x7363656E then --scen
			NewTableEntry(5, name, meta_id, tag_data)
		elseif tag_class == 0x6D616368 then --mach
			NewTableEntry(6, name, meta_id, tag_data)
		elseif tag_class == 0x6374726C then --ctrl
			NewTableEntry(7, name, meta_id, tag_data)
		elseif tag_class == 0x6C696669 then --lifi
			NewTableEntry(8, name, meta_id, tag_data)
		end
		
		if tag_class == 0x73627370 then --sbsp
			TAGS[9][#TAGS[9]+1] = {
				["name"] = name,
			}
		end
	end
	
	local scenario_tag_index = read_word(0x40440004)
	local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
	local scenario_tag_data = read_dword(scenario_tag + 0x14)
	
	local netgame_flag_count = read_dword(scenario_data + 0x378)
	local netgame_flags = read_dword(scenario_data + 0x378 + 4)
	
	for i=0,netgame_flag_count do
		local current_flag = netgame_flags + i*148
		if read_word(current_flag + 0x10) == 7 then
			console_out("tele")
		end
	end
end

function NewTableEntry(id, name, meta_id, tag_data)
	local model = read_dword(tag_data + 0x28 + 0xC)
	if model ~= 0xFFFFFFFF then
		local radius = read_float(tag_data + 0x04)
		if radius > max_radius then
			radius = max_radius
		end
		TAGS[id][#TAGS[id]+1] = {
			["name"] = name,
			["meta_id"] = meta_id,
			["radius"] = radius,
		}
	end
end

Initialize()

function OnFrame()
	
	if TAGS == nil then return end
	
	player = get_dynamic_player()
	
	-- HOTKEYS
	local chat_is_open = read_byte(0x0064E788)
	if console_is_open() == false and player ~= nil then
		local menu = read_byte(open_menu_key)
		local info = read_byte(open_info_key)
		local devcam = read_byte(devcam_key)
		local weapons = read_byte(all_weapons_key)
		local vehicles = read_byte(all_vehicles_key)
		local up = read_byte(up_arrow_key)
		local down = read_byte(down_arrow_key)
		local left = read_byte(left_arrow_key)
		local right = read_byte(right_arrow_key)
		
		if menu_is_open then
			if up == 1 or (up > scroll_start_delay and up%scroll_speed == 1) then
				if selection_lvl == 0 then
					selection1 = selection1 - 1
					if selection1 < 1 then
						selection1 = #TAGS
					end
				else
					selection2 = selection2 - 1
					if selection2 < 1 then
						selection2 = #TAGS[selection1]
					end
				end
			elseif down == 1 or (down > scroll_start_delay and down%scroll_speed == 1) then
				if selection_lvl == 0 then
					selection1 = selection1 + 1
					if selection1 > #TAGS then
						selection1 = 1
					end
				else
					selection2 = selection2 + 1
					if selection2 > #TAGS[selection1] then
						selection2 = 1
					end
				end
			elseif left == 1 then
				selection_lvl = selection_lvl - 1
				if selection_lvl < 0 then
					CloseMenu()
				end
			elseif right == 1 then
				if #TAGS[selection1] > 0 then
					selection_lvl = selection_lvl + 1
					if selection_lvl > 1 then
						selection_lvl = 1
						if selection1 == 9 then --bsp
							-- to do later
						else
							SpawnTag(TAGS[selection1][selection2].meta_id, TAGS[selection1][selection2].radius)
						end
					else
						selection2 = 1
					end
				end
			end
		end
	
		if chat_is_open == 0 then
			if (menu == 1 or (right == 1 and menu_is_open == false)) then
				if menu_is_open then
					CloseMenu()
				else
					OpenMenu()
				end
			elseif info == 1 then
				
			elseif devcam == 1 then
				if read_word(camera_address) == 30704 then
					execute_script("camera_control 0")
				else
					execute_script("debug_camera_save")
					execute_script("debug_camera_load")
				end
			elseif weapons == 1 then
				execute_script("cheat_all_weapons")
			elseif vehicles == 1 then
				execute_script("cheat_all_vehicles")
			end
		end
		
	elseif menu_is_open then
		menu_is_open = false
		ClearScreen()
	end
	
	if menu_is_open then
		ShowMenu()
	end
end

function OpenMenu()
	menu_is_open = true
end

function CloseMenu()
	menu_is_open = false
	selection_lvl = 0
	ClearScreen()
end

function ShowMenu()
	ClearScreen()
	
	if selection_lvl == 0 then
		console_out("Select tag type:", 0.5, 1, 0)
		for i=1,#TAGS do
			if #TAGS[i] > 0 then
				if i == selection1 then
					console_out(">> "..TAGS[i].name.." ("..#TAGS[i]..") <<", 0, 1, 0)
				else
					console_out("   "..TAGS[i].name.." ("..#TAGS[i]..")", 0.5, 1, 0)
				end
			elseif i == selection1 then
				console_out(">> "..TAGS[i].name.." (0) <<", 1, 0, 0)
			else
				console_out("   "..TAGS[i].name.." (0)", 1, 0.5, 0)
			end
		end
	else
		console_out("Select tag:", 0.5, 1, 0)
		for j=1,#TAGS[selection1] do
		
			if j - selection2 > 19 then
				console_out("...", 0.5, 1, 0)
				break
			else
				if j == selection2 then
					console_out(">> "..TAGS[selection1][j].name.." <<", 0, 1, 0)
				else
					console_out("   "..TAGS[selection1][j].name, 0.5, 1, 0)
				end
			end
		end
	end
end

function SpawnTag(meta_id, radius)
	if meta_id == nil then
		CloseMenu()
		console_out("ERROR SPAWNING OBJECT")
		return
	end
	
	local player = get_dynamic_player()
	local x = read_float(player + 0x5C)
	local y = read_float(player + 0x60)
	local z = read_float(player + 0x64)
	
	local vehicle = get_object(read_dword(player + 0x11C))
	if vehicle then
		x = read_float(vehicle + 0x5C)
		y = read_float(vehicle + 0x60)
		z = read_float(vehicle + 0x64)
	end
	
	local spawn_dist = 1 + radius
	local aim_x = read_float(player + 0x23C)*spawn_dist
	local aim_y = read_float(player + 0x240)*spawn_dist
	local aim_z = read_float(player + 0x244)*spawn_dist
	
	--if new_chimera then
	--	spawn_object(meta_id, x, y, z + 0.2)
	--else
		local tag = get_tag(meta_id)
		local tag_class = read_dword(tag)
		tag_class = unhex( string.format("%X", tag_class) )
		local name = read_string(read_dword(tag + 0x10))
		spawn_object(tag_class, name, x+aim_x, y+aim_y, z + aim_z + 0.6)
	--end
end

function unhex( input )
    return (input:gsub( "..", function(c)
        return string.char( tonumber( c, 16 ) )
    end))
end

function OnMapLoad()
	TAGS = nil
	Initialize()
end

function ClearScreen()
	for i=0,30 do
		console_out(" ")
	end
end