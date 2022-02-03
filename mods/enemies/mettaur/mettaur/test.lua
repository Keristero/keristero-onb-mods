function package_init(package)
    package:declare_package_id("Perma toad soul.player")
    package:set_special_description("perma toad soul")
    package:set_speed(1.0)
    package:set_attack(1)
    package:set_charged_attack(10)
    package:set_icon_texture(Engine.load_texture(_folderpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_folderpath.."preview.png"))
    package:set_overworld_animation_path(_folderpath.."overworld.animation")
    package:set_overworld_texture_path(_folderpath.."overworld.png")
    package:set_mugshot_texture_path(_folderpath.."mug.png")
    package:set_mugshot_animation_path(_folderpath.."mug.animation")
end

function player_init(player)
    player:set_name("Toad Soul")
    player:set_health(1000)
    player:set_element(Element.Aqua)
    player:set_height(38.0)
    local base_texture = Engine.load_texture(_folderpath.."battle.png")
    local base_animation_path = _folderpath.."battle.animation"
    local base_charge_color = Color.new(57, 198, 243, 255)
    player:set_animation(base_animation_path)
    player:set_texture(base_texture)
    player:set_fully_charged_color(base_charge_color)
    player:set_charge_position(0, -20)

    local submerge = Battle.DefenseRule.new(0, DefenseOrder.Always)
    player.am_moist = 0

    submerge.determine_if_dive(player)
        local submerge = Battle.DefenseRule.new(0, DefenseOrder.Always)
            player.am_moist= false
            submerge.can_block_func = function(judge, attacker)

                if not player.am_moist then
                return
            end
            local hitprops = attacker:copy_hit_props()

             if hitprops.element == Element.Elec then
                    judge:signal_defense_was_pierced()
                return
             end

    end

    player.update_func = function()
             -- if on the designated panel type
             if player:get_current_tile():get_state() == TileState.Ice
                then
                player.am_moist = true

            else
                 player.am_moist = false
            end

    end

    player:add_defense_rule(submerge)

            player.update_func = function()
                if player.am_moist then
                    player.dive_active = true
                end
            end
        end
    end

    submerge.do_dive_action = function(player)
        if player.dive_active then
            judge:block_impact()
            judge:block_damage()
        end
    end


    player.normal_attack_func = function()
        return Battle.Buster.new(player, false, player:get_attack_level())
    end


    player.charged_attack_func = function(player)
        return special_card_action(player)
    end

    function special_card_action(user)
        local action = Battle.CardAction.new(user,"PLAYER_SHOOTING")
        action:set_lockout(make_animation_lockout())
        action.execute_func = function(self, user)
            local buster = self:add_attachment("Buster")

            buster:sprite():set_texture(base_texture)
            buster:sprite():set_layer(-1)

            local buster_anim = buster:get_animation()
            buster_anim:load(_modpath.."battle.animation")
            buster_anim:set_state("Buster")


            local do_attack = function()
                --get the tile you want to initially spawn the spell on.
                local t1 = (user:get_tile(user:get_facing(),1))
                --setup a search query to find beings who exist, aren't deleted, and aren't on the same team as the user.
                local target_query = function(ent)
                    return ent ~= nil and not ent:is_deleted() and not ent:is_team(user:get_team())
                end
                --search the field for all targets matching that query,
                local target_search = user:get_field():find_characters(target_query)
                --and set the target to be sent to nil. We may not find anything.
                local target = nil
                --set an absurd distance so that the first target found is guaranteed to be matched.
                local distance = 999
                --if the target search returns characters, loop over the list and check the distance between the X value of the spell's intended tile,
                --and the X value of the found target's tile. If it's less than distance, which the first one will be, set the target variable to that
                --character and set the distance to the calculated difference in X values.
                if #target_search > 0 then
                    for i = 1, #target_search, 1 do
                        local search_entry = target_search[i]
                        if math.abs(search_entry:get_tile():x() - t1:x()) < distance then
                            target = search_entry
                            distance = math.abs(search_entry:get_tile():x() - t1:x())
                        end
                    end
                end
                --spawn the attack with the following inputs: user of the attack, the direction they're facing (for initial tracking),
                --the opposite of the way they're facing (for resetting the direction of the projectile), the tile, and the target, which may be ni.
                spawn_attack(user, user:get_facing(), user:get_facing_away(), t1, target)
            end
            self:add_anim_action(2, do_attack)
        end
        return action
    end

    function spawn_attack(user, track_direction, direction, t1, target)
        local spawn_next
        spawn_next = function()
            local spell = Battle.Spell.new(user:get_team())
            spell:set_facing(direction)

            spell:set_hit_props(
                HitProps.new(
                    (player:get_attack_level() * 10) + 20,
                    Hit.Flinch | Hit.Stun | Hit.Impact,
                    Element.Elec,
                    user:get_context(),
                    Drag.None
                )
            )
            --make sure the spell can move to any tile.
            spell.can_move_to_func = function()
                return true
            end
            --attack entities on spell update every frame
            spell.update_func = function(self, dt)
                self:get_tile():attack_entities(self)
            end

            local animation = spell:get_animation()
            spell:set_texture(base_texture)
            spell:get_animation():load(_modpath.."battle.animation" )
            spell:get_animation():set_state("PLAYER_SPECIAL_CS")
            animation:on_frame(3,function()
                --Here comes the fun part. The tracking. If the target is NOT nil,
                --then we update the input track_direction based on whether or not
                --that target's Y coordinate is above or below the spell's current tile,
                --represented as t1.
                
                --If it's on the same row, the direction is reset.
                if target ~= nil then
                    if track_direction == Direction.Right then
                        if target:get_tile():y() < t1:y() then
                            track_direction = Direction.UpRight
                        elseif target:get_tile():y() > t1:y() then
                            track_direction = Direction.DownRight
                        end
                    elseif track_direction == Direction.Left then
                        if target:get_tile():y() < t1:y() then
                            track_direction = Direction.UpLeft
                        elseif target:get_tile():y() > t1:y() then
                            track_direction = Direction.DownLeft
                        end
                    end
                end
                --set t1 to equal the tile in the direction we picked, and
                t1 = t1:get_tile(track_direction, 1)
                --reset the track direction, and
                track_direction = Direction.reverse(direction)
                --spawn that damn spell. repeat until done.
                spawn_next()
            end)
            animation:on_complete(function() if not spell:is_deleted() then spell:erase() end end)

            spell.collision_func = function(self)
                self:erase()
            end

            user:get_field():spawn(spell, t1)
        end
        spawn_next()
    end
end