local shared_package_init = include("../shared/entry.lua")

function package_init(character)
  shared_package_init(character)
  character:set_name("Shooter")

  if character:get_rank() == Rank.V1 then
    character:set_palette(Engine.load_texture(_modpath.."shooter.palette.png"))
    character.sweeping_reticle = true
    character.reticle_travel_frames = 30
    character.shots = 5
    character:set_health(140)
  end
end
