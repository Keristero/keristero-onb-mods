local package_prefix = "keristero"
local character_name = "RickAstley"

--Everything under this comment is standard and does not need to be edited
local character_package_id = "com."..package_prefix..".char."..character_name
local mob_package_id = "com."..package_prefix..".mob."..character_name

function package_requires_scripts()
    -- Note: `requires_character` will throw if unable to find or load
    Engine.define_character(character_package_id, _modpath.."character")
end

function package_init(package) 
    package:declare_package_id(mob_package_id)
    package:set_name(character_name)
    package:set_description("test fight with a "..character_name)
    package:set_preview_texture_path(_modpath.."preview.png")
    package:set_speed(1)
    package:set_attack(20)
    package:set_health(200)
end

function package_build(mob) 
    mob:stream_music(_modpath.."music.ogg",0,0)
    local texPath = _modpath.."background.png"
    local animPath = _modpath.."background.animation"
    mob:set_background(texPath, animPath, -0.5, 0.0)
    --can setup backgrounds, music, and field here
    local test_spawner = mob:create_spawner(character_package_id,Rank.V1)
    --local loop_start = 1000
    --local loop_end = ((2*60)+56.5)*1000
    test_spawner:spawn_at(5, 2)
    --test_spawner:spawn_at(6, 2)
    --test_spawner:spawn_at(4, 2)
end