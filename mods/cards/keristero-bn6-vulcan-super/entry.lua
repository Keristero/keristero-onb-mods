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
    props.shortname = "SprVulcan"
    props.damage = 10
    props.time_freeze = false
    props.element = Element.None
    props.description = "12-shot vulcan cannon!"
    props.class = CardClass.Mega

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes({"V"})
end

function card_create_action(actor, props)
    debug_print("in create_card_action()!")

    local card_action = Battle.CardAction.from_card("com.keristero.card.Vulcan0",actor,props)
    card_action.shots_animated = 24
    card_action.hits = 12
    card_action.before_exec(card_action)
    return card_action
    --special properties
end