nonce = function() end

local debug = true
function debug_print(text)
    if debug then
        print("[guard] " .. text)
    end
end

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = "Vulcan1"
    props.damage = 10
    props.time_freeze = false
    props.element = Element.None
    props.description = "3-shot to pierce 1 panel"

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes({'A',"D","K","*"})
end

function card_create_action(actor,props)
    debug_print("in create_card_action()!")

    local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
	action:set_lockout(make_async_lockout(guard_duration))

    action.execute_func = function(self, user)
    end

    return action
end