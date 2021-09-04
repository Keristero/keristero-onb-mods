local texture = nil

local battle_animation_path = nil
local sfx_charge_buster = nil
local sfx_cannon = nil
local buster_damage = 5
local charge_buster_damage = 50

function package_init(package) 
    battle_animation_path = _modpath.."battle.animation"
    battle_texture_path = _modpath.."battle.png"
    sfx_buster_path = _modpath.."charge_buster.ogg"
    sfx_cannon_path = _modpath.."cannon.ogg"

    package:declare_package_id("com.example.player.Colonel")
    package:set_special_description("Tall cloaked dude!")
    package:set_speed(2.0)
    package:set_attack(buster_damage)
    package:set_charged_attack(charge_buster_damage)
    package:set_icon_texture(Engine.load_texture(_modpath.."pet.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_overworld_animation_path(_modpath.."overworld.animation")
    package:set_overworld_texture_path(_modpath.."overworld.png")
    package:set_mugshot_texture_path(_modpath.."mug.png")
    package:set_mugshot_animation_path(_modpath.."mug.animation")

    sfx_charge_buster = Engine.load_audio(sfx_buster_path)
    sfx_cannon = Engine.load_audio(sfx_cannon_path)
end

function player_init(player)
    player:set_name("Colonel")
    player:set_health(1000)
    player:set_element(Element.Sword)
    player:set_height(55.0)
    player:set_animation(battle_animation_path)
    texture = Engine.load_texture(battle_texture_path)
    player:set_texture(texture, true)
    player:set_fully_charged_color(Color.new(255,0,0,255))

    player.update_func = function(self, dt) 
        -- nothing in particular
    end
end

function create_normal_attack(player)
    print("buster attack")
    return Battle.Buster.new(player, false, buster_damage)
end

function create_charged_attack(player)
    local action = Battle.CardAction.new(player, "PLAYER_SPECIAL")
    action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, player)
        local do_attack = function()
            local direction = player:get_facing()
            local target_tile = target_first_enemy_tile(player,direction,true)
            if target_tile then
                spawn_cross_divide_slash(player,target_tile:x(),target_tile:y(),direction)
            end
        end
        self:add_anim_action(3, do_attack)
    end
    return action
end

function create_special_attack(player)
    print("execute special")
    local action = Battle.CardAction.new(player, "COLONEL_CANNON")
    action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, player)
        local do_attack = function()
            local direction = player:get_facing()
            local hit_back_column = true
            --Spawn a spell which scans for the first enemy in the row then triggers a callback
            local target_tile = target_first_enemy_tile(player,direction,true)
            if target_tile then
                spawn_tank_cannon_shell(player,target_tile:x(),target_tile:y(),direction)
            end
        end
        self:add_anim_action(4, do_attack)
    end
    return action
end

function find_targets_ahead(user)
    local field = user:get_field()
    local user_tile = user:get_current_tile()
    local user_team = user:get_team()
    local list = field:find_characters(function(character)
        return character:get_current_tile():y() == user_tile:y() and character:get_team() ~= user_team
    end)
    return list
end

function target_first_enemy_tile(user,direction,can_hit_back_column)
    local field = user:get_field()
    local user_tile = user:get_current_tile()
    local targets = find_targets_ahead(user)
    if #targets == 0 then
        if can_hit_back_column then
            return field:tile_at(field:width(),user_tile:y())
        end
    elseif #targets == 1 then
        return targets[1]:get_current_tile()
    else
        local closest_x_dist = 10
        for index, character in ipairs(targets) do
            local x_dist = math.abs(character:get_current_tile():x()-user_tile:x())
            if x_dist < closest_x_dist then
                closest_x_dist = x_dist
            end
        end
        print('closest x dist '..closest_x_dist)
        return user:get_tile(direction,closest_x_dist)
    end
    return nil
end

