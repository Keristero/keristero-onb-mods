local package_prefix = "keristero"
local package_name = "ezencounters"

--Everything under this comment is standard and does not need to be edited\
local mob_package_id = "com."..package_prefix..".mob."..package_name
local loaded_obstacles = {}

local encounter_info = {
    enemy_packages = {
        Champy="com.keristero.char.Champy",
        Chumpy="com.keristero.char.Chumpy",
        Chimpy="com.keristero.char.Chimpy",
        RareChampy="com.keristero.char.RareChampy",
        BigBrute="com.keristero.char.BigBrute",
        Mettaur="com.keristero.char.Mettaur",
        Gunner="com.keristero.char.Gunner",
        Cactikil="com.discord.Konstinople#7692.enemy.cactikil",
        Cactroll="com.discord.Konstinople#7692.enemy.cactroll",
        Cacter="com.discord.Konstinople#7692.enemy.cacter",
        Powie="com.discord.Konstinople#7692.enemy.powie",
        Powie2="com.discord.Konstinople#7692.enemy.powie2",
        Powie3="com.discord.Konstinople#7692.enemy.powie2",
        Spikey="com.Dawn.char.Spikey",
        Canodumb="com.discord.Konstinople#7692.enemy.canodumb",
        Canosmart="com.dawn.enemy.canosmart"
    },
    obstacles = {
        RockCube="obstacles/rock_cube.lua",
        Rock="obstacles/rock.lua",
        Coffin="obstacles/coffin.lua",
        BlastCube="obstacles/blast_cube.lua",
        IceCube="obstacles/ice_cube.lua",
        MysteryData="obstacles/mystery.lua",
    },
    tile_states = {
        0,--normal
        1,--cracked
        2,--broken
        11,--up
        12,--down
        9,--left
        10,--right
        7,--empty
        4,--grass
        14,--hidden
        8,--holy
        3,--ice
        5,--lava
        6,--poison
        13--volcano
    },
    enemy_ranks = {
        0,--v1
        1,--v2
        2,--v3
        3,--sp
        4,--ex
        5,--rare1
        6,--rare2
        7--nightmare
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
    --First a work around to not crash the server, include the obstacle scripts here rather than in global scope
    for obstacle_alias, script_path in pairs(encounter_info.obstacles) do
        print('[ezencounters] including '..script_path)
        loaded_obstacles[obstacle_alias] = include(script_path)
    end
    --work around end

    local field = mob:get_field()
    --can setup music, and field here
    if not data then
        --test data here
        data = {
            enemies = {
                {name="Mettaur",rank=1},
                {name="Mettaur",rank=2},
                {name="Mettaur",rank=3},
                {name="Mettaur",rank=4},
                {name="Mettaur",rank=6},
                {name="Mettaur",rank=7},
            },
            positions = {
                {0,0,0,2,0,0},
                {0,0,0,0,0,2},
                {0,0,0,0,2,0}
            },
            obstacles = {
                {name="MysteryData"}
            },
            obstacle_positions = {
                {0,0,0,0,0,0},
                {0,0,1,0,0,0},
                {0,0,0,0,0,0}
            },
            music={
                path="bn1_battle.mid"
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
        print("trying to make spawner for ",enemy_info.name,enemy_rank)
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

    if data.player_positions then
        for y, x_table in ipairs(data.player_positions) do
            for x, player_id in ipairs(x_table) do
                if player_id ~= 0 then
                    mob:spawn_player( player_id, x, y )
                end
            end
        end
    end

    if data.freedom_mission then
        local turns = 3
        local can_flip = true
        if data.freedom_mission.turns ~= nil then
            turns = data.freedom_mission.turns
        end
        if data.freedom_mission.player_can_flip ~= nil then
            can_flip = data.freedom_mission.player_can_flip
        end
        mob:enable_freedom_mission(turns,can_flip)
    end

    if data.music then
        local loop_start = 0
        local loop_end = 0
        if data.music.loop_start then
            loop_start = data.music.loop_start
        end
        if data.music.loop_end then
            loop_end = data.music.loop_end
        end
        mob:stream_music(_folderpath.."/music/"..data.music.path,loop_start,loop_end)
    end

    if data.obstacle_positions then
        for y, x_table in ipairs(data.obstacle_positions) do
            for x, obstacle_id in ipairs(x_table) do
                if obstacle_id ~= 0 then
                    local obstacle_info = data.obstacles[obstacle_id]
                    local create_obstacle_func = loaded_obstacles[obstacle_info.name]
                    local new_obstacle = create_obstacle_func()
                    print('spawning obstacle '..obstacle_info.name..' at '..x..','..y)
                    field:spawn(new_obstacle,x,y)
                end
            end
        end
    end

end