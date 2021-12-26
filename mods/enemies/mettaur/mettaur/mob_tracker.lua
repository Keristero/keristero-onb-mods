
MobTracker = {}
function MobTracker:new ()
    local o = {}-- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    if not o.tbl_mobs then
        o.tbl_mobs = {}
        o.tbl_index = 1
    end
    return o
end

function MobTracker:add_by_id(mob_id)
    table.insert(self.tbl_mobs,mob_id)
    --print('added',mob_id)
end

function MobTracker:print_ids()
    for index, value in ipairs(self.tbl_mobs) do
        print('i=',index,'id=',value)
    end
end

function MobTracker:sort_turn_order(sort_function,reverse_sorting)
    --print('sorting mob tracker turn order')
    local reversable_sort = function(a,b)
        local bool_result = sort_function(a,b)
        if reverse_sorting then
            bool_result = not bool_result
        end
        return bool_result
    end
    table.sort(self.tbl_mobs,reversable_sort)
end

function MobTracker:get_index(mob_id)
    for index, value in ipairs(self.tbl_mobs) do
        if value == mob_id then
            return index
        end
    end
    return nil
end

function MobTracker:remove_by_id(mob_id)
    --print('removing ',mob_id)
    local i = self:get_index(mob_id)
    table.remove(self.tbl_mobs,i)
    if self.tbl_index > i then
        self.tbl_index = self.tbl_index - 1
    end
    if self.tbl_index > #self.tbl_mobs then
        self.tbl_index = 1
    end
end

function MobTracker:clear()
    --print('clearing mob tracker')
    for index, value in ipairs(self.tbl_mobs) do
        table.remove(self.tbl_mobs,index)
    end
end

function MobTracker:get_active_mob()
    return self.tbl_mobs[self.tbl_index]
end

function MobTracker:advance_a_turn()
    self.tbl_index = self.tbl_index + 1
    if self.tbl_index > #self.tbl_mobs then
        self.tbl_index = self.tbl_index - #self.tbl_mobs
    end
end

return MobTracker

--[[ 
right_mobs = MobTracker:new()

right_mobs:add_by_id(12)
right_mobs:add_by_id(10)
right_mobs:add_by_id(11)
right_mobs:add_by_id(15)
right_mobs:print_ids()
right_mobs:sort_turn_order(function(a,b)
    return b > a
end)
right_mobs:print_ids()
print('active mob',right_mobs:get_active_mob())
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob())
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob())
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob())
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob())
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob())
right_mobs:remove_by_id(10)
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob())
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob())
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob())
right_mobs:remove_by_id(12)
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob())
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob())
right_mobs:advance_a_turn()
print('active mob',right_mobs:get_active_mob()) ]]