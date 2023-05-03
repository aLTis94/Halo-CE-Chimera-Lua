
-- Code that was used in this script:
--  https://github.com/Calinou/fov
--  https://github.com/excessive/cpml

clua_version = 2.042

-- NOTES
	-- need to detect which light is the sun in the sky tag
	-- could add os detection so none of this is done for players without os
	
--CONFIG
	
	map_name = "bigass_"
	
	-- AO
		local mxao_enable = 1
		local mxao_debug = 0
		local mxao_amount = 1.0 -- 0 to 3
		local mxao_indirect_lighting_amount = 0 -- 0 to 12
		local mxao_saturation = 0 -- 0 to 3
		local mxao_sample_radius = 3 -- 1 to 8
		local mxao_sample_count = 8 -- 8 to 255
		local mxao_dither_level = 3 -- 2 to 8
		local mxao_normal_bias = 0.35 -- 0 to 0.8
		local mxao_smooth_normals = 0
		local mxao_blur_sharpness = 400 -- 0 to 5
		local mxao_blur_steps = 2 -- 0 to 5
		local mxao_fade_out_start = 0.01 -- 0 to 1
		local mxao_fade_out_end = 0.04 -- 0 to 1
	
	-- VOLUMETRIC LIGHTING
		local vl_enable = 1
		local vl_use_fog_color = true
		local vl_red = 0.7 -- 1
		local vl_green = 0.8 -- 0.75
		local vl_blue = 1 -- 0.5
		local vl_center_x = 0.5
		local vl_center_y = 0.2
		local vl_sun_shafts_multiplier = 0.5
		local vl_fog_shadows = 0
		local vl_iterations = 50
		local vl_depth_plane = 0.005
		local vl_far_plane = 1000
		
		local vl_horizontal_fade_extend = 0.15 -- how far the sun can go from the screen before the effect is disabled
		local vl_vertical_fade_extend = 0.5
		
		-- these two might cause crashes
		local screen_h = read_word(0x637CF0)
		local screen_w = read_word(0x637CF2)
		local aspect_ratio = screen_w/screen_h
		-- changing these values affect each FOV differently
		local view_xy = 0
		local view_w = 1 --1.12
		local view_h = 1 --1.12
	
--CONFIG

local pi = math.pi
local atan = math.atan
local tan = math.tan
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local rad = math.rad
local floor = math.floor

local delay_timer = 15
set_callback("precamera", "OnCamera")

function OnCamera(x, y, z, fov, x1, y1, z1, x2, y2, z2)
	if string.find(map, map_name) then
		if delay_timer > 0 then
			delay_timer = delay_timer - 1
		else
			if vl_enable == 1 then
				GetSunFromScenario() --this could just be called on script load
				
				if sun_yaw ~= nil then
					CalculateFov(fov)
					
					sun_rot = Get3DVectorFromAngles(sun_yaw, sun_pitch)
					sun_x, sun_y, sun_z = FindSunInScreenSpace(sun_rot[1]*100000, sun_rot[2]*100000, sun_rot[3]*100000, 0, 0, 0, x1, y1, z1, vertical_fov)
					
					vl_center_x = 1 - sun_x
					vl_center_y = 1 - sun_y

					vl_sun_shafts = 1
					FadeSunShafts()
				end
			else
				execute_script("pp_set_effect_instance_active 1 0")
			end
			
			ExecuteOSCommands()
		end
	end
end

function ExecuteOSCommands()
	execute_script("pp_set_effect_instance_active 0 "..mxao_enable)
	if mxao_enable then
		execute_script("pp_set_effect_shader_variable_boolean 0 1 "..mxao_debug.." 0")
		execute_script("pp_set_effect_shader_variable_boolean 0 8 "..mxao_smooth_normals.." 0")
		
		execute_script("pp_set_effect_shader_variable_integer 0 5 "..mxao_sample_count.." 0")
		execute_script("pp_set_effect_shader_variable_integer 0 6 "..mxao_dither_level.." 0")
		execute_script("pp_set_effect_shader_variable_integer 0 10 "..mxao_blur_steps.." 0")
		
		execute_script("pp_set_effect_shader_variable_real 0 0 "..mxao_amount.." 0 0 0 0")
		execute_script("pp_set_effect_shader_variable_real 0 2 "..mxao_indirect_lighting_amount.." 0 0 0 0")
		execute_script("pp_set_effect_shader_variable_real 0 3 "..mxao_saturation.." 0 0 0 0")
		execute_script("pp_set_effect_shader_variable_real 0 4 "..mxao_sample_radius.." 0 0 0 0")
		execute_script("pp_set_effect_shader_variable_real 0 7 "..mxao_normal_bias.." 0 0 0 0")
		execute_script("pp_set_effect_shader_variable_real 0 9 "..mxao_blur_sharpness.." 0 0 0 0")
		execute_script("pp_set_effect_shader_variable_real 0 11 "..mxao_fade_out_start.." 0 0 0 0")
		execute_script("pp_set_effect_shader_variable_real 0 12 "..mxao_fade_out_end.." 0 0 0 0")
	end
	
	if vl_enable == 1 and sun_yaw ~= nil then
		execute_script("pp_set_effect_shader_variable_real (pp_get_effect_index_by_name \"sun_shafts\") (pp_get_effect_shader_variable_index_by_name (pp_get_effect_index_by_name \"sun_shafts\") \"center\") "..vl_center_x.." "..vl_center_y.." 0 0 0")
		execute_script("pp_set_effect_shader_variable_real (pp_get_effect_index_by_name \"sun_shafts\") (pp_get_effect_shader_variable_index_by_name (pp_get_effect_index_by_name \"sun_shafts\") \"sun_shafts\") "..vl_sun_shafts.." 0 0 0 0")
		execute_script("pp_set_effect_shader_variable_integer (pp_get_effect_index_by_name \"sun_shafts\") (pp_get_effect_shader_variable_index_by_name (pp_get_effect_index_by_name \"sun_shafts\") \"iterations\") "..vl_iterations.." 0")
		execute_script("pp_set_effect_shader_variable_real (pp_get_effect_index_by_name \"sun_shafts\") (pp_get_effect_shader_variable_index_by_name (pp_get_effect_index_by_name \"sun_shafts\") \"tint\") 0 "..vl_red.." "..vl_green.." "..vl_blue.." 0")
		execute_script("pp_set_effect_shader_variable_real (pp_get_effect_index_by_name \"sun_shafts\") (pp_get_effect_shader_variable_index_by_name (pp_get_effect_index_by_name \"sun_shafts\") \"fog_shadows\") "..vl_fog_shadows.." 0 0 0 0")
		execute_script("pp_set_effect_shader_variable_real (pp_get_effect_index_by_name \"sun_shafts\") (pp_get_effect_shader_variable_index_by_name (pp_get_effect_index_by_name \"sun_shafts\") \"depth_plane\") "..vl_depth_plane.." 0 0 0 0")
		execute_script("pp_set_effect_shader_variable_real (pp_get_effect_index_by_name \"sun_shafts\") (pp_get_effect_shader_variable_index_by_name (pp_get_effect_index_by_name \"sun_shafts\") \"FarPlane\") "..vl_far_plane.." 0 0 0 0")
	end
