--CEnshine terrain fix script by aLTis. Version 1.0.0 
--Fixes broken grass/dirt on some custom maps
--This script should ONLY be used if you use CEnshine!

clua_version = 2.042

set_callback("map load", "OnMapLoad")

function FixShader(tag)
	local tag_data = read_dword(tag + 0x14)
	local material_type = read_word(tag_data + 0x22)
	
	-- only change dirt and sand
	if material_type == 0 or material_type == 1 or material_type == 3 then
		write_word(tag_data + 0x2A, 1) -- set to blended
	end
end

function FindShaders()
	local tag_count = read_dword(0x4044000C)
	
    for i = 0,tag_count - 1 do
        local tag = get_tag(i)
		local tag_class = read_dword(tag)
		if tag_class == 0x73656E76 then
			FixShader(tag)
		end
	end
end

FindShaders()

function OnMapLoad()
	FindShaders()
end