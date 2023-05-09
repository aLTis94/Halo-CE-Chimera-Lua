-- version 0.2 (by aLTis)

--CONFIG

	sway_hud = true
	sway_amount = 1 -- how much the hud moves
	sway_amount_horizontal = 1.25
	walking_sway_amount = 0.5 -- how much the hud moves when you walk left or right
	vertical_velocity_amount = 0.8 -- how much the hud moves when player jumps or falls
	use_direct_input = true -- use if you want direct input from mouse/controller to affect the hud
	enable_in_vehicles = false -- only works if mouse input is enabled
	inverse_direction = true
	
	weapon_animation_sway = true
	weapon_animation_sway_amount = 15
	camera_sway_amount = 0.04 -- camera sway amount
	camera_sway_recenter_speed = 0.01 -- used to move the camera back to its position
	
--END OF CONFIG

--Known issues:
-- melee right after switching to BR moves grenade number?

clua_version = 2.042

local horizontal_sway = 9*sway_amount_horizontal
local vertical_sway = 16*sway_amount
local aim_left_amount = 0
local aim_down_amount = 0
local aim_left_amount_previous = 0
local aim_down_amount_previous = 0
local z_vel_change = 0
local HUD = nil
local WEAPONS = {}

local player_alive_timer = 5
		
local fp_anim_address = 0x40000EB8
local mouse_input_address = 0x64C73C
local zoom_address = read_dword(0x815918) + 204

local x_adjust = 0
local z_adjust = 0
	
set_callback("tick", "OnTick")
set_callback("frame", "OnFrame")
set_callback("map load", "OnMapLoad")
set_callback("unload", "OnUnload")
if weapon_animation_sway then
	set_callback("precamera", "OnCamera")
end

function OnMapLoad()
	HUD = nil
	WEAPONS = {}
	player_alive_timer = 5
end

function OnCamera(cam_x, cam_y, cam_z, fov, x1, y1, z1, x2, y2, z2)
	local player = get_dynamic_player()
	if player ~= nil then
		local no_vehicle = read_dword(player + 0x11C) == 0xFFFFFFFF
		local unzoomed = read_word(zoom_address) == 0xFFFF
		
		if testx_old and no_vehicle and unzoomed then
			local yaw, pitch = GetAnglesFrom3DVector(x1,y1,z1)
			
			local time_after_tick = ticks() - math.floor(ticks())
			local t1 = (testx_old*(1-time_after_tick)+testx*time_after_tick)*camera_sway_amount + yaw
			local t2 = (testz_old*(1-time_after_tick)+testz*time_after_tick)*camera_sway_amount + pitch
			
			local x, y, z = Get3DVectorFromAngles(t1,t2)
			x1,y1,z1 = x1+x,y1+y,z1+z
			x, y, z = Get3DVectorFromAngles(t1,t2+math.pi/2)
			x2,y2,z2 = x2+x,y2+y,z2+z
			
			x1, y1, z1 = Normalize(x1, y1, z1)
			x2, y2, z2 = Normalize(x2, y2, z2)
			
			return cam_x, cam_y, cam_z, fov, x1, y1, z1, x2, y2, z2
		end
	end
end

function Normalize(x, y, z)
	local length = 1/math.sqrt(x * x + y * y + z * z)
	x = x * length
	y = y * length
	z = z * length
	return x, y, z
end

function Get3DVectorFromAngles(alpha,beta)
	local x = math.cos(alpha) * math.cos(beta)
	local y = math.sin(alpha) * math.cos(beta)
	local z = math.sin(beta)
	return x, y, z, 1
end

function GetAnglesFrom3DVector(x,y,z)
	local pitch = math.asin(z)
	local yaw = math.atan(x,-y) - math.pi/2
	return yaw, pitch
end

