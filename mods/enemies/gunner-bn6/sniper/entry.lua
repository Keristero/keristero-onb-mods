local shared_package_init = include("../shared/entry.lua")

function package_init(character)
  shared_package_init(character)
  character:set_name("Sniper")

  if character:get_rank() == Rank.V1 then
    character:set_palette(Engine.load_texture(_modpath.."sniper.palette.png"))
    character:set_health(220)
    character.reticle_travel_frames = 10
    character.bullet_damage = 50
    character.break_tile = true
  end
end