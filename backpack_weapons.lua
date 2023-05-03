-- version 2023-04-23

local enable_in_vehicles = false -- set to false if you want weapons to not be visible if player is in a vehicle
local automatic_detection = true -- tries to guess where the weapon should be positioned if it's not referenced in the list
local only_on_servers = false -- if true, the script will only work when you join a server

local backpack_weap_z_offset = 0.1 -- how high up the weapon spawns

local WEAP_NAMES = {

-- CLASSIC MAPS
	["weapons\\assault rifle\\assault rifle"] = {["name"] = "ar"},
	["weapons\\shotgun\\shotgun"] = {["name"] = "sg"},
	["weapons\\sniper rifle\\sniper rifle"] = {["name"] = "sr"},
	["weapons\\pistol\\pistol"] = {["name"] = "p"},
	["weapons\\plasma pistol\\plasma pistol"] = {["name"] = "pp"},
	["weapons\\needler\\mp_needler"] = {["name"] = "n"},
	["weapons\\plasma rifle\\plasma rifle"] = {["name"] = "pr"},
	["weapons\\rocket launcher\\rocket launcher"] = {["name"] = "rl"},
	["weapons\\flamethrower\\flamethrower"] = {["name"] = "f"},
	["weapons\\plasma_cannon\\plasma_cannon"] = {["name"] = "frg"},
	["weapons\\gravity rifle\\gravity rifle"] = {["name"] = "ar"},
	
-- HCEA
	["hcea\\weapons\\plasma_cannon\\plasma_cannon"] = {["name"] = "frg"},
	
--COLDSNAP
	["weapons\\sniper\\sniper"] = {["name"] = "sr"},
	
--EXTINCTION
	["weapons\\sniper_rifle\\sniper_rifle"] = {["name"] = "sr"},
	["weapons\\nsniper\\nsniper_rifle"] = {["name"] = "ar"},
	["weapons\\beam_rifle\\beam_rifle"] = {["name"] = "ar"},
	["weapons\\big_sniper\\big_sniper"] = {["name"] = "sr"},
	["weapons\\smg_to_end_all\\smg"] = {["name"] = "p"},
	["weapons\\flak_cannon\\d_flak_cannon"] = {["name"] = "sr"},
	["weapons\\homing rocket launcher\\rocket launcher"] = {["name"] = "rl"},
	["weapons\\hpistol\\hpistol"] = {["name"] = "p"},
	["weapons\\hshotgun\\hshotgun"] = {["name"] = "sg"},
	["weapons\\ma2d\\assault rifle"] = {["name"] = "ar"},
	["weapons\\rifle\\rifle"] = {["name"] = "sr"},
	["weapons\\sg14\\sg14 sniper rifle"] = {["name"] = "sr"},
	
--CURSED HALO
	["weapons\\c assault rifle\\c assault rifle"] = {["name"] = "ar"},
	["weapons\\c pistol mp\\c pistol mp"] = {["name"] = "p"},
	["weapons\\c plasma pistol mp\\c plasma pistol mp"] = {["name"] = "pp"},
	["weapons\\c pink\\c pink"] = {["name"] = "pp"},
	["weapons\\c plasma cannon\\c plasma cannon"] = {["name"] = "frg"},
	["weapons\\c laser\\c laser"] = {["name"] = "pr"},
	["weapons\\c plasma rifle\\c plasma rifle mp"] = {["name"] = "pr"},
	["weapons\\c rocket launcher mp\\c rocket launcher mp"] = {["name"] = "rl"},
	["weapons\\c shotgun\\c shotgun"] = {["name"] = "sg"},
	["weapons\\c bow\\c bow"] = {["name"] = "p"},
	["weapons\\c needler\\c needler"] = {["name"] = "n"},
	["weapons\\c zapper\\c zapper"] = {["name"] = "p"},
	["weapons\\c triple\\c triple"] = {["name"] = "pr"},
	["weapons\\c axe\\c axe"] = {["name"] = "ar"},
	["weapons\\c sword\\c sword"] = {["name"] = "ar"},
	["weapons\\c double\\c double"] = {["name"] = "p"},
	["weapons\\c sniper rifle\\c sniper rifle"] = {["name"] = "sr"},
	
--UT2K4
	["weapons\\u2magnum\\u2magnum"] = {["name"] = "p"},
	["weapons\\link gun\\link gun"] = {["name"] = "ar"},
	["weapons\\impactgun\\impactgun"] = {["name"] = "ar"},
	["weapons\\bio rifle\\biorifle"] = {["name"] = "p"},
	["weapons\\redeemer\\redeemer"] = {["name"] = "f"},
	["weapons\\shock rifle\\shock rifle"] = {["name"] = "sr"},
	["weapons\\flak cannon\\flak cannon"] = {["name"] = "pr"},
	["weapons\\minigun\\minigun"] = {["name"] = "ar"},
	["weapons\\lightninggun\\lightninggun"] = {["name"] = "sr"},
	["weapons\\ut rocket launcher\\rocket launcher"] = {["name"] = "rl"},

--CHRONOPOLIS
	["weapons\\h2_smg\\h2_smg"] = {["name"] = "smg"},
	["weapons\\magnum\\pistol"] = {["name"] = "p"},
	
--MYSTIC
	["weapons\\assault rifle\\c3_assault rifle"] = {["name"] = "br"},
	["weapons\\plasma rifle\\c3 plasma rifle"] = {["name"] = "pr"},
	["weapons\\plasma pistol\\c3_plasma pistol"] = {["name"] = "pp"},
	["weapons\\shotgun\\c3_shotgun"] = {["name"] = "sg"},
	["weapons\\needler\\c3_needler"] = {["name"] = "sg"},

--H2
	["weapons\\smg\\smg"] = {["name"] = "p"},
	["weapons\\battle_rifle\\battle_rifle"] = {["name"] = "ar"},
	["weapons\\battle rifle\\battle rifle"] = {["name"] = "br"},
	["weapons\\battle_rifle\\battlerifle"] = {["name"] = "ar"},
	["weapons\\energy_sword\\energy_sword"] = {["name"] = "smg"},
	["weapons\\energy_sword\\energy sword"] = {["name"] = "smg"},
	
--SNOWDROP
	["cmt\\weapons\\human\\ma5k\\ma5k mp"] = {["name"] = "ar"},
	["weapons\\cad assault rifle\\assault rifle"] = {["name"] = "br"},
	["cmt\\weapons\\human\\shotgun\\shotgun"] = {["name"] = "sg2"},
	["weapons\\pistol\\reachpistol"] = {["name"] = "p"},
	["weapons\\gauss sniper\\gauss sniper"] = {["name"] = "br"},
	["halo3\\weapons\\battle rifle\\tactical battle rifle"] = {["name"] = "br"},

--ERASUS
	["cmt\\weapons\\covenant\\plasma_rifle\\plasma rifle"] = {["name"] = "pr"},
	["h2\\weapons\\single\\covenant_carbine\\covenant carbine"] = {["name"] = "br"},
	
-- TSCEv2
	["dreamweb\\weapon mie\\pompa"] = {["name"] = "sg"},
	["dreamweb\\weapon mie\\precisioneh2a"] = {["name"] = "ar"},
	["reach\\objects\\weapons\\rifle\\storm_forerunner_rifle\\storm_forerunner_rifle"] = {["name"] = "ar"},
	["weapons\\plasma_cannon\\plasma_cannon"] = {["name"] = "frg"},

-- TSCEv1
	["cmt\\weapons\\covenant\\brute_plasma_rifle\\reload\\brute plasma rifle"] = {["name"] = "pr"},
	["cmt\\weapons\\evolved_h1-spirit\\plasma_rifle\\_plasma_rifle_mp\\plasma_rifle_mp"] = {["name"] = "pr"},
	["cmt\\weapons\\evolved\\covenant\\carbine\\carbine"] = {["name"] = "ar"},
	
--AERIAL
	["aerial\\weapons\\shotgun\\shotgun"] = {["name"] = "ar"},
	["aerial\\weapons\\super shotgun\\super shotgun"] = {["name"] = "ar"},
	["aerial\\weapons\\plasma rifle\\plasma rifle"] = {["name"] = "ar"},
	["aerial\\weapons\\smg\\smg"] = {["name"] = "smg2"},
	["aerial\\weapons\\machete\\machete"] = {["name"] = "sword"},
}

