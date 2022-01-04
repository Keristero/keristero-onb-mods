local fully_assembled = false
local part_list = {RIGHTLEG=1,LEFTLEG=1,RIGHTARM=1,LEFTARM=1}
local selected_parts = 0

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = "EXODIA"
    props.damage = 0
    props.time_freeze = false
    props.element = Element.None
    props.description = "Send this then others and win"
    props.limit = 1

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes({"E"})

    package.filter_hand_step = function(in_props, adj_cards) 
        print("filter hand step")
        fully_assembled = false
        while adj_cards:has_card_to_right() and part_list[adj_cards.right_card.shortname] == 1 do
            part_list[adj_cards.right_card.shortname] = 0
            selected_parts = selected_parts + 1
            print("discarded ",adj_cards.right_card.shortname)
            adj_cards:discard_right()
            if selected_parts == 4 then
                fully_assembled = true
                print("fully assembled!")
            end
        end
        print(props.shortname,' assembled pieces = ',selected_parts)
	end
end

function card_create_action(user,props)
    local action = nil
    if fully_assembled then
        print("you win")
        action = Battle.CardAction.new(user, "PLAYER_SHOOTING")
    end
    return action
end