function OnFrame()
	if sway_hud and HUD then
		local time_after_tick = ticks() - math.floor(ticks())
		
		x = (aim_left_amount_previous*(1-time_after_tick)+aim_left_amount*time_after_tick)*horizontal_sway
		z = (aim_down_amount_previous*(1-time_after_tick)+aim_down_amount*time_after_tick)*vertical_sway
		
		if weapon_animation_sway then
			local node = 148 + 28
			testx = read_float(fp_anim_address + node)
			testy = read_float(fp_anim_address + node + 4)
			testz = read_float(fp_anim_address + node + 8)
			
			testx, testz = GetAnglesFrom3DVector(testx, testy, testz)
			
			testx = testx + x_adjust
			local adjust_speed = math.sqrt(math.abs(testx))*camera_sway_recenter_speed
			--local adjust_speed = math.abs(testx)*0.03
			if testx < 0 then
				x_adjust = x_adjust + adjust_speed
			elseif testx > 0 then
				x_adjust = x_adjust - adjust_speed
			else
				x_adjust = 0
			end
			
			testz = testz + z_adjust
			adjust_speed = math.sqrt(math.abs(testz))*camera_sway_recenter_speed
			--adjust_speed = math.abs(testz)*0.03
			if testz < 0 then
				z_adjust = z_adjust + adjust_speed
			elseif testz > 0 then
				z_adjust = z_adjust - adjust_speed
			else
				z_adjust = 0
			end
			
			local player = get_dynamic_player()
			if player ~= nil then
				local object = get_object(read_dword(player + 0x118))
				if object ~= nil and read_word(object + 0xB4) == 2 then
					local ready_timer = read_word(object + 0x23A)-15
					if ready_timer > 0 then
						local ready_fixer = 1/math.sqrt(ready_timer)
						testx = testx*ready_fixer
						testz = testz*ready_fixer
						--console_out(ready_fixer)
					end
				end
			end
			
			x = x + testx*weapon_animation_sway_amount
			z = z + -testz*weapon_animation_sway_amount
		end
		
		if x > 0 then
			x = math.floor(x)
		elseif x < 0 then
			x = math.ceil(x)
		end	
		
		if z > 0 then
			z = math.floor(z)
		elseif z < 0 then
			z = math.ceil(z)
		end	
		
		for tag_data,adresses_table in pairs (HUD) do
			for address, INFO in pairs (adresses_table) do
				if INFO["count"] ~= nil then
					for i=0,INFO["count"]-1 do
						local struct = INFO["address"] + i * INFO["size"]
						if INFO["x2"] then
							write_short(struct + INFO["x"], INFO["coord"][i*4] + x * INFO["direction"])
							write_short(struct + INFO["y"], INFO["coord"][i*4+1] + z * INFO["direction_y"])
							write_short(struct + INFO["x2"], INFO["coord"][i*4+2] + x * INFO["direction"])
							write_short(struct + INFO["y2"], INFO["coord"][i*4+3] + z * INFO["direction_y"])
						else
							write_short(struct + INFO["x"], INFO["coord"][i*2] + x * INFO["direction"])
							write_short(struct + INFO["y"], INFO["coord"][i*2+1] + z * INFO["direction_y"])
						end
					end
				elseif INFO["type"] == 0 then
					write_i16(tag_data + address, INFO["coord"] + x * INFO["direction"])
				else
					write_i16(tag_data + address, INFO["coord"] + z * INFO["direction"])
				end
			end
		end
	end
end
	
function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end
	
