Cinema = {
    hideHud = false,
    noTraffic = false,
    time = nil,      -- { hour, minute } while overridden
    weather = nil,   -- weather name while overridden
}

local running = false

local function setSync(enabled)
    -- Renewed-Weathersync / qb-weathersync stop overwriting local time and weather
    LocalPlayer.state:set('syncWeather', enabled, false)
    TriggerEvent(enabled and 'qb-weathersync:client:EnableSync' or 'qb-weathersync:client:DisableSync')
end

local function isActive()
    return Cinema.hideHud or Cinema.noTraffic or Cinema.time or Cinema.weather
end

local function run()
    if running then return end
    running = true

    CreateThread(function()
        local lastWeather = 0
        while isActive() do
            Wait(0)
            if Cinema.hideHud then
                HideHudAndRadarThisFrame()
            end
            if Cinema.noTraffic then
                SetVehicleDensityMultiplierThisFrame(0.0)
                SetRandomVehicleDensityMultiplierThisFrame(0.0)
                SetParkedVehicleDensityMultiplierThisFrame(0.0)
                SetPedDensityMultiplierThisFrame(0.0)
                SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
            end
            if Cinema.time then
                NetworkOverrideClockTime(Cinema.time.hour, Cinema.time.minute, 0)
            end
            if Cinema.weather and GetGameTimer() - lastWeather > 1000 then
                lastWeather = GetGameTimer()
                SetWeatherTypeNowPersist(Cinema.weather)
                SetOverrideWeather(Cinema.weather)
            end
        end
        running = false
    end)
end

function Cinema.toggleHud()
    Cinema.hideHud = not Cinema.hideHud
    DisplayRadar(not Cinema.hideHud)
    run()
end

function Cinema.toggleTraffic()
    Cinema.noTraffic = not Cinema.noTraffic
    run()
end

function Cinema.setTime(hour, minute)
    setSync(false)
    Cinema.time = { hour = hour, minute = minute }
    run()
end

function Cinema.setWeather(weather)
    setSync(false)
    ClearOverrideWeather()
    SetWeatherTypeOvertimePersist(weather, 5.0)
    Cinema.weather = weather
    run()
end

function Cinema.resetWorld()
    Cinema.time = nil
    Cinema.weather = nil
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    setSync(true)
end

--- Time stop: nearby NPCs and vehicles freeze in place, scene NPC animations pause mid-pose.
--- On resume everything gets its old velocity back, so moving cars carry on as if nothing happened.
Cinema.timeStopped = false
local stopped = {} -- [entity] = velocity at the moment it was frozen
local stopToken

local function hasPlayer(vehicle)
    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped ~= 0 and IsPedAPlayer(ped) then return true end
    end
    return false
end

local function canStop(entity)
    if stopped[entity] or not DoesEntityExist(entity) then return false end
    local item = Scene.find(entity)
    if item and item.frozen then return false end -- already pinned by the user, leave it alone

    local kind = GetEntityType(entity)
    if kind == 1 then
        if IsPedAPlayer(entity) then return false end
        local vehicle = GetVehiclePedIsIn(entity, false)
        return vehicle == 0 or not hasPlayer(vehicle)
    elseif kind == 2 then
        return not hasPlayer(entity)
    end
    return item ~= nil -- props: only the ones in the scene
end

local function stopEntity(entity)
    stopped[entity] = GetEntityVelocity(entity)
    if NetworkGetEntityIsNetworked(entity) then NetworkRequestControlOfEntity(entity) end
    FreezeEntityPosition(entity, true)
end

local function scan()
    local center = GetEntityCoords(cache.ped)
    local radius = Config.TimeStop.radius
    for _, pool in ipairs({ 'CPed', 'CVehicle' }) do
        for _, entity in ipairs(GetGamePool(pool)) do
            if #(GetEntityCoords(entity) - center) <= radius and canStop(entity) then
                stopEntity(entity)
            end
        end
    end
    for _, item in ipairs(Scene.entities) do
        if item.kind == 'prop' and canStop(item.handle) then stopEntity(item.handle) end
    end
end

local function setAnimSpeed(speed)
    for _, item in ipairs(Scene.entities) do
        local activity = item.activity
        if activity and activity.type == 'anim' and stopped[item.handle] then
            SetEntityAnimSpeed(item.handle, activity.anim.dict, activity.anim.clip, speed)
        end
    end
end

local function startTimeStop()
    Cinema.timeStopped = true
    stopped = {}
    scan()

    local current = {}
    stopToken = current -- a quick stop/resume/stop must not leave two loops running
    CreateThread(function()
        local lastScan = GetGameTimer()
        while Cinema.timeStopped and stopToken == current do
            Wait(0)
            setAnimSpeed(0.0) -- has to be applied every frame
            if GetGameTimer() - lastScan > 500 then
                lastScan = GetGameTimer()
                scan() -- catch anything that drives or walks into the area
            end
        end
    end)
end

local function resumeTime()
    Cinema.timeStopped = false
    setAnimSpeed(1.0)
    for entity, velocity in pairs(stopped) do
        if DoesEntityExist(entity) then
            local item = Scene.find(entity)
            if not (item and item.frozen) then -- the user may have pinned it in the meantime
                FreezeEntityPosition(entity, false)
                SetEntityVelocity(entity, velocity.x, velocity.y, velocity.z)
            end
        end
    end
    stopped = {}
end

function Cinema.toggleTimeStop()
    if Cinema.timeStopped then resumeTime() else startTimeStop() end
    Notify(locale(Cinema.timeStopped and 'cinema.time_stopped' or 'cinema.time_flows'), 'inform')
end

function Cinema.clearArea(radius)
    local coords = GetEntityCoords(cache.ped)
    ClearAreaOfPeds(coords.x, coords.y, coords.z, radius, 1)
    ClearAreaOfVehicles(coords.x, coords.y, coords.z, radius, false, false, false, false, false)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    DisplayRadar(true)
    if Cinema.timeStopped then resumeTime() end
    if Cinema.time or Cinema.weather then Cinema.resetWorld() end
end)
