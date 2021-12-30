local bomb = include('bomb.lua')

bomb.name="MiniBomb"
bomb.damage=50
bomb.element=Element.None
bomb.description = "Throws a MiniBomb 3sq ahead"
bomb.codes = {"B","L","R","*"}

function package_init(package)
    local props = package:get_card_props()
    --standard properties
    props.shortname = bomb.name
    props.damage = bomb.damage
    props.time_freeze = false
    props.element = bomb.element
    props.description = bomb.description

    package:declare_package_id("com.keristero.card."..props.shortname)
    package:set_icon_texture(Engine.load_texture(_modpath .. "icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath .. "preview.png"))
    package:set_codes(bomb.codes)
end

card_create_action = bomb.card_create_action