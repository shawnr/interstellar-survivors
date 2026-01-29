-- Simple OOP helper using Playdate's class system
-- This wraps the CoreLibs/object class() function for convenience

-- The class() function is already available from CoreLibs/object
-- This file provides additional utility functions for OOP patterns

-- Deep copy a table (useful for cloning data)
function table.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Check if a table contains a value
function table.contains(tbl, element)
    for _, value in pairs(tbl) do
        if value == element then
            return true
        end
    end
    return false
end

-- Get the index of an element in a table
function table.indexOf(tbl, element)
    for i, value in ipairs(tbl) do
        if value == element then
            return i
        end
    end
    return nil
end

-- Remove an element from a table by value
function table.removeValue(tbl, element)
    local index = table.indexOf(tbl, element)
    if index then
        table.remove(tbl, index)
        return true
    end
    return false
end

-- Shuffle a table in place
function table.shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

-- Get table length (works for non-sequential tables too)
function table.length(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end
