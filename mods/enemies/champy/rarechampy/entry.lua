local shared_package_init = include("../shared/entry.lua")

function package_init(character)
  shared_package_init(character)
  character:set_name("RareChampy")
  character:set_palette(Engine.load_texture(_modpath.."rarechampy.palette.png"))
  character:set_health(150)
  character._punch_twice = true
  character._idle_steps_before_return = 1
  character._reveal_time = 3
  character._punch_damage = 30
end
