local vulcan = include("vulcan/vulcan.lua")

vulcan.name = "SprVulcan"
vulcan.codes = {"V"}
vulcan.damage = 10
vulcan.time_freeze = false
vulcan.can_boost = true
vulcan.description = "12-shot vulcan cannon!"
vulcan.shots_animated = 24
vulcan.hits = 12
vulcan.card_class = CardClass.Mega

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