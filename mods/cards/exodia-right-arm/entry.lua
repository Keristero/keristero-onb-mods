local part_list = {RIGHTLEG=1,LEFTLEG=1,RIGHTARM=1,LEFTARM=1,EXODIA=1}

local fully_assembled = false

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = "RIGHTARM"
    props.damage = 0
    props.time_freeze = false
    props.element = Element.None
    props.description = "A forbidden right arm sealed with magic"
    props.limit = 1

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes({"E"})
end

function card_create_action(user,props)
    return nil
end