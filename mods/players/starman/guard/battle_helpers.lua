--Functions for easy reuse in scripts
--Version 1.1

battle_helpers = {}

function battle_helpers.spawn_visual_artifact(character,tile,texture,animation_path,animation_state,position_x,position_y,dont_flip_offset)
    local visual_artifact = Battle.Artifact.new()
    --visual_artifact:hide()
    visual_artifact:set_texture(texture,true)
    local anim = visual_artifact:get_animation()
    local sprite = visual_artifact:sprite()
    local field = character:get_field()
    local facing = character:get_facing()
    anim:load(animation_path)
    anim:set_state(animation_state)
    anim:on_complete(function()
        visual_artifact:delete()
    end)
    if facing == Direction.Left and not dont_flip_offset then
        position_x = position_x *-1
    end
    visual_artifact:set_offset(position_x,position_y)
    anim:refresh(sprite)
    field:spawn(visual_artifact, tile:x(), tile:y())
end

return battle_helpers