clua_version = 2.042

-- version 1.5

-- CONFIG
	
	local enabled = true -- turns the script off for whatever reason :v
	
	local use_both_controls = true -- this will keep mouse controls while also letting you to control using keyboard
	
	-- These two only work if above is false
	local turn_rate_multiplier = 1
	local turn_amount_multiplier = 1
	
	local cinematic_camera = false
	local cinematic_camera_scale = 1
	
--END OF CONFIG

if use_both_controls then
	turn_rate_multiplier = 1
	turn_amount_multiplier = 1
end

local VEHICLES = nil
local smatch = string.gmatch
local tinsert = table.insert
local rad = math.rad
local abs = math.abs

set_callback("tick", "OnTick")
set_callback("map load", "OnMapLoad")
set_callback("unload", "OnUnload")
set_callback("rcon message", "OnRcon")

local object_table = read_dword(read_dword(0x401192 + 2))
local camera_address = 0x647494
local enable_on_dedi = false

function OnMapLoad()
	VEHICLES = nil
	enable_on_dedi = false
end

function OnUnload()
	local object_count = read_word(object_table + 0x2E)
	if object_count ~= 0 and VEHICLES ~= nil then --IF CHIMERA WAS RELOADED
		for tag, info in pairs (VEHICLES) do
			local turn_rate = read_float(info.tag_data + 0x314)
			if turn_rate == 0 then
				write_float(info.tag_data + 0x314, info.turn_rate)
			end
		end
	end
end

function OnRcon(Message)
	if Message == "You must have keyboard vehicle turning lua script for this to work!|ncFC0303" then
		return false
	else
		-- split the MESSAGE string into words
		MESSAGE = {}
		for word in smatch(Message, "([^".."~".."]+)") do 
			tinsert(MESSAGE, word)
		end
		
		if MESSAGE[1] == "Turning" then
			turn_rate_multiplier = tonumber(MESSAGE[2])
			turn_amount_multiplier = tonumber(MESSAGE[3])
			use_both_controls = false
			OnUnload()
			VEHICLES = nil
			hud_message("Keyboard vehicle turning enabled!")
			enable_on_dedi = true
			return false
		end
	end
	
	return true
end

function OnTick()
	if (server_type == "dedicated" or enabled == false) and enable_on_dedi == false then 
		return
	end
	
	if VEHICLES == nil then
		VEHICLES = {}
		FindVehiTags()
	end
	
	local m_unit = get_dynamic_player()
	if m_unit ~= nil then
		local vehicle = get_object(read_dword(m_unit + 0x11C))
		if vehicle ~= nil then
			local tag_id = read_dword(vehicle)
			if VEHICLES[tag_id] ~= nil then
				local forward = read_float(vehicle + 0x278)
				local left = read_float(vehicle + 0x27C)
				local turn = read_float(vehicle + 0x4DC)
				left = left + left*abs(forward)/2 -- makes it more consistant when driving forwards or backwards
				
				local turn_rate = rad(VEHICLES[tag_id].turn_rate)/30*turn_rate_multiplier
				
				if left ~= 0 then
					turn = turn + left*turn_rate
				elseif turn > 0 then
					turn = turn - turn_rate
					if turn < 0 then
						turn = 0
					end
				elseif turn < 0 then
					turn = turn + turn_rate
					if turn > 0 then
						turn = 0
					end
				end
				
				if turn < -VEHICLES[tag_id].max_turn then
					turn = -VEHICLES[tag_id].max_turn
				elseif turn > VEHICLES[tag_id].max_turn then
					turn = VEHICLES[tag_id].max_turn
				end
				
				if left ~= 0 or use_both_controls == false then
					write_float(VEHICLES[tag_id].tag_data + 0x314, 0)
					write_float(vehicle + 0x4DC, turn)
				else
					
					write_float(VEHICLES[tag_id].tag_data + 0x314, VEHICLES[tag_id].turn_rate)
				end
				
				if cinematic_camera then
					write_float(camera_address, cinematic_camera_scale)
				end
			end
		end
	end
end
	
function FindVehiTags()
	local tag_array = read_dword(0x40440000)
    local tag_count = read_word(0x4044000C)
    for i=0,tag_count-1 do
        local tag = tag_array + i * 0x20
		local tag_class = read_dword(tag)
		if tag_class == 0x76656869 then
			local tag_id = read_dword(tag + 0xC)
			if VEHICLES[tag_id] == nil then
				local tag_data = read_dword(tag + 0x14)
				local vehicle_type = read_byte(tag_data + 0x2F4)
				if vehicle_type == 0 or vehicle_type == 1 then
					local turn_rate = read_float(tag_data + 0x314)
					local max_turn = read_float(tag_data + 0x308)
					if turn_rate == 0 then
						turn_rate = 90
					end
					if max_turn == 0 then
						max_turn = 8
					end
					VEHICLES[tag_id] = {}
					VEHICLES[tag_id].max_turn = rad(max_turn)*turn_amount_multiplier
					VEHICLES[tag_id].turn_rate = turn_rate
					VEHICLES[tag_id].tag_data = tag_data
					write_float(tag_data + 0x314, 0)
				end
			end
		end
	end
	return nil
end

function ClearConsole()
	for j=0,25 do
		console_out(" ")
	end
end