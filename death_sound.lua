-- 2020-12-26
-- CONFIG
	
	use_airborne_sound = true -- tries to play death sound when dying in air or from explosives
	use_violent_count = false -- if true, it will use violent death sound. If false it will use quiet one
	
-- END OF CONFIG

clua_version = 2.042

if use_violent_count then
	sound_type = 0x100
else
	sound_type = 0xF0
end

set_callback("map load", "OnMapLoad")
if use_airborne_sound then
	set_callback("tick", "OnTick")
end

local death_sound_enable = false
local death_timer = 0

local PLAYER_ALIVE = {}
local PLAYER_AIRBORNE_ADDRESS = {}
for i=0,15 do
	PLAYER_ALIVE[i] = false
end

function OnMapLoad()
	death_sound_enable = false
	airborne_dead_address = nil
	set_timer(1000, "DoSoundTagStuff")
end

function DoSoundTagStuff()
	airborne_dead_address = {}
	if server_type ~= "dedicated" then return false end
	local tag_array = read_dword(0x40440000)
    local tag_count = read_dword(0x4044000C)
    for i = 0,tag_count - 1 do
        local tag = tag_array + i * 0x20
        local tag_class = read_dword(tag)
        if tag_class == 0x62697064 then
			local tag = read_dword(tag + 0x14)
			local dialog_count = read_dword(tag + 0x2B4)
			if dialog_count > 0 then
				local dialog_address = read_dword(tag + 0x2B8)
				local dialog_tag = get_tag(read_dword(dialog_address + 0x08 + 0xC))
				if dialog_tag ~= nil then
					dialog_tag = read_dword(dialog_tag + 0x14)
					local death_sound_meta_id = read_dword(dialog_tag + sound_type + 0xC)
					local death_sound_tag = get_tag(death_sound_meta_id)
					if death_sound_tag ~= nil then
						local animation_tag = get_tag(read_dword(tag + 0x38 + 0xC))
						if animation_tag ~= nil then
							animation_tag = read_dword(animation_tag + 0x14)
							
							local sounds_count =  read_dword(animation_tag + 0x54)
							local sounds_address = read_dword(animation_tag + 0x58)
							for l=0,sounds_count - 1 do
								local struct = sounds_address + l*20
								local path_address = read_dword(struct + 0x4)
								if path_address ~= 0xFFFFFFFF and string.find(read_string(path_address), "skillfrontgut") ~= nil then
									
									write_dword(struct + 0xC, death_sound_meta_id)
									
									local anim_count = read_dword(animation_tag + 0x74)
									local anim_address = read_dword(animation_tag + 0x78)
									for k=0,anim_count - 1 do
										local struct = anim_address + k*180
										if string.find(read_string(struct), "kill") ~= nil then
											write_word(struct + 0x3C, l)
											write_word(struct + 0x3E, 0)
										elseif use_airborne_sound and read_string(struct)== "stand airborne-dead" then
											death_sound_enable = true
											airborne_dead_address[read_dword(tag + 0xC)] = struct + 0x3C
										end
									end
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

DoSoundTagStuff()

function OnTick()
	if death_sound_enable and airborne_dead_address ~= nil then
		for i=0,15 do
			local player = get_dynamic_player(i)
			if player ~= nil then
				PLAYER_ALIVE[i] = true
				PLAYER_AIRBORNE_ADDRESS[i] = read_dword(player + 0xC)
			else
				if PLAYER_ALIVE[i] then
					if PLAYER_AIRBORNE_ADDRESS[i] ~= nil and airborne_dead_address[PLAYER_AIRBORNE_ADDRESS[i]] ~= nil then
						write_word(airborne_dead_address[PLAYER_AIRBORNE_ADDRESS[i]], 0)
						write_word(airborne_dead_address[PLAYER_AIRBORNE_ADDRESS[i]]+2, 1)
					end
					PLAYER_ALIVE[i] = false
					death_timer = 5
					return
				end
				PLAYER_ALIVE[i] = false
			end
		end
		
		if death_timer < 1 then
			for biped,address in pairs (airborne_dead_address) do
				write_word(address, -1)
			end
		else
			death_timer = death_timer - 1
		end
	end
end