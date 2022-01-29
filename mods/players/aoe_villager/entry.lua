local arrow = include('arrow/arrow.lua')
local texture = nil
local battle_animation_path = nil
local special_attack_cooldown_frames = 360
local remaining_special_cooldown = 0

local sounds = {
    move1="move1.ogg",
    move2="move2.ogg",
    move3="move3.ogg",
    move4="move4.ogg",
    attack1="attack1.ogg",
    build="build.ogg",
    spawn="spawn.ogg"
}
local move_sounds = {"move1","move2","move3","move4"}

--load all audio
for key, value in pairs(sounds) do
    sounds[key] = Engine.load_audio(_folderpath..value)
end

local player_info = {
    name = "Villager",
    author = "keristero",
    description = "Rougan?",
    buster_damage = 1,
    charge_buster_damage = 1,
    speed = 1,
    hp = 25,
    element = Element.None,
    height = 40,
    charge_buster_glow_y_offset = -20
}

local played_move_sound = false

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
    player:set_fully_charged_color(Color.new(50, 50, 200, 200))
    player:set_charge_position(0, player_info.charge_buster_glow_y_offset)
    player.normal_attack_func = create_normal_attack
    player.charged_attack_func = create_charged_attack
    player.special_attack_func = create_special_attack
    special_attack_cooldown_frames = 360
    remaining_special_cooldown = 0
    sparkle_component = nil
    player:set_air_shoe(true)

    player.battle_start_func = function ()
        Engine.play_audio(sounds.spawn, AudioPriority.Highest)
    end

    player.update_func = function(self, dt)
        if player:is_moving() then
            if not played_move_sound then
                local sound_name = move_sounds[math.random(1,#move_sounds)]
                Engine.play_audio(sounds[sound_name], AudioPriority.Highest)
                played_move_sound = true
            end
        else
            played_move_sound = false
        end
        if remaining_special_cooldown > 0 then
            remaining_special_cooldown = remaining_special_cooldown - 1
        end
    end
end

function create_normal_attack(player)
    return nil
end

function create_special_attack(player)
    return nil
end

function create_charged_attack(player)
    Engine.play_audio(sounds.attack1,AudioPriority.Highest)
    local props = Battle.CardProperties:new()
    props.damage = 1
    local arrow_action = arrow.card_create_action(player, props)
    return arrow_action
end
