local texture = nil
local battle_animation_path = nil
local sword = include("sword/sword.lua")
local guard = include("guard/guard.lua")

local player_info = {
    name="Protomen",
    author="keristero",
    description="Three protomans",
    buster_damage=15,
    charge_buster_damage=300,
    speed=4,
    hp=3000,
    element=Element.Sword,
    height=60,
    charge_buster_glow_y_offset=-20,
    charge_buster_color=Color.new(255,50,0,200)
}

function package_init(package) 
    battle_animation_path = _modpath.."battle.animation"
    battle_texture_path = _modpath.."battle.png"

    package:declare_package_id("com."..player_info.author..".player."..player_info.name)
    package:set_special_description(player_info.description)
    package:set_speed(player_info.speed)
    package:set_attack(player_info.buster_damage)
    package:set_charged_attack(player_info.charge_buster_damage)
    package:set_icon_texture(Engine.load_texture(_modpath.."pet.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_overworld_animation_path(_modpath.."overworld.animation")
    package:set_overworld_texture_path(_modpath.."overworld.png")
    package:set_mugshot_texture_path(_modpath.."mug.png")
    package:set_mugshot_animation_path(_modpath.."mug.animation")
end

function player_init(player)
    player:set_name(player_info.name)
    player:set_health(player_info.hp)
    player:set_element(player_info.element)
    player:set_height(player_info.height)
    player:set_animation(battle_animation_path)
    texture = Engine.load_texture(battle_texture_path)
    player:set_texture(texture, true)
    player:set_fully_charged_color(player_info.charge_buster_color)
    player:set_charge_position(0,player_info.charge_buster_glow_y_offset)
    player.normal_attack_func = create_normal_attack
    player.charged_attack_func = create_charged_attack
    player.special_attack_func = create_special_attack

    player.update_func = function(self, dt) 
        -- nothing in particular
    end
end

function create_normal_attack(player)
    print("buster attack")
    return Battle.Buster.new(player, false, player:get_attack_level())
end

function create_special_attack(player)
    print("execute special")
    local props = Battle.CardProperties:new()
    props.damage = 30+(player:get_attack_level()*10)
    guard.duration = 0.384
    guard.guard_animation = "PROTOGUARD"
    local guard_action = guard.card_create_action(player,props)
    guard_action:set_lockout(make_async_lockout(guard.duration*2))
    return guard_action
end

function create_charged_attack(player)
    print("charged attack")
    local props = Battle.CardProperties:new()
    props.damage = 30+(player:get_attack_level()*20)
    local sword_action = sword.card_create_action(player,props)
    return sword_action
end