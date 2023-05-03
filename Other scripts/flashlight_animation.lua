clua_version = 2.042

flashlight_turn_on_timer = 8

set_callback("tick", "OnTick")

fp_anim_address = 0x40000EB8

flashlight_timer = 0
flashlight_toggle = false

function OnTick()
	local player = get_dynamic_player()
	if player ~= nil then
		local weapon = get_object(read_dword(player + 0x118))
		if weapon ~= nil and GetName(weapon) == "weapons\\assault rifle\\assault rifle" then
			local flashlight_key = read_bit(player + 0x208, 4)
			if flashlight_key == 1 then
				local anim = read_word(fp_anim_address + 30)
				if anim == 1 or anim == 6 or anim == 2 then
					write_word(fp_anim_address + 30, 2)
					write_word(fp_anim_address + 32, 0)
					flashlight_timer = flashlight_turn_on_timer
				--	if flashlight_toggle then
				--		flashlight_toggle = false
				--	else
				--		flashlight_toggle = true
				--	end
				end
			end
			
		--	if flashlight_timer > 0 then
		--		flashlight_timer = flashlight_timer - 1
		--		if flashlight_toggle then
		--			write_float(player + 0x340, -9)
		--		else
		--			write_float(player + 0x340, 1)
		--		end
		--	elseif flashlight_toggle then
		--		write_bit(player + 0x204, 19, 1)
		--		write_float(player + 0x340, 1)
		--	elseif flashlight_toggle == false then
		--		write_bit(player + 0x204, 19, 0)
		--		write_float(player + 0x340, -9)
		--	end
		end
	end
end

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end