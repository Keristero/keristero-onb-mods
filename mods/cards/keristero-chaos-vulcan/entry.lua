nonce = function() end

local debug = true
function debug_print(text)
    if debug then
        print("[vulcan] " .. text)
    end
end

function package_requires()
    Engine.requires_card("com.keristero.card.Vulcan0")
end

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = "CHAOSVLCN"
    props.damage = 2
    props.time_freeze = true
    props.element = Element.None
    props.description = "SHOOT MORE?"
    props.class = CardClass.Mega

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes({'A',"D","K","*"})
end

function card_create_action(actor, props)
    debug_print("in create_card_action()!")

    local card_action = Battle.CardAction.from_card("com.keristero.card.Vulcan0",actor,props)
    card_action.hits = math.random(1,99)
    card_action.shots_animated = card_action.hits*2
    card_action.before_exec(card_action)
    return card_action
    --special properties
end