end

function CalculateFov(fov)
	fov = fov*180/pi
	vertical_fov = atan(tan(fov*pi/360) * (1/aspect_ratio)) * 360/pi
	vertical_fov = vertical_fov * 0.9
end

function FadeSunShafts()
	local sun_shafts_enabled = false
	
	if sun_z < 1 then
		if sun_x > 0.5 and sun_x < 1 + vl_horizontal_fade_extend then
			sun_shafts_enabled = true
			vl_sun_shafts = sqrt((1 + vl_horizontal_fade_extend - sun_x)*2) * vl_sun_shafts_multiplier
		elseif sun_x > 0 - vl_horizontal_fade_extend and sun_x < 1 + vl_horizontal_fade_extend then
			sun_shafts_enabled = true
			vl_sun_shafts = (sqrt((sun_x + vl_horizontal_fade_extend)*2)) * vl_sun_shafts_multiplier
		else
			sun_shafts_enabled = false
			vl_sun_shafts = 0
		end
		
		if vl_sun_shafts ~= 0 then
			if sun_y > 1 and sun_y < 1 + vl_vertical_fade_extend then
				vl_sun_shafts = vl_sun_shafts * (1 - (sun_y - 1) / vl_vertical_fade_extend)
			elseif sun_y > 0 - vl_vertical_fade_extend and sun_y < 0 then
				vl_sun_shafts = vl_sun_shafts + vl_sun_shafts * sun_y / vl_vertical_fade_extend
			elseif sun_y > 1 + vl_vertical_fade_extend or sun_y < 0 - vl_vertical_fade_extend then
				sun_shafts_enabled = false
				vl_sun_shafts = 0
			end
		end
	else
		sun_shafts_enabled = false
	end
	
	if sun_shafts_enabled then
		execute_script("pp_set_effect_instance_active (pp_get_effect_index_by_name \"sun_shafts\") 1")
	else
		execute_script("pp_set_effect_instance_active (pp_get_effect_index_by_name \"sun_shafts\") 0")
	end
end

function GetSunFromScenario()
	local scenario_tag_index = read_word(0x40440004)
	local scenario_tag = read_dword(0x40440000) + scenario_tag_index * 0x20
	local scenario_data = read_dword(scenario_tag + 0x14)
	local sky_count = read_dword(scenario_data + 0x30)
	local sky_address = read_dword(scenario_data + 0x34)
	--let's assume that the first sky is the current sky
	--for i=0, sky_count-1 do
	if sky_count > 3 then
		local i = 3
		local struct = sky_address + i*16
		local sky_dependancy = read_dword(struct + 0x4)
		local sky_tag_path = read_string(sky_dependancy)
		if sky_tag_path ~= nil then
			local sky_tag = read_dword(get_tag("sky ", sky_tag_path) + 0x14)
			local light_count = read_dword(sky_tag + 0xC4)
			local light_address = read_dword(sky_tag + 0xC8)
			-- let's just assume that the first light is the sun
			if light_count > 0 then
				sun_yaw = read_float(light_address + 0x68)
				sun_pitch = read_float(light_address + 0x6C)
			end
			if vl_use_fog_color then
				vl_red = math.abs(read_float(sky_tag + 0x58))
				vl_green =  math.abs(read_float(sky_tag + 0x58 + 4))
				vl_blue =  math.abs(read_float(sky_tag + 0x58 + 8))
			end
		end
	end
end

function Get3DVectorFromAngles(alpha,beta)
	local x = cos(alpha) * cos(beta)
	local y = sin(alpha) * cos(beta)
	local z = sin(beta)
	return {x, y, z}
end

-- used for debug console messages only
function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return floor(num * mult + 0.5) / mult
end

function FindSunInScreenSpace(x, y, z, eye_x, eye_y, eye_z, look_x, look_y, look_z, fovy)
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