-- ZenithXI NPC helpers (modules/zenith-public/lua/1-enum/zxi/npcHelpers.lua).
--
-- zxi.npcHelpers.removeDefaultHandler(zoneId, npcName) queues an NPC whose zone DefaultActions
-- onTrigger handler should go. From xi.server.onServerStart, after the interaction framework has
-- filled InteractionGlobal.lookup.data, the module removes that NPC's Default priority (10)
-- onTrigger entry and keeps every other entry. LSB has no such helper.
--
-- onServerStart runs once per run, so the cases call the module's own removal function, read from
-- the onServerStart override chain, on a stand-in NPC entry they add and remove themselves.

describe('Zenith NPC helpers', function()
    local zoneId  = xi.zone.LOWER_JEUNO
    local npcName = 'ZENITH_TEST_NPC'

    -- Walks the xi.server.onServerStart override chain to the module's removal function,
    -- or nil when the module is not loaded
    local function moduleRemoveDefaultHandler()
        local fn = xi.server.onServerStart

        while type(fn) == 'function' do
            local index = 1

            while true do
                local name, value = debug.getupvalue(fn, index)
                if name == nil then
                    break
                end

                if name == 'removeDefaultHandler' and type(value) == 'function' then
                    return value
                end

                index = index + 1
            end

            fn = rawget(getfenv(fn), 'super')
        end

        return nil
    end

    local function entry(priority)
        return { handler = { priority = priority } }
    end

    before_each(function()
        InteractionGlobal.lookup.data[zoneId] = InteractionGlobal.lookup.data[zoneId] or {}
    end)

    after_each(function()
        InteractionGlobal.lookup.data[zoneId][npcName] = nil
    end)

    it('removes the Default priority onTrigger handler and keeps the others', function()
        local removeDefault = moduleRemoveDefaultHandler()
        assert(removeDefault, 'the npcHelpers removal is not hooked into xi.server.onServerStart')

        local progress = entry(Action.Priority.Progress)
        local event    = entry(Action.Priority.Event)
        InteractionGlobal.lookup.data[zoneId][npcName] =
        {
            onTrigger = { progress, entry(Action.Priority.Default), event },
        }

        removeDefault(zoneId, npcName)

        local handlers = InteractionGlobal.lookup.data[zoneId][npcName].onTrigger
        assert(#handlers == 2, string.format('expected 2 onTrigger handlers left, got %d', #handlers))
        assert(handlers[1] == progress and handlers[2] == event, 'the Progress and Event handlers were not kept in order')
    end)

    it('leaves an NPC without a Default priority handler alone', function()
        local removeDefault = moduleRemoveDefaultHandler()
        assert(removeDefault, 'the npcHelpers removal is not hooked into xi.server.onServerStart')

        InteractionGlobal.lookup.data[zoneId][npcName] =
        {
            onTrigger = { entry(Action.Priority.ReplaceDefault), entry(Action.Priority.Event) },
        }

        removeDefault(zoneId, npcName)

        local handlers = InteractionGlobal.lookup.data[zoneId][npcName].onTrigger
        assert(#handlers == 2, string.format('expected 2 onTrigger handlers left, got %d', #handlers))
    end)

    it('queues a removal for the server start pass', function()
        assert(zxi and zxi.npcHelpers and zxi.npcHelpers.removeDefaultHandler, 'zxi.npcHelpers.removeDefaultHandler does not exist')

        local queue  = zxi.npcHelpers.removeDefaultHandlerList
        local before = #queue

        zxi.npcHelpers.removeDefaultHandler(zoneId, npcName)

        local added  = #queue - before
        local queued = queue[#queue]
        if added > 0 then
            table.remove(queue) -- not part of the server's real queue
        end

        assert(added == 1, string.format('expected 1 queued removal, got %d', added))
        assert(queued[1] == zoneId and queued[2] == npcName, 'removeDefaultHandler queued the wrong zone or NPC')
    end)
end)
