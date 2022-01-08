local TEXTURE = Engine.load_texture(_folderpath.."thunder.png")
local ANIMATION_PATH = _folderpath.."thunder.animation"
local HIT_TEXTURE = Engine.load_texture(_folderpath.."hit.png")
local HIT_ANIMATION_PATH = _folderpath.."hit.animation"
local THUNDER_SFX = Engine.load_audio(_folderpath.."thunder.ogg")
local HURT_SFX = Engine.load_audio(_folderpath.."hurt.ogg")
local VERTICAL_OFFSET = -30


local thunder = {}

thunder.create_spell = function(character)
  local spell = Battle.Spell.new(character:get_team())

  spell:set_texture(TEXTURE, true)
  spell:highlight_tile(Highlight.Solid)

  local anim = spell:get_animation()
  anim:load(ANIMATION_PATH)
  anim:set_state("DEFAULT")
  anim:set_playback(Playback.Loop)

  -- The origin is the center of the sprite. Raise thunder upwards 15 pixels
  -- (keep in mind scale is 2, e.g. 15 * 2 = 30)
  spell:set_offset(0, VERTICAL_OFFSET)

  Engine.play_audio(THUNDER_SFX, AudioPriority.High)

  spell:set_hit_props(
    HitProps.new(
      40,
      Hit.Flinch | Hit.Stun | Hit.Impact,
      Element.Elec,
      character:get_id(),
      Drag.None
    )
  )

  -- Thunder is removed in roughly 7 seconds
  local timeout = 20 / 3
  local elapsed = 0
  local target = nil

  local field = character:get_field()

  spell.update_func = function(_, dt)
    if elapsed > timeout then
      spell:delete()
    end

    elapsed = elapsed + dt

    local tile = spell:get_current_tile()

    -- Find target if we don't have one
    if not target then
      local closest_dist = math.huge

      field:find_characters(function(character)
        local character_team = character:get_team()

        if (
          character_team == character:get_team() or
          character_team == Team.Other or
          character:will_erase_eof()
        ) then
          return false
        end

        if not target then
          target = character
        else
          -- If the distance to one enemy is shorter than the other, target the shortest enemy path
          local dist = math.abs(tile:x() - character:get_current_tile():x()) + math.abs(tile:y() - character:get_current_tile():y())

          if dist < closest_dist then
            target = character
            closest_dist = dist
          end
        end

        return false
      end)

      -- We have found a target
      -- Create a notifier so we can null the target when they are deleted
      if target then
        local callback = function()
          target = nil
        end

        field:notify_on_delete(target:get_id(), spell:get_id(), callback)
      end
    end

    -- If sliding is flagged to false, we know we've ended a move
    if not spell:is_sliding() then
      -- If there are no targets, aimlessly move right or left
      local direction = character:get_facing()

      if target then
        local target_tile = target:get_current_tile()

        if target_tile then
          if target_tile:x() < tile:x() then
            direction = Direction.Left
          elseif target_tile:x() > tile:x() then
            direction = Direction.Right
          elseif target_tile:y() < tile:y() then
            direction = Direction.Up
          elseif target_tile:y() > tile:y() then
            direction = Direction.Down
          end

          -- Poll if target is flagged for deletion, remove our mark
          if target:will_erase_eof() then
            target = nil
          end
        end
      end

      -- Always slide to the tile we're moving to
      local next_tile = spell:get_tile(direction, 1)
      spell:slide(next_tile, frames(60), frames(0), ActionOrder.Voluntary)
    end

    -- Always affect the tile we're occupying
    tile:attack_entities(spell)
  end

  spell.attack_func = function()
    local artifact = Battle.Artifact.new()
    artifact:sprite():set_layer(-1)
    artifact:set_texture(HIT_TEXTURE, true)
    artifact:set_offset(0, VERTICAL_OFFSET)
    artifact:get_animation():load(HIT_ANIMATION_PATH)
    artifact:get_animation():set_state("DEFAULT")
    artifact:get_animation():on_complete(function()
      artifact:erase()
    end)

    local tile = spell:get_current_tile()
    field:spawn(artifact, tile:x(), tile:y())

    Engine.play_audio(HURT_SFX, AudioPriority.High)

    spell:delete()
  end

  spell.can_move_to_func = function() return true end

  local spawn_tile = character:get_tile(character:get_facing(), 1)
  field:spawn(spell, spawn_tile:x(), spawn_tile:y())
end

thunder.card_create_action = function(character, props)
  local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
  -- action:set_lockout(make_async_lockout(0.67))
  -- action:override_animation_frames(FRAMES)

  action.execute_func = function()
    local buster = action:add_attachment("Buster")
    buster:sprite():set_texture(character:get_texture(), true)
    buster:sprite():set_layer(-1)
    buster:sprite():enable_parent_shader(true)

    local buster_anim = buster:get_animation()
    buster_anim:copy_from(character:get_animation())
    buster_anim:set_state("BUSTER")

    character:get_animation():on_frame(1, function()
      thunder.create_spell(character)
    end, false)
  end

  return action
end

return thunder