local BLACKLISTED_WEAPONS = {
	["aerial\\weapons\\chaingun\\chaingun"] = true,
	["aerial\\weapons\\big fuelrod gun\\big fuelrod gun"] = true,
}

local BACK_WEAP_OFFSETS = {
--ASSAULT RIFLE
	["ar"] = {
		["x"] = -10,
		["y"] = 9.5,
		["z"] = -40,
		["rot1"] = -1,
		["rot2"] = 1,
		["rot3"] = -1,
		["node"] = "spine1",
	},
	
--SHOTGUN
	["sg"] = {
		["x"] = -80,
		["y"] = 9.5,
		["z"] = 60,
		["rot1"] = -1,
		["rot2"] = 1,
		["rot3"] = -1,
		["node"] = "spine1",
	},
	
--SHOTGUN2
	["sg2"] = {
		["x"] = -80,
		["y"] = 12,
		["z"] = 60,
		["rot1"] = -1,
		["rot2"] = 1,
		["rot3"] = -1,
		["node"] = "spine1",
	},
	
--SNIPER RIFLE
	["sr"] = {
		["x"] = -20,
		["y"] = 9.5,
		["z"] = 60,
		["rot1"] = -1,
		["rot2"] = 1,
		["rot3"] = -1,
		["node"] = "spine1",
	},
	
--PISTOL
	["p"] = {
		["x"] = -20,
		["y"] = -16,
		["z"] = -300,
		["rot1"] = 1,
		["rot2"] = -1,
		["rot3"] = -1,
		["node"] = "r thigh",
	},
	
--PLASMA PISTOL
	["pp"] = {
		["x"] = -14,
		["y"] = -16,
		["z"] = 60,
		["rot1"] = 1,
		["rot2"] = -1,
		["rot3"] = -1,
		["node"] = "r thigh",
	},
	
--NEEDLER
	["n"] = {
		["x"] = -20,
		["y"] = 8.5,
		["z"] = 80,
		["rot1"] = -1,
		["rot2"] = 1,
		["rot3"] = -1,
		["node"] = "spine1",
	},
	
--PLASMA RIFLE
	["pr"] = {
		["x"] = -13,
		["y"] = -19,
		["z"] = -180,
		["rot1"] = 1,
		["rot2"] = -1,
		["rot3"] = -1,
		["node"] = "r thigh",
	},
	
--ROCKET LAUNCHER
	["rl"] = {
		["x"] = -11,
		["y"] = 8.5,
		["z"] = -40,
		["rot1"] = -1,
		["rot2"] = 1,
		["rot3"] = -1,
		["node"] = "spine1",
	},
	
--FLAMETHROWER
	["f"] = {
		["x"] = 9,
		["y"] = 7,
		["z"] = 60,
		["rot1"] = 1,
		["rot2"] = -1,
		["rot3"] = -1,
		["node"] = "spine1",
	},
	
--FUEL ROD GUN
	["frg"] = {
		["x"] = 30,
		["y"] = 40,
		["z"] = 17,
		["rot1"] = -1,
		["rot2"] = -1,
		["rot3"] = 1,
		["node"] = "spine1",
	},

--SMG
	["smg"] = {
		["x"] = -60,
		["y"] = -16,
		["z"] = -100,
		["rot1"] = 1,
		["rot2"] = -1,
		["rot3"] = -1,
		["node"] = "r thigh",
	},

--SMG2
	["smg2"] = {
		["x"] = -10,
		["y"] = -15,
		["z"] = -50,
		["rot1"] = 1,
		["rot2"] = -1,
		["rot3"] = -1,
		["node"] = "r thigh",
	},
	
--BATTLE RIFLE
	["br"] = {
		["x"] = -10,
		["y"] = 13,
		["z"] = -40,
		["rot1"] = -1,
		["rot2"] = 1,
		["rot3"] = -1,
		["node"] = "spine1",
	},
	
--SWORD
	["sword"] = {
		["x"] = -6,
		["y"] = 17,
		["z"] = 22,
		["rot1"] = -1,
		["rot2"] = 1,
		["rot3"] = -1,
		["node"] = "spine1",
	},
}