function GetWPHI(meta_id)
	local tag = get_tag(meta_id)
	if tag then
		local tag_data = read_dword(tag + 0x14)
		local tag_name = read_string(read_dword(tag + 0x10))
		
		local child = read_dword(tag_data + 0xC)
		if child ~= 0xFFFFFFFF then
			GetWPHI(child)
		end
		
		local anchor = read_short(tag_data + 0x3C)
		if HUD[tag_data] == nil and tag_name ~= "taunts\\wheel_selection" then
			
			local direction = 1
			if anchor==1 or anchor==3 then
				direction = -1
			end
			HUD[tag_data] = {}
			HUD[tag_data][0x60] = {}
			HUD[tag_data][0x60]["direction"] = direction
			HUD[tag_data][0x60]["direction_y"] = -1
			HUD[tag_data][0x60]["count"] = read_u32(tag_data + 0x60 + 0)
			HUD[tag_data][0x60]["address"] = read_u32(tag_data + 0x60 + 4)
			HUD[tag_data][0x60]["size"] = 180
			HUD[tag_data][0x60]["x"] = 0x24
			HUD[tag_data][0x60]["y"] = 0x26
			HUD[tag_data][0x60]["coord"] = {}
			for i=0,HUD[tag_data][0x60]["count"]-1 do
				local struct = HUD[tag_data][0x60]["address"] + i * HUD[tag_data][0x60]["size"]
				--if anchor ~= 4 then
					HUD[tag_data][0x60]["coord"][i*2] = read_short(struct + HUD[tag_data][0x60]["x"])
					HUD[tag_data][0x60]["coord"][i*2+1] = read_short(struct + HUD[tag_data][0x60]["y"])
					if anchor == 4 then
						local bitmap = read_string(read_dword(struct + 0x4C))
						if HUD[tag_data][0x60]["coord"][i*2] == 0 and HUD[tag_data][0x60]["coord"][i*2+1] == 0 or string.find(bitmap, "dynamic") then
							HUD[tag_data][0x60] = nil
							break
						end
					end
				--else
					--local bitmap = read_string(read_dword(struct + 0x4C))
					--if string.find(bitmap, "visor") then
					--	HUD[tag_data][0x60]["coord"][i*2] = read_short(struct + HUD[tag_data][0x60]["x"])
					--	HUD[tag_data][0x60]["coord"][i*2+1] = read_short(struct + HUD[tag_data][0x60]["y"])
					--else
					--	HUD[tag_data][0x60] = nil
					--end
				--end
			end
			HUD[tag_data][0x6C] = {}
			HUD[tag_data][0x6C]["direction"] = direction
			HUD[tag_data][0x6C]["direction_y"] = -1
			HUD[tag_data][0x6C]["count"] = read_u32(tag_data + 0x6C + 0)
			HUD[tag_data][0x6C]["address"] = read_u32(tag_data + 0x6C + 4)
			HUD[tag_data][0x6C]["size"] = 180
			HUD[tag_data][0x6C]["x"] = 0x24
			HUD[tag_data][0x6C]["y"] = 0x26
			HUD[tag_data][0x6C]["coord"] = {}
			for i=0,HUD[tag_data][0x6C]["count"]-1 do
			   local struct = HUD[tag_data][0x6C]["address"] + i * HUD[tag_data][0x6C]["size"]
			   HUD[tag_data][0x6C]["coord"][i*2] = read_word(struct + HUD[tag_data][0x6C]["x"])
			   HUD[tag_data][0x6C]["coord"][i*2+1] = read_short(struct + HUD[tag_data][0x6C]["y"])
			   if anchor == 4 and HUD[tag_data][0x6C]["coord"][i*2] == 0 and HUD[tag_data][0x6C]["coord"][i*2+1] == 0 then
					HUD[tag_data][0x6C] = nil
					break
			   end
			end
			HUD[tag_data][0x78] = {}
			HUD[tag_data][0x78]["direction"] = direction
			HUD[tag_data][0x78]["direction_y"] = -1
			HUD[tag_data][0x78]["count"] = read_u32(tag_data + 0x78 + 0)
			HUD[tag_data][0x78]["address"] = read_u32(tag_data + 0x78 + 4)
			HUD[tag_data][0x78]["size"] = 160
			HUD[tag_data][0x78]["x"] = 0x24
			HUD[tag_data][0x78]["y"] = 0x26
			HUD[tag_data][0x78]["coord"] = {}
			for i=0,HUD[tag_data][0x78]["count"]-1 do
			   local struct = HUD[tag_data][0x78]["address"] + i * HUD[tag_data][0x78]["size"]
			   HUD[tag_data][0x78]["coord"][i*2] = read_short(struct + HUD[tag_data][0x78]["x"])
			   HUD[tag_data][0x78]["coord"][i*2+1] = read_short(struct + HUD[tag_data][0x78]["y"])
			end
			
			local crosshair_count = read_dword(tag_data + 0x84)
			local crosshair_address = read_dword(tag_data + 0x88)
			for j=0,crosshair_count-1 do
				local struct = crosshair_address + j * 104
				local bitmap = read_string(read_dword(struct + 0x28))
				if bitmap ~= nil and string.find(bitmap, "visor") then
					local address = struct+0x34-tag_data
					HUD[tag_data][address] = {}
					HUD[tag_data][address]["direction"] = 1
					HUD[tag_data][address]["direction_y"] = -1
					HUD[tag_data][address]["count"] = read_u32(tag_data + address + 0)
					HUD[tag_data][address]["address"] = read_u32(tag_data + address + 4)
					HUD[tag_data][address]["size"] = 136
					HUD[tag_data][address]["x"] = 0x00
					HUD[tag_data][address]["y"] = 0x02
					HUD[tag_data][address]["coord"] = {}
					for i=0,HUD[tag_data][address]["count"]-1 do
					   local struct = HUD[tag_data][address]["address"] + i * HUD[tag_data][address]["size"]
					   HUD[tag_data][address]["coord"][i*2] = read_short(struct + HUD[tag_data][address]["x"])
					   HUD[tag_data][address]["coord"][i*2+1] = read_short(struct + HUD[tag_data][address]["y"])
					end
				end
			end
			
			local overlay_count = read_dword(tag_data + 0x90)
			local overlay_address = read_dword(tag_data + 0x94)
			for j=0,overlay_count-1 do
				local struct = overlay_address + j * 104
				local address = struct+0x34-tag_data
				HUD[tag_data][address] = {}
				HUD[tag_data][address]["direction"] = direction
				HUD[tag_data][address]["direction_y"] = -1
				HUD[tag_data][address]["count"] = read_u32(tag_data + address + 0)
				HUD[tag_data][address]["address"] = read_u32(tag_data + address + 4)
				HUD[tag_data][address]["size"] = 136
				HUD[tag_data][address]["x"] = 0x00
				HUD[tag_data][address]["y"] = 0x02
				HUD[tag_data][address]["coord"] = {}
				for i=0,HUD[tag_data][address]["count"]-1 do
				   local struct = HUD[tag_data][address]["address"] + i * HUD[tag_data][address]["size"]
				   HUD[tag_data][address]["coord"][i*2] = read_short(struct + HUD[tag_data][address]["x"])
				   HUD[tag_data][address]["coord"][i*2+1] = read_short(struct + HUD[tag_data][address]["y"])
				end
			end
		end
	end
	return
