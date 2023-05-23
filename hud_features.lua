--Hud Features script by aLTis.

--CONFIG
	dead_ally_markers = true -- shows a red arrow above dead ally bodies
	
	secondary_weapon = true -- shows what weapons you have in your inventory
		position_x = -293
		position_y = -216
		position_x_bigass = 409
		position_y_bigass = -143
--END OF CONFIG

clua_version = 2.042

local bitmap_numbers = "ui\\hud\\bitmaps\\combined\\hud_counter_numbers"
local bitmap_reticles = "ui\\hud\\bitmaps\\combined\\hud_reticles"
local bitmap_waypoints = "ui\\hud\\bitmaps\\combined\\hud_waypoints"
local bitmap_icons = "ui\\hud\\bitmaps\\combined\\hud_msg_icons"
local bitmap_ammo = "ui\\hud\\bitmaps\\combined\\hud_ammo_type_icons"
local bitmap_damage = "ui\\hud\\bitmaps\\combined\\hud_damage_arrows"
local bitmap_unit = "ui\\hud\\bitmaps\\combined\\hud_unit_backgrounds"
local bitmap_multiplayer = "ui\\hud\\bitmaps\\hud_multiplayer"
local bitmap_blip = "ui\\hud\\bitmaps\\hud_sensor_blip"
local bitmap_cursor = "ui\\shell\\bitmaps\\cursor"
local bitmap_blood = "effects\\decals\\blood splats\\bitmaps\\blood splat engineer"
local bitmap_player_color = "ui\\shell\\main_menu\\settings_select\\player_setup\\player_profile_edit\\color_edit\\player_color_marine_large"
local bitmap_test = "weapons\\assault rifle\\fp\\bitmaps\\numbers_plate"

local memory_address = 0x40440000
local new_struct1_size = 180*19 + 4
local new_struct1 = memory_address - new_struct1_size

local bitmap_id = 0
local red = 1
local green = 0
local blue = 0
local alpha = 0.5
local scale_x = 0.1
local scale_y = 0.3

if build > 0 then
	position_x = position_x + 100
	position_x_bigass = position_x_bigass - 100
end

set_callback("map load", "OnMapLoad")
set_callback("tick", "OnTick")
set_callback("precamera", "OnCamera")
set_callback("unload", "OnUnload")

local loaded = false
local bigass = false
local POSITIONS = {}
local WEAPON_HUDS = {}

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

function OnTick()
	if loaded == false then return end
	local m_player = get_player()
	
	if m_player then
		local player_team = read_byte(m_player + 0x20)
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
					end
				else
					POSITIONS[i] = nil
				end
			else
				POSITIONS[i] = nil
			end
		end
	end
end

function OnMapLoad()
	ResetMemory()
	loaded = false
	SetupTags()
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
			console_out("Error at "..i.." because its "..read_byte(address + i))
			return false
		end
	end
	return true
end

function ResetMemoryField(address, size)
	if loaded then
		for i=0,size-4 do
			write_byte(address + i, 0)
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
	end
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
				hud_tag = read_dword(hud_tag + 0x14)
				local msg_id = read_short(hud_tag + 0x13C)
				if msg_id > -1 and msg_id < 100 then
					local metaid = read_dword(tag + 0xC)
					WEAPON_HUDS[metaid] = {}
					WEAPON_HUDS[metaid].id = msg_id
					WEAPON_HUDS[metaid].width = GetBitmapWidth(msg_id)
					if WEAPON_HUDS[metaid].width == 1 then
						console_out(msg_id.." "..read_string(read_dword(tag + 0x10)))
					end
				end
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
		console_out("error getting width")
		return 1
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

