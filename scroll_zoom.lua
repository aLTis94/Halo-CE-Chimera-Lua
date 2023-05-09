--Scroll zoom by aLTis. This script allows you to zoom using scroll wheel or by holding the zoom key
-- version 2023-04-24

-- CONFIG
	
	toggle_zoom = true
	auto_key_detection = true -- if true, below value will be ignored and the key will be automatically detected
	toggle_zoom_key = 1 -- 0 - scroll wheel, 1 - right click, 2 - mouse extra button, 3 - mouse extra button2
	toggle_zoom_hold_time = 6 -- how long you need to hold the key for it to toggle (in ticks)
	
-- END OF CONFIG

--CHANGELOG:
-- version 2023-04-23:
--fixed descoping issues when getting damaged
--if you're holding zoom you will stay zoomed in even if you scroll down with the mouse
--added toggle_zoom_hold_time variable
-- version 2023-04-23:
--toggle key is now automatically detected
clua_version = 2.042

set_callback("frame", "OnFrame")
set_callback("tick", "OnTick")

local mouse_input_address = 0x64C73C
local keyboard_input_address = 0x64C550
local zoom_address = read_dword(0x815918) + 204
local zoom_key_profile_address = 0x6AD888
local hold_timer = 0
local control_type = 2 -- 0 - controller?, 1 - keyboard, 2 - mouse

-- Fixes descoping
function OnTick()
	if toggle_zoom == false then return end
	
	local player = get_dynamic_player()
	if player ~= nil then
		local shield_damage_time = read_dword(player + 0xFC)
		local health_damage_time = read_dword(player + 0x100)
		if shield_damage_time == 0 or health_damage_time == 0 then
			if hold_timer > 0 then
				Zoom(0xFFFF)
				hold_timer = 0
			end
		end
	end
end

function OnFrame()
	local player = get_dynamic_player()
	if player ~= nil then
		local weapon = get_object(read_dword(player + 0x118))
		local reloading = read_byte(player + 0x2A4)
		m_player = get_player()
		if m_player ~= nil and weapon ~= nil and reloading ~= 5 then
			local weapon_tag = read_dword(get_tag(read_dword(weapon)) + 0x14)
			local weapon_zoom_levels = read_short(weapon_tag + 0x3DA)
			if weapon_zoom_levels > 0 then
				local scroll = read_char(mouse_input_address + 8)
				local player_zoom_level = read_word(zoom_address)
				local zoom_level_change = 0
				
				if scroll > 0 then
					if player_zoom_level == 0 then
						if toggle_zoom then
							if hold_timer == 0 then
								Zoom(0xFFFF)
							end
						else
							Zoom(0xFFFF)
						end
					elseif player_zoom_level > 0 and player_zoom_level ~= 0xFFFF then
						Zoom(player_zoom_level - 1)
					end
				elseif scroll < 0 then
					if player_zoom_level == 0xFFFF then
						Zoom(0)
					elseif scroll < 0 and player_zoom_level < weapon_zoom_levels - 1 then
						Zoom(player_zoom_level + 1)
					end
				end
				
				player_zoom_level = read_word(zoom_address)
				
				if toggle_zoom then
					
					if auto_key_detection then
						control_type = read_byte(zoom_key_profile_address)
						local zoom_key_profile = read_byte(zoom_key_profile_address + 6) - 1
						if zoom_key_profile >= 0 then
							--if toggle_zoom_key ~= zoom_key_profile then
								--console_out("Key changed to: "..zoom_key_profile)
							--end
							toggle_zoom_key = zoom_key_profile
						else
							return false
						end
					end
					
					local toggle_key = 0
					local toggle_key_release = 0
					
					if control_type == 2 then
						local key_address = mouse_input_address + 13 + toggle_zoom_key
						toggle_key = read_byte(key_address)
						toggle_key_release = read_byte(key_address + 8)
						--console_out(toggle_key)
						--console_out(toggle_key_release)
					elseif control_type == 1 then
						local key_address = keyboard_input_address + 1 + toggle_zoom_key
						toggle_key = read_byte(key_address)
						if toggle_key ~= 0 then
							zoomed_keyboard = 1
						elseif zoomed_keyboard ~= nil then
							toggle_key_release = 1
							zoomed_keyboard = nil
						end
					else
						return false -- controller needs testing
					end
					
					-- set the time when the key was first pressed
					if toggle_key ~= 0 and hold_timer == 0 then
						hold_timer = ticks()
					end
					
					-- if key was released, set how long it was held for
					if toggle_key_release ~= 0 then
						local hold_time = ticks() - hold_timer
						hold_timer = 0
						--console_out("zoomed "..hold_time)
						
						if player_zoom_level ~= 0xFFFF and hold_time > toggle_zoom_hold_time then
							Zoom(0xFFFF)
						end
					end
				end

			end
		end
	end
end

function Zoom(level)
	write_word(zoom_address, level)
	--console_out("zoomed to "..level)
end