local package_prefix = "keristero"
local character_name = "Mettaur"

--Everything under this comment is standard and does not need to be edited
local character_package_id = "com."..package_prefix..".char."..character_name
local mob_package_id = "com."..package_prefix..".mob."..character_name

function package_requires_scripts()
    -- Note: `requires_character` will throw if unable to find or load
    Engine.define_character(character_package_id, _modpath..character_name)
end

function package_init(package)
    print('package init for '..mob_package_id)
    package:declare_package_id(mob_package_id)
    package:set_name(character_name)
    package:set_description("test fight with a "..character_name)
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob) 
    --can setup backgrounds, music, and field here
    local test_spawner = mob:create_spawner(character_package_id,Rank.V1)
    test_spawner:spawn_at(4, 1)
    test_spawner:spawn_at(5, 2)
    test_spawner:spawn_at(6, 3)
end