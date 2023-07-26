local sword = include("sword_revamp/sword_revamp.lua")
local battle_helpers = include("sword_revamp/battle_helpers.lua")

sword.name = "HeroSwrd"
sword.description = "Cut 3x1 ahead"
sword.codes = {"H","E","R"}
sword.damage = 200
sword.attack_pattern = {
    {1,2,2}
}
sword.attack_pattern_center = 4
sword.card_class = CardClass.Mega
sword.element = Element.Sword
sword.cut_animation_state = "VERYLONG"
sword.hit_particle_animation_state = "LARGE_BLUE"
sword.cut_afterimages = {{5,-10,0}}--{{lifetime_frames,velocity_x,velocity_y},...}
sword.blade_particle_animation_state = "ELEC"
sword.particle_update = function(particle,progress)
    local r = math.floor(0)
    local g = math.floor(255)
    local b = math.floor(255)
    local a = math.floor(255)
    local color = Color.new( r, g, b, a )
    particle:set_color(color)
    local offset = particle:get_offset()
    battle_helpers.update_offset(particle,offset.x+4,offset.y-2)
end
sword.apply_color_effect = function(node,progress)
    local r = math.floor(0+-progress*255)
    local g = math.floor(240-progress*200)
    local b = math.floor(255)
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
sword.afterimage_update = function(afterimage,progress,x_vel,y_vel)
    local r = 255
    local g = 0
    local b = 255
    local a = math.floor(100-progress*100)
    local color = Color.new( r, g, b, a )
    local offset = afterimage:get_offset()
    battle_helpers.update_offset(afterimage,offset.x+x_vel,offset.y+y_vel)
    afterimage:set_color(color)
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