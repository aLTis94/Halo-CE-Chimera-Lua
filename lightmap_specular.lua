-- Lightmap Specular script by aLTis. Version 1.0.1

-- This enables "lightmap is specular" shader feature. KEEP IN MIND THIS FEATURE BREAKS WHEN DYNAMIC LIGHTS ARE USED!!!
-- This script only exists to show off what this feature does and should not be used for normal gameplay. You can use it for nice photos I guess.

--CONFIG
	
	enable_script = true -- enables the script automatically
	force_white_specular = false -- changes all specular color to white
	
	-- Change these to adjust specular based on material (you can set values above 1 to make them very bright)
	use_custom_brightness = true
	SPECULAR_BRIGHTNESS = {
		[0] = 0.1, --Dirt
		[1] = 0.1, --Sand
		[2] = 0.2, --Stone
		[3] = 0.75, --Snow
		[4] = 0.15, --Wood
		[5] = 1, --Metal (hollow)
		[6] = 1, --Metal (thin)
		[7] = 1, --Metal (thick)
		[8] = 0.25, --Rubber
		[9] = 1, --Glass
		[27] = 0.2, --Plastic
		[31] = 1, --Ice
	}
	
	disable_specular_dynamic_lights = true -- flashlight and gunshots will not have specular lighting
	
	hotkey = 53 -- L by default
	
--Keyboard keys reference:
--17="1", 18="2", 19="3", 20="4", 2="5", 22="6", 23="7", 24="8", 25="9", 26="10", 27="Minus", 28="Equal", 30="Tab", 31="Q", 32="W", 33="E", 34="R", 35="T", 36="Y", 37="U", 38="I", 39="O", 40="P", 43="Backslash",
--44="Caps Lock", 45="A", 46="S", 47="D", 48="F", 49="G", 50="H", 51="J", 52="K", 53="L", 56="Enter", 57="Shift", 58="Z", 59="X", 60="C", 61="V", 62="B", 63="N", 64="M", 69="Ctrl",71="Alt",72="Space",
	
--END OF CONFIG

clua_version = 2.042

set_callback("precamera", "OnCamera")
if enable_script then
	set_callback("map load", "OnMapLoad")
end

local toggle = false
local keyboard_input_address = 0x64C550

function WriteColor(address, red, green, blue)
	write_float(address, red)
	write_float(address+4, green)
	write_float(address+8, blue)
end

function IsColorBlack(address)
	if read_float(address) == 0 and read_float(address+4) == 0 and read_float(address+8) == 0 then
		return true
	else
		return false
	end
end

function ToggleSpecular(enable)
	toggle = enable
	local tag_count = read_dword(0x4044000C)
	
    for i = 0,tag_count - 1 do
        local tag = get_tag(i)
		local tag_class = read_dword(tag)
		
		if tag_class == 0x73656E76 then
			local tag_data = read_dword(tag + 0x14)
			--local normal = read_dword(tag_data + 0x128)
			write_bit(tag_data + 0x27C, 2, enable)
			
			if use_custom_brightness then
				local material = read_word(tag_data + 0x22)
				local current_brightness = read_float(tag_data + 0x290)
				if SPECULAR_BRIGHTNESS[material] and SPECULAR_BRIGHTNESS[material] > current_brightness and read_dword(tag_data + 0x128 + 0xC) ~= 0xFFFFFFFF then
					write_float(tag_data + 0x290, SPECULAR_BRIGHTNESS[material])
				end
			end
			
			if force_white_specular then
				WriteColor(tag_data + 0x2A8, 1, 1, 1)
				WriteColor(tag_data + 0x2B4, 1, 1, 1)
			elseif IsColorBlack(tag_data + 0x2A8) and read_dword(tag_data + 0x128 + 0xC) ~= 0xFFFFFFFF then
				WriteColor(tag_data + 0x2A8, 1, 1, 1)
			end
		elseif disable_specular_dynamic_lights and tag_class == 0x6C696768 then
			local tag_data = read_dword(tag + 0x14)
			write_bit(tag_data, 1, 1)
		end
	end
end

ToggleSpecular(enable_script)

function OnMapLoad()
	ToggleSpecular(true)
end

function OnCamera()
	-- HOTKEYS
	local chat_is_open = read_byte(0x0064E788)
	if chat_is_open == 0 and console_is_open() == false then
		if read_byte(keyboard_input_address + hotkey) == 1 then
			if toggle then
				ToggleSpecular(false)
			else
				ToggleSpecular(true)
			end
		end
	end
end