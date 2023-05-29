--HUD Features script by aLTis. Version 1.0.1

--CONFIG
	dead_ally_markers_enable = true -- shows a red arrow above dead ally bodies (doesn't work on Chimera 1.0)
	
	secondary_weapon_enable = true -- shows what weapons you have in your inventory
		show_in_vehicles = true
		position_x = -293
		position_y = -216
		position_x_bigass = 409
		position_y_bigass = -141
		
	score_meters_enable = true -- shows score meters on HUD like in newer Halo games
		team_color_red = {["red"] = 255, ["green"] = 30, ["blue"] = 40}
		team_color_blue = {["red"] = 60, ["green"] = 50, ["blue"] = 255}
		
--END OF CONFIG

clua_version = 2.042

local dead_ally_markers = dead_ally_markers_enable
local secondary_weapon = secondary_weapon_enable
local score_meters = score_meters_enable

local bitmap_test = "rasterizer\\distance attenuation"
local bitmap_numbers = "ui\\hud\\bitmaps\\combined\\hud_counter_numbers"
local bitmap_reticles = "ui\\hud\\bitmaps\\combined\\hud_reticles"
local bitmap_waypoints = "ui\\hud\\bitmaps\\combined\\hud_waypoints"
local bitmap_icons = "ui\\hud\\bitmaps\\combined\\hud_msg_icons"
local bitmap_ammo_meters = "ui\\hud\\bitmaps\\combined\\hud_ammo_meters"
local bitmap_ammo_alphas = "ui\\hud\\bitmaps\\combined\\hud_ammo_alphas"
local bitmap_ammo_outlines = "ui\\hud\\bitmaps\\combined\\hud_ammo_outlines"
local bitmap_weapon_backgrounds = "ui\\hud\\bitmaps\\combined\\hud_weapon_backgrounds"
local bitmap_ammo = "ui\\hud\\bitmaps\\combined\\hud_ammo_type_icons"
local bitmap_damage = "ui\\hud\\bitmaps\\combined\\hud_damage_arrows"
local bitmap_unit = "ui\\hud\\bitmaps\\combined\\hud_unit_backgrounds"
local bitmap_unit_meters = "ui\\hud\\bitmaps\\combined\\hud_unit_meters"
local bitmap_multiplayer = "ui\\hud\\bitmaps\\hud_multiplayer"
local bitmap_blip = "ui\\hud\\bitmaps\\hud_sensor_blip"
local bitmap_cursor = "ui\\shell\\bitmaps\\cursor"
local bitmap_blood = "effects\\decals\\blood splats\\bitmaps\\blood splat engineer"
local bitmap_player_color = "ui\\shell\\main_menu\\settings_select\\player_setup\\player_profile_edit\\color_edit\\player_color_marine_large"
local bitmap_white = "ui\\shell\\bitmaps\\white"
local bitmap_arrow_right = "ui\\shell\\bitmaps\\arrow_sm_right"

local memory_address = 0x40440000
local struct1_count = 26
local new_struct1_size = 180*struct1_count + 4
local new_struct1 = memory_address - new_struct1_size
local new_struct2_size = 180*2 + 4
local new_struct2 = new_struct1 - new_struct2_size - 4

local red = 1
local green = 0
local blue = 0
local alpha = 0.5

local chimera_fix = 0
if build > 0 then
	dead_ally_markers_enable = false
	dead_ally_markers = false
	position_x = position_x + 100
	position_x_bigass = position_x_bigass - 100
	chimera_fix = -100
end

set_callback("map load", "OnMapLoad")
set_callback("tick", "OnTick")
set_callback("precamera", "OnCamera")
set_callback("unload", "OnUnload")

local loaded = false
local bigass = false
local POSITIONS = {}
local WEAPON_HUDS = {}
local hrx = false
local h2_hud = false
local hud_address = 0x400007F4
local gametype_base = 0x68CC48
local ctf_globals = 0x64BDB8
local slayer_globals = 0x64C308
local oddball_globals = 0x64C078
local koth_globals = 0x64BDF0
local race_globals = 0x64C1C0
local stats_globals = 0x64BAB8
local sqrt = math.sqrt
local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local find = string.find
local pi = math.pi
local atan = math.atan
local tan = math.tan
local sin = math.sin
local cos = math.cos
local rad = math.rad

local PLAYER_COLORS = {
	[0] = {["r"] = 255, ["g"] = 255, ["b"] = 255}, --white
	[1] = {["r"] = 40, ["g"] = 40, ["b"] = 40}, --black {["r"] = 0, ["g"] = 0, ["b"] = 0}
	[2] = {["r"] = 254, ["g"] = 0, ["b"] = 0}, --red
	[3] = {["r"] = 2, ["g"] = 1, ["b"] = 227}, --blue
	[4] = {["r"] = 112, ["g"] = 126, ["b"] = 113}, --gray
	[5] = {["r"] = 225, ["g"] = 225, ["b"] = 1}, --yellow
	[6] = {["r"] = 0, ["g"] = 225, ["b"] = 1}, --green
	[7] = {["r"] = 225, ["g"] = 86, ["b"] = 185}, --pink
	[8] = {["r"] = 171, ["g"] = 16, ["b"] = 244}, --purple
	[9] = {["r"] = 1, ["g"] = 255, ["b"] = 255}, --cyan
	[10] = {["r"] = 100, ["g"] = 147, ["b"] = 237}, --cobalt
	[11] = {["r"] = 255, ["g"] = 127, ["b"] = 0}, --orange
	[12] = {["r"] = 30, ["g"] = 204, ["b"] = 145}, --teal
	[13] = {["r"] = 0, ["g"] = 100, ["b"] = 1}, --sage
	[14] = {["r"] = 96, ["g"] = 56, ["b"] = 20}, --brown
	[15] = {["r"] = 198, ["g"] = 156, ["b"] = 108}, --tan
	[16] = {["r"] = 157, ["g"] = 11, ["b"] = 14}, --maroon
	[17] = {["r"] = 245, ["g"] = 153, ["b"] = 158}, --salmon
}

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end

function FixInVehicles()
	local player = get_dynamic_player()
	if player then
		
		local vehicle = get_object(read_dword(player + 0x11C))
		if vehicle then
			--add gunner flag for the driver seat
			local seat = read_word(m_player + 0x2A)
			local metaid = read_dword(vehicle)
			local tag = get_tag(metaid)
			if tag then
				local tag_data = read_dword(tag + 0x14)
				
				local seat_address = read_dword(tag_data + 0x2E8)
				local struct = seat_address + 284*seat
				local driver = read_bit(struct, 2)
				local gunner = read_bit(struct, 3)
				if driver == 1 and gunner == 0 then
					driver_seat_address = struct
					write_bit(driver_seat_address, 3, 1)
					
					--remove gauss hog heat meters
					if GetName(vehicle) == "bourrin\\halo reach\\vehicles\\warthog\\reach gauss hog" then
						local hud_tag = get_tag("wphi", "bourrin\\halo reach\\vehicles\\warthog\\gauss\\gauss turret")
						if hud_tag then
							local hud_data = read_dword(hud_tag + 0x14)
							gauss_meter_address = hud_data + 0x6C
							write_dword(gauss_meter_address, 0)
						end
					end
				end
			end
		elseif driver_seat_address then
			--remove the gunner
			write_bit(driver_seat_address, 3, 0)
			driver_seat_address = nil
			
			if gauss_meter_address then
				write_dword(gauss_meter_address, 1)
			end
		end
	end
	
	--remove reticle while in driver seat
	if driver_seat_address then
		write_bit(hud_address + 292, 0, 0)
	end
end

function OnTick()
	if loaded == false then return end
	m_player = get_player()
	if m_player == nil then
		--console_out("umm what")
		return
	end
	local player_team = read_byte(m_player + 0x20)
	
	FixInVehicles()
	
	if dead_ally_markers then
		for i=0,15 do
			if i~= local_player_index then
				local player2 = get_player(i)
				if player2 then
					local player2_team = read_byte(player2 + 0x20)
					if player_team == player2_team then
						local obj_id = read_dword(player2 + 0x34)
						if get_object(obj_id) then
							POSITIONS[i] = obj_id
						end
					elseif POSITIONS[i] ~= nil then
						POSITIONS[i] = nil
					end
				else
					SetHudPosition(i,999,999)
					POSITIONS[i] = nil
				end
			else
				SetHudPosition(i,999,999)
				POSITIONS[i] = nil
			end
		end
	end
	
	if score_meters then
		local teamplay = read_byte(gametype_base + 0x34)
		gametype = read_byte(gametype_base + 0x30)
		score_limit = read_byte(gametype_base + 0x58)
		if teamplay == 1 then
			
			local red_score = 0
			local blue_score = 0
			
			if gametype == 1 then --ctf
				red_score = read_dword(ctf_globals + 0x10)
				blue_score = read_dword(ctf_globals + 4 + 0x10)
				score_limit = read_dword(ctf_globals + 0x18)
			elseif gametype == 2 then --slayer
				red_score = read_dword(slayer_globals)
				blue_score = read_dword(slayer_globals + 4)
			elseif gametype == 3 then --oddball
				red_score = floor(read_dword(oddball_globals + 0x4)/30)
				blue_score = floor(read_dword(oddball_globals + 4 + 0x4)/30)
				score_limit = read_dword(oddball_globals)
				score_limit = score_limit * 60
			elseif gametype == 4 then --KOTH
				red_score = floor(read_dword(koth_globals)/30)
				blue_score = floor(read_dword(koth_globals + 4)/30)
				score_limit = score_limit * 60
			else -- Race
				red_score = read_dword(race_globals + 0x88)
				blue_score = read_dword(race_globals + 4 + 0x88)
			end
			if red_score > score_limit then
				score_limit = red_score
			end
			if blue_score > score_limit then
				score_limit = blue_score
			end
			SetMeters(red_score, blue_score, score_limit, player_team)
		else
			local opponent_score = -1000
			local opponent_id = -1
			
			if gametype == 3 or gametype == 4 then
				score_limit = score_limit * 60
			end
			
			local your_score = GetPlayerScore(local_player_index)
			
			--Get the highest scoring opponent
			for i=0,15 do
				if i~=local_player_index and get_player(i) then
					local score = GetPlayerScore(i)
					if score > opponent_score then
						opponent_id = i
						opponent_score = score
					end
				end
			end
			SetMeters(your_score, opponent_score, score_limit, -1, opponent_id)
		end
	end
end

function GetPlayerScore(i)
	local stats_base = stats_globals + i*0x30
	local player_score = 0
	if gametype == 2 then --slayer
		player_score = read_dword(slayer_globals + i*4 + 0x40)
	elseif gametype == 3 then --oddball
		player_score = floor(read_dword(oddball_globals + i*4 + 0x44)/30)
	elseif gametype == 4 then --KOTH
		player_score = read_word(stats_base + 0x1E)
	else -- Race
		player_score = read_word(stats_base + 0x20)
	end
	
	if player_score > score_limit then
		score_limit = player_score
	end
	
	return player_score
end

function OnMapLoad()
	ResetMemory()
	dead_ally_markers = dead_ally_markers_enable
	secondary_weapon = secondary_weapon_enable
	score_meters = score_meters_enable
	loaded = false
	set_timer(700, "SetupTags")
	set_timer(2100, "SetupTags")
	--SetupTags()
	POSITIONS = {}
	WEAPON_HUDS = {}
end

function OnUnload()
	if loaded then
		ResetTags()
		ResetMemory()
	end
end

function ResetMemory()
	ResetMemoryField(new_struct1, new_struct1_size)
	ResetMemoryField(new_struct2, new_struct2_size)
end

function WriteColor(address, blue, green, red, alpha)
	write_byte(address, blue)
	write_byte(address+1, green)
	write_byte(address+2, red)
	if alpha ~= nil then
		write_byte(address+3, alpha)
	end
end

function CheckAllocation(address, size)
	for i=0,size-4 do
		if read_byte(address + i) ~= 0 then
			console_out("HUD_FEATURES.LUA Error at "..i.." because its "..read_byte(address + i))
			return false
		end
	end
	return true
end

function AllocateMemory()
	if CheckAllocation(new_struct1, new_struct1_size) == false then
		loaded = false
		console_out("HUD_FEATURES.LUA Failed to allocate memory for struct1")
		return false
	end
	if CheckAllocation(new_struct2, new_struct2_size) == false then
		loaded = false
		console_out("HUD_FEATURES.LUA Failed to allocate memory for struct2")
		return false
	end
end
function ResetMemoryField(address, size)
	if loaded then
		for i=0,size-4 do
			local val = read_byte(address + i)
			if val ~= 0 then
				--console_out(val.." at address "..i)
				write_byte(address + i, 0)
			end
		end
		--console_out("memory reset")
	end
end

function ResetTags()
	if loaded then
		local hud_tag = get_tag("wphi", "ui\\hud\\master")
		if hud_tag then
			hud_tag = read_dword(hud_tag + 0x14)
			write_dword(hud_tag + 0x60, 0)
		end
		--remove gunner flag from driver seat
		if driver_seat_address then
			write_bit(driver_seat_address, 3, 0)
		end
		if gauss_meter_address then
			write_dword(gauss_meter_address, 1)
		end
	end
end

function GetAspectRatio(offset_from_corner)
	local hac_widescreen = 1
	local screen_h = read_word(0x637CF0)
	local screen_w = read_word(0x637CF2)
	local aspect_ratio_fix = floor((320 + offset_from_corner) - (320 + offset_from_corner)*(screen_w/screen_h)/(16/9) +1)
	if bigass then
		local dmr_tag = get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\dmr")
		if dmr_tag then
			hac_widescreen = read_float(read_dword(read_dword(dmr_tag + 0x14) + 0x64) + 0x28)
		end
	else
		local pistol_hud = get_tag("wphi", "weapons\\pistol\\pistol")
		if pistol_hud then
			local tag_data = read_dword(pistol_hud + 0x14)
			if read_dword(tag_data + 0x60) > 0 then
				local struct = read_dword(tag_data + 0x64)
				local x = read_float(struct + 0x28)
				local y = read_float(struct + 0x28+4)
				hac_widescreen = x/y
			end
		end
	end
	return aspect_ratio_fix, hac_widescreen
end

function GetHudMsgIDs()
	local master_hud = read_dword(master_hud_tag + 0xC)
	
	WEAPON_HUDS = {}
	local tag_count = read_dword(0x4044000C)
	
    for i = 0,tag_count - 1 do
        local tag = get_tag(i)
		local tag_class = read_dword(tag)
		
		--weap
		if tag_class == 0x77656170 then
			local tag_data = read_dword(tag + 0x14)
			local hud_tag = get_tag(read_dword(tag_data + 0x480 + 0xC))
			if hud_tag then
				if secondary_weapon then
					hud_tag = read_dword(hud_tag + 0x14)
					local msg_id = read_short(hud_tag + 0x13C)
					if msg_id > -1 and msg_id < 100 then
						local metaid = read_dword(tag + 0xC)
						local width = GetBitmapWidth(msg_id)
						if width ~= 1 then
							WEAPON_HUDS[metaid] = {}
							WEAPON_HUDS[metaid].id = msg_id
							WEAPON_HUDS[metaid].width = width
						end
					end
				end
			else
				-- Add hud for flag and oddball
				write_dword(tag_data + 0x480 + 0xC, master_hud)
				--console_out("no hud: "..read_string(read_dword(tag + 0x10)))
			end
			
		--wphi
		elseif tag_class == 0x77706869 then
			local tag_data = read_dword(tag + 0x14)
			if read_dword(tag_data + 0xC) == 0xFFFFFFFF then
				local metaid = read_dword(tag + 0xC)
				if metaid ~= master_hud then
					write_dword(tag_data + 0xC, master_hud)
					--console_out(tag_data)
				end
			end
		end
    end
	
	return false
end

function GetBitmapWidth(id)
	local bitmap_tag = read_dword(bitmap_icons_tag + 0x14)
	local count = read_dword(bitmap_tag + 0x54)
	if id > count then
		console_out("HUD_FEATURES.LUA error getting width")
		return -1
	end
	local address = read_dword(bitmap_tag + 0x58)
	local struct = address + id*64
	local count2 = read_dword(struct + 0x34)
	local address2 = read_dword(struct + 0x38)
	for j=0,count2-1 do
		local struct2 = address2 + j*32
		local left = read_float(struct2 + 0x08)
		local right = read_float(struct2 + 0x0C)
		local width = right-left
		return width
	end
end

function GetTags()
	bitmap_test_tag = get_tag("bitm", bitmap_test)
	bitmap_damage_tag = get_tag("bitm", bitmap_damage)
	bitmap_icons_tag = get_tag("bitm", bitmap_icons)
	bitmap_meters_tag = get_tag("bitm", bitmap_unit_meters)
	bitmap_ammo_outlines_tag = get_tag("bitm", bitmap_ammo_outlines)
	bitmap_weapon_background = get_tag("bitm", bitmap_weapon_backgrounds)
	bitmap_arrow_tag = get_tag("bitm", bitmap_arrow_right)
	master_hud_tag = get_tag("wphi", "ui\\hud\\master")
	
	bigass = false
	hrx = false
	h2_hud = false
	if bitmap_damage_tag == nil then
		bitmap_damage_tag = get_tag("bitm", "ui\\hud\\hrx_bitmaps\\hrx_damage_arrows\\hrx_damage_arrows")
		if bitmap_damage_tag then
			hrx = true
			bitmap_icons_tag = get_tag("bitm", "ui\\hud\\hrx_bitmaps\\hrx_pickup_icons\\hrx_pickup_icons")
			bitmap_meters_tag = get_tag("bitm", "ui\\hud\\hrx_bitmaps\\hrx_flashlight\\hrx_flashlight")
			bitmap_ammo_outlines_tag = get_tag("bitm", "ui\\hud\\hrx_bitmaps\\hrx_weapon_meters\\hrx_weapon_meters_alpha")
			bitmap_weapon_background = get_tag("bitm", "ui\\hud\\hrx_bitmaps\\hrx_weapon_backgrounds\\hrx_weapon_backgrounds")
		end
	end
	if bitmap_icons_tag == nil then
		bitmap_icons_tag = get_tag("bitm", "ui\\hud\\bitmaps\\combined\\cmt_hud_msg_icons")
		if bitmap_icons_tag == nil then
			bigass = true
			bitmap_icons_tag = get_tag("bitm", "bourrin\\hud\\v3\\bitmaps\\bourrin hud msg icons")
		end
	end
	if bitmap_ammo_outlines_tag == nil then
		bitmap_ammo_outlines_tag = bitmap_test_tag
	end
	hrhh = false
	if bitmap_meters_tag == nil then
		bitmap_meters_tag = get_tag("bitm", bitmap_unit_meters.."_hrhh")
		bitmap_ammo_outlines_tag = get_tag("bitm", bitmap_ammo_outlines.."_hrhh")
		bitmap_weapon_background = get_tag("bitm", bitmap_weapon_backgrounds.."_hrhh")
		if bitmap_meters_tag and bitmap_ammo_outlines_tag and bitmap_weapon_background then
			hrhh = true
		end
	end
	if master_hud_tag == nil then
		master_hud_tag = get_tag("wphi", "taunts\\wheel_selection")
		if master_hud_tag == nil then
			master_hud_tag = get_tag("wphi", "ui\\hud\\h2 master")
			if master_hud_tag ~= nil then
				h2_hud = true
			end
		end
	end
end

function SetupTags()
	if map == "ui" then return end
	
	if loaded == false then -- check if tags exist
		AllocateMemory()
		GetTags()
		
		if master_hud_tag == nil then
			--console_out("Master HUD tag not found :(")
			loaded = false
			return false
		end
		
		if dead_ally_markers_enable then
			if bitmap_damage_tag then
				--console_out("ally markers enabled :D")
				dead_ally_markers = true
			else
				--console_out("bitmap not found: "..bitmap_damage)
				dead_ally_markers = false
			end
		end
		
		if secondary_weapon_enable then
			if bitmap_icons_tag then
				--console_out("secondaries enabled :D")
				secondary_weapon = true
			else
				--if bitmap_icons_tag==nil then console_out("bitmap not found: "..bitmap_icons) end
				secondary_weapon = false
			end
		end
		
		if score_meters_enable then
			if bitmap_meters_tag and bitmap_ammo_outlines_tag and bitmap_weapon_background and bitmap_arrow_tag then
				--console_out("score meters enabled :D")
				score_meters = true
			else
				--console_out("BITMAPS NOT FOUND: ")
				--if bitmap_meters_tag==nil then console_out(bitmap_unit_meters) end
				--if bitmap_ammo_outlines_tag==nil then console_out(bitmap_ammo_outlines) end
				--if bitmap_weapon_background==nil then console_out(bitmap_weapon_backgrounds) end
				--if bitmap_arrow_tag==nil then console_out(bitmap_arrow_right) end
				score_meters = false
			end
		end
		
		if dead_ally_markers == false and secondary_weapon == false and score_meters == false then
			--console_out("not loaded :(")
			loaded = false
		else
			--console_out("loaded :)")
			loaded = true
		end
	end
	
	if bitmap_test_tag == nil then return false end -- just make sure the bitmap exists otherwise it will crash
	
	if server_type == "none" then
		dead_ally_markers = false
		score_meters = false
	end
	
	local master_hud_tag_data = read_dword(master_hud_tag + 0x14)
	GetHudMsgIDs()
	--set_timer(700, "GetHudMsgIDs")
	
	--position
	write_short(master_hud_tag_data + 0x3C, 4)
	
	write_dword(master_hud_tag_data + 0x60, struct1_count)
	write_dword(master_hud_tag_data + 0x64, new_struct1)
	
	
--dead markers
	for i=0,15 do
		local address = new_struct1 + i*180
		write_word(address + 0x00, 0)--state
		write_word(address + 0x04, 0)--map type
		write_short(address + 0x24, 999)--x
		write_short(address + 0x26, 999)--y
		write_float(address + 0x28, 0.1)--scale x
		write_float(address + 0x2C, 0.3)--scale y
		if dead_ally_markers then
			write_dword(address + 0x48, read_dword(bitmap_damage_tag))--bitmap
			write_dword(address + 0x48 + 0xC, read_dword(bitmap_damage_tag + 0xC))
		else
			write_dword(address + 0x48, read_dword(bitmap_test_tag))--bitmap
			write_dword(address + 0x48 + 0xC, read_dword(bitmap_test_tag + 0xC))
		end
		WriteColor(address + 0x58, floor(blue*255), floor(green*255), floor(red*255), floor(alpha*255)) --default color
		WriteColor(address + 0x5C, 0, 0, 0, 0) --flashing color
		write_float(address + 0x60, 0)--flash period
		write_float(address + 0x64, 0)--flash delay
		write_short(address + 0x68, 0)--number of flashes
		write_short(address + 0x6C, 0)--flash length
		WriteColor(address + 0x70, floor(blue*255), floor(green*255), floor(red*255), floor(alpha*255)) --disabled color
		write_short(address + 0x78, 0) --sequence index
	end
	
--secondaries
	for i=0,2 do
		local address = new_struct1 + (16+i)*180
		write_word(address + 0x00, 0)--state
		write_word(address + 0x04, 0)--map type
		write_short(address + 0x24, 999)--x
		write_short(address + 0x26, 999)--y
		write_float(address + 0x28, 0.75)--scale x
		write_float(address + 0x2C, 0.75)--scale y
		if secondary_weapon then
			write_dword(address + 0x48, read_dword(bitmap_icons_tag))--bitmap
			write_dword(address + 0x48 + 0xC, read_dword(bitmap_icons_tag + 0xC))
		else
			write_dword(address + 0x48, read_dword(bitmap_test_tag))--bitmap
			write_dword(address + 0x48 + 0xC, read_dword(bitmap_test_tag + 0xC))
		end
		WriteColor(address + 0x58, 255, 150, 40, 0) --default color
		WriteColor(address + 0x5C, 0, 0, 0, 0) --flashing color
		write_float(address + 0x60, 0)--flash period
		write_float(address + 0x64, 0)--flash delay
		write_short(address + 0x68, 0)--number of flashes
		write_short(address + 0x6C, 0)--flash length
		WriteColor(address + 0x70, 255, 150, 40, 0) --disabled color
		write_short(address + 0x78, 9) --sequence index
		
		if bigass then
			write_float(address + 0x2C, 0.5)
			WriteColor(address + 0x58, 255, 180, 80, 0) --default color
			WriteColor(address + 0x70, 255, 180, 80, 0) --disabled color
		end
	end

--SCORE METERS
	if score_meters then
		local aspect_ratio_fix, hac_widescreen = GetAspectRatio(100)
		--console_out(aspect_ratio_fix.." "..hac_widescreen)
		--outline
		for i=0,2 do
			local address = new_struct1 + (19+i)*180
			write_word(address + 0x00, 6)--state
			write_short(address + 0x24, floor((376 - (i-1)*2 +chimera_fix -aspect_ratio_fix)*hac_widescreen))--x
			write_short(address + 0x26, 178 + i*20)--y
			write_float(address + 0x28, 0.665*hac_widescreen)--scale x
			write_float(address + 0x2C, 4.2)--scale y
			write_dword(address + 0x48, read_dword(bitmap_ammo_outlines_tag))--bitmap
			write_dword(address + 0x48 + 0xC, read_dword(bitmap_ammo_outlines_tag + 0xC))
			write_short(address + 0x78, 1) --sequence index
			
			if hrhh then -- compatibility
				write_float(address + 0x28, 0.16*hac_widescreen)--scale x
				write_float(address + 0x2C, 0.72)--scale y
				write_short(address + 0x24, floor((376 - (i-1)*2 -1 +chimera_fix -aspect_ratio_fix)*hac_widescreen))--x
				write_short(address + 0x26, 178 + i*20 -2)--y
			elseif hrx then
				write_short(address + 0x26, 178 + i*20 +4)--y
				write_float(address + 0x28, 0.163*hac_widescreen)--scale x
				write_float(address + 0x2C, 1.69)--scale y
				write_short(address + 0x78, 9) --sequence index
			end
		end
		
		--squares
		for i=0,1 do
			local address = new_struct1 + (22+i)*180
			write_word(address + 0x00, 6)--state
			write_short(address + 0x24, floor((342 - i*2 +chimera_fix -aspect_ratio_fix)*hac_widescreen))--x
			write_short(address + 0x26, 198 + i*20)--y
			write_float(address + 0x28, 0.4*hac_widescreen)--scale x
			write_float(address + 0x2C, 1.05)--scale y
			write_dword(address + 0x48, read_dword(bitmap_weapon_background))--bitmap
			write_dword(address + 0x48 + 0xC, read_dword(bitmap_weapon_background + 0xC))
			write_short(address + 0x78, 0) --sequence index
			
			if hrhh then -- compatibility
				write_float(address + 0x28, (0.4/4)*hac_widescreen)--scale x
				write_float(address + 0x2C, 1.05/4)--scale y
			elseif hrx then
				write_short(address + 0x24, floor((342 - i*2 -10 +chimera_fix -aspect_ratio_fix)*hac_widescreen))--x
				write_short(address + 0x26, 198 + i*20 -1)--y
				write_float(address + 0x28, (0.4/5.5)*hac_widescreen)--scale x
				write_float(address + 0x2C, 1.05/4)--scale y
				write_short(address + 0x78, 1) --sequence index
			end
		end
		
		--arrow
		for i=0,1 do
			local address = new_struct1 + (24+i)*180
			write_word(address + 0x00, 6)--state
			write_short(address + 0x24, floor((328 - i*2 +chimera_fix -aspect_ratio_fix)*hac_widescreen))--x
			write_short(address + 0x26, 191 + i*20)--y
			write_float(address + 0x28, 0.8*hac_widescreen)--scale x
			write_float(address + 0x2C, 0.8)--scale y
			write_dword(address + 0x48, read_dword(bitmap_arrow_tag))--bitmap
			write_dword(address + 0x48 + 0xC, read_dword(bitmap_arrow_tag + 0xC))
			write_short(address + 0x78, 0) --sequence index
		end
		
		--meters
		write_dword(master_hud_tag_data + 0x6C, 2)
		write_dword(master_hud_tag_data + 0x6C+4, new_struct2)
		
		for i=0,1 do
			local address = new_struct2 + i*180
			write_word(address + 0x00, 6)--state
			write_word(address + 0x04, 0)--map type
			write_short(address + 0x24, floor((369 - i*2 +chimera_fix -aspect_ratio_fix)*hac_widescreen))--x
			write_short(address + 0x26, 190 + i*20)--y
			write_float(address + 0x28, -0.332*hac_widescreen)--scale x
			write_float(address + 0x2C, 1.4)--scale y
			write_dword(address + 0x48, read_dword(bitmap_meters_tag))--bitmap
			write_dword(address + 0x48 + 0xC, read_dword(bitmap_meters_tag + 0xC))
			write_byte(address + 0x69, 240)--min meter value
			write_short(address + 0x6A, 4) --sequence index
			write_byte(address + 0x6C, 20)--alpha multiplier
			write_byte(address + 0x6D, 0)--alpha bias
			write_byte(address + 0x6E, 0)--value scale
			write_float(address + 0x70, 0)--opacity
			write_float(address + 0x74, 1)--transulency
			
			if hrhh then-- compatibility
				write_float(address + 0x28, (-0.332/2)*hac_widescreen)--scale x
				write_float(address + 0x2C, 1.4/2)--scale y
			elseif hrx then
				write_float(address + 0x28, (-0.332/4)*hac_widescreen)--scale x
				write_float(address + 0x2C, 1.4/4)--scale y
				write_short(address + 0x6A, 7) --sequence index
			end
		end
	else
		for i=0,6 do
			local address = new_struct1 + (19+i)*180
			write_dword(address + 0x48, read_dword(bitmap_test_tag))--bitmap
			write_dword(address + 0x48 + 0xC, read_dword(bitmap_test_tag + 0xC))
		end
	end
	
	return false
end

SetupTags()

function SetMeterColor(i ,blue, green, red, player_team)
	local alpha = 255
	if red==0 and green==0 and blue==0 then
		alpha = 0
	end
	
	--outline
	local address = new_struct1 + (20+i)*180
	WriteColor(address + 0x58, floor(blue/4), floor(green/4), floor(red/4), alpha)
	--square
	address = new_struct1 + (22+i)*180
	WriteColor(address + 0x58, floor(blue/1.2), floor(green/1.2), floor(red/1.2), alpha)
	--arrow
	address = new_struct1 + (24+i)*180
	if player_team == i then
		WriteColor(address + 0x58, 255, 255, 255, floor(alpha/2))
	else
		WriteColor(address + 0x58, 0, 0, 0, 0)
	end
	--meter
	address = new_struct2 + i*180
	WriteColor(address + 0x58, blue, green, red) --min color
	WriteColor(address + 0x64, floor(blue/6.3), floor(green/6.3), floor(red/6.3)) --empty color
end

function SetMeters(red_score, blue_score, max_score, player_team, opponent_id)
	--red_score = 2
	--blue_score = 1
	local address_red = new_struct2
	local address_blue = new_struct2 + 180
	local red_bar = floor(red_score/max_score*254)
	local blue_bar = floor(blue_score/max_score*254)
	
	write_byte(address_red + 0x69, red_bar)
	write_byte(address_blue + 0x69, blue_bar)
	
	if player_team ~= -1 then
		SetMeterColor(0, team_color_red.blue, team_color_red.green, team_color_red.red, player_team)
		SetMeterColor(1, team_color_blue.blue, team_color_blue.green, team_color_blue.red, player_team)
	else
		local player_color = PLAYER_COLORS[read_word(m_player + 0x60)]
		SetMeterColor(0, player_color.b, player_color.g, player_color.r, 0)
		
		local m_opponent = get_player(opponent_id)
		if opponent_id ~= -1 and m_opponent then
			local player_color = PLAYER_COLORS[read_word(m_opponent + 0x60)]
			--console_out("color id "..read_word(m_opponent + 0x60))
			--console_out("color r "..player_color.r.." g "..player_color.g.." b "..player_color.b)
			SetMeterColor(1, player_color.b, player_color.g, player_color.r, 0)
		else
			SetMeterColor(1, 0, 0, 0, 0)
		end
	end
end

function SetSecondaryWeapon(id, width, i)
	local address = new_struct1 + (16+i)*180
	if id > -1 then
		--console_out(id)
		local aspect_ratio_fix, hac_widescreen = GetAspectRatio(110)
		-- If player also has hud_sway.lua
		local x_offset = 0
		local y_offset = 0
		local player = get_dynamic_player()
		if player then
			x_offset = read_short(player + 0x38A)
			y_offset = read_short(player + 0x3BA)
		end
		
		if bigass then
			local slot_offsetx = i*3
			local slot_offsety = i*21
			write_short(address + 0x78, id) --sequence index
			write_short(address + 0x24, floor((position_x_bigass - width*100 + slot_offsetx - aspect_ratio_fix)*hac_widescreen + x_offset))--x
			write_short(address + 0x26, position_y_bigass - y_offset + slot_offsety)--y
			write_float(address + 0x28, -0.5)--x scale
		else
			local slot_offsetx = i*-8
			local slot_offsety = i*30
			write_short(address + 0x78, id) --sequence index
			if hrx then
				x_offset = x_offset + 10
			elseif h2_hud then
				x_offset = x_offset + 40
			end
			write_short(address + 0x24, floor((position_x + width*50 + slot_offsetx + aspect_ratio_fix)*hac_widescreen + x_offset))--x
			write_short(address + 0x26, position_y - y_offset + slot_offsety)--y
			write_float(address + 0x28, 0.75*hac_widescreen)
		end
	else
		write_short(address + 0x24, 999)--x
		write_short(address + 0x26, 999)--y
	end
end

function SetHudPosition(i,x,y,x_scale,y_scale)
	local address = new_struct1 + i*180
	
	write_short(address + 0x24, x)--x
	write_short(address + 0x26, y)--y
	if x_scale ~= nil and y_scale ~= nil then
		write_float(address + 0x28, x_scale*0.1)--scale x
		write_float(address + 0x2C, y_scale*0.3)--scale y
	end
end

function OnCamera(x, y, z, fov, x1, y1, z1, x2, y2, z2)
	if loaded == false then return end
	
	if dead_ally_markers then
		for i,info in pairs (POSITIONS) do
			local player = get_dynamic_player(i)
			if player then
				SetHudPosition(i,999,999)
			else
				local object = get_object(info)
				if object then
					local obj_type = read_word(object + 0xB4)
					if obj_type == 0 then
						local head = object + 0x550 + 0x34*12
						
						local dist_x = read_float(head + 0x28)-x
						local dist_y = read_float(head + 0x2C)-y
						local dist_z = read_float(head + 0x30)-z
						CalculateFov(fov)
						local ssx, ssy, ssz = FindSunInScreenSpace(dist_x,dist_y,dist_z+0.35, 0, 0, 0, x1, y1, z1, vertical_fov)
						ssx = -floor((50-ssx*100)*8.7)
						ssy = floor((50-ssy*100)*4.9)
						
						local dist = sqrt((dist_x*dist_x)+(dist_y*dist_y)+(dist_z*dist_z))
						dist = GetScale(dist)
						
						if ssz < 1 then
							SetHudPosition(i,ssx,ssy,dist,dist)
						else
							SetHudPosition(i,999,999)
						end
					else
						SetHudPosition(i,999,999)
						POSITIONS[i] = nil
					end
				else
					SetHudPosition(i,999,999)
					POSITIONS[i] = nil
				end
			end
		end
	end
	
	if secondary_weapon then
		local player = get_dynamic_player()
		
		if player then
			local vehicle = get_object(read_dword(player + 0x11C))
			if show_in_vehicles == false and vehicle ~= nil then
				SetSecondaryWeapon(-1, 1, 0)
				SetSecondaryWeapon(-1, 1, 1)
				SetSecondaryWeapon(-1, 1, 2)
			else
				local Secondaries = {}
				local weap_slot = read_byte(player + 0x2F2)
				
				for i=0,3 do
					if weap_slot ~= i then
						local msg_id = -1
						local width = 1
						local weapon = get_object(read_dword(player + 0x2F8+4*i))
						
						if weapon then
							weapon = read_dword(weapon)
							if WEAPON_HUDS[weapon] ~= nil then
								msg_id = WEAPON_HUDS[weapon].id
								width = WEAPON_HUDS[weapon].width
							end
						end
						
						Secondaries[i] = {["msg"] = msg_id,["width"] = width}
					else
						Secondaries[i] = {["msg"] = -1,["width"] = 1}
					end
				end
				
				if weap_slot == 1 and Secondaries[2].msg > -1 then
					Secondaries[1] = Secondaries[0]
					Secondaries[0] = Secondaries[2]
					Secondaries[2] = Secondaries[3]
				elseif weap_slot == 0 then
					Secondaries[0] = Secondaries[1]
					Secondaries[1] = Secondaries[2]
					Secondaries[2] = Secondaries[3]
				end
				
				for i=0,3 do
					if Secondaries[i] ~= nil then
						SetSecondaryWeapon(Secondaries[i].msg, Secondaries[i].width, i)
					end
				end
			end
		else
			SetSecondaryWeapon(-1, 1, 0)
			SetSecondaryWeapon(-1, 1, 1)
			SetSecondaryWeapon(-1, 1, 2)
		end
	end
end

function GetScale(dist)
	if dist < 1 then
		dist = 1
	elseif dist > 10 then
		dist = 10
	end
	--console_out(dist)
	dist = 10-dist
	--console_out(dist)
	return 1 + dist/10
end

function CalculateFov(fov)
	local screen_h = read_word(0x637CF0)
	local screen_w = read_word(0x637CF2)
	aspect_ratio = screen_w/screen_h
	fov = fov*180/pi
	vertical_fov = atan(tan(fov*pi/360) * (1/aspect_ratio)) * 360/pi
	vertical_fov = vertical_fov * 0.9
end

function FindSunInScreenSpace(x, y, z, eye_x, eye_y, eye_z, look_x, look_y, look_z, fovy)
	local view_xy = 0
	local view_w = 1 --1.12
	local view_h = 1 --1.12
		
	local eye = {}
	eye.x = eye_x
	eye.y = eye_y
	eye.z = eye_z
	local lookat = {}
	lookat.x = look_x
	lookat.y = look_y
	lookat.z = look_z
	local view  = new()
	local up = {}
	up.x, up.y, up.z = 0, 0, 1
	local aspect = aspect_ratio
	local near = 0.000001
	local far = 1000000
	view = look_at(view, eye, lookat, up)
	projection = from_perspective(fovy, aspect, near, far)
	viewport = {view_xy, view_xy, view_w, view_h}
	return project(x, y, z, view, projection, viewport)
end

function project(x, y, z, view, projection, viewport)
	local position = { x, y, z, 1 }
	
	mul_vec4(position, view,       position)
	mul_vec4(position, projection, position)
	
	if position[4] ~= 0 then
		position[1] = position[1] / position[4] * 0.5 + 0.5
		position[2] = position[2] / position[4] * 0.5 + 0.5
		position[3] = position[3] / position[4] * 0.5 + 0.5
	end
	
	position[1] = position[1] * viewport[3] + viewport[1]
	position[2] = position[2] * viewport[4] + viewport[2]
	return position[1], position[2], position[3]
end

function mul_vec4(out, a, b)
	local tv4 = { 0, 0, 0, 0 }
	tv4[1] = b[1] * a[1] + b[2] * a[5] + b [3] * a[9]  + b[4] * a[13]
	tv4[2] = b[1] * a[2] + b[2] * a[6] + b [3] * a[10] + b[4] * a[14]
	tv4[3] = b[1] * a[3] + b[2] * a[7] + b [3] * a[11] + b[4] * a[15]
	tv4[4] = b[1] * a[4] + b[2] * a[8] + b [3] * a[12] + b[4] * a[16]

	for i=1, 4 do
		out[i] = tv4[i]
	end
	
	return out
end

function look_at(out, eye, lookat, up)
	eye.x = eye.x - lookat.x
	eye.y = eye.y - lookat.y
	eye.z = eye.z - lookat.z
	local z_axis = normalize(eye)
	local x_axis = normalize(cross(up, z_axis))
	local y_axis = cross(z_axis, x_axis)
	out[1] = x_axis.x
	out[2] = y_axis.x
	out[3] = z_axis.x
	out[4] = 0
	out[5] = x_axis.y
	out[6] = y_axis.y
	out[7] = z_axis.y
	out[8] = 0
	out[9] = x_axis.z
	out[10] = y_axis.z
	out[11] = z_axis.z
	out[12] = 0
	out[13] = 0
	out[14] = 0
	out[15] = 0
	out[16] = 1

  return out
end

function normalize(a)
	if is_zero(a) then
		return new_v3()
	end
	return scale(a, (1 / len(a)))
end

function len(a)
	return sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end

function scale(a, b)
	return new_v3(
		a.x * b,
		a.y * b,
		a.z * b
	)
end

function is_zero(a)
	return a.x == 0 and a.y == 0 and a.z == 0
end

function cross(a, b)
	return new_v3(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

function from_perspective(fovy, aspect, near, far)
	assert(aspect ~= 0)
	assert(near   ~= far)

	local t   = tan(rad(fovy) / 2)
	local out = new()
	out[1]    =  1 / (t * aspect)
	out[6]    =  1 / t
	out[11]   = -(far + near) / (far - near)
	out[12]   = -1
	out[15]   = -(2 * far * near) / (far - near)
	out[16]   =  0
	
	return out
end

function new_v3(x, y, z)
	return {
		x = x or 0,
		y = y or 0,
		z = z or 0
	}
end

function new(m)
	m = m or {
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0
	}
	return m
end