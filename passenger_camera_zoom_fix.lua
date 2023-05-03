clua_version = 2.042

-- Fixes zooming for passenger seats that have third person cameras

set_callback("tick", "OnTick")

camera_address = 0x647498
first_person = 30400
third_person = 31952
devcam = 30704

function OnTick()
	local player = get_dynamic_player()
	if player ~= nil then
		local camera = read_i16(camera_address)
		local zoom_level = read_u8(player + 0x320)
		local vehicle = read_u32(player + 0x11C)
		if vehicle ~= 0xFFFFFFFF then
			if read_u16(player + 0x2F0) > 0 and zoom_level < 255 then
				if camera == third_person then
					vehicle_camera = 1
				end
				if read_i16(camera_address) ~= devcam then
					write_i16(camera_address, first_person)
				end
			elseif vehicle_camera == 1 and read_i16(camera_address) ~= devcam then
				write_i16(camera_address, third_person)
			end
		else
			vehicle_camera = 0
		end
	else
		vehicle_camera = 0
	end
end
