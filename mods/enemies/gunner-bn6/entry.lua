local package_prefix = "keristero"
local package_name = "Gunner"

--Everything under this comment is standard and does not need to be edited
local character_package_prefix = "com."..package_prefix..".char."
local mob_package_id = "com."..package_prefix..".mob."..package_name

function define_package(name)
    local id = character_package_prefix..name
    Engine.define_character(id, _modpath..name)
end

function get_package(name) 
    return character_package_prefix..name
end

function package_requires_scripts()
    define_package("Gunner")
    define_package("Shooter")
    define_package("Sniper")
end

function package_init(package) 
    print('package init for '..mob_package_id)
    package:declare_package_id(mob_package_id)
    package:set_name(package_name)
    package:set_description("test fight with a "..package_name)
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob) 
    --can setup backgrounds, music, and field here
    local test_spawner = mob:create_spawner(get_package("Gunner"),Rank.V1)
    local test_spawner2 = mob:create_spawner(get_package("Shooter"),Rank.V1)
    local test_spawner3 = mob:create_spawner(get_package("Sniper"),Rank.V1)
    test_spawner:spawn_at(4, 1)
    test_spawner2:spawn_at(5, 2)
    test_spawner3:spawn_at(6, 3)
end