clua_version = 2.042
local sqrt = math.sqrt
local find = string.find
local map_is_protected = true

local WEAP_NAMES_LOCAL = {}

local BACK_WEAP = {}
for i=0,15 do
	BACK_WEAP[i] = {}
	BACK_WEAP[i].id = nil
	BACK_WEAP[i].name = nil
	BACK_WEAP[i].node = nil
end

function CheckProtection()
	if get_tag("proj", "altis\\effects\\distance_check") ~= nil then -- make sure we don't run this on bigass v3
		return true
	end
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
            if read_dword(tag_k) == tag_class and read_string(read_dword(tag_k + 0x10)) == tag_path and tag_path ~= "MISSINGNO." then
                return true
            end
        end
    end
    return false
end

function AutomaticDetection()
	local tag_array = read_dword(0x40440000)
	local tag_count = read_dword(0x4044000C)
	for i = 0,tag_count - 1 do
		local tag = tag_array + i * 0x20
		local tag_class = read_dword(tag)
		if tag_class == 0x77656170 then
			local name = read_string(read_dword(tag + 0x10))
			if WEAP_NAMES[name] == nil then
				if automatic_detection then
					local new_name = nil
					if find(name, "pistol") or find(name, "magnum") or find(name, "revolver") then
						new_name = "p"
					elseif find(name, "rifle") then
						if find(name, "sniper") then
							new_name = "sr"
						elseif find(name, "plasma") then
							new_name = "pr"
						else
							new_name = "ar"
						end
					elseif find(name, "shotgun") then
						new_name = "sg"
					elseif find(name, "needler") then
						new_name = "n"
					elseif find(name, "smg") then
						new_name = "p"
					elseif find(name, "cannon") then
						new_name = "ar"
					elseif find(name, "rocket") then
						new_name = "rl"
					elseif find(name, "flame") then
						new_name = "f"
					elseif find(name, "laser") then
						new_name = "sg2"
					elseif find(name, "redeemer") then
						new_name = "ar"
					elseif find(name, "sniper") then
						new_name = "sr"
					elseif find(name, "gun") or find(name, "br") or find(name, "ar") or find(name, "dmr") or find(name, "ma5") then
						new_name = "ar"
					end
					
					if new_name ~= nil then
						WEAP_NAMES_LOCAL[name] = {["name"] = new_name}
					end
				end
			else
				WEAP_NAMES_LOCAL[name] = WEAP_NAMES[name]
			end
		end
	end
