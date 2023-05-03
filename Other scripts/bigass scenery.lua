--	Dynamic scenery script by aLTis
--	This script spawns scenery objects near the player
--	Objects are spawned on each edge of the BSP on a given material (should be grass or something)
--	Can only be used for one map at once, even if it is a global script

clua_version = 2.042

--CONFIG
	enable_script = false
	
	map_name = "bigass_mod"
	
	--PERFORMANCE
		density = 0.3		-- (0;1] controls how many objects appear, lowering this will increase performance greatly
		use_individual_ranges = true -- ignore the below value and use range for each object type from OBJECTS table
		max_distance = 45	-- objects will disappear after this distance, lowering this will increase performance
		range_by_scale = true -- reduces range of smaller objects, setting to true will increase performance (only works if use_individual_ranges is true)
	
	--VISUALS
		max_scale = 0.9		-- (0;1] maximum object scale, 1 is default
		scale_rand = 1.6 	-- (1;inf) how small can objects randomly get, 1 means objects can be extremely tiny
		loc_rand = 0 		-- how far away can an object be from its spawn location (recommended to use values below 0.5)
		steepness = 7		-- defines how steep the surface has to be (check "steep" in OBJECTS table)
	
	--SOUNDS
		enable_sound = true		-- play sounds when passing through scenery
		sound_tag = "altis\\effects\\bush\\bush"
		sound_rate = 2			-- delay after which a new sound can play (in ticks)
	
	
	-- if use_individual_ranges is true then range determines how far objects are visible
	-- weight determines how likely it is to spawn that object, (0;1]
	-- steep determines whether an object can spawn on steep angles (hills)
	OBJECTS = {
		[0] = {
			["path"] = "altis\\scenery\\bush\\bush_alt",
			["range"] = 45,
			["weight"] = 0.7,
			["steep"] = true,
		},
		[1] = {
			["path"] = "altis\\scenery\\grass_long_dry\\grass_long_dry",
			["range"] = 40,
			["weight"] = 0.9,
			["steep"] = false,
		},
		[2] = {
			["path"] = "altis\\scenery\\tomato\\tomato",
			["range"] = 32,
			["weight"] = 0.4,
			["steep"] = true,
		},
		[3] = {
			["path"] = "altis\\scenery\\mall_plant\\mall_plant",
			["range"] = 37,
			["weight"] = 0.4,
			["steep"] = true,
		},
		[4] = {
			["path"] = "altis\\scenery\\mall_bush\\mall_bush",
			["range"] = 43,
			["weight"] = 0.7,
			["steep"] = false,
		},
		[5] = {
			["path"] = "altis\\scenery\\grass_bush\\grass_bush",
			["range"] = 37,
			["weight"] = 0.4,
			["steep"] = true,
		},
		[6] = {
			["path"] = "altis\\scenery\\grass_swamp\\grass_swamp",
			["range"] = 40,
			["weight"] = 0.8,
			["steep"] = false,
		},
	}
	
	use_scenery = true	--	uses scenery object instead of bsp
	scenery_tag = "altis\\scenery\\bigassgrass\\bigassgrass"
	scenery_material_id = 1
	
	-- for materials, open the bsp that you want and go to collision material, find the material you want and put its ID here
	BSPS = {
		[0] = {
			["path"] = "altis\\levels\\bigass\\bigass",
			["material"] = 18,
		},
		[1] = {
			["path"] = "altis\\levels\\bigass\\bigassnight",
			["material"] = 17,
		},
		[2] = {
			["path"] = "altis\\levels\\bigass\\bigasssnow",
			["material"] = 0,
		},
	}

	z_offset = 1.48	-- changes z axis for all objects

	refresh_rate = 15 	-- in ticks (I need a much better method to optimize this) (must be higher than 1)
	object_spawn_limit = 400 -- how many objects can we spawn in one tick
	object_limit = 800	-- no more objects will be spawned once there are so many
--END OF CONFIG

--todo
--disable on snow mode
--still need to optimize OnTick stuff...

set_callback("unload", "OnUnload")
set_callback("tick", "OnTick")
set_callback("map load", "OnMapLoad")
set_callback("command", "OnCommand")

timer = 1
sound_timer = 0
current_bsp = nil
prev_x = 0
prev_y = 0
prev_z = 0
local cos = math.cos
local sin = math.sin
local random = math.random
local randomseed = math.randomseed
local sqrt = math.sqrt
local abs = math.abs

