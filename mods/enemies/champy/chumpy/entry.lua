local shared_package_init = include("../shared/entry.lua")

function package_init(character)
  shared_package_init(character)
  character:set_name("Chumpy")
  character:set_health(120)
  character:set_palette(Engine.load_texture(_modpath.."chumpy.palette.png"))
  character._reveal_time = 30
  character._punch_damage = 30
end
