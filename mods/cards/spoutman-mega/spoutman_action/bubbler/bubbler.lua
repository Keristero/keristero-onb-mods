local battle_helpers = include('../battle_helpers.lua')

local bubble_texture = Engine.load_texture(_folderpath .. "bubbler_shot.png")
local bubble_animation = _folderpath .. "bubbler_shot.animation"

local impacts_texture = Engine.load_texture(_folderpath .. "../impacts.png")
local impacts_animation = _folderpath .. "../impacts.animation"

local splash_texture = Engine.load_texture(_folderpath .. "splash.png")
local splash_animation = _folderpath .. "splash.animation"

local splash_sound =  Engine.load_audio(_folderpath.."splash_sound.wav")
local shoot_sound =  Engine.load_audio(_folderpath.."bubbler_shoot.ogg")

local bubbler = {}

bubbler.create_aqua_shot = function(player, context,damage)
    local team = player:get_team()
    local spell = Battle.Spell.new(team)
    spell:set_facing(player:get_facing())
    spell:set_texture(bubble_texture)
    local spell_anim = spell:get_animation()
    spell_anim:load(bubble_animation)
    spell_anim:set_state("1")
    spell_anim:refresh(spell:sprite())

    local TOTAL_FRAMES = 15
    local frame_count = 0

    local start_offset_x = -96
    local start_offset_y = -24

    if player:get_facing() == Direction.Left then
        start_offset_x = start_offset_x * -1
    end

    Engine.play_audio(shoot_sound,AudioPriority.High)

    spell:set_offset(start_offset_x, start_offset_y)

    spell.update_func = function()
        if frame_count >= TOTAL_FRAMES then
            if spell:get_tile():is_walkable() then
                create_splash(player,team, context, spell:get_tile(), true,damage)
                create_splash(player,team, context, spell:get_tile(spell:get_facing(), 1),false,damage)
            end

            spell:erase()
            return
        end

        spell:set_offset(
            start_offset_x + frame_count * -start_offset_x / TOTAL_FRAMES,
            start_offset_y + frame_count * -start_offset_y / TOTAL_FRAMES
        )

        frame_count = frame_count + 1
    end

    player:get_field():spawn(spell, player:get_tile(player:get_facing(), 2))
end

function create_splash(player,team, context, tile, break_panel,damage)
    if not tile:is_walkable() then
        return
    end

    local spell = Battle.Spell.new(team)
    spell:set_facing(player:get_facing())
    spell:set_texture(splash_texture)
    local spell_anim = spell:get_animation()
    spell_anim:load(splash_animation)
    spell_anim:set_state("0")
    spell_anim:refresh(spell:sprite())
    spell:sprite():set_layer(-5)

    spell:set_hit_props(
        HitProps.new(
            damage,
            Hit.Impact,
            Element.Aqua,
            context,
            Drag.None
        )
    )

    spell.attack_func = function ()
        battle_helpers.spawn_visual_artifact(spell,tile,impacts_texture,impacts_animation,"1",0,0)
    end

    spell.update_func = function()
        spell:get_tile():attack_entities(spell)
    end

    spell_anim:on_complete(function()
        if tile:is_walkable() and break_panel then
            if tile:get_state() == TileState.Cracked then
                tile:set_state(TileState.Broken)
            else
                tile:set_state(TileState.Cracked)
            end
        end

        spell:erase()
    end)

    Engine.play_audio(splash_sound, AudioPriority.High)
    player:get_field():spawn(spell, tile)
end

return bubbler