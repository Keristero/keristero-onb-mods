local vulcan = include("/vulcan/vulcan.lua")

vulcan.name = "ChaosVlcn"
vulcan.codes = {"C"}
vulcan.damage = 4
vulcan.time_freeze = true
vulcan.can_boost = false
vulcan.description = "??-shot to pierce 1 panel!"
vulcan.card_class = CardClass.Giga

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = vulcan.name
    props.damage = vulcan.damage
    props.time_freeze = vulcan.time_freeze
    props.element = Element.None
    props.description = vulcan.description
    props.can_boost = vulcan.can_boost
    props.card_class = vulcan.card_class

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes(vulcan.codes)
end

function card_create_action(user,props)
    vulcan.hits = math.random(1,99)
    vulcan.shots_animated = vulcan.hits*2
    return vulcan.card_create_action(user,props)
end