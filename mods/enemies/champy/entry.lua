local package_prefix = "keristero"
local package_name = "Champy"

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
    define_package("Champy")
    define_package("Chimpy")
    define_package("Chumpy")
    define_package("RareChampy")
end

function package_init(package) 
    print('package init for '..mob_package_id)
    package:declare_package_id(mob_package_id)
    package:set_name(package_name)
    package:set_description("BN5 accurate "..package_name.." with BN6 forms")
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob) 
    --can setup backgrounds, music, and field here
    local test_spawner = mob:create_spawner(get_package("Champy"),Rank.V1)
    test_spawner:spawn_at(4, 1)

    test_spawner = mob:create_spawner(get_package("Chimpy"),Rank.V1)
    test_spawner:spawn_at(5, 2)

    test_spawner = mob:create_spawner(get_package("RareChampy"),Rank.V1)
    test_spawner:spawn_at(6, 3)
end