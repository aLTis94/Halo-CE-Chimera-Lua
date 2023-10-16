-- This script allows you to spawn in any object that is in the map files. Should work on protected maps too.
-- !!!WARNING!!! - This script should not be used in multiplayer games because spawned objects will not sync.

-- Controls:
-- Arrow keys to use the spawn menu
-- 1 - open spawn menu
-- 3 - devcam
-- 4 - cheat_all_weapons
-- 5 - cheat_all_vehicles

local keyboard_input_address = 0x64C550
local mouse_input_address = 0x64C73C
--CONFIG

	local scroll_speed = 8 -- lower means faster
	local scroll_start_delay = 15 -- how long to hold before scrolling
	local max_radius = 3 -- furthest distance an object can spawn
	
	local esc_key = keyboard_input_address
	local open_menu_key = keyboard_input_address + 17
	local open_info_key = keyboard_input_address + 18
	local devcam_key = keyboard_input_address + 19
	local all_weapons_key = keyboard_input_address + 20
	local all_vehicles_key = keyboard_input_address + 21
	local up_arrow_key = keyboard_input_address + 77
	local down_arrow_key = keyboard_input_address + 78
	local left_arrow_key = keyboard_input_address + 79
	local right_arrow_key = keyboard_input_address + 80
	
	local DEFAULT_TAGS ={
		["vehicles\\warthog\\mp_warthog"] = 1,
		["vehicles\\warthog\\warthog"] = 1,
		["vehicles\\rwarthog\\rwarthog"] = 1,
		["vehicles\\scorpion\\scorpion_mp"] = 1,
		["vehicles\\scorpion\\scorpion"] = 1,
		["vehicles\\banshee\\banshee_mp"] = 1,
		["vehicles\\banshee\\banshee"] = 1,
		["vehicles\\ghost\\ghost_mp"] = 1,
		["vehicles\\ghost\\ghost"] = 1,
		["vehicles\\c gun turret\\c gun turret_mp"] = 1,
		["vehicles\\c gun turret\\c gun turret"] = 1,
		
		["weapons\\assault rifle\\assault rifle"] = 1,
		["weapons\\flamethrower\\flamethrower"] = 1,
		["weapons\\gravity rifle\\gravity rifle"] = 1,
		["weapons\\needler\\needler"] = 1,
		["weapons\\pistol\\pistol"] = 1,
		["weapons\\plasma pistol\\plasma pistol"] = 1,
		["weapons\\plasma rifle\\plasma rifle"] = 1,
		["weapons\\rocket launcher\\rocket launcher"] = 1,
		["weapons\\shotgun\\shotgun"] = 1,
		["weapons\\sniper rifle\\sniper rifle"] = 1,
		["weapons\\ball\\ball"] = 1,
		["weapons\\flag\\flag"] = 1,
		["weapons\\frag grenade\\frag grenade"] = 1,
		["weapons\\plasma grenade\\plasma grenade"] = 1,
		["weapons\\plasma_cannon\\plasma_cannon"] = 1,
		["weapons\\needler\\mp_needler"] = 1,
		
		["powerups\\active camouflage"] = 1,
		["powerups\\double speed"] = 1,
		["powerups\\full-spectrum vision"] = 1,
		["powerups\\over shield"] = 1,
		["powerups\\health pack"] = 1,
		["powerups\\sniper rifle ammo\\sniper rifle ammo"] = 1,
		["powerups\\shotgun ammo\\shotgun ammo"] = 1,
		["powerups\\rocket launcher ammo\\rocket launcher ammo"] = 1,
		["powerups\\pistol ammo\\pistol ammo"] = 1,
		["powerups\\needler ammo\\needler ammo"] = 1,
		["powerups\\flamethrower ammo\\flamethrower ammo"] = 1,
		["powerups\\assault rifle ammo\\assault rifle ammo"] = 1,
		
		["characters\\cyborg\\cyborg"] = 1,
		["characters\\cyborg_mp\\cyborg_mp"] = 1,
		
		["levels\\a10\\devices\\alert_light\\alert_light"] = 1,
		["levels\\a10\\devices\\bulletin board\\bulletin board"] = 1,
		["levels\\a10\\devices\\doors\\door_blast_collision\\door_blast_collision"] = 1,
		["levels\\a10\\devices\\h computer bank\\h computer bank"] = 1,
		["levels\\a10\\devices\\h computer bank burnt\\h computer bank burnt"] = 1,
		["levels\\a10\\devices\\h gun rack\\h gun rack"] = 1,
		["levels\\a10\\devices\\h oxy tank\\h oxy tank"] = 1,
		["levels\\a10\\devices\\hushed casket-off\\hushed casket-off"] = 1,
		["levels\\a10\\devices\\hushed casket-on\\hushed casket-on"] = 1,
		["levels\\a10\\poa_explosions\\poa_fire_emitter large"] = 1,
		["levels\\a10\\poa_explosions\\poa_fire_emitter"] = 1,
		["levels\\a10\\scenery\\large exhaust"] = 1,
		["levels\\a10\\scenery\\small exhaust"] = 1,
		["levels\\a30\\devices\\beam emitter\\beam emitter"] = 1,
		["levels\\a30\\devices\\beam emitter\\beam emitter"] = 1,
		["levels\\a30\\devices\\torpedo_bridge\\torpedo_bridge"] = 1,
		["levels\\a30\\scenery\\holo control indicator\\holo control indicator"] = 1,
		["levels\\a50\\devices\\grav_lift_particles\\grav_lift_particles"] = 1,
		["levels\\a50\\devices\\interior tech objects\\holo command control\\holo command control"] = 1,
		["levels\\a50\\devices\\interior tech objects\\holo control dual\\holo control dual"] = 1,
		["levels\\a50\\scenery\\a50_nutblocker\\a50_nutblocker"] = 1,
		["levels\\b40\\scenery\\b40_battery\\b40_battery"] = 1,
		["levels\\b40\\scenery\\b40_bigbattery\\b40_bigbattery"] = 1,
		["levels\\b40\\scenery\\b40_cpanel\\b40_cpanel"] = 1,
		["levels\\b40\\scenery\\b40_ctorch\\ctorch"] = 1,
		["levels\\b40\\scenery\\b40_doorblinker\\doorblinker"] = 1,
		["levels\\b40\\scenery\\b40_metal_small\\metal_small"] = 1,
		["levels\\b40\\scenery\\b40_metal_tall\\metal_tall"] = 1,
		["levels\\b40\\scenery\\b40_metal_wide\\metal_wide"] = 1,
		["levels\\b40\\scenery\\b40_shaftring\\b40_shaftring"] = 1,
		["levels\\b40\\scenery\\b40_snowbush\\b40_snowbush"] = 1,
		["levels\\b40\\scenery\\b40_snowbushsmall\\b40_snowbushsmall"] = 1,
		["levels\\b40\\scenery\\bridge lightning markers\\bridge lightning"] = 1,
		["levels\\c10\\devices\\bridge\\bridge"] = 1,
		["levels\\c10\\devices\\helmet\\helmet"] = 1,
		["levels\\c10\\scenery\\c10_bigplant\\c10_bigplant"] = 1,
		["levels\\c10\\scenery\\c10_lilypad\\c10_lilypad"] = 1,
		["levels\\c10\\scenery\\c10_lilypadbunch\\c10_lilypadbunch"] = 1,
		["levels\\c10\\scenery\\c10_lilypadbunchb\\c10_lilypadbunchb"] = 1,
		["levels\\c10\\scenery\\c10_lilypadcluster\\c10_lilypadcluster"] = 1,
		["levels\\c10\\scenery\\c10_lilypadclusterb\\c10_lilypadclusterb"] = 1,
		["levels\\c10\\scenery\\c10_plantclump\\c10_plantclump"] = 1,
		["levels\\c10\\scenery\\c10_smallplant\\c10_smallplant"] = 1,
		["levels\\c10\\scenery\\cyan point light\\light blink cyan dynamic"] = 1,
		["levels\\c10\\scenery\\cyan point light\\light blink cyan"] = 1,
		["levels\\c10\\scenery\\cyan point light\\light cyan dynamic"] = 1,
		["levels\\c10\\scenery\\cyan point light\\light cyan"] = 1,
		["levels\\c10\\scenery\\cyan point light\\light jitter cyan dynamic"] = 1,
		["levels\\c10\\scenery\\cyan point light\\light jitter cyan"] = 1,
		["levels\\c10\\scenery\\green point light\\light blink green dynamic"] = 1,
		["levels\\c10\\scenery\\green point light\\light blink green"] = 1,
		["levels\\c10\\scenery\\green point light\\light green dynamic"] = 1,
		["levels\\c10\\scenery\\green point light\\light green"] = 1,
		["levels\\c10\\scenery\\green point light\\light jitter green dynamic"] = 1,
		["levels\\c10\\scenery\\green point light\\light jitter green"] = 1,
		["levels\\c10\\scenery\\mri lightning\\mri lightning"] = 1,
		["levels\\c10\\scenery\\orange point light\\light blink orange dynamic"] = 1,
		["levels\\c10\\scenery\\orange point light\\light blink orange"] = 1,
		["levels\\c10\\scenery\\orange point light\\light jitter orange dynamic"] = 1,
		["levels\\c10\\scenery\\orange point light\\light jitter orange"] = 1,
		["levels\\c10\\scenery\\orange point light\\light orange dynamic"] = 1,
		["levels\\c10\\scenery\\orange point light\\light orange"] = 1,
		["levels\\c10\\scenery\\red point light\\blink red dynamic nomodel"] = 1,
		["levels\\c10\\scenery\\red point light\\light blink red dynamic"] = 1,
		["levels\\c10\\scenery\\red point light\\light blink red"] = 1,
		["levels\\c10\\scenery\\red point light\\light jitter red dynamic"] = 1,
		["levels\\c10\\scenery\\red point light\\light jitter red"] = 1,
		["levels\\c10\\scenery\\red point light\\light red dynamic"] = 1,
		["levels\\c10\\scenery\\red point light\\light red"] = 1,
		["levels\\c20\\devices\\index platform\\index platform"] = 1,
		["levels\\c40\\scenery\\c40_snowbushsmall_dark\\c40_snowbushsmall_dark"] = 1,
		["levels\\c40\\scenery\\c40_snowbush_dark\\c40_snowbush_dark"] = 1,
		["levels\\d40\\devices\\countdown timer\\sd abort text\\abort"] = 1,
		["levels\\d40\\devices\\countdown timer\\sd background\\background"] = 1,
		["levels\\d40\\devices\\countdown timer\\sd countdown display\\countdown"] = 1,
		["levels\\d40\\devices\\temp critical\\temp critical"] = 1,
		["levels\\test\\carousel\\devices\\car_spotlight\\car_spotlight"] = 1,
		["levels\\test\\damnation\\devices\\dam_spotlight\\dam_spotlight"] = 1,
		["levels\\test\\damnation\\devices\\light_ceiling\\mp bright_light_ceiling"] = 1,
		["levels\\test\\dangercanyon\\scenery\\mp_tree_pine_small\\mp_tree_pine_small"] = 1,
		["levels\\test\\deathisland\\devices\\light fixtures\\light fixture ceiling2"] = 1,
		["levels\\test\\deathisland\\devices\\light fixtures\\light fixture floor1"] = 1,
		["levels\\test\\deathisland\\devices\\light fixtures\\light fixture floor2"] = 1,
		["levels\\test\\deathisland\\devices\\light fixtures\\light fixture wall1"] = 1,
		["levels\\test\\deathisland\\devices\\light fixtures\\light fixture wall2"] = 1,
		["levels\\test\\deathisland\\devices\\light fixtures\\light fixture wall3"] = 1,
		["levels\\test\\icefields\\scenery\\mp_boulder_snow_large_00\\mp_boulder_snow_large_00"] = 1,
		["levels\\test\\icefields\\scenery\\mp_boulder_snow_large_01\\mp_boulder_snow_large_01"] = 1,
		["levels\\test\\icefields\\scenery\\mp_boulder_snow_large_02\\mp_boulder_snow_large_02"] = 1,
		["levels\\test\\icefields\\scenery\\mp_boulder_snow_large_03\\mp_boulder_snow_large_03"] = 1,
		["levels\\test\\icefields\\scenery\\mp_boulder_snow_large_04\\mp_boulder_snow_large_04"] = 1,
		["levels\\test\\icefields\\scenery\\mp_tree_pine_snow_small\\mp_tree_pine_snow_small"] = 1,
		["levels\\test\\icefields\\scenery\\mp_tree_pine_snow_tall\\mp_tree_pine_snow_tall"] = 1,
		["levels\\test\\infinity\\devices\\beam emitter red\\beam emitter_blue"] = 1,
		["levels\\test\\infinity\\devices\\beam emitter red\\beam emitter_red"] = 1,
		["levels\\test\\swampthing\\devices\\swamp_light_ground\\swamp_light_ground"] = 1,
		["levels\\test\\timberland\\scenery\\mp_beacon_blue\\mp_beacon_blue"] = 1,
		["levels\\test\\timberland\\scenery\\mp_beacon_red\\mp_beacon_red"] = 1,
		["levels\\test\\timberland\\scenery\\mp_boulder_granite_gigantic\\mp_boulder_granite_gigantic"] = 1,
		["levels\\test\\timberland\\scenery\\mp_boulder_granite_large\\mp_boulder_granite_large_00\\mp_boulder_granite_large_00"] = 1,
		["levels\\test\\timberland\\scenery\\mp_boulder_granite_large\\mp_boulder_granite_large_01\\mp_boulder_granite_large_01"] = 1,
		["levels\\test\\timberland\\scenery\\mp_boulder_granite_large\\mp_boulder_granite_large_02\\mp_boulder_granite_large_02"] = 1,
		["levels\\test\\timberland\\scenery\\mp_boulder_granite_large\\mp_boulder_granite_large_03\\mp_boulder_granite_large_03"] = 1,
		["levels\\test\\timberland\\scenery\\mp_boulder_granite_large\\mp_boulder_granite_large_04\\mp_boulder_granite_large_04"] = 1,
		["levels\\test\\timberland\\scenery\\mp_boulder_granite_medium\\mp_boulder_granite_medium"] = 1,
		["levels\\test\\timberland\\scenery\\mp_boulder_granite_small\\mp_boulder_granite_small"] = 1,
		["levels\\test\\timberland\\scenery\\mp_boulder_moss_large\\mp_boulder_moss_large"] = 1,
		["levels\\test\\timberland\\scenery\\mp_boulder_moss_small\\mp_boulder_moss_small"] = 1,
		["levels\\test\\timberland\\scenery\\mp_tree_pine_tall\\mp_tree_pine_tall"] = 1,
		["levels\\test\\timberland\\scenery\\simple_beacon_blue\\simple_beacon_blue"] = 1,
		["levels\\test\\timberland\\scenery\\simple_beacon_red\\simple_beacon_red"] = 1,
		["levels\\test\\timberland\\scenery\\waterfall_spray_emitter_small\\waterfall_spray_emitter_small"] = 1,
		["levels\\test\\wizard\\devices\\wiz_alert_light\\wiz_alert_light"] = 1,
		["scenery\\baton\\baton dynamic"] = 1,
		["scenery\\baton\\baton"] = 1,
		["scenery\\bent_beam\\bent_beam"] = 1,
		["scenery\\blood_pool\\blood_pool"] = 1,
		["scenery\\blue landing beacon\\blue landing beacon"] = 1,
		["scenery\\c_field_generator\\c_field_generator"] = 1,
		["scenery\\c_metalsmall\\c_metalsmall"] = 1,
		["scenery\\c_metaltall\\c_metaltall"] = 1,
		["scenery\\c_metalwide\\c_metalwide"] = 1,
		["scenery\\c_storage\\c_storage"] = 1,
		["scenery\\c_storage_large\\c_storage_large"] = 1,
		["scenery\\c_uplink\\c_uplink"] = 1,
		["scenery\\emitters\\burning_flame\\burning_flame"] = 1,
		["scenery\\emitters\\burning_flame_nondynamic\\burning_flame_nondynamic"] = 1,
		["scenery\\emitters\\condensation\\condensation"] = 1,
		["scenery\\emitters\\coolant bubble\\coolant bubble"] = 1,
		["scenery\\emitters\\dust\\dust"] = 1,
		["scenery\\emitters\\energy_rope\\energy_rope"] = 1,
		["scenery\\emitters\\glowingdrip\\glowingdrip"] = 1,
		["scenery\\emitters\\heavysmoke\\heavysmoke"] = 1,
		["scenery\\emitters\\plasma_flame\\plasma_flame"] = 1,
		["scenery\\emitters\\smoldering_debris\\smoldering_debris"] = 1,
		["scenery\\emitters\\sparks\\sparks"] = 1,
		["scenery\\emitters\\sparks constant\\sparks constant"] = 1,
		["scenery\\emitters\\sparks friction\\sparks friction"] = 1,
		["scenery\\emitters\\sparks spurt\\sparks spurt"] = 1,
		["scenery\\emitters\\steam jets\\steam jets fast"] = 1,
		["scenery\\emitters\\steam jets\\steam jets"] = 1,
		["scenery\\emitters\\stone debris\\stone debris"] = 1,
		["scenery\\flag_base\\flag_base"] = 1,
		["scenery\\floor_arrow\\floor_arrow"] = 1,
		["scenery\\hilltop\\hilltop"] = 1,
		["scenery\\h_barricade_large\\h_barricade_large"] = 1,
		["scenery\\h_barricade_large_gap\\h_barricade_large_gap"] = 1,
		["scenery\\h_barricade_small\\h_barricade_small"] = 1,
		["scenery\\h_barricade_small_visor\\h_barricade_small_visor"] = 1,
		["scenery\\landing beacon\\landing beacon"] = 1,
		["scenery\\light lens flare\\light lens flare green"] = 1,
		["scenery\\light lens flare\\light lens flare yellow"] = 1,
		["scenery\\light lens flare\\light lens flare"] = 1,
		["scenery\\lightning\\lightning"] = 1,
		["scenery\\plants\\plant fern\\plant fern"] = 1,
		["scenery\\plants\\plant_broadleaf_short\\plant_broadleaf_short"] = 1,
		["scenery\\plants\\plant_broadleaf_tall\\plant_broadleaf_tall"] = 1,
		["scenery\\plants\\plant_yellowbig\\plant_yellowbig"] = 1,
		["scenery\\plants\\plant_yellowsmall\\plant_yellowsmall"] = 1,
		["scenery\\plants\\vines_hanging\\vines_hanging"] = 1,
		["scenery\\rocks\\a50_rock_large\\a50_rock_large"] = 1,
		["scenery\\rocks\\b40_snowrocks\\snowrock"] = 1,
		["scenery\\rocks\\b40_snowrocksmall\\snowrocksmall"] = 1,
		["scenery\\rocks\\boulder\\boulder"] = 1,
		["scenery\\rocks\\boulder_crouch\\boulder_crouch"] = 1,
		["scenery\\rocks\\boulder_doublewide\\boulder_doublewide"] = 1,
		["scenery\\rocks\\boulder_granite_gigantic\\boulder_granite_gigantic"] = 1,
		["scenery\\rocks\\boulder_granite_large\\boulder_granite_large"] = 1,
		["scenery\\rocks\\boulder_granite_medium\\boulder_granite_medium"] = 1,
		["scenery\\rocks\\boulder_granite_small\\boulder_granite_small"] = 1,
		["scenery\\rocks\\boulder_large_grey\\boulder_large_grey"] = 1,
		["scenery\\rocks\\boulder_moss_gigantic\\boulder_moss_gigantic"] = 1,
		["scenery\\rocks\\boulder_moss_large\\boulder_moss_large"] = 1,
		["scenery\\rocks\\boulder_moss_small\\boulder_moss_small"] = 1,
		["scenery\\rocks\\boulder_redrock_gigantic\\boulder_redrock_gigantic"] = 1,
		["scenery\\rocks\\boulder_redrock_large\\boulder_redrock_large"] = 1,
		["scenery\\rocks\\boulder_redrock_medium\\boulder_redrock_medium"] = 1,
		["scenery\\rocks\\boulder_redrock_small\\boulder_redrock_small"] = 1,
		["scenery\\rocks\\boulder_snow_gigantic\\boulder_snow_gigantic"] = 1,
		["scenery\\rocks\\boulder_snow_large\\boulder_snow_large"] = 1,
		["scenery\\rocks\\boulder_snow_small\\boulder_snow_small"] = 1,
		["scenery\\rocks\\rock_shardlong\\rock_shardlong"] = 1,
		["scenery\\rocks\\rock_shardmed\\rock_shardmed"] = 1,
		["scenery\\rocks\\rock_shardrubble\\rock_shardrubble"] = 1,
		["scenery\\rocks\\rock_shardsmall\\rock_shardsmall"] = 1,
		["scenery\\rocks\\rock_shardwide\\rock_shardwide"] = 1,
		["scenery\\rocks\\rock_sharpcurly\\rock_sharpcurly"] = 1,
		["scenery\\rocks\\rock_sharphole\\rock_sharphole"] = 1,
		["scenery\\rocks\\rock_sharpsmall\\rock_sharpsmall"] = 1,
		["scenery\\rocks\\rock_sharpstubby\\rock_sharpstubby"] = 1,
		["scenery\\rocks\\rock_sharptall\\rock_sharptall"] = 1,
		["scenery\\rocks\\rock_sharpwedge\\rock_sharpwedge"] = 1,
		["scenery\\rocks\\rock_sharpwide\\rock_sharpwide"] = 1,
		["scenery\\shrubs\\shrub_large\\shrub_large"] = 1,
		["scenery\\shrubs\\shrub_small\\shrubsmall"] = 1,
		["scenery\\small beacon\\small blue beacon"] = 1,
		["scenery\\small beacon\\small red beacon"] = 1,
		["scenery\\sprinkler\\sprinkler"] = 1,
		["scenery\\teleporter_base\\teleporter_base"] = 1,
		["scenery\\teleporter_shield\\teleporter"] = 1,
		["scenery\\trees\\tree_desert_dead\\tree_desert_dead"] = 1,
		["scenery\\trees\\tree_desert_whitebark\\tree_desert_whitebark"] = 1,
		["scenery\\trees\\tree_gnarled_doublewide\\tree_gnarled_doublewide"] = 1,
		["scenery\\trees\\tree_leafy\\tree_leafy"] = 1,
		["scenery\\trees\\tree_leafycover_doublewide\\tree_leafycover_doublewide"] = 1,
		["scenery\\trees\\tree_leafydense_doublewide\\tree_leafydense_doublewide"] = 1,
		["scenery\\trees\\tree_leafy_doublewide\\tree_leafy_doublewide"] = 1,
		["scenery\\trees\\tree_leafy_fallentrunk\\tree_leafy_fallentrunk"] = 1,
		["scenery\\trees\\tree_leafy_fallentrunk_short\\tree_leafy_fallentrunk_short"] = 1,
		["scenery\\trees\\tree_leafy_medium\\tree_leafy_medium"] = 1,
		["scenery\\trees\\tree_leafy_sapling\\tree_leafy_sapling"] = 1,
		["scenery\\trees\\tree_leafy_stump\\tree_leafy_stump"] = 1,
		["scenery\\trees\\tree_leafy_stump_crouch\\tree_leafy_stump_crouch"] = 1,
		["scenery\\trees\\tree_pine\\tree_pine"] = 1,
		["scenery\\trees\\tree_pine_snow\\tree_pine_snow"] = 1,
		["scenery\\trees\\tree_pine_snowsmall\\tree_pine_snowsmall"] = 1,
		["scenery\\trees\\tree_pine_tall\\tree_pine_tall"] = 1,
		["scenery\\trees\\tree_wall1\\tree_wall"] = 1,
		["scenery\\trees\\tree_wall2\\tree_wall2"] = 1,
		["scenery\\trees\\tree_wallbig\\tree_wallbig"] = 1,
		["scenery\\tubewire\\tubewire"] = 1,
		["scenery\\waterfalls\\spray_emitter_medium\\spray_emitter_medium"] = 1,
		["scenery\\waterfalls\\waterfall_emitter\\waterfall_emitter"] = 1,
		["scenery\\white dynamic light\\white dynamic light"] = 1,
		["sound\\sfx\\ambience\\a30\\a30_beam_emitter"] = 1,
		["sound\\sfx\\ambience\\a30\\river_sound"] = 1,
		["sound\\sfx\\ambience\\a30\\stream"] = 1,
		["sound\\sfx\\ambience\\a30\\waterfall_sound"] = 1,
		["sound\\sfx\\ambience\\b30\\waves_sound"] = 1,
		["vehicles\\c_dropship\\c_dropship"] = 1,
		["vehicles\\fighterbomber\\fighterbomber_scenery"] = 1,
		["vehicles\\lifepod\\lifepod"] = 1,
		["vehicles\\pelican\\pelican"] = 1,
	}
	
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
		local name = read_string(name_addr)
        for k = 0,i - 1 do
            local tag_k = tag_array + k * 0x20
            if read_dword(tag_k) == tag_class and read_dword(tag_k + 0x10) == name_addr then
                return true, name_addr, name
            end
        end
    end
    return false
