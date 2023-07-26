local sword = include("sword_revamp/sword_revamp.lua")

sword.name = "ElecBlade"
sword.description = "Cut 2x1 ahead"
sword.codes = {"S","W","D"}
sword.damage = 120
sword.attack_pattern = {
    {1,2}
}
sword.attack_pattern_center = 4
sword.card_class = CardClass.Standard
sword.element = Element.Elec
sword.cut_animation_state = "LONG"
sword.hit_particle_animation_state = "ELEC"
sword.blade_particle_animation_state = "ELEC"
sword.apply_color_effect = function(node,progress)
    local r = math.floor(230-progress*200)
    local g = math.floor(230-progress*10)
    local b = math.floor(0+progress*255)
    local a = math.floor(255-progress*255)
    local color = Color.new( r, g, b, a )
    node:set_color(color)
end
sword.apply_scale_effect = function(node,original_width,original_height,progress)
    local width = original_width
    local height = original_height*1.2
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