local texture = nil
local battle_animation_path = nil
local falling_star = include("falling_star/falling_star.lua")
local sparkley_arrow = include("sparkley_arrow/sparkley_arrow.lua")
local add_sparkle_component = include("sparkle_component/sparkle_component.lua")
local special_attack_cooldown_frames = 360
local remaining_special_cooldown = 0
local sparkle_component = nil

local player_info = {
    name = "Starman",
    author = "keristero",
    description = "He thinks he'd blow our minds",
    buster_damage = 1,
    charge_buster_damage = 150,
    speed = 1,
    hp = 1000,
    element = Element.None,
    height = 66,
    charge_buster_glow_y_offset = -30
}

function package_init(package)
    battle_animation_path = _modpath .. "battle.animation"
    battle_texture_path = _modpath .. "battle.png"

    package:declare_package_id("com." .. player_info.author .. ".player." ..
                                   player_info.name)
    package:set_special_description(player_info.description)
    package:set_speed(player_info.speed)
    package:set_attack(player_info.buster_damage)
    package:set_charged_attack(player_info.charge_buster_damage)
    package:set_icon_texture(Engine.load_texture(_modpath .. "pet.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_overworld_animation_path(_modpath .. "overworld.animation")
    package:set_overworld_texture_path(_modpath .. "overworld.png")
    package:set_mugshot_texture_path(_modpath .. "mug.png")
    package:set_mugshot_animation_path(_modpath .. "mug.animation")
end

function player_init(player)
    player:set_name(player_info.name)
    player:set_health(player_info.hp)
    player:set_element(player_info.element)
    player:set_height(player_info.height)
    player:set_animation(battle_animation_path)
    texture = Engine.load_texture(battle_texture_path)
    player:set_texture(texture, true)
    player:set_fully_charged_color(Color.new(200, 150, 0, 200))
    player:set_charge_position(0, player_info.charge_buster_glow_y_offset)
    player.normal_attack_func = create_normal_attack
    player.charged_attack_func = create_charged_attack
    player.special_attack_func = create_special_attack
    special_attack_cooldown_frames = 360
    remaining_special_cooldown = 0
    sparkle_component = nil
    player:set_air_shoe(true)

    player.update_func = function(self, dt)
        local current_tile = player:get_current_tile()
        if remaining_special_cooldown > 0 then
            remaining_special_cooldown = remaining_special_cooldown - 1
            if sparkle_component ~= nil then 
                sparkle_component:eject()
                sparkle_component = nil
            end
        else
            if sparkle_component == nil then
                sparkle_component = add_sparkle_component(player)
            end
            -- nothing in particular
        end
    end
end

function create_normal_attack(player)
    print("buster attack")
    return Battle.Buster.new(player, false, player:get_attack_level())
end

function create_special_attack(player)
    print("execute special")
    local sparkley_arrow_action = nil
    if remaining_special_cooldown == 0 then
        local props = Battle.CardProperties:new()
        props.damage = player:get_attack_level() * 5
        sparkley_arrow_action = sparkley_arrow.card_create_action(player, props)
        remaining_special_cooldown = special_attack_cooldown_frames
    end
    return sparkley_arrow_action
end

function create_charged_attack(player)
    print("charged attack")
    local props = Battle.CardProperties:new()
    props.damage = 25 + (player:get_attack_level() * 5)
    falling_star.number_of_stars = math.min(3, math.max(1, math.floor((player:get_charge_level() /2) + 1)))
    local falling_star_action = falling_star.card_create_action(player, props)
    return falling_star_action
end
