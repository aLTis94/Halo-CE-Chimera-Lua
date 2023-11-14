	-- version 1.0.1
-- FEATURES:
	-- fixes grenade throw animation when walking, jumping, crouching, riding a vehicle
	-- should work on all maps, including protected maps
	-- will now support multiple bipeds in the same map

-- KNOWN ISSUES:
	-- only works on multiplayer and only if you are not the host
	-- only fixes in client side so what you see other players doing will not match what's happening on the server
	-- spamming grenade throw key in third person will repeat the animation
	
-- CHANGELOG:
-- 1.0.1
-- fixed support for animation tags with over 256 animations

clua_version = 2.042

BIPEDS = {}
GRENADES = {}
GRENADE_TAGS = {}
map_is_protected = true

local find = string.find

set_callback("tick", "OnTick")
set_callback("map load", "OnMapLoad")

function CheckProtection()
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
            if read_dword(tag_k) == tag_class and read_string(read_dword(tag_k + 0x10)) == tag_path then
                return true
            end
        end
    end
    return false
end

function OnMapLoad()
	BIPEDS = {}
	if server_type == "dedicated" then
		SetupAnimationTag()
	end
end

function FindAllBipeds()
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        if tag_class == 0x62697064 then
			local meta_id = read_dword(tag + 0x0C)
			local tag_data = read_dword(tag + 0x14)
			BIPEDS[meta_id] = {}
			BIPEDS[meta_id].tag_data = tag_data
			BIPEDS[meta_id].name = read_string(read_dword(tag + 0x10))
		end
	end
end

function GetGrenades()
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        if tag_class == 0x6D617467 then
            tag = read_dword(tag + 0x14)
			local grenade_count = read_dword(tag+0x128)
			local grenade_address = read_dword(tag+0x12C)
			GRENADE_TAGS = {}
			for i=0,grenade_count-1 do
				local struct = grenade_address + i*68
				GRENADE_TAGS[i] = read_string(read_dword(struct + 0x34 + 0x4))
			end
		end
	end
end

function SetupAnimationTag()
	map_is_protected = CheckProtection()
	
	if map_is_protected == false then
		GetGrenades()
	end
	
	FindAllBipeds()
	
	for meta_id, INFO in pairs (BIPEDS) do
		local anim_tag = get_tag(read_dword(INFO.tag_data + 0x38 + 0xC))
		if anim_tag ~= nil then
			local anim_tag_data = read_dword(anim_tag + 0x14)
			
			local node_count = read_dword(anim_tag_data + 0x68)
			local node_address = read_dword(anim_tag_data + 0x6C)
			
			INFO.node = nil
			
			for j=0,node_count-1 do
				local node_name = read_string(node_address + j*64)
				if find(node_name, "l hand") then
					INFO.node = 0x550 + 0x28 + 0x34*j
					break
				end
			end
			
			local unit_count = read_dword(anim_tag_data + 0x0C)
			local unit_address = read_dword(anim_tag_data + 0x0C + 4)
			for i=0,unit_count-1 do
				if INFO.anim_id == nil then
					local struct = unit_address + i * 100
					local weap_count = read_dword(struct + 0x58)
					local weap_address = read_dword(struct + 0x58 + 4)
					for i=0,weap_count-1 do
						local struct = weap_address + i * 188
						local anim_count = read_dword(struct + 0x98)
						if anim_count > 19 then
							local anim_address = read_dword(struct + 0x98 + 4)
							local struct = anim_address + 20 * 2
							local anim = read_word(struct)
							if anim ~= 0xFFFF then
								local animation_count = read_dword(anim_tag_data + 0x74)
								local animation_address = read_dword(anim_tag_data + 0x74 + 4)
								if animation_count > anim then
									local struct = animation_address + anim * 180
									write_byte(struct + 0x20, 2) -- changes type from base to replacement
									INFO.anim_id = anim
									INFO.keyframe = read_short(struct + 0x34)
									break
								end
							end
						end
					end
				end
			end
		end
	end
	return false
end

if server_type == "dedicated" then
	SetupAnimationTag()
end

function OnTick()
	if server_type == "dedicated" then
		for i=0,15 do
			if read_word(0x647498) ~= 30400 or i ~= local_player_index then
				local player = get_dynamic_player(i)
				if player ~= nil then
					local meta_id = read_dword(player)
					
					if BIPEDS[meta_id] == nil and map_is_protected == false then
						local name = GetName(player)
						for META_ID,INFO in pairs (BIPEDS) do
							if INFO.name == name then
								BIPEDS[meta_id] = INFO
								break
							end
						end
					end
					
					if BIPEDS[meta_id] ~= nil and BIPEDS[meta_id].anim_id ~= nil and BIPEDS[meta_id].anim_id ~= -1 then
						if read_byte(player + 0x2A3) == 33 then
							write_byte(player + 0x2A3, 999)-- switches the main anim
							PlayReplacementAnimation(player, BIPEDS[meta_id].anim_id)
							
							if map_is_protected == false and BIPEDS[meta_id].node then
								local x,y,z = read_vector3D(player+BIPEDS[meta_id].node)
								local grenade_type = read_char(player + 0x31C)
								if GRENADES[i] and get_object(GRENADES[i].id) then
									delete_object(GRENADES[i].id)
								end
								if get_tag("proj", GRENADE_TAGS[grenade_type]) then
									local new_id = spawn_object("proj", GRENADE_TAGS[grenade_type],x,y,z)
									if new_id then
										GRENADES[i] = {}
										GRENADES[i].id = new_id
										GRENADES[i].timer = BIPEDS[meta_id].keyframe-2
									end
								end
							end
						end
					end
					
					if GRENADES[i] then
						local object = get_object(GRENADES[i].id)
						if object then
							GRENADES[i].timer = GRENADES[i].timer - 1
							if GRENADES[i].timer < 1 then
								delete_object(GRENADES[i].id)
								GRENADES[i] = nil
							else
								local m_player = get_player(i)
								local player_obj_id = read_dword(m_player + 0x34)
								write_dword(object + 0xC4, player_obj_id)
								--write_dword(object + 0x11C, player_obj_id)
								write_dword(object + 0x234, player_obj_id)
								local x,y,z = read_vector3D(player+BIPEDS[meta_id].node)
								write_vector3D(object + 0x5C,x,y,z)
								write_vector3D(object + 0x68,0,0,0)
								write_bit(object + 0x22C, 3, 1) -- make sure projectile doesn't detonate
								write_float(object + 0x248, 0) -- set detonation timer to 0
							end
						else
							GRENADES[i] = nil
						end
					end
				else
					GRENADES[i] = nil
				end
			end
		end
	end
end

function PlayReplacementAnimation(player, anim_id)
	write_word(player + 0x2AC, 999)	--resets the animation in case it was already playing
	write_word(player + 0x2AA, anim_id)--changes the animation that is playing
	write_word(player + 0x2A4, 5)	--removes left hand from the weapon
	write_word(player + 0xD4, 5)	--makes animation switch instantly
end

function read_vector3D(address)
	return read_float(address),read_float(address+4),read_float(address+8)
end

function write_vector3D(address,x,y,z)
	write_float(address,x)
	write_float(address+4,y)
	write_float(address+8,z)
end

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end