function spawn_tank_cannon_shell(user, x, y, direction)
    local spell = Battle.Spell.new(user:get_team())
    spell:set_texture(texture, true)
    spell:highlight_tile(Highlight.Flash)
    spell:set_hit_props(
        make_hit_props(
            120, 
            Hit.Impact | Hit.Flinch | Hit.Drag, 
            Element.None, 
            user:get_id(), 
            drag(Direction.Right, 3)
        )
    )

    local field = user:get_field()
    --use direct hit / back of field animation
    local anim = spell:get_animation()
    anim:load(battle_animation_path)
    if (x == 0 or x == field:width()) then
        anim:set_state("COLONEL_CANNON_BACK")
        spell:set_position(35,0)
    else
        anim:set_state("COLONEL_CANNON_DIRECT")
    end
    anim:on_complete(function() 
        spell:delete()
    end)

    Engine.play_audio(sfx_cannon, AudioPriority.High)

    spell.tic = 0
    spell.update_func = function(self)
        --Deal damage on first tic
        if spell.tic == 0 then
            local field = user:get_field()
            print('shell hit '..x..', '..y)
            spell:shake_camera(8.0,1.0)
            if (x == 0 or x == field:width()) then
                --If we hit an unoccupied tile at the back of a row
                local above_tile = self:get_tile(Direction.Up,1)
                local main_tile = self:get_current_tile()
                local below_tile = self:get_tile(Direction.Down,1)
                spell.hit_tiles = {above_tile,main_tile,below_tile}
                --Loop over and attack all tiles
                for index, tile in ipairs(spell.hit_tiles) do
                    if tile ~= nil then
                        tile:attack_entities(self)
                    end
                    local is_cracked = tile:is_cracked()
                    local is_hole = tile:is_hole()
                    --crack normal tiles
                    if not is_cracked and not is_hole then
                        tile:set_state(TileState.Cracked)
                    else
                        --break cracked tiles
                        if not is_hole then
                            tile:set_state(TileState.Broken)
                        end
                    end
                end
                spell.tic = spell.tic +1
                return
            end
            print("Cannon shell direct hit")
            local current_tile = self:get_tile(direction,0)
            current_tile:attack_entities(self)
        end
        if spell.tic == 15 then
            --after a short delay
            if spell.hit_tiles then
                local field = user:get_field()
                for index, tile in ipairs(spell.hit_tiles) do
                    if tile ~= nil then
                        if tile:y() > 0 and tile:y() <= field:height() then
                            --create explosions on the tiles
                            local explosion_count = math.random(2,3)
                            local explosion_speed = math.random(10,15)/10
                            local explosion = Battle.Explosion.new(explosion_count, explosion_speed)
                            field:spawn(explosion,tile:x(),tile:y())
                        end
                    end
                end
            end
        end
        spell.tic = spell.tic +1
    end

    spell.attack_func = function(self, other) 
        -- on hit does nothing
    end

    user:get_field():spawn(spell, x, y)
end

function spawn_cross_divide_slash(user, x, y, direction)
    local spell = Battle.Spell.new(user:get_team())
    spell:set_texture(texture, true)
    spell:highlight_tile(Highlight.Flash)
    spell:set_hit_props(
        make_hit_props(
            charge_buster_damage, 
            Hit.Impact | Hit.Flinch, 
            Element.Sword, 
            user:get_id(), 
            drag(Direction.Right, 1)
        )
    )

    local anim = spell:get_animation()
    anim:load(battle_animation_path)
    anim:set_state("SPECIAL_SLASH")
    anim:on_complete(function() 
        spell:delete()
    end)

    Engine.play_audio(sfx_charge_buster, AudioPriority.High)

    spell.tic = 0
    spell.update_func = function(self)
        --Deal damage on first tic
        if spell.tic == 0 then
            local diagonal_1 = Direction.UpLeft
            local diagonal_2 = Direction.DownLeft
            if direction == Direction.Left then
                diagonal_1 = Direction.UpRight
                diagonal_2 = Direction.DownRight
            end
            local current_tile = self:get_tile(direction,0)
            local diag_tile_1 = self:get_tile(diagonal_1,1)
            local diag_tile_2 = self:get_tile(diagonal_2,1)
            current_tile:attack_entities(self)
            if diag_tile_1 ~= nil then
                diag_tile_1:attack_entities(self)
            end
            if diag_tile_2 ~= nil then
                diag_tile_2:attack_entities(self)
            end
        end
        spell.tic = spell.tic +1
    end

    spell.attack_func = function(self, other) 
        -- on hit does nothing
    end

    user:get_field():spawn(spell, x, y)
end