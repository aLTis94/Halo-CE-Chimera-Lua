clua_version = 2.042

--CONFIG
	
	--detail_function: 0 - Double/Biased Multiply; 1 - Multiply; 2 - Double/Biased Add
	
	SHADER_MODELS = {
		["scenery\\c_storage\\shaders\\c_storage"] = {
			["detail_after_reflection"] = 0,
			["detail_map_scale"] = 18,
			["detail_map_v_scale"] = 0.25,
		},
		["scenery\\rocks\\boulder_granite_gigantic\\shaders\\boulder_granite_gigantic"] = {
			["detail_map_scale"] = 15,
		},
		["scenery\\rocks\\boulder_snow_large\\shaders\\boulder_snow_large"] = {
			["detail_map_scale"] = 9,
		},
	}
	
	SHADER_ENVIRONMENTS = {
		["levels\\test\\dangercanyon\\shaders\\dangercanyon_cliff_walls"] = {
			["rescale_detail_maps"] = 0,
			["primary_scale"] = 4,
			["micro_scale"] = 20,
		},
		["levels\\test\\beavercreek\\shaders\\beavercreek cliffs"] = {
			["primary_scale"] = 3,
			["micro_scale"] = 30,
		},
		["levels\\test\\beavercreek\\shaders\\beavercreek boulder"] = {
			["primary_scale"] = 6,
			["micro_scale"] = 10,
		},
		["levels\\b30\\shaders\\metal strips wide"] = {
			["rescale_detail_maps"] = 1,
			["micro_scale"] = 3,
		},
		["levels\\b30\\shaders\\metal strips wide a"] = {
			["rescale_detail_maps"] = 1,
			["micro_scale"] = 3,
		},
	}
	
	COLLISION_GEOMETRY = {
		["scenery\\c_storage_large\\c_storage_large"] = 5,
		["powerups\\active camoflage\\active camoflage"] = 18,
	}
	
--END OF CONFIG

set_callback("map load", "OnMapLoad")
--set_callback("tick", "OnTick")

function OnTick()
	local object = get_dynamic_player()
	if object ~= nil then
	end
end

function OnMapLoad()
	FixStuff()
end

function FixStuff()
	for path,info in pairs (SHADER_MODELS) do
		ChangeShaderModel(path)
	end
	
	for path,info in pairs (SHADER_ENVIRONMENTS) do
		ChangeShaderEnvironment(path)
	end
	
	for path,info in pairs (COLLISION_GEOMETRY) do
		ChangeCollisionGeometry(path, info)
	end
	
	-- fix pistol effect for hollow metal
	local effect = get_tag("effe", "weapons\\pistol\\effects\\impact metal hollow reflect")
	if effect ~= nil then
		effect = read_dword(effect + 0x14)
		
		local events = read_dword(effect + 0x34 + 4)
		if events ~= nil and events ~= 0xFFFFFFFF then
			local particle_address = read_dword(events + 0x38 + 4)
			local particle = particle_address + 232 * 4
			if particle ~= nil and particle ~= 0xFFFFFFFF then
				write_float(particle + 0xA0, 0.025)
				write_float(particle + 0xA4, 0.07)
			end
		end
	end
	
	-- fix shotgun effect for engineer skin (powerups)
	local effect = get_tag("effe", "weapons\\shotgun\\effects\\impact engineer force field")
	if effect ~= nil then
		effect = read_dword(effect + 0x14)
		
		local events = read_dword(effect + 0x34 + 4)
		if events ~= nil and events ~= 0xFFFFFFFF then
			write_float(events + 0x10, 0)
			write_float(events + 0x14, 0)
		end
	end
end

function ChangeShaderModel(path)
	local shader = get_tag("soso", path)
	if shader ~= nil then
		local shader = read_dword(shader + 0x14)
		
		--model shader flags
		if SHADER_MODELS[path].detail_after_reflection ~= nil then
			write_bit(shader + 0x28, 0, SHADER_MODELS[path].detail_after_reflection)
		end
		
		--diffuse map
		if SHADER_MODELS[path].u_scale ~= nil then
			write_float(shader + 0x9C, SHADER_MODELS[path].u_scale)
		end
		if SHADER_MODELS[path].v_scale ~= nil then
			write_float(shader + 0xA0, SHADER_MODELS[path].v_scale)
		end
		
		--detail map
		if SHADER_MODELS[path].detail_function ~= nil then
			write_short(shader + 0xD4, SHADER_MODELS[path].detail_function)
		end
		if SHADER_MODELS[path].detail_mask ~= nil then
			write_short(shader + 0xD6, SHADER_MODELS[path].detail_mask)
		end
		if SHADER_MODELS[path].detail_map_scale ~= nil then
			write_float(shader + 0xD8, SHADER_MODELS[path].detail_map_scale)
		end
		if SHADER_MODELS[path].detail_map_v_scale ~= nil then
			write_float(shader + 0xEC, SHADER_MODELS[path].detail_map_v_scale)
		end
	end
end

function ChangeShaderEnvironment(path)
	local shader = get_tag("senv", path)
	if shader ~= nil then
		local shader = read_dword(shader + 0x14)
		
		--rescale maps
		if SHADER_ENVIRONMENTS[path].rescale_detail_maps ~= nil then
			write_bit(shader + 0x6C, 0, SHADER_ENVIRONMENTS[path].rescale_detail_maps)
		end
		if SHADER_ENVIRONMENTS[path].rescale_bump_maps ~= nil then
			write_bit(shader + 0x6C, 1, SHADER_ENVIRONMENTS[path].rescale_bump_maps)
		end
		
		--detail maps
		if SHADER_ENVIRONMENTS[path].detail_function ~= nil then
			write_short(shader + 0xB0, SHADER_ENVIRONMENTS[path].detail_function)
		end
		if SHADER_ENVIRONMENTS[path].primary_scale ~= nil then
			write_float(shader + 0xB4, SHADER_ENVIRONMENTS[path].primary_scale)
		end
		if SHADER_ENVIRONMENTS[path].secondary_scale ~= nil then
			write_float(shader + 0xC8, SHADER_ENVIRONMENTS[path].secondary_scale)
		end
		
		--micro detail
		if SHADER_ENVIRONMENTS[path].micro_function ~= nil then
			write_short(shader + 0xF4, SHADER_ENVIRONMENTS[path].micro_function)
		end
		if SHADER_ENVIRONMENTS[path].micro_scale ~= nil then
			write_float(shader + 0xF8, SHADER_ENVIRONMENTS[path].micro_scale)
		end
	end
end

function ChangeCollisionGeometry(path, material)
	local tag = get_tag("coll", path)
	if tag ~= nil then
		local tag = read_dword(tag + 0x14)
		local struct = read_dword(tag + 0x234 + 4)
		
		if struct ~= nil and struct ~= 0xFFFFFFFF then
			write_short(struct + 0x24, material)
		end
	end
end

FixStuff()