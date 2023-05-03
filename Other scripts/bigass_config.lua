-- Edit this file to change bigass v3 settings
-- CONFIGURATION

	-- MISC
	key_sprint_hold = true -- you will stop sprinting when you release your sprint key
	switch_fp_hands = true -- marine armors will have different first person hands
	blur_screen_on_join = false -- when you join a server your screen will be blurred for a couple of seconds
	
	-- VISUALS (change these to increase performance)
	use_backpack_weapons = true -- secondary weapon will be visible on player's biped
	use_backpack_aa = true -- armor ability will be visible on player's biped
	backpack_weapon_render_distance = 30 -- after this distance the backpack weapons will disappear
	
	use_refractions = true -- refraction effects for bubble shield and gauss explosions
	use_new_dynamic_reticles = true -- use better dynamic reticles
	binoculars_highlights = true -- adds highlights around players when zoomed in with binoculars
	use_cubemap_switching = false -- some reflections will change based on where you are and time of day (WIP)
	use_ready_anims = true -- when a player readies their weapon, an animation will play
	
	remove_scenery_on_distance = false -- some scenery objects will be removed on distance (WIP)
	remove_scenery_distance = 180 -- scenery will be removed after this distance
	
	map_name = "bigass_mod" -- only needs to include a part of the name
-- END OF CONFIGURATION


clua_version = 2.042

set_callback("map load", "OnMapLoad")

function OnMapLoad()
	set_timer(500, "ChangeSettings")
end

function ChangeSettings()
	if string.find(map, map_name) then
		set_global("settings_changed", true)
		set_global("key_sprint_hold", key_sprint_hold)
		set_global("switch_fp_hands", switch_fp_hands)
		set_global("blur_screen_on_join", blur_screen_on_join)
		set_global("use_backpack_weapons", use_backpack_weapons)
		set_global("backpack_weapon_render_distance", backpack_weapon_render_distance)
		set_global("use_backpack_aa", use_backpack_aa)
		set_global("use_refractions", use_refractions)
		set_global("use_new_dynamic_reticles", use_new_dynamic_reticles)
		set_global("binoculars_highlights", binoculars_highlights)
		set_global("use_cubemap_switching", use_cubemap_switching)
		set_global("use_ready_anims", use_ready_anims)
		set_global("remove_scenery_on_distance", remove_scenery_on_distance)
		set_global("remove_scenery_distance", remove_scenery_distance)
	end
	return false
end

ChangeSettings()