end

function RemoveUnusedNames()
	for name,info in pairs (WEAP_NAMES) do
		if get_tag("weap", name) ~= nil then
			WEAP_NAMES_LOCAL[name] = {["name"] = name}
		end
	end
end

function SetupTags()
	
	map_is_protected = CheckProtection()
	
	if map_is_protected == false and (only_on_servers == false or server_type == "dedicated") then
		
		WEAP_NAMES_LOCAL = {}
		AutomaticDetection()
		
		for name,info in pairs (WEAP_NAMES_LOCAL) do
			info.nodes = {}
			info.node_count = nil
			local tag = get_tag("weap", name)
			if tag ~= nil then
				local tag_data = read_dword(tag + 0x14)
				local model_tag = get_tag(read_dword(tag_data + 0x28 + 0xC))
				if model_tag ~= nil then
					local model_tag_data = read_dword(model_tag + 0x14)
					info.node_count = read_dword(model_tag_data + 0xB8)
					local node_address = read_dword(model_tag_data + 0xB8 + 4)
					for i=0,info.node_count-1 do
						local struct = node_address + i * 156
						info.nodes[i] = {}
						info.nodes[i].x = read_float(struct + 0x28)
						info.nodes[i].y = read_float(struct + 0x2C)
						info.nodes[i].z = read_float(struct + 0x30)
						info.nodes[i].rot1 = read_float(struct + 0x34)
						info.nodes[i].rot2 = read_float(struct + 0x38)
						info.nodes[i].rot3 = read_float(struct + 0x3C)
						info.nodes[i].rot4 = read_float(struct + 0x40)
					end
				end
			end
		end
	end
	return false
