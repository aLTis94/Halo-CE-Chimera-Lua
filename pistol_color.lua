--Pistol color script by aLTis. Version 1.0.1

--CONFIG	(use values between 0 and 1)

	--THESE AFFECT YOUR PISTOL ONLY
		--Primary color RGB
		primary_color = {0, 0, 0}
		--Secondary color RBG
		secondary_color = {0, 1, 1}
		
	--THESE AFFECT ALL PISTOLS
		--Color of reflection RGB
		perpendicular_color = {1, 1, 1}	--1, 1, 1 by default
		parallel_color = {1, 1, 1}			--1, 1, 1 by default
		
		--How shiny it is
		perpendicular_brightness = 0.5	-- 0.5 by default
		parallel_brightness = 0.5			-- 1 by default
		
		cubemap = "weapons\\assault rifle\\fp\\bitmaps\\diffuse gunmetal"
		
		anniversary_fix = false	-- fixes color change on Anniversary maps
--END OF CONFIG

clua_version = 2.042

local multipurpose_map = "weapons\\pistol\\fp\\bitmaps\\pistol multipurpose"
if anniversary_fix then
	multipurpose_map = "weapons\\pistol\\fp\\bitmaps\\pistol"
end

set_callback("tick", "OnTick")
set_callback("map load", "OnMapLoad")
local object_table = read_dword(read_dword(0x401194))
local script_loaded = false

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end

function WriteColor(address, COLOR)
	if COLOR[1] < 0 or COLOR[1] > 1 then
		console_out("PISTOL_COLOR.LUA ERROR: Invalid color for red!")
		return
	end
	if COLOR[2] < 0 or COLOR[2] > 1 then
		console_out("PISTOL_COLOR.LUA ERROR: Invalid color for green!")
		return
	end
	if COLOR[3] < 0 or COLOR[3] > 1 then
		console_out("PISTOL_COLOR.LUA ERROR: Invalid color for blue!")
		return
	end
	--console_out("color set to "..COLOR[1].." "..COLOR[2].." "..COLOR[3])
	write_float(address, COLOR[1])
	write_float(address+4, COLOR[2])
	write_float(address+8, COLOR[3])
end

function SetTags()
	local shader1 = get_tag("soso", "weapons\\pistol\\fp\\shaders\\silver")
	local shader2 = get_tag("soso", "weapons\\pistol\\fp\\shaders\\black")
	if shader1 and shader2 then
		local tag_data1 = read_dword(shader1 + 0x14)
		local tag_data2 = read_dword(shader2 + 0x14)
		
		write_word(tag_data1 + 0x4C, 3)
		write_word(tag_data2 + 0x4C, 4)
		
		local cubemap_tag = get_tag("bitm", cubemap)
		local multi_tag = get_tag("bitm", multipurpose_map)
		if cubemap_tag and multi_tag then
			write_dword(tag_data2 + 0xBC, read_dword(multi_tag))
			write_dword(tag_data2 + 0xBC + 0xC, read_dword(multi_tag + 0xC))
			if anniversary_fix then
				write_dword(tag_data1 + 0xBC, read_dword(multi_tag))
				write_dword(tag_data1 + 0xBC + 0xC, read_dword(multi_tag + 0xC))
			end
			
			write_dword(tag_data1 + 0x164, read_dword(cubemap_tag))
			write_dword(tag_data1 + 0x164 + 0xC, read_dword(cubemap_tag + 0xC))
			write_dword(tag_data2 + 0x164, read_dword(cubemap_tag))
			write_dword(tag_data2 + 0x164 + 0xC, read_dword(cubemap_tag + 0xC))
			
			write_float(tag_data1 + 0x144, perpendicular_brightness)
			WriteColor(tag_data1 + 0x148, perpendicular_color)
			write_float(tag_data1 + 0x154, parallel_brightness)
			WriteColor(tag_data1 + 0x158, parallel_color)
			
			write_float(tag_data2 + 0x144, perpendicular_brightness)
			WriteColor(tag_data2 + 0x148, perpendicular_color)
			write_float(tag_data2 + 0x154, parallel_brightness)
			WriteColor(tag_data2 + 0x158, parallel_color)
		end
		script_loaded = true
	else
		script_loaded = false
	end
	
	return false
end

SetTags()

function OnMapLoad()
	set_timer(700, "SetTags")
end

function SetupPistol(object)
	WriteColor(object + 0x1D0, primary_color)
	WriteColor(object + 0x1DC, secondary_color)
end

function ResetPistol(object)
	WriteColor(object + 0x1D0, {1, 1, 1})
	WriteColor(object + 0x1DC, {1, 1, 1})
end

function FindPistols()
	local player = get_dynamic_player()
	local object_count = read_word(object_table + 0x2E)
	local first_object = read_dword(object_table + 0x34)
	for i=0,object_count-1 do
		local object = read_dword(first_object + i * 0xC + 0x8)
		if object ~= 0 then
			local object_type = read_word(object + 0xB4)
			if object_type == 2 and GetName(object) == "weapons\\pistol\\pistol" then
				local parent = get_object(read_dword(object + 0x11C))
				if parent == player then
					SetupPistol(object)
				else
					ResetPistol(object)
				end
			end
		end
	end
end

function OnTick()
	if script_loaded then
		FindPistols()
	end
end