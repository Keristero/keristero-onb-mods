local battle_helpers = include("battle_helpers.lua")

local debug = true
local attachment_texture = Engine.load_texture(_modpath .. "attachment.png")
local attachment_animation_path = _modpath .. "attachment.animation"
local vulcan_impact_texture = Engine.load_texture(_modpath .. "vulcan_impact.png")
local vulcan_impact_animation_path = _modpath .. "vulcan_impact.animation"
local bullet_hit_texture = Engine.load_texture(_modpath .. "bullet_hit.png")
local bullet_hit_animation_path = _modpath .. "bullet_hit.animation"
local gun_sfx = Engine.load_audio(_modpath .. "gun.ogg")


function debug_print(text)
    if debug then
        print("[vulcan] " .. text)
    end
end

local vulcan_details = {
    name="ChaosVlcn",
    description="??-shot to pierce 1 panel!",
    codes={"C"},
    damage=4,
    time_freeze=true,
    can_boost=false,
    card_class=CardClass.Giga
}
local vulcan = include("vulcan.lua")

vulcan.name = "ChaosVlcn"
vulcan.codes = {"C"}
vulcan.damage = 4
vulcan.time_freeze = true
vulcan.can_boost = false
vulcan.description = "??-shot to pierce 1 panel!"
vulcan.card_class = CardClass.Giga

function package_init(package)
    math.randomseed(Engine.get_rand_seed())
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

function card_create_action(actor,props)
    vulcan.hits = math.random(1,99)
    vulcan.shots_animated = vulcan.hits*2
    return vulcan.card_create_action(actor,props)
end