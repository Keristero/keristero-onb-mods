nonce = function() end

local debug = true
function debug_print(text)
    if debug then
        print("[guard] " .. text)
    end
end

function package_requires()
    Engine.requires_card("com.keristero.card.Guard1")
end

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = "Guard3"
    props.damage = 150
    props.time_freeze = false
    props.element = Element.None
    props.description = "Repels an enemys attack"

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview_"..props.shortname..".png"))
    package:set_codes({'A',"D","K","*"})
end

function card_create_action(actor, props)
    debug_print("in create_card_action()!")

    local reflect_action = Battle.CardAction.from_card("com.keristero.card.Guard1",actor)
    reflect_action:set_metadata(props)
    reflect_action.guard_animation = "GUARD3"
    return reflect_action
    --special properties
end