end

function CheckTagClass(tag_class)
	if tag_class==0x77656170 or tag_class==0x76656869 or tag_class==0x62697064 or tag_class==0x65716970 or tag_class==0x7363656E or tag_class==0x6D616368 or tag_class==0x6374726C or tag_class==0x6C696669 then
		return true
	else
		return false
	end
end

function Initialize()
	if map == "ui" then
		return false
	end
	map_is_protected, protected_addr, protected_name = CheckProtection()
	if map_is_protected then
		console_out("Map is protected! Protection tag path: "..protected_name)
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
		[10] = {["name"] = "TELEPORTERS",},
	}
	
	local protected_tag_counter = 0
	
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
		local classic_tag = false
        local tag = tag_array + i * 0x20
		local tag_class = read_dword(tag)
		local meta_id = read_dword(tag + 0xC)
		local name_addr = read_dword(tag + 0x10)
		local name = read_string(name_addr)
		if map_is_protected and (name_addr == protected_addr or (protected_name == name and CheckTagClass(tag_class)) ) then
			name_addr = name_addr + protected_tag_counter * 32
			protected_tag_counter = protected_tag_counter + 1
			name = meta_id
			write_dword(tag + 0x10, name_addr)
			write_string(name_addr, name)
		else
			if DEFAULT_TAGS[name] then
				classic_tag = true
			end
			
			for word in string.gmatch(name, "([^".."\\".."]+)") do
				name = word
			end
		end
		
		name = string.upper(name)
		
		::fail::
		
		local tag_data = read_dword(tag + 0x14)
		if tag_class == 0x77656170 then --weap
			NewTableEntry(1, name, meta_id, tag_data, classic_tag)
		elseif tag_class == 0x76656869 then --vehi
			NewTableEntry(2, name, meta_id, tag_data, classic_tag)
		elseif tag_class == 0x62697064 then --bipd
			NewTableEntry(3, name, meta_id, tag_data, classic_tag)
		elseif tag_class == 0x65716970 then --eqip
			NewTableEntry(4, name, meta_id, tag_data, classic_tag)
		elseif tag_class == 0x7363656E then --scen
			NewTableEntry(5, name, meta_id, tag_data, classic_tag)
		elseif tag_class == 0x6D616368 then --mach
			NewTableEntry(6, name, meta_id, tag_data, classic_tag)
		elseif tag_class == 0x6374726C then --ctrl
			NewTableEntry(7, name, meta_id, tag_data, classic_tag)
		elseif tag_class == 0x6C696669 then --lifi
			NewTableEntry(8, name, meta_id, tag_data, classic_tag)
		end
		
		if tag_class == 0x73627370 then --sbsp
			TAGS[9][#TAGS[9]+1] = {
				["name"] = name,
			}
		end
	end
	
	--TELEPORTERS
	local scenario_tag_index = read_word(0x40440004)
	local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
	local scenario_tag_data = read_dword(scenario_tag + 0x14)
	local netgame_flag_count = read_dword(scenario_tag_data + 0x378)
	local netgame_flags = read_dword(scenario_tag_data + 0x378 + 4)
	
	for i=0,netgame_flag_count-1 do
		local current_flag = netgame_flags + i*148
		local flag_type = read_word(current_flag + 0x10)
		if flag_type == 6 or flag_type == 7 then
			local x = read_float(current_flag)
			local y = read_float(current_flag+4)
			local z = read_float(current_flag+8)
			local name = read_short(current_flag + 0x12)
			if flag_type == 6 then
				name = name.." from"
			else
				name = name.." to"
			end
			
			TAGS[10][#TAGS[10]+1] = {
				["name"] = name,
				["x"] = x,
				["y"] = y,
				["z"] = z,
			}
		end
	end
	
	--MARK DEFAULT TAGS
	for i=1,#TAGS do
		local classic = true
		for j=1,#TAGS[i] do
			if TAGS[i][j].classic_tag ~= true then
				classic = false
				break
			end
		end
		if classic then
			TAGS[i].classic = true
		end
	end
