local sword = include("sword_revamp/sword_revamp.lua")

sword.name = "WideSword"
sword.description = "Cut 1x3 ahead"
sword.codes = {"S","W","D"}
sword.damage = 80
sword.attack_pattern = {
    {2},
    {1},
    {2}
}
sword.card_class = CardClass.Standard
sword.element = Element.Sword
sword.cut_animation_state = "WIDE"
sword.apply_color_effect = function(node,progress)
    local r = 0
    local g = math.floor(220-progress*150)
    local b = math.floor(200-progress*40)
    local a = math.floor(255-progress*255)
    local color = Color.new( r, g, b, a )
    node:set_color(color)
end
sword.apply_scale_effect = function(node,original_width,original_height,progress)
    local width = original_width*1.2
    local height = original_height
    node:set_width(width)
    node:set_height(height)
end

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = sword.name
    props.damage = sword.damage
    props.time_freeze = sword.time_freeze
    props.element = sword.element
    props.description = sword.description
    props.can_boost = sword.can_boost
    props.card_class = sword.card_class

    package:declare_package_id("com.keristero.card.revamp."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes(sword.codes)
end

card_create_action = sword.card_create_action