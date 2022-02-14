local spoutman_action = include("spoutman_action/spoutman_action.lua")

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = spoutman_action.name
    props.damage = spoutman_action.damage
    props.time_freeze = spoutman_action.time_freeze
    props.element = Element.None
    props.description = spoutman_action.description
    props.can_boost = spoutman_action.can_boost
    props.card_class = spoutman_action.card_class

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes(spoutman_action.codes)
end

card_create_action = spoutman_action.card_create_action