--Functions for easy reuse in scripts
--Version 1.0

battle_helpers = {}

function battle_helpers.spawn_visual_artifact(field,tile,texture,animation_path,animation_state,position_x,position_y)
    local visual_artifact = Battle.Artifact.new()
    visual_artifact:set_texture(texture,true)
    local anim = visual_artifact:get_animation()
    anim:load(animation_path)
    anim:set_state(animation_state)
    anim:on_complete(function()
        visual_artifact:delete()
    end)
    visual_artifact:sprite():set_offset(position_x,position_y)
    anim:refresh(visual_artifact:sprite())
    field:spawn(visual_artifact, tile:x(), tile:y())
end

return battle_helpers