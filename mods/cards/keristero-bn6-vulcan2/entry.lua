local vulcan = include("vulcan/vulcan.lua")

vulcan.name = "Vulcan2"
vulcan.codes = {"D","F","L"}
vulcan.damage = 10
vulcan.time_freeze = false
vulcan.can_boost = true
vulcan.description = "5-shot to pierce 1 panel!"
vulcan.shots_animated = 10
vulcan.hits = 5
vulcan.card_class = CardClass.Standard

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

card_create_action = vulcan.card_create_action