end

SetupTags()

set_callback("tick", "OnTick")
set_callback("unload", "OnUnload")
set_callback("map load", "OnMapLoad")

function OnMapLoad()
	map_is_protected = true
	
	for name,info in pairs (BACK_WEAP_OFFSETS) do
		info.nodes = nil
	end
	
	set_timer(700, "SetupTags")
end

function BackpackWeapons(i, player)
	if player ~= nil and read_float(player + 0xE0) ~= 0 then
		
		-- check if biped already has backpack weapons in this map
		local player_biped_name = GetName(player)
		local biped_tag = read_dword(get_tag("bipd", player_biped_name) + 0x14)
		local biped_model = read_dword(biped_tag + 0x28 + 0xC)
		local biped_model_tag = read_dword(get_tag(biped_model) + 0x14)
		local region_count = read_dword(biped_model_tag + 0xC4)
		local region_address = read_dword(biped_model_tag + 0xC8)
		if region_count > 1 then
			for j=1,region_count-1 do
				local struct = region_address + j*76
				local permutation_count = read_dword(struct + 0x40)
				if permutation_count > 7 then -- if there are many permutations
					return
				end
			end
		end
		
		local camo = read_float(player + 0x37C)
		local weapon_slot = read_byte(player + 0x2F2)
		if weapon_slot == 1 then
			weapon_slot = 0
		else
			weapon_slot = 1
		end
		local secondary_weapon = get_object(read_dword(player + 0x2F8 + 4*weapon_slot))
		local vehicle_id = get_object(read_dword(player + 0x11C))
		if secondary_weapon ~= nil and (vehicle_id == nil or enable_in_vehicles) then
			local x = read_float(player + 0x688 + 0x28)
			local y = read_float(player + 0x688 + 0x2C)
			local z = read_float(player + 0x688 + 0x30)
			local x_vel = read_float(player + 0x68)
			local y_vel = read_float(player + 0x6C)
			local z_vel = read_float(player + 0x70)
			if vehicle_id ~= nil then
				vehicle = get_object(vehicle_id)
				if vehicle ~= nil then
					x_vel = read_float(vehicle + 0x68)
					y_vel = read_float(vehicle + 0x6C)
					z_vel = read_float(vehicle + 0x70)
				end
			end
			local sec_weap_name = GetName(secondary_weapon)
			--console_out(sec_weap_name)
			local backpack_weapon = nil
			if BACK_WEAP[i].id ~= nil then
				backpack_weapon = get_object(BACK_WEAP[i].id)
			end
			
			if backpack_weapon ~= nil then
				local distance = GetDistance(backpack_weapon, player)
				if distance > 5 then
					RemoveBackpackWeapon(i)
				end
			end
			
			if get_tag("weap", sec_weap_name) ~= nil and (local_player_index == i and camera == 30400) == false and WEAP_NAMES_LOCAL[sec_weap_name] ~= nil and BLACKLISTED_WEAPONS[sec_weap_name] == nil and camo == 0 then
				
				local node_count = read_dword(biped_model_tag + 0xB8)
				local node_address = read_dword(biped_model_tag + 0xBC)
				
				for j=1,node_count-1 do
					local node_name = read_string(node_address + j*156)
					if find(node_name, BACK_WEAP_OFFSETS[WEAP_NAMES_LOCAL[sec_weap_name].name].node) then
						BACK_WEAP[i].node = 0x550 + 0x34*j
						break
					end
				end
				
				if (sec_weap_name ~= BACK_WEAP[i].name or backpack_weapon == nil) and BACK_WEAP[i].node ~= nil then
					RemoveBackpackWeapon(i)
					BACK_WEAP[i].id = spawn_object("weap", sec_weap_name, x, y, z+backpack_weap_z_offset)
				end
			else
				RemoveBackpackWeapon(i)
			end
			
			if BACK_WEAP[i].id ~= nil and BACK_WEAP[i].node ~= nil then
				local backpack_weapon = get_object(BACK_WEAP[i].id)
				if backpack_weapon ~= nil then
					BACK_WEAP[i].name = GetName(backpack_weapon)
					
					--prevent player from pickin up this weapon
					local m_player = get_player()
					if m_player ~= nil then
						local player_interaction_obj_id = read_dword(m_player + 0x24)
						if player_interaction_obj_id == BACK_WEAP[i].id then
							write_dword(m_player + 0x24, 0xFFFFFFFF)
						end
					end
					
					-- set cluster
					write_dword(backpack_weapon + 0x98, read_dword(player + 0x98))
					write_word(backpack_weapon + 0x9C, read_word(player + 0x9C))
					
					--make it not respawn (doesn't work?)
					write_dword(backpack_weapon + 0x204, 0xF000000)
					
					--Ignore gravity
					write_bit(backpack_weapon + 0x10, 2, 1)
					
					--Disable shadows
					write_bit(backpack_weapon + 0x10, 18, 1)
					write_float(backpack_weapon + 0xAC, 0.15)
					
					--Set ammo
					write_word(backpack_weapon + 0x2B6, 0)
					
					--Is in inventory
					write_bit(backpack_weapon + 0x1F4, 0, 1)
					
					--Remove collision
					write_bit(backpack_weapon + 0x1F4, 2, 1)
					
					--Set velocity
					--if math.floor(ticks())%10 == 1 then
						write_float(backpack_weapon + 0x68, 0.001)
					--else
					--	write_float(backpack_weapon + 0x68, 0)
					--end
					write_float(backpack_weapon + 0x6C, 0)
					write_float(backpack_weapon + 0x70, 0)
					
					local info = WEAP_NAMES_LOCAL[sec_weap_name]
					local info2 = BACK_WEAP_OFFSETS[WEAP_NAMES_LOCAL[sec_weap_name].name]
					
					if info.nodes ~= nil and info.node_count ~= nil then
						local address = player + BACK_WEAP[i].node
						
						local offset_from_x = info2.x
						local offset_from_y = info2.y
						local offset_from_z = info2.z
						
						local x_offset = -(read_float(address+0x4)/offset_from_x)-(read_float(address+0x10)/offset_from_y)-(read_float(address+0x1C)/offset_from_z)
						local y_offset = -(read_float(address+0x8)/offset_from_x)-(read_float(address+0x14)/offset_from_y)-(read_float(address+0x20)/offset_from_z)
						local z_offset = -(read_float(address+0xC)/offset_from_x)-(read_float(address+0x18)/offset_from_y)-(read_float(address+0x24)/offset_from_z)
						--ClearConsole()
						
						for j=0,info.node_count-1 do
							local address2 = backpack_weapon + 0x340 + j*0x34
							CopyNodeInfo(address, address2, 0, x_offset, y_offset, z_offset, info.nodes[j], j, info2.rot1, info2.rot2, info2.rot3, backpack_weapon)
						end
					end
				end
			end
		else
			RemoveBackpackWeapon(i)
		end
	else
		RemoveBackpackWeapon(i)
	end
end

function OnTick()
	if map_is_protected or (only_on_servers and server_type ~= "dedicated") then return end
	
	camera = read_word(0x647498)
	if server_type == "none" then
		local player = get_dynamic_player()
		BackpackWeapons(0, player)
	else
		for i=0,15 do
			local player = get_dynamic_player(i)
			BackpackWeapons(i, player)
		end
	end
end

function RemoveBackpackWeapon(i)
	if BACK_WEAP[i] ~= nil and BACK_WEAP[i].id ~= nil then
		local backpack_weapon = get_object(BACK_WEAP[i].id)
		if backpack_weapon ~= nil then
			delete_object(BACK_WEAP[i].id)
		end
		BACK_WEAP[i].id = nil
	end
end

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end

function CopyNodeInfo(address, address2, offset, x, y, z, node_info, j, rot1, rot2, rot3, backpack_weapon) -- copies node info from address to adddress2
	x2 = node_info.x
	y2 = node_info.y
	z2 = node_info.z
	address = address + (offset or 0x0)
	address2 = address2 + (offset or 0x0)
	write_float(address2 + 0x0,read_float(address + 0x0))	--scale
	
	local x_pos, y_pos, z_pos = read_float(address + 0x4)*rot1, read_float(address + 0x8)*rot1, read_float(address + 0xC)*rot1
	local x_pos2, y_pos2, z_pos2 = read_float(address + 0x10)*rot2, read_float(address + 0x14)*rot2, read_float(address + 0x18)*rot2
	local x_pos3, y_pos3, z_pos3 = read_float(address + 0x1C)*rot3, read_float(address + 0x20)*rot3, read_float(address + 0x24)*rot3
	
	-- copy rotation
	write_float(address2 + 0x4,x_pos)
	write_float(address2 + 0x8,y_pos)
	write_float(address2 + 0xC,z_pos)
	write_float(address2 + 0x10,x_pos2)
	write_float(address2 + 0x14,y_pos2)
	write_float(address2 + 0x18,z_pos2)
	write_float(address2 + 0x1C,x_pos3)
	write_float(address2 + 0x20,y_pos3)
	write_float(address2 + 0x24,z_pos3)
	
	-- change position of weapon's child nodes
	if j ~= 0 then
		--x = x + (x2*x_pos + y2*x_pos2 + z2*x_pos3)
		--y = y + (x2*y_pos + y2*y_pos2 + z2*y_pos3)
		--z = z + (x2*z_pos + y2*z_pos2 + z2*z_pos3)
		x = x + (x2*x_pos + y2*x_pos2 + z2*x_pos3)
		y = y + (x2*y_pos + y2*y_pos2 + z2*y_pos3)
		z = z + (x2*z_pos + y2*z_pos2 + z2*z_pos3)
	else
		--Change location of the weapon itself
		write_float(backpack_weapon + 0x5C, read_float(address + 0x28) + x)
		write_float(backpack_weapon + 0x60, read_float(address + 0x2C) + y)
		write_float(backpack_weapon + 0x64, read_float(address + 0x30) + z)
	end
	
	-- change position
	write_float(address2 + 0x28,read_float(address + 0x28) + x)
	write_float(address2 + 0x2C,read_float(address + 0x2C) + y)
	write_float(address2 + 0x30,read_float(address + 0x30) + z)
end

function OnUnload()
	for i=0,15 do
		RemoveBackpackWeapon(i)
	end
end

function GetDistance(object, player)
	local x = read_float(object + 0x5C)
	local y = read_float(object + 0x60)
	local z = read_float(object + 0x64)
	local x1 = read_float(player + 0x550 + 0x28)
	local y1 = read_float(player + 0x550 + 0x2C)
	local z1 = read_float(player + 0x550 + 0x30)
	local x_dist = x1 - x
	local y_dist = y1 - y
	local z_dist = z1 - z
	return math.sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
end

function ClearConsole()
	for j=0,25 do
		console_out(" ")
	end
end