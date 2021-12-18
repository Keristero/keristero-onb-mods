function package_requires()
    Engine.requires_card("com.keristero.card.Vulcan1")
end

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = "Vulcan3"
    props.damage = 10
    props.time_freeze = false
    props.element = Element.None
    props.description = "7-shot to pierce 1 panel!"

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes({"A","G","R"})
end

function card_create_action(actor, props)
    local card_action = Battle.CardAction.from_card("com.keristero.card.Vulcan1",actor,props)
    card_action.shots_animated = 13
    card_action.hits = 7
    card_action.before_exec(card_action)
    return card_action
end