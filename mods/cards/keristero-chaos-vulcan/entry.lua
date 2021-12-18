function package_requires()
    Engine.requires_card("com.keristero.card.Vulcan1")
end

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = "ChaosVlcn"
    props.damage = 2
    props.time_freeze = true
    props.element = Element.None
    props.description = "I fear the man who shoots one gun x times"
    props.class = CardClass.Mega
    props.boostable = false

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes({'A',"D","K","*"})
    math.randomseed(Engine.get_rand_seed())
end

function card_create_action(actor, props)
    local card_action = Battle.CardAction.from_card("com.keristero.card.Vulcan1",actor,props)
    card_action.hits = math.random(1,99)
    card_action.shots_animated = card_action.hits*2
    card_action.before_exec(card_action)
    return card_action
    --special properties
end