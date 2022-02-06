local shared_package_init = include("../shared/entry.lua")

function package_init(character)
  shared_package_init(character)
  character:set_name("Sniper")

  if character:get_rank() == Rank.V1 then
    character:set_palette(Engine.load_texture(_modpath.."sniper.palette.png"))
    character:set_health(220)
    character.reticle_travel_frames = 10
  elseif character:get_rank() == Rank.SP then
    character:set_palette(Engine.load_texture(_modpath.."snipersp.palette.png"))
    character:set_health(400)
    character.reticle_travel_frames = 5
  end
end