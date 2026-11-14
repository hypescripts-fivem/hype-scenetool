function SpawnVehicle(model, label, point)
    local hash = LoadModel(model)
    if not hash then return end

    point = point or GetSpawnPoint()
    local vehicle = CreateVehicle(hash, point.x, point.y, point.z, point.w, true, false)
    SetModelAsNoLongerNeeded(hash)
    if vehicle == 0 then return Notify(locale('error.vehicle_failed'), 'error') end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, Config.Plate)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    Entity(vehicle).state:set('fuel', 100.0, true)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdCanMigrate(netId, true)
    TriggerServerEvent('hype-scenetool:server:giveKeys', netId)

    return Scene.add(vehicle, 'vehicle', model, label)
end

function SpawnPed(model, label, point)
    local hash = LoadModel(model)
    if not hash then return end

    point = point or GetSpawnPoint()
    local ped = CreatePed(4, hash, point.x, point.y, point.z, point.w, true, true)
    SetModelAsNoLongerNeeded(hash)
    if ped == 0 then return Notify(locale('error.ped_failed'), 'error') end

    SetPedDefaultComponentVariation(ped)
    SetupScenePed(ped)
    return Scene.add(ped, 'ped', model, label)
end

--- A copy of your own character, so one person can play two roles.
function SpawnClone(point)
    point = point or GetSpawnPoint()
    local ped = ClonePed(cache.ped, true, false, true)
    if ped == 0 then return Notify(locale('error.clone_failed'), 'error') end

    SetEntityCoords(ped, point.x, point.y, point.z, false, false, false, false)
    SetEntityHeading(ped, point.w)
    SetupScenePed(ped)

    local item = Scene.add(ped, 'ped', GetEntityModel(ped), 'entity.clone')
    item.clone = true
    return item
end

function SetupScenePed(ped)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedKeepTask(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedDiesWhenInjured(ped, false)
    SetEntityInvincible(ped, true)
    SetPedConfigFlag(ped, 281, true) -- no writhe
end

function SpawnProp(model, label, point)
    local hash = LoadModel(model)
    if not hash then return end

    point = point or GetSpawnPoint()
    local object = CreateObject(hash, point.x, point.y, point.z, true, true, false)
    SetModelAsNoLongerNeeded(hash)
    if object == 0 then return Notify(locale('error.prop_failed'), 'error') end

    SetEntityAsMissionEntity(object, true, true)
    SetEntityHeading(object, point.w)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)

    local item = Scene.add(object, 'prop', model, label)
    item.frozen = true
    return item
end

--- Spawns a trailer right behind the truck and hooks it up.
function SpawnTrailer(truckItem, model, label)
    local truck = truckItem.handle
    local hash = LoadModel(model)
    if not hash or not DoesEntityExist(truck) then return end

    local truckMin = GetModelDimensions(GetEntityModel(truck))
    local _, trailerMax = GetModelDimensions(hash)
    local offset = GetOffsetFromEntityInWorldCoords(truck, 0.0, truckMin.y - trailerMax.y - 0.5, 0.0)
    local point = vec4(offset.x, offset.y, offset.z, GetEntityHeading(truck))

    local trailerItem = SpawnVehicle(model, label or 'entity.trailer', point)
    if not trailerItem then return end

    AttachVehicleToTrailer(truck, trailerItem.handle, 1.1)
    trailerItem.trailerOf = truck
    return trailerItem
end
