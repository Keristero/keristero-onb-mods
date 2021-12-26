local shared_package_init = include("../champy_shared/entry.lua")

function package_init(character)
  shared_package_init(character)
  character:set_name("Champy")

  if character:get_rank() == Rank.V2 then
    character:set_palette(Engine.load_texture(_modpath.."champysp.palette.png"))
    character:set_health(220)
  else
    character:set_palette(Engine.load_texture(_modpath.."champy.palette.png"))
    character:set_health(60)
  end
end
