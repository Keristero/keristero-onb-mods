local debug = true
local attachment_texture = Engine.load_texture(_modpath .. "attachment.png")
local attachment_animation_path = _modpath .. "attachment.animation"
local explosion_texture = Engine.load_texture(_modpath .. "explosion.png")
local explosion_sfx = Engine.load_audio(_modpath .. "explosion.ogg")
local explosion_animation_path = _modpath .. "explosion.animation"
local throw_sfx = Engine.load_audio(_modpath .. "toss_item.ogg")

function debug_print(text)
    if debug then
        print("[minibomb] " .. text)
    end
end

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = "MiniBomb"
    props.damage = 50
    props.time_freeze = false
    props.element = Element.None
    props.description = "Throws a MiniBomb 3sq ahead"

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes({"B","L","R","*"})
end

function card_create_action(actor,props)
    local action = Battle.CardAction.new(actor, "PLAYER_THROW")
	action:set_lockout(make_animation_lockout())
    local override_frames = {{1,0.064},{2,0.064},{3,0.064},{4,0.064},{5,0.064}}
    local frame_data = make_frame_data(override_frames)
    action:override_animation_frames(frame_data)

    local hit_props = HitProps.new(
        props.damage,
        Hit.Impact | Hit.Flinch | Hit.Flash, 
        props.element,
        actor:get_context(),
        Drag.None
    )

    action.execute_func = function(self, user)
        --local props = self:copy_metadata()
        local attachment = self:add_attachment("HAND")
        local attachment_sprite = attachment:sprite()
        attachment_sprite:set_texture(attachment_texture)
        attachment_sprite:set_layer(-2)
        --attachment_sprite:enable_parent_shader(true)

        local attachment_animation = attachment:get_animation()
        attachment_animation:load(attachment_animation_path)
        attachment_animation:set_state("DEFAULT")

        self:add_anim_action(3,function()
            attachment_sprite:hide()
            --self.remove_attachment(attachment)
            local tiles_ahead = 3
            local frames_in_air = 40
            local toss_height = 70
            local facing = user:get_facing()
            local target_tile = user:get_tile(facing,tiles_ahead)
            action.on_landing = function ()
                hit_explosion(user,target_tile,hit_props,explosion_texture,explosion_animation_path,explosion_sfx)
            end
            toss_spell(user,toss_height,attachment_texture,attachment_animation_path,target_tile,frames_in_air,action.on_landing)
		end)

        Engine.play_audio(throw_sfx, AudioPriority.Highest)
    end
    return action
end

function toss_spell(tosser,toss_height,texture,animation_path,target_tile,frames_in_air,arrival_callback)
    local starting_height = -110
    local start_tile = tosser:get_current_tile()
    local field = tosser:get_field()
    local spell = Battle.Spell.new(tosser:get_team())
    local spell_animation = spell:get_animation()
    spell_animation:load(animation_path)
    spell_animation:set_state("DEFAULT")
    if tosser:get_height() > 1 then
        starting_height = -(tosser:get_height()+40)
    end

    spell.jump_started = false
    spell.starting_y_offset = starting_height
    spell.starting_x_offset = 10
    spell.y_offset = spell.starting_y_offset
    spell.x_offset = spell.starting_x_offset
    local sprite = spell:sprite()
    sprite:set_texture(texture)
    spell:set_offset(spell.x_offset,spell.y_offset)

    spell.update_func = function(self)
        if not spell.jump_started then
            self:jump(target_tile, toss_height, frames(frames_in_air), frames(frames_in_air), ActionOrder.Voluntary)
            self.jump_started = true
        end
        if self.y_offset < 0 then
            self.y_offset = self.y_offset + math.abs(self.starting_y_offset/frames_in_air)
            self.x_offset = self.x_offset - math.abs(self.starting_x_offset/frames_in_air)
            self:set_offset(self.x_offset,self.y_offset)
        else
            arrival_callback()
            self:delete()
        end
    end
    spell.can_move_to_func = function(tile)
        return true
    end
    field:spawn(spell, start_tile)
end

function hit_explosion(user,target_tile,props,texture,anim_path,explosion_sound)
    local field = user:get_field()
    local spell = Battle.Spell.new(user:get_team())

    local spell_animation = spell:get_animation()
    spell_animation:load(anim_path)
    spell_animation:set_state("DEFAULT")
    local sprite = spell:sprite()
    sprite:set_texture(texture)
    spell_animation:refresh(sprite)

    spell_animation:on_complete(function()
		spell:erase()
	end)

    spell:set_hit_props(props)
    spell.has_attacked = false
    spell.update_func = function(self)
        if not spell.has_attacked then
            Engine.play_audio(explosion_sound, AudioPriority.Highest)
            spell:get_current_tile():attack_entities(self)
            spell.has_attacked = true
        end
    end
    field:spawn(spell, target_tile)
end