end
		
function GetWeaponHUD(meta_id)
	local tag = get_tag(tonumber(meta_id))
	if tag and HUD ~= nil then
		tag = read_dword(tag + 0x14)
		local hud = read_dword(tag + 0x480 + 0xC)
		if hud ~= nil then
			GetWPHI(hud, 1)
		end
	end
	return false
end
		
function OnTick()
	if sway_hud then
		if tonumber(ticks()) < 15 then return end
		
		testx_old = testx
		testz_old = testz
		
		local player = get_dynamic_player()
		if player ~= nil then
			
			if player_alive_timer > 0 then
				player_alive_timer = player_alive_timer - 1
				return
			end
			
			local no_vehicle = read_dword(player + 0x11C) == 0xFFFFFFFF
			local show_hud = read_byte(0x400003bc) == 1
			
			if HUD == nil and no_vehicle and show_hud then
				camera_address = 0x647498
				camera_type = read_word(camera_address)
				if camera_type ~= 23776 then
					GetHUD()
				end
			end
			
			aim_left_amount_previous = aim_left_amount
			aim_down_amount_previous = aim_down_amount
			if use_direct_input and (enable_in_vehicles or no_vehicle) then
				if desired_aim ~= read_float(player + 0x230) then
					local mouse_left = -read_long(mouse_input_address)*0.01
					local mouse_down = -read_long(mouse_input_address + 4)*0.01
					controller_rs_down = 0
					controller_rs_left = 0
					
					for controller_id = 0,3 do
						controller_input_address = 0x64D998 + controller_id*0xA0
						controller_rs_down = controller_rs_down + read_long(controller_input_address + 34)*0.000000002
						controller_rs_left = controller_rs_left - read_long(controller_input_address + 36)*0.000000002
					end
					
					aim_left_amount = mouse_left + controller_rs_left
					aim_down_amount = mouse_down + controller_rs_down
				else
					aim_left_amount = 0
					aim_down_amount = 0
				end
				desired_aim = read_float(player + 0x230)
			elseif no_vehicle then
				aim_left_amount = read_float(fp_anim_address + 72)
				aim_down_amount = read_float(fp_anim_address + 76)
			else
				aim_left_amount = 0
				aim_down_amount = 0
			end
			
			if no_vehicle then
				aim_left_amount = aim_left_amount + read_float(fp_anim_address + 60)*walking_sway_amount
			end
			
			if inverse_direction then
				aim_left_amount = -aim_left_amount
				aim_down_amount = -aim_down_amount
			end
			
			local z_vel = read_float(player + 0x70)*10
			if z_vel_prev ~= nil then
				z_vel_change = z_vel_change*0.7
				z_vel_change = z_vel_change + z_vel - z_vel_prev
				
				if math.abs(z_vel_change) < 0.001 then
					z_vel_change = 0
				end
				
				aim_down_amount = aim_down_amount + z_vel_change*vertical_velocity_amount
			end
			z_vel_prev = z_vel
			
			local weapon = get_object(read_dword(player + 0x118))
			if weapon and read_word(weapon + 0xB4) == 2 then
				local meta_id = read_dword(weapon)
				if WEAPONS[meta_id] == nil and HUD~=nil then
					WEAPONS[meta_id] = true
					set_timer(33, "GetWeaponHUD", meta_id)
				end
			end
			
			if enable_in_vehicles and no_vehicle == false and use_direct_input then
				local vehicle = get_object(read_dword(player + 0x11C))
				if vehicle then
					local weapon = get_object(read_dword(vehicle + 0x2F8))
					if weapon then
						local meta_id = read_dword(weapon)
						if WEAPONS[meta_id] == nil and HUD~=nil then
							WEAPONS[meta_id] = true
							set_timer(33, "GetWeaponHUD", meta_id)
						end
					end
				end
			end
			
		else
			aim_left_amount_previous = 0
			aim_down_amount_previous = 0
			aim_left_amount = 0
			aim_down_amount = 0
			z_vel_prev = 0
			player_alive_timer = 5
			return
		end
	end
