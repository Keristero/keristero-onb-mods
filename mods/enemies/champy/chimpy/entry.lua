local shared_package_init = include("../shared/entry.lua")

function package_init(character)
  shared_package_init(character)
  character:set_name("Chimpy")
  character:set_health(180)
  character:set_palette(Engine.load_texture(_modpath.."chimpy.palette.png"))
  character._punch_twice = true
  character._idle_steps_before_return = 1
  character._reveal_time = 14
  character._punch_damage = 20
end
