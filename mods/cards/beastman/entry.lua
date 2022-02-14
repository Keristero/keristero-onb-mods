local battle_helpers = include("battle_helpers.lua")

DAMAGE = 40
TEXTURE = nil
AUDIO = nil

function package_init(package) 
    package:declare_package_id("com.example.card.Beastman")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_codes({'B','E','A','S','T','*'})
    
    local props = package:get_card_props()
    props.shortname = "BeastMan"
    props.damage = DAMAGE
    props.time_freeze = true
    props.element = Element.None
    props.description = "Claw atk 3 squares ahead!"
    props.card_class = CardClass.Mega

    -- assign the global resources
    TEXTURE = Engine.load_texture(_modpath.."beastman.png")
	AUDIO = Engine.load_audio(_modpath.."swipe.ogg")
end

--[[
    1. megaman stunt double warps out
    2. purple in
    3. beast man idle one cycle
    4. beast man roar one cycle
    5. beast man claw one cycle
    6. purple out
    7. beast man is hidden
    8. down_right claw spawned in the same column as the user, row 0
    9. after down_right claw reaches 2nd tile, up_right claw is spawned
        (same col as down_right claw, but row 4)
    10. after up_right claw reaches 2nd tile, head is spawned on the last col, row as user
    11. after all elements are off-screen and deleted, megaman is returned and time freeze ends
--]]
function card_create_action(user, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(user, "PLAYER_IDLE")

    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")

        local step1 = Battle.Step.new()
        local step2 = Battle.Step.new()
        local step3 = Battle.Step.new()
        local step4 = Battle.Step.new()

        self.down_right_claw = nil
        self.up_right_claw   = nil
        self.head            = nil
        self.beastman        = nil
        self.tile            = user:get_current_tile()

        local ref = self
        local actor = self:get_actor()

        step1.update_func = function(self, dt) 
            if ref.beastman == nil then
                ref.beastman = create_beast_intro(actor)
                actor:hide()
                actor:get_field():spawn(ref.beastman, ref.tile:x(), ref.tile:y())
            end

            if ref.beastman:will_erase_eof() then
                self:complete_step()
            end
        end

        step2.update_func = function(self, dt)
            if ref.down_right_claw == nil then
                local dir = Direction.DownRight
                if actor:get_facing() == Direction.Left then 
                    dir = Direction.DownLeft
                end
                local step = {x = 0, y = -3}
                ref.down_right_claw = create_beast_part_artifact("claw_down_right", dir, actor,step.x,step.y)
            end

            if ref.down_right_claw.x_tiles_traveled > 2 then
                self:complete_step()
            elseif user:input_has(Input.Pressed.Use) then 
                local field = actor:get_field()
                local damage_spell = create_spell(user)
                field:spawn(damage_spell, ref.down_right_claw.rounded_tile.x, ref.down_right_claw.rounded_tile.y)
            end
        end

        step3.update_func = function(self, dt) 
            if ref.up_right_claw == nil then
                local dir = Direction.UpRight
                if actor:get_facing() == Direction.Left then 
                    dir = Direction.UpLeft
                end
                local step = {x = 0, y = 3}
                ref.up_right_claw = create_beast_part_artifact("claw_up_right", dir, actor,step.x,step.y)
            end

            if ref.up_right_claw.x_tiles_traveled > 2 then
                self:complete_step()
            elseif user:input_has(Input.Pressed.Use) then 
                local field = actor:get_field()
                local damage_spell = create_spell(user)
                field:spawn(damage_spell, ref.up_right_claw.rounded_tile.x, ref.up_right_claw.rounded_tile.y)
            end
        end

        step4.update_func = function(self, dt) 
            local field_width = actor:get_field():width()
            if ref.head == nil then
                local dir = Direction.Right
                local tile = actor:get_current_tile()

                local x = -tile:x()
                local y = 0

                if actor:get_facing() == Direction.Left then 
                    dir = Direction.Left
                    x = field_width-tile:x()
                end

                ref.head = create_beast_part_artifact("head", dir, actor,x,y)
            end

            if ref.head.x_tiles_traveled > field_width-1 then
                self:complete_step()
            elseif user:input_has(Input.Pressed.Use) then 
                local field = actor:get_field()
                local damage_spell = create_spell(user)
                field:spawn(damage_spell, ref.head.rounded_tile.x, ref.head.rounded_tile.y)
            end
        end

        self:add_step(step1)
        self:add_step(step2)
        self:add_step(step3)
        self:add_step(step4)
    end

    return action
end

function create_beast_intro(user) 
    local fx = Battle.Artifact.new()
    fx:set_texture(TEXTURE, true)
    fx:get_animation():load(_modpath.."beastman.animation")
    fx:get_animation():set_state("INTRO")
    fx:set_facing(user:get_facing())
    fx:get_animation():refresh(fx:sprite())
    fx:get_animation():on_complete(function()
        fx:erase() 
    end)

    return fx
end

function tile_to_screenspace(tile_x,tile_y)
    return {x=math.floor(tile_x*40)*2,y=math.floor(tile_y*25)*2}
end
function screenspace_to_tile(screen_x,screen_y)
    return {x=math.floor(((screen_x/2)/40)+0.5),y=math.floor(((screen_y/2)/25)+0.5)}
end

function create_beast_part_artifact(animation_state,direction,user,offset_tiles_x,offset_tiles_y)
    local visual_artifact = Battle.Artifact.new()
    --visual_artifact:hide()
    visual_artifact:set_texture(TEXTURE,true)
    local anim = visual_artifact:get_animation()
    local sprite = visual_artifact:sprite()
    local field = user:get_field()
    local tile = user:get_current_tile()
    local facing = user:get_facing()
    visual_artifact:set_facing(facing)
    visual_artifact.tile = tile
    anim:load(_modpath.."beastman.animation")
    anim:set_state(animation_state)

    local speed = 0.25
    visual_artifact.end_tile_x_offset = 6
    visual_artifact.x_tiles_traveled = 0
    visual_artifact.offset_tiles_x = offset_tiles_x
    visual_artifact.offset_tiles_y = offset_tiles_y
    print('spawned beast part at relative ',offset_tiles_x,offset_tiles_y)
    local screen_pos = tile_to_screenspace(visual_artifact.offset_tiles_x,visual_artifact.offset_tiles_y)
    visual_artifact.rounded_tile = screenspace_to_tile(screen_pos.x,screen_pos.y)
    visual_artifact.rounded_tile.x = visual_artifact.rounded_tile.x + tile:x()
    visual_artifact.rounded_tile.y = visual_artifact.rounded_tile.y + tile:y()
    visual_artifact:set_offset(screen_pos.x,screen_pos.y)
    anim:refresh(sprite)
    field:spawn(visual_artifact, tile:x(), tile:y())

    visual_artifact.update_func = function ()
        if visual_artifact.x_tiles_traveled > field:width() then
            visual_artifact:erase()
            return
        end
        local direction_vector = Direction.unit_vector(direction)
        visual_artifact.offset_tiles_x = visual_artifact.offset_tiles_x + (direction_vector.x*speed)
        visual_artifact.offset_tiles_y = visual_artifact.offset_tiles_y + (direction_vector.y*speed)
        visual_artifact.virtual_tile_x = tile:x()+visual_artifact.offset_tiles_x
        visual_artifact.virtual_tile_y = tile:y()+visual_artifact.offset_tiles_y
        visual_artifact.x_tiles_traveled = math.abs(offset_tiles_x-visual_artifact.offset_tiles_x)
        local screen_pos = tile_to_screenspace(visual_artifact.offset_tiles_x,visual_artifact.offset_tiles_y)
        visual_artifact:set_offset(screen_pos.x,screen_pos.y)
        local new_rounded_tile = screenspace_to_tile(screen_pos.x,screen_pos.y)
        new_rounded_tile.x = new_rounded_tile.x + tile:x()
        new_rounded_tile.y = new_rounded_tile.y + tile:y()
        if visual_artifact.rounded_tile.x ~= new_rounded_tile.x or visual_artifact.rounded_tile.y ~= new_rounded_tile.y then
            --stop highlighting old tile
            try_highlight_tile(field,visual_artifact.rounded_tile.x,visual_artifact.rounded_tile.y,Highlight.None)
            --drop a hitbox here
            local damage_spell = create_spell(user)
            field:spawn(damage_spell, new_rounded_tile.x, new_rounded_tile.y)
            print('moved to new rounded tile',new_rounded_tile.x,new_rounded_tile.y)
            visual_artifact.rounded_tile = new_rounded_tile
            --highlight new tile
            try_highlight_tile(field,visual_artifact.rounded_tile.x,visual_artifact.rounded_tile.y,Highlight.Solid)
            drop_trace_fx(visual_artifact)
        end
    end
    return visual_artifact
end

function try_highlight_tile(field,x,y,highlight_mode)
    local tile = field:tile_at(x,y)
    if tile then
        tile:highlight(highlight_mode)
    end
end

function create_spell(user)
    local spell = Battle.Spell.new(user:get_team())
    spell:set_hit_props(
        HitProps.new(
            DAMAGE, 
            Hit.Impact | Hit.Flash | Hit.Flinch, 
            Element.None, 
            user:get_id(), 
            Drag.None
        )
    )
    spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)
        print('attacked!')
        self:erase()
    end

    spell.attack_func = function(self, other) 
    end

    spell.delete_func = function(self) 
    end

	Engine.play_audio(AUDIO, AudioPriority.High)

    return spell
end

function drop_trace_fx(target_artifact)
    local fx = Battle.Artifact.new()
    local anim = target_artifact:get_animation()
    local field = target_artifact:get_field()
    fx:set_facing(target_artifact:get_facing())
    fx:set_texture(TEXTURE, true)
    fx:get_animation():copy_from(anim)
    fx:get_animation():set_state(anim:get_state().."_dark")
    fx.lifetime = 255

    local screen_pos = tile_to_screenspace(target_artifact.offset_tiles_x,target_artifact.offset_tiles_y)
    fx:set_offset(screen_pos.x,screen_pos.y)

    fx.update_func = function(self, dt)

        self.lifetime = math.max(0, self.lifetime-math.floor(dt*1000))
        self:set_color(Color.new(0, 0, 0, self.lifetime))

        if self.lifetime == 0 then 
            self:erase()
        end
    end

	local tile = target_artifact:get_current_tile()
    field:spawn(fx, tile:x(), tile:y())
end