end

function GetHUD()
	HUD = {}
	local tag_count = read_u32(0x4044000C)
	for i = 0,tag_count-1 do
		local tag = get_tag(i)
		local tag_class = read_u32(tag)
		local tag_data = read_u32(tag + 0x14)
		local tag_name = read_string(read_dword(tag + 0x10))

		-- unhi
		if tag_class == 0x756E6869 and tag_name ~= "taunts\\wheel_selection" then
			local anchor = read_short(tag_data)
			local direction = 1
			local direction_y = 1
			if anchor==1 or anchor==3 then
				direction = -1
			end
			if anchor==0 or anchor==1 or anchor==4 then
				direction_y = -1
			end
			HUD[tag_data] = {}
			local bitmap = read_string(read_dword(tag_data + 0x4C))
			if bitmap ~= "bourrin\\hud\\light\\weapons\\circle" then
				HUD[tag_data][0x24] = {}
				HUD[tag_data][0x24]["coord"] = read_i16(tag_data + 0x24)
				HUD[tag_data][0x24]["direction"] = direction
				HUD[tag_data][0x24]["type"] = 0
				HUD[tag_data][0x26] = {}
				HUD[tag_data][0x26]["coord"] = read_i16(tag_data + 0x26)
				HUD[tag_data][0x26]["direction"] = direction_y
				HUD[tag_data][0x26]["type"] = 1
			end
			HUD[tag_data][0xF4] = {}
			HUD[tag_data][0xF4]["coord"] = read_i16(tag_data + 0xF4)
			HUD[tag_data][0xF4]["direction"] = direction
			HUD[tag_data][0xF4]["type"] = 0
			HUD[tag_data][0xF6] = {}
			HUD[tag_data][0xF6]["coord"] = read_i16(tag_data + 0xF6)
			HUD[tag_data][0xF6]["direction"] = direction_y
			HUD[tag_data][0xF6]["type"] = 1
			HUD[tag_data][0x8C] = {}
			HUD[tag_data][0x8C]["coord"] = read_i16(tag_data + 0x8C)
			HUD[tag_data][0x8C]["direction"] = direction
			HUD[tag_data][0x8C]["type"] = 0
			HUD[tag_data][0x8E] = {}
			HUD[tag_data][0x8E]["coord"] = read_i16(tag_data + 0x8E)
			HUD[tag_data][0x8E]["direction"] = direction_y
			HUD[tag_data][0x8E]["type"] = 1
			HUD[tag_data][0x1E4] = {}
			HUD[tag_data][0x1E4]["coord"] = read_i16(tag_data + 0x1E4)
			HUD[tag_data][0x1E4]["direction"] = direction
			HUD[tag_data][0x1E4]["type"] = 0
			HUD[tag_data][0x1E6] = {}
			HUD[tag_data][0x1E6]["coord"] = read_i16(tag_data + 0x1E6)
			HUD[tag_data][0x1E6]["direction"] = direction_y
			HUD[tag_data][0x1E6]["type"] = 1
			HUD[tag_data][0x17C] = {}
			HUD[tag_data][0x17C]["coord"] = read_i16(tag_data + 0x17C)
			HUD[tag_data][0x17C]["direction"] = direction
			HUD[tag_data][0x17C]["type"] = 0
			HUD[tag_data][0x17E] = {}
			HUD[tag_data][0x17E]["coord"] = read_i16(tag_data + 0x17E)
			HUD[tag_data][0x17E]["direction"] = direction_y
			HUD[tag_data][0x17E]["type"] = 1
			HUD[tag_data][0x26C] = {}
			HUD[tag_data][0x26C]["coord"] = read_i16(tag_data + 0x26C)
			HUD[tag_data][0x26C]["direction"] = 1
			HUD[tag_data][0x26C]["type"] = 0
			HUD[tag_data][0x26E] = {}
			HUD[tag_data][0x26E]["coord"] = read_i16(tag_data + 0x26E)
			HUD[tag_data][0x26E]["direction"] = 1
			HUD[tag_data][0x26E]["type"] = 1
			HUD[tag_data][0x2D4] = {}
			HUD[tag_data][0x2D4]["coord"] = read_i16(tag_data + 0x2D4)
			HUD[tag_data][0x2D4]["direction"] = 1
			HUD[tag_data][0x2D4]["type"] = 0
			HUD[tag_data][0x2D6] = {}
			HUD[tag_data][0x2D6]["coord"] = read_i16(tag_data + 0x2D6)
			HUD[tag_data][0x2D6]["direction"] = 1
			HUD[tag_data][0x2D6]["type"] = 1
			HUD[tag_data][0x35C] = {}
			HUD[tag_data][0x35C]["coord"] = read_i16(tag_data + 0x35C)
			HUD[tag_data][0x35C]["direction"] = 1
			HUD[tag_data][0x35C]["type"] = 0
			HUD[tag_data][0x35E] = {}
			HUD[tag_data][0x35E]["coord"] = read_i16(tag_data + 0x35E)
			HUD[tag_data][0x35E]["direction"] = 1
			HUD[tag_data][0x35E]["type"] = 1
			
			HUD[tag_data][0x3CC] = {}
			HUD[tag_data][0x3CC]["direction"] = direction
			HUD[tag_data][0x3CC]["direction_y"] = -1
			HUD[tag_data][0x3CC]["count"] = read_u32(tag_data + 0x3CC + 0)
			HUD[tag_data][0x3CC]["address"] = read_u32(tag_data + 0x3CC + 4)
			HUD[tag_data][0x3CC]["size"] = 324
			HUD[tag_data][0x3CC]["x"] = 0x14
			HUD[tag_data][0x3CC]["y"] = 0x16
			HUD[tag_data][0x3CC]["x2"] = 0x7C
			HUD[tag_data][0x3CC]["y2"] = 0x7E
			HUD[tag_data][0x3CC]["coord"] = {}
			for i=0,HUD[tag_data][0x3CC]["count"]-1 do
			   local struct = HUD[tag_data][0x3CC]["address"] + i * HUD[tag_data][0x3CC]["size"]
			   HUD[tag_data][0x3CC]["coord"][i*4] = read_short(struct + HUD[tag_data][0x3CC]["x"])
			   HUD[tag_data][0x3CC]["coord"][i*4+1] = read_short(struct + HUD[tag_data][0x3CC]["y"])
			   HUD[tag_data][0x3CC]["coord"][i*4+2] = read_short(struct + HUD[tag_data][0x3CC]["x2"])
			   HUD[tag_data][0x3CC]["coord"][i*4+3] = read_short(struct + HUD[tag_data][0x3CC]["y2"])
			end
		-- grhi
		elseif tag_class == 0x67726869 then
			local anchor = read_short(tag_data)
			local direction = 1
			if anchor==1 or anchor==3 then
				direction = -1
			end
			HUD[tag_data] = {}
			HUD[tag_data][0x24] = {}
			HUD[tag_data][0x24]["coord"] = read_i16(tag_data + 0x24)
			HUD[tag_data][0x24]["direction"] = direction
			HUD[tag_data][0x24]["type"] = 0
			HUD[tag_data][0x26] = {}
			HUD[tag_data][0x26]["coord"] = read_i16(tag_data + 0x26)
			HUD[tag_data][0x26]["direction"] = -1
			HUD[tag_data][0x26]["type"] = 1
			HUD[tag_data][0x8C] = {}
			HUD[tag_data][0x8C]["coord"] = read_i16(tag_data + 0x8C)
			HUD[tag_data][0x8C]["direction"] = direction
			HUD[tag_data][0x8C]["type"] = 0
			HUD[tag_data][0x8E] = {}
			HUD[tag_data][0x8E]["coord"] = read_i16(tag_data + 0x8E)
			HUD[tag_data][0x8E]["direction"] = -1
			HUD[tag_data][0x8E]["type"] = 1
			HUD[tag_data][0xF4] = {}
			HUD[tag_data][0xF4]["coord"] = read_i16(tag_data + 0xF4)
			HUD[tag_data][0xF4]["direction"] = direction
			HUD[tag_data][0xF4]["type"] = 0
			HUD[tag_data][0xF6] = {}
			HUD[tag_data][0xF6]["coord"] = read_i16(tag_data + 0xF6)
			HUD[tag_data][0xF6]["direction"] = -1
			HUD[tag_data][0xF6]["type"] = 1
			
			HUD[tag_data][0x15C] = {}
			HUD[tag_data][0x15C]["direction"] = 1
			HUD[tag_data][0x15C]["direction_y"] = -1
			HUD[tag_data][0x15C]["count"] = read_u32(tag_data + 0x15C + 0)
			HUD[tag_data][0x15C]["address"] = read_u32(tag_data + 0x15C + 4)
			HUD[tag_data][0x15C]["size"] = 136
			HUD[tag_data][0x15C]["x"] = 0x00
			HUD[tag_data][0x15C]["y"] = 0x02
			HUD[tag_data][0x15C]["coord"] = {}
			for i=0,HUD[tag_data][0x15C]["count"]-1 do
			   local struct = HUD[tag_data][0x15C]["address"] + i * HUD[tag_data][0x15C]["size"]
			   HUD[tag_data][0x15C]["coord"][i*2] = read_short(struct + HUD[tag_data][0x15C]["x"])
			   HUD[tag_data][0x15C]["coord"][i*2+1] = read_short(struct + HUD[tag_data][0x15C]["y"])
			end
		end
	end
	return false
end

function OnUnload()
	if HUD==nil then return end
	
	for tag_data,adresses_table in pairs (HUD) do
		for address, INFO in pairs (adresses_table) do
			if INFO["count"] ~= nil then
				for i=0,INFO["count"]-1 do
					local struct = INFO["address"] + i * INFO["size"]
					if INFO["x2"] then
						write_i16(struct + INFO["x"], INFO["coord"][i*4])
						write_i16(struct + INFO["y"], INFO["coord"][i*4+1])
						write_i16(struct + INFO["x2"], INFO["coord"][i*4+2])
						write_i16(struct + INFO["y2"], INFO["coord"][i*4+3])
					else
						write_i16(struct + INFO["x"], INFO["coord"][i*2])
						write_i16(struct + INFO["y"], INFO["coord"][i*2+1])
					end
				end
			elseif INFO["type"] == 0 then
				write_i16(tag_data + address, INFO["coord"])
			else
				write_i16(tag_data + address, INFO["coord"])
			end
		end
	end
end

function ClearConsole()
	for i=0,30 do
		console_out(" ")
	end
end

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end