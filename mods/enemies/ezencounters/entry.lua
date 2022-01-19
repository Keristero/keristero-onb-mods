local package_prefix = "keristero"
local package_name = "ezencounters"

--Everything under this comment is standard and does not need to be edited\
local mob_package_id = "com."..package_prefix..".mob."..package_name

local encounter_info = {
    enemy_packages = {
        Champy="com.keristero.char.Champy",
        BigBrute="com.keristero.char.BigBrute",
        Mettaur="com.keristero.char.Mettaur",
    },
    tile_states = {
        TileState.Normal,
        TileState.Cracked,
        TileState.Broken,
        TileState.DirectionUp,
        TileState.DirectionDown,
        TileState.DirectionLeft,
        TileState.DirectionRight,
        TileState.Empty,
        TileState.Grass,
        TileState.Hidden,
        TileState.Holy,
        TileState.Ice,
        TileState.Lava,
        TileState.Poison,
        TileState.Volcano
    },
    enemy_ranks = {
        Rank.V1,
        Rank.V2,
        Rank.V3,
        Rank.SP,
        Rank.EX,
        Rank.Rare1,
        Rank.Rare2,
        Rank.NM
    },
    field_tiles_default = {
        {1,1,1,1,1,1},
        {1,1,1,1,1,1},
        {1,1,1,1,1,1}
    },
    field_teams_default = {
        {2,2,2,1,1,1},
        {2,2,2,1,1,1},
        {2,2,2,1,1,1}
    }
}

function get_enum_value_by_index(mapping_table,p_index)
    for i, value in ipairs(mapping_table) do
        if tonumber(i) == tonumber(p_index) then
            return value
        end
    end
    print("~WARNING~ invalid input data, no index",p_index)
end

function package_requires_scripts()
    for mob_alias, package in pairs(encounter_info.enemy_packages) do
        print('[ezencounters] requiring '..package)
        Engine.requires_character(package)
    end
end

function get_package_id(alias) 
    return encounter_info.enemy_packages[alias]
end

function package_init(package) 
    package:declare_package_id(mob_package_id)
    package:set_name(package_name)
    package:set_description("Initiate custom battles from the server!")
    package:set_preview_texture_path(_modpath.."preview.png")
end

function package_build(mob,data) 
    local field = mob:get_field()
    --can setup backgrounds, music, and field here
    if not data then
        --test data here
        data = {
            weight=10,
            enemies = {
                {name="BigBrute",rank=1,max_hp=500,starting_hp=500,nickname="Doggie"},
                {name="Champy",rank=1},
            },
            positions = {
                {0,0,0,1,0,0},
                {0,0,0,0,2,0},
                {0,0,0,0,0,1}
            },
            tiles = {
                {7,7,7,1,1,1},
                {4,1,5,1,1,1},
                {6,6,6,1,1,1}
            }
        }
    end
    print('building package with data!')
    --load tile states from  data
    if not data.tiles then
        data.tiles = encounter_info.field_tiles_default
    end
    for y, x_table in ipairs(data.tiles) do
        for x, tile_state_index in ipairs(x_table) do
            local tile = field:tile_at(x,y)
            local tile_state = get_enum_value_by_index(encounter_info.tile_states,tile_state_index)
            tile:set_state(tile_state)
        end
    end

    --load tile teams from  data
    if not data.teams then
        data.teams = encounter_info.field_teams_default
    end
    for y, x_table in ipairs(data.teams) do
        for x, team_index in ipairs(x_table) do
            local tile = field:tile_at(x,y)
            tile:set_team(team_index,false)
        end
    end

    --load enemies from data
    if not data.enemies then
        print('~WARNING~ no enemies listed for encounter')
        return
    end
    spawners = {}
    for index, enemy_info in ipairs(data.enemies) do
        local enemy_rank = get_enum_value_by_index(encounter_info.enemy_ranks,enemy_info.rank)
        spawners[index] = mob:create_spawner(get_package_id(enemy_info.name),enemy_rank)
    end

    --spawn enemies at positions
    if not data.positions then
        print('~WARNING~ no enemy spawn positions')
        return
    end
    for y, x_table in ipairs(data.positions) do
        for x, spawner_id in ipairs(x_table) do
            if spawner_id ~= 0 then
                local spawner = spawners[spawner_id]
                local enemy_info = data.enemies[spawner_id]
                local mutator = spawner:spawn_at(x, y)
                mutator:mutate(function (character)
                    print('mutating')
                    if enemy_info.nickname ~= nil then
                        character:set_name(enemy_info.nickname)
                    end
                    if enemy_info.max_hp ~= nil then
                        --character:mod_max_hp(enemy_info.max_hp) it dont work
                    end
                    if enemy_info.starting_hp ~= nil then
                        character:set_health(enemy_info.starting_hp)
                    end
                end)
            end
        end
    end

end