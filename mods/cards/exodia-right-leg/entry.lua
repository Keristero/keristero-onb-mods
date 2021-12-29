function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = "RIGHT LEG"
    props.damage = 0
    props.time_freeze = false
    props.element = Element.None
    props.description = "RIGHT LEG OF THE FORBIDDEN ONE"

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes({"E"})
end

function card_create_action(actor,props)
    return nil
end