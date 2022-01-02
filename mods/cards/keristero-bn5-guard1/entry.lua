local guard = include("/guard/guard.lua")

--variables that change for each version of the card
guard.name = "Guard1"
guard.codes = {'A',"D","K","*"}
guard.damage = 50
guard.duration = 1.024
guard.guard_animation = "GUARD1"

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = guard.name
    props.damage = guard.damage
    props.time_freeze = false
    props.element = Element.None
    props.description = guard.description

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes(guard.codes)
end

card_create_action = guard.card_create_action