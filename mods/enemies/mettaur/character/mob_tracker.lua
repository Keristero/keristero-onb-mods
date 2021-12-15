
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
    print('added',mob_id)
end

function MobTracker:print_ids()
    for index, value in ipairs(self.tbl_mobs) do
        print('i=',index,'id=',value)
    end
end

function MobTracker:sort_turn_order(sort_function)
    table.sort(self.tbl_mobs,sort_function)
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
    print('removing ',mob_id)
    local i = self:get_index(mob_id)
    table.remove(self.tbl_mobs,i)
end

function MobTracker:get_active_mob()
    return self.tbl_mobs[self.tbl_index]
end

right_mobs = MobTracker:new()

right_mobs:add_by_id(12)
right_mobs:add_by_id(10)
right_mobs:add_by_id(11)
right_mobs:print_ids()
right_mobs:remove_by_id(10)
right_mobs:print_ids()

left_mobs = MobTracker:new()

left_mobs:add_by_id(20)
left_mobs:print_ids()