end

function NewTableEntry(id, name, meta_id, tag_data, classic_tag)
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
			["classic_tag"] = classic_tag,
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
		local esc = read_byte(esc_key)
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
						elseif selection1 == 10 then -- tele
							write_float(player + 0x5C, TAGS[selection1][selection2].x)
							write_float(player + 0x60, TAGS[selection1][selection2].y)
							write_float(player + 0x64, TAGS[selection1][selection2].z)
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
		
		if esc == 1 then
			CloseMenu()
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
		console_out("Select tag type:", 0.5, 1, 1)
		for i=1,#TAGS do
			if #TAGS[i] > 0 then
				if TAGS[i].classic ~= nil then
					if i == selection1 then
						console_out(">> "..TAGS[i].name.." ("..#TAGS[i]..") <<", 0, 0.5, 1)
					else
						console_out("   "..TAGS[i].name.." ("..#TAGS[i]..")", 0.5, 1, 1)
					end
				else
					if i == selection1 then
						console_out(">> "..TAGS[i].name.." ("..#TAGS[i]..") <<", 0, 1, 0)
					else
						console_out("   "..TAGS[i].name.." ("..#TAGS[i]..")", 0.5, 1, 0)
					end
				end
			elseif i == selection1 then
				console_out(">> "..TAGS[i].name.." (0) <<", 1, 0, 0)
			else
				console_out("   "..TAGS[i].name.." (0)", 1, 0.5, 0)
			end
		end
	else
		console_out("Select tag:", 0.5, 1, 1)
		for j=1,#TAGS[selection1] do
		
			if j - selection2 > 19 then
				console_out("...", 0.5, 1, 0)
				break
			else
				if TAGS[selection1][j].classic_tag then
					if j == selection2 then
						console_out(">> "..TAGS[selection1][j].name.." <<", 0, 0.5, 1)
					else
						console_out("   "..TAGS[selection1][j].name, 0.5, 1, 1)
					end
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