function SetupTags()
	bigass = false
	
	if CheckAllocation(new_struct1, new_struct1_size) == false then
		loaded = false
		console_out("Failed to allocate memory for struct1")
		return
	end
	
	local bitmap_tag = get_tag("bitm", bitmap_damage)
	bitmap_icons_tag = get_tag("bitm", bitmap_icons)
	master_hud_tag = get_tag("wphi", "ui\\hud\\master")
	
	if bitmap_tag == nil then
		bitmap_tag = get_tag("bitm", "ui\\hud\\hrx_bitmaps\\hrx_damage_arrows\\hrx_damage_arrows")
	end
	if bitmap_icons_tag == nil then
	bitmap_icons_tag = get_tag("bitm", "ui\\hud\\hrx_bitmaps\\hrx_pickup_icons\\hrx_pickup_icons")
	end
	if bitmap_icons_tag == nil then
		bigass = true
		bitmap_icons_tag = get_tag("bitm", "bourrin\\hud\\v3\\bitmaps\\bourrin hud msg icons")
	end
	if master_hud_tag == nil then
		master_hud_tag = get_tag("wphi", "taunts\\wheel_selection")
	end
	
	if bitmap_tag and bitmap_icons_tag then
		if master_hud_tag then
			master_hud_tag_data = read_dword(master_hud_tag + 0x14)
			--console_out("loaded :)")
			loaded = true
		else
			loaded = false
			--console_out("hud not found :(")
			return
		end
	else
		--console_out("bitmaps not found :(")
		return
	end
	
	GetHudMsgIDs()
	set_timer(700, "GetHudMsgIDs")
	
	--position
	write_short(master_hud_tag_data + 0x3C, 4)
	
	write_dword(master_hud_tag_data + 0x60, 19)
	write_dword(master_hud_tag_data + 0x64, new_struct1)
	
	for i=0,15 do
		local address = new_struct1 + i*180
		write_word(address + 0x00, 0)--state
		write_word(address + 0x04, 0)--map type
		write_short(address + 0x24, 999)--x
		write_short(address + 0x26, 999)--y
		write_float(address + 0x28, scale_x)--scale x
		write_float(address + 0x2C, scale_y)--scale y
		write_dword(address + 0x48, read_dword(bitmap_tag))--bitmap
		write_dword(address + 0x48 + 0xC, read_dword(bitmap_tag + 0xC))
		WriteColor(address + 0x58, floor(blue*255), floor(green*255), floor(red*255), floor(alpha*255)) --default color
		WriteColor(address + 0x5C, 0, 0, 0, 0) --flashing color
		write_float(address + 0x60, 0)--flash period
		write_float(address + 0x64, 0)--flash delay
		write_short(address + 0x68, 0)--number of flashes
		write_short(address + 0x6C, 0)--flash length
		WriteColor(address + 0x70, floor(blue*255), floor(green*255), floor(red*255), floor(alpha*255)) --disabled color
		write_short(address + 0x78, bitmap_id) --sequence index
	end
	
	for i=0,2 do
		local address = new_struct1 + (16+i)*180
		write_word(address + 0x00, 0)--state
		write_word(address + 0x04, 0)--map type
		write_short(address + 0x24, 999)--x
		write_short(address + 0x26, 999)--y
		--if i == 0 then
			write_float(address + 0x28, 0.75)--scale x
			write_float(address + 0x2C, 0.75)--scale y
		--else
		--	write_float(address + 0x28, 0.5)--scale x
		--	write_float(address + 0x2C, 0.5)--scale y
		--end
		write_dword(address + 0x48, read_dword(bitmap_icons_tag))--bitmap
		write_dword(address + 0x48 + 0xC, read_dword(bitmap_icons_tag + 0xC))
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
end

SetupTags()

function GetAspectRatio()
	local screen_h = read_word(0x637CF0)
	local screen_w = read_word(0x637CF2)
	aspect_ratio = (screen_w/screen_h)/(16/9)
	if bigass then
		local dmr_tag = get_tag("wphi", "bourrin\\hud\\v3\\interfaces\\dmr")
		if dmr_tag then
			local hac_widescreen = read_float(read_dword(read_dword(dmr_tag + 0x14) + 0x64) + 0x28)
			aspect_ratio = aspect_ratio*hac_widescreen
		end
	else
		aspect_ratio = aspect_ratio*aspect_ratio
		local pistol_hud = get_tag("wphi", "weapons\\pistol\\pistol")
		if pistol_hud then
			local x = read_float(read_dword(read_dword(pistol_hud + 0x14) + 0x64) + 0x28)
			local y = read_float(read_dword(read_dword(pistol_hud + 0x14) + 0x64) + 0x28+4)
			local hac_widescreen = x/y
			aspect_ratio = aspect_ratio*hac_widescreen
		end
	end
	return aspect_ratio
end

function SetSecondaryWeapon(id, width, i)
	local address = new_struct1 + (16+i)*180
	if id > -1 then
		local aspect_ratio = GetAspectRatio()
		
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
			write_short(address + 0x24, floor((position_x_bigass - width*100)*aspect_ratio + x_offset + slot_offsetx))--x
			write_short(address + 0x26, position_y_bigass - y_offset + slot_offsety)--y
			write_float(address + 0x28, -0.5)--x scale
		else
			local slot_offsetx = i*-8
			local slot_offsety = i*30
			write_short(address + 0x78, id) --sequence index
			write_short(address + 0x24, floor((position_x + width*50)*aspect_ratio + x_offset + slot_offsetx))--x
			write_short(address + 0x26, position_y - y_offset + slot_offsety)--y
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
		write_float(address + 0x28, x_scale*scale_x)--scale x
		write_float(address + 0x2C, y_scale*scale_y)--scale y
	end
end

function OnCamera(x, y, z, fov, x1, y1, z1, x2, y2, z2)
	if loaded == false then return end
	
	if dead_ally_markers then
		for i,info in pairs (POSITIONS) do
			local player = get_dynamic_player(i)
			--if player then
			--	SetHudPosition(i,999,999)
			--else
				local object = get_object(info)
				if object then
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
			--end
		end
	end
	
	if secondary_weapon then
		local player = get_dynamic_player()
		if player and get_object(read_dword(player + 0x11C)) == nil then
			--console_out(" ")
			local Secondaries = {}
			local weap_slot = read_byte(player + 0x2F2)
			--console_out("slot "..weap_slot)
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
					--if msg_id > -1 then
					--	console_out(i.." id: "..msg_id)
					--end
				else
					--console_out(":)")
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
	return 0.5 + dist/10
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