local shared_package_init = include("../shared/entry.lua")

function package_init(character)
  shared_package_init(character)
  character:set_name("Gunner")

  if character:get_rank() == Rank.V1 then
    character:set_palette(Engine.load_texture(_modpath.."gunner.palette.png"))
    character:set_health(60)
  elseif character:get_rank() == Rank.SP then
    character:set_palette(Engine.load_texture(_modpath.."gunnersp.palette.png"))
    character:set_health(250)
    character.bullet_damage = 70
  elseif character:get_rank() == Rank.Rare1 then
    character:set_palette(Engine.load_texture(_modpath.."raregunner.palette.png"))
    character:set_health(180)
    character.bullet_damage = 40
  elseif character:get_rank() == Rank.Rare2 then
    character:set_palette(Engine.load_texture(_modpath.."raregunner2.palette.png"))
    character:set_health(250)
    character.bullet_damage = 90
  end
end
