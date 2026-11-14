Scene = {
    entities = {},  -- { id, handle, kind = 'vehicle' | 'ped' | 'prop', model, label, owned, frozen, activity?, clone? }
    nextId = 1,
}

function Notify(message, type)
    lib.notify({ title = 'Sahne Aracı', description = message, type = type or 'inform' })
end

function RequestControl(entity, timeout)
    if not DoesEntityExist(entity) then return false end
    if not NetworkGetEntityIsNetworked(entity) or NetworkHasControlOfEntity(entity) then return true end

    local deadline = GetGameTimer() + (timeout or 1500)
    repeat
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    until NetworkHasControlOfEntity(entity) or GetGameTimer() > deadline

    return NetworkHasControlOfEntity(entity)
end

function LoadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        Notify(('Model bulunamadı: %s'):format(model), 'error')
        return
    end
    if not pcall(lib.requestModel, hash, 10000) then
        Notify(('Model yüklenemedi: %s'):format(model), 'error')
        return
    end
    return hash
end

--- Point on the ground the camera looks at, or a few meters in front of the player.
function GetSpawnPoint()
    local playerCoords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local hit, _, coords = lib.raycast.fromCamera(1, 4, 40.0)

    if hit and #(coords - playerCoords) <= 30.0 then
        return vec4(coords.x, coords.y, coords.z, heading)
    end

    local front = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, Config.SpawnDistance, 0.0)
    local found, groundZ = GetGroundZFor_3dCoord(front.x, front.y, front.z + 2.0, false)
    return vec4(front.x, front.y, found and groundZ or front.z, heading)
end

function GetEntityKind(entity)
    local entityType = GetEntityType(entity)
    return entityType == 1 and 'ped' or entityType == 2 and 'vehicle' or entityType == 3 and 'prop' or nil
end

function Scene.find(entity)
    for _, item in ipairs(Scene.entities) do
        if item.handle == entity then return item end
    end
end

function Scene.add(entity, kind, model, label, owned)
    local existing = Scene.find(entity)
    if existing then return existing end

    local item = {
        id = Scene.nextId,
        handle = entity,
        kind = kind,
        model = model,
        label = label or tostring(model),
        owned = owned ~= false,
        frozen = false,
    }
    Scene.nextId = Scene.nextId + 1
    Scene.entities[#Scene.entities + 1] = item
    return item
end

--- Drops entries whose entity no longer exists (deleted by the game or another player).
function Scene.cleanup()
    for i = #Scene.entities, 1, -1 do
        if not DoesEntityExist(Scene.entities[i].handle) then
            DetachPedProp(Scene.entities[i].handle)
            table.remove(Scene.entities, i)
        end
    end
end

function DeleteSceneEntity(entity)
    if not DoesEntityExist(entity) then return end
    DetachPedProp(entity)
    RequestControl(entity)
    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
end

function Scene.remove(item)
    if item.kind == 'vehicle' then
        -- passengers spawned by the tool go with their vehicle
        for seat = -1, GetVehicleMaxNumberOfPassengers(item.handle) - 1 do
            local ped = GetPedInVehicleSeat(item.handle, seat)
            local pedItem = ped ~= 0 and Scene.find(ped)
            if pedItem and pedItem.owned then
                DeleteSceneEntity(ped)
            end
        end
    end
    DeleteSceneEntity(item.handle)
    Scene.cleanup()
end

function Scene.clear()
    for i = #Scene.entities, 1, -1 do
        local item = Scene.entities[i]
        if item.owned then DeleteSceneEntity(item.handle) end
    end
    Scene.entities = {}
end

function Scene.vehicles()
    Scene.cleanup()
    local list = {}
    for _, item in ipairs(Scene.entities) do
        if item.kind == 'vehicle' then list[#list + 1] = item end
    end
    return list
end

function FormatTransform(entity)
    local c = GetEntityCoords(entity)
    local r = GetEntityRotation(entity, 2)
    return ('vec4(%.2f, %.2f, %.2f, %.2f)'):format(c.x, c.y, c.z, GetEntityHeading(entity)),
        ('vec3(%.2f, %.2f, %.2f)'):format(r.x, r.y, r.z)
end

function DrawText2D(text, x, y, scale)
    SetTextFont(4)
    SetTextScale(scale or 0.4, scale or 0.4)
    SetTextColour(255, 255, 255, 230)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Scene.clear()
end)
