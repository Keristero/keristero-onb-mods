local battle_helpers = include('../battle_helpers.lua')

local torrent_texture = Engine.load_texture(_folderpath .. "torrent.png")
local torrent_animation = _folderpath .. "torrent.animation"

local impacts_texture = Engine.load_texture(_folderpath .. "../impacts.png")
local impacts_animation = _folderpath .. "../impacts.animation"

local damage_sfx = Engine.load_audio(_folderpath .. "generic_damage.ogg")
local woosh_sfx = Engine.load_audio(_folderpath .. "water_woosh.ogg")

local hydro_pump = {}

hydro_pump.create_torrent = function(actor, damage, distance)
    local team = actor:get_team()
    local facing = actor:get_facing()
    local field = actor:get_field()
    local tile = actor:get_tile()

    local torrent_artifacts = {}
    local spell = Battle.Spell.new(team)
    spell.frames_alive = 0
    spell.target_tiles = {}

    spell:set_hit_props(
        HitProps.new(
            damage,
            Hit.Impact | Hit.Flash,
            Element.Aqua,
            actor:get_context(),
            Drag.None
        )
    )
    
    local create_torrent_artifact = function(torrent_index,is_first)
        local artifact = Battle.Artifact.new()
        artifact:set_facing(facing)
        artifact:set_texture(torrent_texture)
        local tile_width_offset = 80
        if facing == Direction.Left then
            tile_width_offset = -80
        end
        local x_offset = (torrent_index*tile_width_offset)
        artifact:set_offset(x_offset, 0)
        local artifact_anim = artifact:get_animation()
        local artifact_sprite = artifact:sprite()
        artifact_sprite:set_layer(-2)
        artifact_anim:load(torrent_animation)
        if is_first then
            artifact_anim:set_state("TORRENT_START")
        elseif torrent_index == distance then
            artifact_anim:set_state("TORRENT_SPREAD")
            local target_tile = actor:get_tile(facing, distance)
            spell.target_tiles[#spell.target_tiles + 1] = target_tile
            spell.target_tiles[#spell.target_tiles + 1] = target_tile:get_tile(Direction.Up, 1)
            spell.target_tiles[#spell.target_tiles + 1] = target_tile:get_tile(Direction.Down, 1)
        else
            artifact_anim:set_state("TORRENT_BODY")
            spell.target_tiles[#spell.target_tiles + 1] = actor:get_tile(facing,torrent_index)
        end
        artifact_anim:refresh(artifact_sprite)
        artifact_anim:set_playback(Playback.Loop)
        return artifact
    end
    local last_frame_number = 62
    local frames_to_damage_on = {[0] = true, [31] = true, [61] = true}

    spell.update_func = function(self)
        Engine.play_audio(woosh_sfx,AudioPriority.High)
        -- create artifacts for each part of the animation
        local torrent_first_artifact = create_torrent_artifact(0,true)
        torrent_artifacts[#torrent_artifacts + 1] = torrent_first_artifact
        field:spawn(torrent_first_artifact,tile:x(),tile:y())
        for i = 1, distance, 1 do
            local torrent_body_artifact = create_torrent_artifact(#torrent_artifacts)
            torrent_artifacts[#torrent_artifacts + 1] = torrent_body_artifact
            field:spawn(torrent_body_artifact,tile:x(),tile:y())
        end

        spell.update_func = function()
            print(spell.frames_alive)
            for index, tile in ipairs(self.target_tiles) do
                tile:highlight(Highlight.Solid)
                if frames_to_damage_on[spell.frames_alive] then
                    --tile:attack_entities(spell)
                    field:spawn(create_damage_spell(team,spell:copy_hit_props()),tile:x(),tile:y())
                    print('attacking tile',tile:x(),",",tile:y())
                end
            end
            spell.frames_alive = spell.frames_alive + 1
            if spell.frames_alive == last_frame_number then
                for index, artifact in ipairs(torrent_artifacts) do
                    artifact:erase()
                end
                spell:erase()
            end
        end
    end
    return spell
end

function create_damage_spell(team,hitprops)
    local spell = Battle.Spell.new(team)
    spell:set_hit_props(hitprops)
    spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)
        self:erase()
    end
    spell.collision_func = function(self)
        Engine.play_audio(damage_sfx,AudioPriority.High)
        battle_helpers.spawn_visual_artifact(spell, self:get_current_tile(), impacts_texture,impacts_animation, "1", 0, 0)
    end
    return spell
end

return hydro_pump
