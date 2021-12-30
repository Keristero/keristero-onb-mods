local guard = include("guard.lua")

--variables that change for each version of the card
guard.name = "Guard3"
guard.codes = {'C',"M","S","*"}
guard.damage = 150
guard.duration = 1.024
guard.guard_animation = "GUARD3"

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
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview_"..props.shortname..".png"))
    package:set_codes(guard.codes)
end

card_create_action = guard.card_create_action