function OnMapLoad()
	BSP_VERTICES = nil
	current_bsp = nil
	if use_scenery then
		InitializeScenery()
	end
end

function OnCommand(Message)
	MESSAGE = {}
	for word in string.gmatch(Message, "([^".." ".."]+)") do 
		table.insert(MESSAGE, word)
	end
	
	if MESSAGE[1] == "enable_dynamic_scenery" then
		enable_script = true
		return false
	end
	
	if MESSAGE[1] == "density" then
		if MESSAGE[2] ~= nil and tonumber(MESSAGE[2]) >= 0 and tonumber(MESSAGE[2]) <= 1 then
			if bsp ~= nil then
				for vertice, info in pairs (BSP_VERTICES) do
					if info.ID ~= nil and get_object(info.ID) ~= nil then
						delete_object(info.ID)
					end
				end
			end
			density = tonumber(MESSAGE[2])
			current_bsp = get_global("client_tod")
			if use_scenery then
				InitializeScenery()
			else
				InitializeBSP(current_bsp)
			end
			console_out("Density set to "..density)
			return false
		else
			console_out(density)
			return false
		end
	end
end

function InitializeScenery()
	tag = get_tag("coll", scenery_tag)
	if tag == nil then return false end
	
	local BSP_SURFACES = {}
	local BSP_EDGES = {}
	BSP_VERTICES = {}
	surfaces = 0
	edges = 0
	vertices = 0

	bsp_data = read_dword(tag + 0x14)
	nodes = read_dword(bsp_data + 0x28C + 4)
	collision_bsp = read_dword(nodes + 0x34 + 4)

	surface_count = read_dword(collision_bsp + 0x3C)
	surface_address = read_dword(collision_bsp + 0x3C + 4)

	for i=0,surface_count-1 do
		if random() < density then -- I could use randomseed here
			local address = surface_address + i * 12
			if read_word(address + 0x0A) == scenery_material_id then
				BSP_SURFACES[surfaces] = read_dword(address + 0x04)
				surfaces = surfaces + 1
			end
		end
	end

	edge_count = read_dword(collision_bsp + 0x48)
	edge_address = read_dword(collision_bsp + 0x48 + 4)

	for id, edge in pairs(BSP_SURFACES) do
		if edge < edge_count then
			BSP_EDGES[edges] = {}
			BSP_EDGES[edges].first = read_dword(edge_address + edge * 24)
			BSP_EDGES[edges].last = read_dword(edge_address + edge * 24 + 0x04)
			edges = edges + 1
		end
	end

	vertice_count = read_dword(collision_bsp + 0x54)
	vertice_address = read_dword(collision_bsp + 0x54 + 4)

	for id, edge in pairs(BSP_EDGES) do
		if edge.first < vertice_count and edge.last < vertice_count then
			local address = vertice_address + edge.first * 16
			local address2 = vertice_address + edge.last * 16
			local x1 = read_float(address)
			local x2 = read_float(address2)
			local y1 = read_float(address + 4)
			local y2 = read_float(address2 + 4)
			local z1 = read_float(address + 8)
			local z2 = read_float(address2 + 8)
			local seed = id
			randomseed(seed)
			local randomness = random()
			local x_dist = x2 - x1
			local y_dist = y2 - y1
			local x_offset = x_dist * randomness
			local y_offset = y_dist * randomness
			local z_offset = (z2 - z1) * randomness
			
			BSP_VERTICES[id] = {}
			BSP_VERTICES[id].x = x1 + x_offset
			BSP_VERTICES[id].y = y1 + y_offset
			BSP_VERTICES[id].z = z1 + z_offset
			
			local distance = sqrt(x_dist*x_dist + y_dist*y_dist)
			if distance / sqrt(z2 - z1) > steepness then
				BSP_VERTICES[id].steep = true
			else
				BSP_VERTICES[id].steep = false
			end
			
			repeat
				local weight_check = random()
				local object_check = random(0,#OBJECTS)
				if OBJECTS[object_check].steep ~= BSP_VERTICES[id].steep and OBJECTS[object_check].weight > weight_check then
					BSP_VERTICES[id].obj = object_check
					BSP_VERTICES[id].rot1 =  sin(randomness*6) -- could use 2*pi but whatevs
					BSP_VERTICES[id].rot2 =  cos(randomness*6)
					BSP_VERTICES[id].scale = 1 - (randomness/scale_rand)
				else
					seed = seed + x2 - z2
					randomseed(seed)
				end
			until BSP_VERTICES[id].obj ~= nil
			vertices = vertices + 1
		end
	end
	
	--console_out("Vertices: "..vertices)
	return false
end

function InitializeBSP(bsp_tod)
	bsp = get_tag("sbsp", BSPS[bsp_tod].path)
	if bsp == nil then return false end
	
	local BSP_SURFACES = {}
	local BSP_EDGES = {}
	BSP_VERTICES = {}
	surfaces = 0
	edges = 0
	vertices = 0

	bsp_data = read_dword(bsp + 0x14)
	collision_bsp = read_dword(bsp_data + 0xB0 + 4)

	surface_count = read_dword(collision_bsp + 0x3C)
	surface_address = read_dword(collision_bsp + 0x3C + 4)

	for i=0,surface_count-1 do
		if random() < density then -- I could use randomseed here
			local address = surface_address + i * 12
			if read_word(address + 0x0A) == BSPS[bsp_tod].material then
				BSP_SURFACES[surfaces] = read_dword(address + 0x04)
				surfaces = surfaces + 1
			end
		end
	end

	edge_count = read_dword(collision_bsp + 0x48)
	edge_address = read_dword(collision_bsp + 0x48 + 4)

	for id, edge in pairs(BSP_SURFACES) do
		if edge < edge_count then
			BSP_EDGES[edges] = {}
			BSP_EDGES[edges].first = read_dword(edge_address + edge * 24)
			BSP_EDGES[edges].last = read_dword(edge_address + edge * 24 + 0x04)
			edges = edges + 1
		end
	end

	vertice_count = read_dword(collision_bsp + 0x54)
	vertice_address = read_dword(collision_bsp + 0x54 + 4)

	for id, edge in pairs(BSP_EDGES) do
		if edge.first < vertice_count and edge.last < vertice_count then
			local address = vertice_address + edge.first * 16
			local address2 = vertice_address + edge.last * 16
			local x1 = read_float(address)
			local x2 = read_float(address2)
			local y1 = read_float(address + 4)
			local y2 = read_float(address2 + 4)
			local z1 = read_float(address + 8)
			local z2 = read_float(address2 + 8)
			local seed = id
			randomseed(seed)
			local randomness = random()
			local x_dist = x2 - x1
			local y_dist = y2 - y1
			local x_offset = x_dist * randomness
			local y_offset = y_dist * randomness
			local z_offset = (z2 - z1) * randomness
			
			BSP_VERTICES[id] = {}
			BSP_VERTICES[id].x = x1 + x_offset
			BSP_VERTICES[id].y = y1 + y_offset
			BSP_VERTICES[id].z = z1 + z_offset
			
			local distance = sqrt(x_dist*x_dist + y_dist*y_dist)
			if distance / sqrt(z2 - z1) > steepness then
				BSP_VERTICES[id].steep = true
			else
				BSP_VERTICES[id].steep = false
			end
			
			repeat
				local weight_check = random()
				local object_check = random(0,#OBJECTS)
				if OBJECTS[object_check].steep ~= BSP_VERTICES[id].steep and OBJECTS[object_check].weight > weight_check then
					BSP_VERTICES[id].obj = object_check
					BSP_VERTICES[id].rot1 =  sin(randomness*6) -- could use 2*pi but whatevs
					BSP_VERTICES[id].rot2 =  cos(randomness*6)
					BSP_VERTICES[id].scale = 1 - (randomness/scale_rand)
				else
					seed = seed + x2 - z2
					randomseed(seed)
				end
			until BSP_VERTICES[id].obj ~= nil
			vertices = vertices + 1
		end
	end
	
	--console_out("Vertices: "..vertices)
	return false
end

function OnTick()
	if enable_script == false then return false end -- use to disable the script
	if map ~= map_name then return false end
	
	local bsp_tod = get_global("client_tod")
	
	if use_scenery == false then
		-- check if TOD has switched or the map wasn't loaded yet
		if current_bsp ~= bsp_tod then
			InitializeBSP(bsp_tod)
			current_bsp = bsp_tod
		end
	else
		if bsp_tod == 2 then return false end
		if BSP_VERTICES == nil then
			InitializeScenery()
		end
	end
	if timer > 0 then
		timer = timer - 1
	else
		timer = refresh_rate
	end
	
	local active_objects = 0
	local spawned_objects = 0
	
	local player = get_dynamic_player()
	if player ~= nil then
		local x = read_float(player + 0x5C)
		local y = read_float(player + 0x60)
		local x_vel = read_float(player + 0x68)
		local y_vel = read_float(player + 0x6C)
		local z = read_float(player + 0x64)
		local vehicle = get_object(read_dword(player + 0x11C))
		if vehicle ~= nil then
			x = read_float(vehicle + 0x5C)
			y = read_float(vehicle + 0x60)
			z = read_float(vehicle + 0x64)
			x_vel = read_float(vehicle + 0x68)
			y_vel = read_float(vehicle + 0x6C)
			sound_distance = 0.6
		else
			sound_distance = 0.3
		end
		local velocity = abs(x_vel) + abs(y_vel)	
		
		if GetDistance(x, y, z, prev_x, prev_y, prev_z) > 5 then
			timer = 1
		end
		prev_x = x
		prev_y = y
		prev_z = z
		
		for vertice, info in pairs (BSP_VERTICES) do
			if timer == 1 or info.ID ~= nil then
				local distance = GetDistance(x, y, z, info.x, info.y, info.z)
				if use_individual_ranges then
					if range_by_scale then
						max_distance = OBJECTS[info.obj].range * info.scale
					else
						max_distance = OBJECTS[info.obj].range
					end
				end
				
				if info.ID ~= nil then
					active_objects = active_objects + 1
					-- remove the object if it's too far away
					if distance > max_distance then
						if get_object(info.ID) ~= nil then
							delete_object(info.ID)
						end
						info.ID = nil
					else
						local object = get_object(info.ID)
						-- rotate the object if it has just spawned
						if object ~= nil then
							if info.new then
								write_float(object + 0x74, info.rot1)
								write_float(object + 0x78, info.rot2)
								write_float(object + 0x64, info.z + z_offset)
								info.new = false
							end
							--change scale based on distance from the player
							local scale = max_scale*info.scale
							--I don't know if it optimizes the process or just makes it even worse lol
							if distance > max_distance/1.8 then
								local scale2 = (1-distance/max_distance)*2
								if scale > scale2 then 
									scale = scale2
								end
							elseif enable_sound and distance < sound_distance and velocity > 0.07 then
								if sound_timer == 0 then
									local bush_sound_obj = spawn_object("garb", sound_tag, x, y, z)
									delete_object(bush_sound_obj)
									sound_timer = sound_rate
								else
									sound_timer = sound_timer - 1
								end
							end
							
							--change scale
							write_float(object + 0xB0, scale)
						end
					end
				elseif distance < max_distance and spawned_objects < object_spawn_limit and active_objects < object_limit then
					local z_coord = info.z
					-- this would make objects spawn above ground but they have wrong scale and rotation so it doesn't really improve much
					--if distance < max_distance/1.8 then
					--	z_coord = z_coord + 1.48
					--else
						z_coord = z_coord + 0.5
					--end
					--spawn a new object
					if loc_rand == 0 then
						info.ID = spawn_object("scen", OBJECTS[info.obj].path, info.x, info.y, z_coord)
					else
						info.ID = spawn_object("scen", OBJECTS[info.obj].path, info.x + random()*loc_rand, info.y + random()*loc_rand, z_coord)
					end
					info.new = true
					active_objects = active_objects + 1
					spawned_objects = spawned_objects + 1
				end
			end
		end
	end
	--ClearConsole()
	--console_out("total objects "..vertices)
	--console_out("active objects "..active_objects)
end

function ClearConsole()
	for i=0,30 do
		console_out(" ")
	end
end

function GetDistance(x, y, z, x1, y1, z1)
	local x_dist = x1 - x
	local y_dist = y1 - y
	local z_dist = z1 - z
	return sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
end

function OnUnload()
	if BSP_VERTICES ~= nil then
		for vertice, info in pairs (BSP_VERTICES) do
			if info.ID ~= nil and get_object(info.ID) ~= nil then
				delete_object(info.ID)
			end
		end
	end
end

