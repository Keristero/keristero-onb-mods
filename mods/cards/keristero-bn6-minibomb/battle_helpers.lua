--Functions for easy reuse in scripts
--Version 1.0

battle_helpers = {}

function battle_helpers.spawn_visual_artifact(field,tile,texture,animation_path,animation_state,position_x,position_y)
    local visual_artifact = Battle.Artifact.new()
    --visual_artifact:hide()
    visual_artifact:set_texture(texture,true)
    local anim = visual_artifact:get_animation()
    local sprite = visual_artifact:sprite()
    anim:load(animation_path)
    anim:set_state(animation_state)
    anim:on_complete(function()
        visual_artifact:delete()
    end)
    visual_artifact:set_offset(position_x,position_y)
    anim:refresh(sprite)
    field:spawn(visual_artifact, tile:x(), tile:y())
end

function battle_helpers.invisible_projectile(user)
	local spell = Battle.Spell.new(user:get_team())
	local direction = user:get_facing()
    local field_width = user:get_field():width()
    local hit_props = HitProps.new(
        0, 
        Hit.None, 
        Element.None,
        user:get_context(),
        Drag.None
    )
    spell:set_hit_props(hit_props)
	spell.update_func = function(self, dt)
        local current_tile = self:get_current_tile()
        current_tile:attack_entities(self)
        for i = 1, field_width, 1 do
            local tile = self:get_tile(direction,i)
            if tile then
                tile:attack_entities(self)
            end
        end
        self:delete()
    end
	return spell
end

local function run_after(character, frame_count, fn)
    local component = Battle.Component.new(character, Lifetimes.Local)
    component.update_func = function()
      frame_count = frame_count - 1
  
      if frame_count < 0 then
        component:eject()
        fn()
      end
    end
    character:register_component(component)
end

return battle_helpers