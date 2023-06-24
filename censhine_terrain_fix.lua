--CEnshine terrain fix script by aLTis. Version 1.0.1
--Fixes broken grass/dirt on some custom maps
--This script should ONLY be used if you use CEnshine!

--CONFIG
	fix_transparent_shaders = true -- Fixes black transparent shaders on some custom maps but makes them glow instead
--END OF CONFIG

clua_version = 2.042

set_callback("map load", "OnMapLoad")

function FixShader(tag)
	local tag_data = read_dword(tag + 0x14)
	local material_type = read_word(tag_data + 0x22)
	
	-- only change dirt, sand or snow
	if material_type == 0 or material_type == 1 or material_type == 3 then
		write_word(tag_data + 0x2A, 1) -- set to blended
	end
	
	if fix_transparent_shaders then
		local alpha_tested = read_bit(tag_data + 0x28, 0)
		if alpha_tested == 1 then
			local diffuse_bitmap = read_dword(tag_data + 0x88 + 0xC)
			local normal_bitmap = read_dword(tag_data + 0x128 + 0xC)
			if diffuse_bitmap ~= 0xFFFFFFFF and diffuse_bitmap == normal_bitmap then
				local white_bitmap_tag = get_tag("bitm", "ui\\shell\\bitmaps\\white")
				if white_bitmap_tag then
					write_float(tag_data + 0x19C, 1)
					write_float(tag_data + 0x19C+4, 1)
					write_float(tag_data + 0x19C+8, 1)
					write_dword(tag_data + 0x254, read_dword(white_bitmap_tag))
					write_dword(tag_data + 0x254+0xC, read_dword(white_bitmap_tag+0xC))
				end
			end
		end
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