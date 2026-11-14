local OpenMainMenu, OpenEntityMenu, OpenEntityList

local function input(title, rows)
    return lib.inputDialog(title, rows)
end

--- Picker list of presets plus a free model field. spawn(model, label) is called with the choice.
local function openSpawnMenu(id, title, presets, spawn, extra)
    local options = extra and { extra } or {}

    options[#options + 1] = {
        title = locale('spawn.custom_model'),
        description = locale('spawn.custom_model_desc'),
        icon = 'keyboard',
        onSelect = function()
            local result = input(title, { { type = 'input', label = locale('spawn.model'), required = true } })
            if result then
                local item = spawn(result[1], result[1])
                if item then return OpenEntityMenu(item) end
            end
            lib.showContext(id)
        end,
    }

    for _, preset in ipairs(presets) do
        options[#options + 1] = {
            title = Label(preset.label),
            description = preset.model,
            onSelect = function()
                local item = spawn(preset.model, preset.label)
                if item then OpenEntityMenu(item) else lib.showContext(id) end
            end,
        }
    end

    lib.registerContext({ id = id, title = title, menu = 'hype_scene_main', options = options })
    lib.showContext(id)
end

local function seatOptions(vehicle)
    local options = { { value = '-1', label = locale('seat.driver') } }
    for seat = 0, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        options[#options + 1] = { value = tostring(seat), label = locale('seat.passenger', seat + 1) }
    end
    return options
end

local function chooseSeat(vehicle)
    local result = input(locale('seat.title'), {
        { type = 'select', label = locale('seat.label'), options = seatOptions(vehicle), default = '-1', required = true },
    })
    return result and tonumber(result[1])
end

local function waypoint()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then
        Notify(locale('common.no_waypoint'), 'error')
        return
    end
    return GetBlipInfoIdCoord(blip)
end

local function exactTransform(item)
    local entity = item.handle
    local c, r = GetEntityCoords(entity), GetEntityRotation(entity, 2)
    local rows = {
        { type = 'number', label = 'X', default = c.x, precision = 3, step = 0.01, required = true },
        { type = 'number', label = 'Y', default = c.y, precision = 3, step = 0.01, required = true },
        { type = 'number', label = 'Z', default = c.z, precision = 3, step = 0.01, required = true },
        { type = 'number', label = locale('entity.heading'), default = r.z, precision = 2, step = 1, required = true },
    }
    if item.kind ~= 'ped' then
        rows[#rows + 1] = { type = 'number', label = locale('entity.pitch'), default = r.x, precision = 2, step = 1 }
        rows[#rows + 1] = { type = 'number', label = locale('entity.roll'), default = r.y, precision = 2, step = 1 }
    end

    local result = input(locale('entity.transform_title'), rows)
    if not result or not RequestControl(entity) then return end

    SetEntityCoordsNoOffset(entity, result[1], result[2], result[3], false, false, false)
    if item.kind == 'ped' then
        SetEntityHeading(entity, result[4])
    else
        SetEntityRotation(entity, result[5] or 0.0, result[6] or 0.0, result[4], 2, true)
    end
end

local function vehicleOptions(item)
    local vehicle = item.handle
    local reopen = function() OpenEntityMenu(item) end

    return {
        {
            title = locale('vehicle.enter'),
            description = locale('vehicle.enter_desc'),
            icon = 'car-side',
            onSelect = function()
                local seat = chooseSeat(vehicle)
                if seat then TaskWarpPedIntoVehicle(cache.ped, vehicle, seat) end
            end,
        },
        {
            title = locale('vehicle.trailer'),
            description = locale('vehicle.trailer_desc'),
            icon = 'trailer',
            onSelect = function()
                local options = {}
                for _, trailer in ipairs(Config.Trailers) do
                    options[#options + 1] = { value = trailer.model, label = Label(trailer.label) }
                end
                local result = input(locale('vehicle.trailer'), {
                    { type = 'select', label = locale('vehicle.trailer_label'), options = options, required = true, searchable = true },
                })
                if result then
                    local label
                    for _, trailer in ipairs(Config.Trailers) do
                        if trailer.model == result[1] then label = trailer.label end
                    end
                    SpawnTrailer(item, result[1], label)
                end
                reopen()
            end,
        },
        {
            title = locale('vehicle.engine'),
            icon = 'power-off',
            onSelect = function()
                RequestControl(vehicle)
                SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), true, true)
                reopen()
            end,
        },
        {
            title = locale('vehicle.lights'),
            icon = 'lightbulb',
            onSelect = function()
                local result = input(locale('vehicle.lights'), {
                    { type = 'select', label = locale('vehicle.lights_state'), required = true, default = '2', options = {
                        { value = '1', label = locale('vehicle.lights_off') },
                        { value = '2', label = locale('vehicle.lights_on') },
                        { value = '3', label = locale('vehicle.lights_high') },
                    } },
                })
                if result then
                    RequestControl(vehicle)
                    local mode = tonumber(result[1])
                    SetVehicleLights(vehicle, mode == 1 and 1 or 2)
                    SetVehicleFullbeam(vehicle, mode == 3)
                end
                reopen()
            end,
        },
        {
            title = locale('vehicle.horn'),
            description = locale('vehicle.horn_desc'),
            icon = 'bullhorn',
            onSelect = function()
                StartVehicleHorn(vehicle, 2000, joaat('HELDDOWN'), false)
                reopen()
            end,
        },
        {
            title = locale('vehicle.doors'),
            icon = 'door-open',
            onSelect = function()
                local doors = {
                    { value = '0', label = locale('vehicle.door_fl') }, { value = '1', label = locale('vehicle.door_fr') },
                    { value = '2', label = locale('vehicle.door_rl') }, { value = '3', label = locale('vehicle.door_rr') },
                    { value = '4', label = locale('vehicle.door_hood') }, { value = '5', label = locale('vehicle.door_trunk') },
                }
                local open = {}
                for i = 0, 5 do
                    if GetVehicleDoorAngleRatio(vehicle, i) > 0.1 then open[#open + 1] = tostring(i) end
                end
                local result = input(locale('vehicle.doors_title'), {
                    { type = 'multi-select', label = locale('vehicle.doors'), options = doors, default = open },
                })
                if result then
                    RequestControl(vehicle)
                    local wanted = {}
                    for _, door in ipairs(result[1] or {}) do wanted[tonumber(door)] = true end
                    for i = 0, 5 do
                        if wanted[i] then
                            SetVehicleDoorOpen(vehicle, i, false, false)
                        else
                            SetVehicleDoorShut(vehicle, i, false)
                        end
                    end
                end
                reopen()
            end,
        },
        {
            title = locale('vehicle.looks'),
            icon = 'palette',
            onSelect = function()
                local liveries = GetVehicleLiveryCount(vehicle)
                local result = input(locale('vehicle.looks_title'), {
                    { type = 'color', label = locale('vehicle.primary'), default = '#ffffff' },
                    { type = 'color', label = locale('vehicle.secondary'), default = '#ffffff' },
                    { type = 'input', label = locale('vehicle.plate'), default = GetVehicleNumberPlateText(vehicle), max = 8 },
                    { type = 'number', label = locale('vehicle.livery', math.max(liveries - 1, 0)),
                      default = math.max(GetVehicleLivery(vehicle), 0), min = 0, max = math.max(liveries - 1, 0) },
                    { type = 'checkbox', label = locale('vehicle.apply_colors'), checked = false },
                })
                if result then
                    RequestControl(vehicle)
                    if result[5] then
                        local function rgb(hex) return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16) end
                        if result[1] then SetVehicleCustomPrimaryColour(vehicle, rgb(result[1])) end
                        if result[2] then SetVehicleCustomSecondaryColour(vehicle, rgb(result[2])) end
                    end
                    if result[3] and result[3] ~= '' then SetVehicleNumberPlateText(vehicle, result[3]) end
                    if liveries > 0 and result[4] then SetVehicleLivery(vehicle, result[4]) end
                end
                reopen()
            end,
        },
        {
            title = locale('vehicle.damage'),
            icon = 'car-burst',
            onSelect = function()
                local result = input(locale('vehicle.damage'), {
                    { type = 'slider', label = locale('vehicle.dirt'), default = math.floor(GetVehicleDirtLevel(vehicle)), min = 0, max = 15 },
                    { type = 'select', label = locale('vehicle.damage_label'), default = 'none', options = {
                        { value = 'none', label = locale('vehicle.damage_none') },
                        { value = 'fix', label = locale('vehicle.damage_fix') },
                        { value = 'light', label = locale('vehicle.damage_light') },
                        { value = 'heavy', label = locale('vehicle.damage_heavy') },
                    } },
                })
                if result then
                    RequestControl(vehicle)
                    SetVehicleDirtLevel(vehicle, result[1] + 0.0)
                    if result[2] == 'fix' then
                        SetVehicleFixed(vehicle)
                        SetVehicleDeformationFixed(vehicle)
                    elseif result[2] == 'light' then
                        SetVehicleDamage(vehicle, 0.0, 2.5, 0.2, 300.0, 1.2, true)
                    elseif result[2] == 'heavy' then
                        SetVehicleDamage(vehicle, 0.0, 2.5, 0.2, 900.0, 2.0, true)
                        SetVehicleDamage(vehicle, 1.0, 0.0, 0.3, 700.0, 1.5, true)
                        SmashVehicleWindow(vehicle, 0)
                        SmashVehicleWindow(vehicle, 1)
                        SetVehicleTyreBurst(vehicle, 0, true, 1000.0)
                    end
                end
                reopen()
            end,
        },
    }
end

local function pedOptions(item)
    local ped = item.handle
    local reopen = function() OpenEntityMenu(item) end

    return {
        {
            title = locale('ped.anims'),
            icon = 'person-walking',
            arrow = true,
            onSelect = function() OpenAnimMenu(ped, item, 'hype_scene_entity') end,
        },
        {
            title = locale('ped.put_in'),
            description = locale('ped.put_in_desc'),
            icon = 'car-side',
            onSelect = function()
                local vehicles = Scene.vehicles()
                if #vehicles == 0 then
                    Notify(locale('ped.no_vehicles'), 'error')
                    return reopen()
                end
                local options = {}
                for _, vehicleItem in ipairs(vehicles) do
                    options[#options + 1] = { value = tostring(vehicleItem.id), label = ('#%d %s'):format(vehicleItem.id, Label(vehicleItem.label)) }
                end
                local result = input(locale('ped.put_in'), {
                    { type = 'select', label = locale('ped.vehicle'), options = options, required = true },
                })
                if result then
                    for _, vehicleItem in ipairs(vehicles) do
                        if vehicleItem.id == tonumber(result[1]) then
                            local seat = chooseSeat(vehicleItem.handle)
                            if seat then
                                RequestControl(ped)
                                DetachPedProp(ped)
                                TaskWarpPedIntoVehicle(ped, vehicleItem.handle, seat)
                            end
                        end
                    end
                end
                reopen()
            end,
        },
        {
            title = locale('ped.leave'),
            icon = 'right-from-bracket',
            onSelect = function()
                RequestControl(ped)
                TaskLeaveAnyVehicle(ped, 0, 0)
                reopen()
            end,
        },
        {
            title = locale('ped.drive'),
            description = locale('ped.drive_desc'),
            icon = 'route',
            onSelect = function()
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
                    Notify(locale('ped.not_driver'), 'error')
                    return reopen()
                end
                local target = waypoint()
                if target then
                    local result = input(locale('ped.drive'), {
                        { type = 'number', label = locale('ped.speed_kmh'), default = math.floor(Config.Drive.speed * 3.6), min = 5, max = 200 },
                    })
                    if result then
                        RequestControl(ped)
                        RequestControl(vehicle)
                        FreezeEntityPosition(vehicle, false)
                        SetVehicleEngineOn(vehicle, true, true, false)
                        TaskVehicleDriveToCoordLongrange(ped, vehicle, target.x, target.y, target.z,
                            result[1] / 3.6, Config.Drive.style, 10.0)
                        Notify(locale('ped.drove_off'), 'success')
                    end
                end
                reopen()
            end,
        },
        {
            title = locale('ped.wander'),
            description = locale('ped.wander_desc'),
            icon = 'shuffle',
            onSelect = function()
                RequestControl(ped)
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= 0 then
                    FreezeEntityPosition(vehicle, false)
                    TaskVehicleDriveWander(ped, vehicle, Config.Drive.speed, Config.Drive.style)
                else
                    TaskWanderStandard(ped, 10.0, 10)
                end
                reopen()
            end,
        },
        {
            title = locale('ped.walk'),
            icon = 'person-walking-arrow-right',
            onSelect = function()
                local target = waypoint()
                if target then
                    local result = input(locale('ped.walk'), {
                        { type = 'select', label = locale('ped.speed'), default = '1.0', options = {
                            { value = '1.0', label = locale('ped.speed_walk') },
                            { value = '2.0', label = locale('ped.speed_run') },
                            { value = '3.0', label = locale('ped.speed_sprint') },
                        } },
                    })
                    if result then
                        RequestControl(ped)
                        FreezeEntityPosition(ped, false)
                        item.frozen = false
                        TaskGoToCoordAnyMeans(ped, target.x, target.y, target.z, tonumber(result[1]), 0, false, 786603, 0.0)
                    end
                end
                reopen()
            end,
        },
        {
            title = locale('ped.follow'),
            icon = 'people-arrows',
            onSelect = function()
                RequestControl(ped)
                FreezeEntityPosition(ped, false)
                item.frozen = false
                TaskFollowToOffsetOfEntity(ped, cache.ped, 1.0, -1.5, 0.0, 1.5, -1, 1.5, true)
                reopen()
            end,
        },
        {
            title = locale('ped.face'),
            icon = 'arrows-rotate',
            onSelect = function()
                RequestControl(ped)
                local a, b = GetEntityCoords(ped), GetEntityCoords(cache.ped)
                SetEntityHeading(ped, GetHeadingFromVector_2d(b.x - a.x, b.y - a.y))
                reopen()
            end,
        },
        {
            title = locale('ped.stop'),
            icon = 'hand',
            onSelect = function()
                StopActivity(ped, item)
                reopen()
            end,
        },
        {
            title = locale('ped.outfit'),
            icon = 'shirt',
            onSelect = function()
                RequestControl(ped)
                SetPedRandomComponentVariation(ped, 0)
                SetPedRandomProps(ped)
                reopen()
            end,
        },
    }
end

OpenEntityMenu = function(item)
    if not DoesEntityExist(item.handle) then
        Scene.cleanup()
        Notify(locale('common.entity_gone'), 'error')
        return OpenEntityList()
    end

    local entity = item.handle
    local reopen = function() OpenEntityMenu(item) end
    local options = {
        {
            title = locale('entity.edit'),
            description = locale('entity.edit_desc'),
            icon = 'up-down-left-right',
            onSelect = function() StartEditor(item, reopen) end,
        },
        {
            title = locale('entity.coords'),
            description = locale('entity.coords_desc'),
            icon = 'crosshairs',
            onSelect = function()
                exactTransform(item)
                reopen()
            end,
        },
        {
            title = locale('entity.bring'),
            icon = 'location-arrow',
            onSelect = function()
                if not RequestControl(entity) then return reopen() end
                local point = GetSpawnPoint()
                if item.kind == 'ped' then
                    SetEntityCoords(entity, point.x, point.y, point.z, false, false, false, false)
                else
                    SetEntityCoordsNoOffset(entity, point.x, point.y, point.z, false, false, false)
                    if item.kind == 'vehicle' then SetVehicleOnGroundProperly(entity) else PlaceObjectOnGroundProperly(entity) end
                end
                reopen()
            end,
        },
        {
            title = locale(item.frozen and 'entity.unfreeze' or 'entity.freeze'),
            description = locale('entity.freeze_desc'),
            icon = item.frozen and 'lock-open' or 'lock',
            onSelect = function()
                RequestControl(entity)
                item.frozen = not item.frozen
                FreezeEntityPosition(entity, item.frozen)
                reopen()
            end,
        },
        {
            title = locale('entity.copy_coords'),
            icon = 'copy',
            onSelect = function()
                local coords, rot = FormatTransform(entity)
                lib.setClipboard(('%s -- rot %s'):format(coords, rot))
                Notify(locale('common.copied'), 'success')
                reopen()
            end,
        },
    }

    local extra = item.kind == 'vehicle' and vehicleOptions(item) or item.kind == 'ped' and pedOptions(item) or {}
    for _, option in ipairs(extra) do options[#options + 1] = option end

    options[#options + 1] = {
        title = locale('common.delete'),
        icon = 'trash',
        iconColor = '#ef4444',
        onSelect = function()
            Scene.remove(item)
            OpenEntityList()
        end,
    }

    lib.registerContext({
        id = 'hype_scene_entity',
        title = ('#%d %s'):format(item.id, Label(item.label)),
        menu = 'hype_scene_entities',
        options = options,
    })
    lib.showContext('hype_scene_entity')
end

OpenEntityList = function()
    Scene.cleanup()
    local icons = { vehicle = 'truck', ped = 'user', prop = 'box' }
    local options = {}

    for _, item in ipairs(Scene.entities) do
        local coords = GetEntityCoords(item.handle)
        options[#options + 1] = {
            title = ('#%d %s'):format(item.id, Label(item.label)),
            description = locale('entities.distance', #(coords - GetEntityCoords(cache.ped)))
                .. (item.frozen and locale('entities.frozen_tag') or '')
                .. (item.owned and '' or locale('entities.world_tag')),
            icon = icons[item.kind],
            arrow = true,
            onSelect = function() OpenEntityMenu(item) end,
        }
    end

    if #options == 0 then
        options[1] = { title = locale('entities.empty'), disabled = true }
    end

    lib.registerContext({ id = 'hype_scene_entities', title = locale('entities.title'), menu = 'hype_scene_main', options = options })
    lib.showContext('hype_scene_entities')
end

local function selectLookedAt()
    local hit, entity = lib.raycast.fromCamera(2 | 4 | 8 | 16, 4, 40.0)
    if not hit or not entity or entity == 0 or not DoesEntityExist(entity) then
        return Notify(locale('select.nothing'), 'error')
    end

    local kind = GetEntityKind(entity)
    if not kind then return Notify(locale('select.invalid'), 'error') end
    if kind == 'ped' and IsPedAPlayer(entity) then return Notify(locale('select.player'), 'error') end

    local item = Scene.find(entity)
        or Scene.add(entity, kind, GetEntityModel(entity), 'select.' .. kind, false)
    OpenEntityMenu(item)
end

--- Translated weather name, or the raw weather type when no translation exists.
local function weatherLabel(weather)
    local key = 'weather.' .. weather
    local text = locale(key)
    return text ~= key and text or weather
end

local function openCinemaMenu()
    local weatherOptions = {}
    for _, weather in ipairs(Config.Weathers) do weatherOptions[#weatherOptions + 1] = { value = weather, label = weatherLabel(weather) } end

    lib.registerContext({
        id = 'hype_scene_cinema',
        title = locale('cinema.title'),
        menu = 'hype_scene_main',
        options = {
            {
                title = locale(Cinema.hideHud and 'cinema.hud_show' or 'cinema.hud_hide'),
                description = locale('cinema.hud_desc'),
                icon = 'eye-slash',
                onSelect = function() Cinema.toggleHud() openCinemaMenu() end,
            },
            {
                title = locale(Cinema.noTraffic and 'cinema.traffic_on' or 'cinema.traffic_off'),
                description = locale('cinema.traffic_desc'),
                icon = 'road',
                onSelect = function() Cinema.toggleTraffic() openCinemaMenu() end,
            },
            {
                title = locale(Cinema.timeStopped and 'cinema.time_resume' or 'cinema.time_stop'),
                description = locale('cinema.time_stop_desc', math.floor(Config.TimeStop.radius)),
                icon = Cinema.timeStopped and 'play' or 'pause',
                onSelect = function() Cinema.toggleTimeStop() openCinemaMenu() end,
            },
            {
                title = locale(Talk.gestures and 'cinema.gestures_on' or 'cinema.gestures_off'),
                description = locale('cinema.gestures_desc', Config.Talk.command),
                icon = 'hands',
                onSelect = function() Talk.toggleGestures() openCinemaMenu() end,
            },
            {
                title = locale(Talk.lipSync and 'cinema.lipsync_on' or 'cinema.lipsync_off'),
                description = locale('cinema.lipsync_desc'),
                icon = 'comment-dots',
                onSelect = function() Talk.toggleLipSync() openCinemaMenu() end,
            },
            {
                title = locale('cinema.clear'),
                description = locale('cinema.clear_desc'),
                icon = 'broom',
                onSelect = function()
                    local result = input(locale('cinema.clear'), { { type = 'slider', label = locale('cinema.radius'), default = 50, min = 10, max = 200 } })
                    if result then Cinema.clearArea(result[1] + 0.0) end
                    openCinemaMenu()
                end,
            },
            {
                title = locale('cinema.clock'),
                description = Cinema.time and locale('cinema.clock_fixed', Cinema.time.hour, Cinema.time.minute) or locale('cinema.clock_server'),
                icon = 'clock',
                onSelect = function()
                    local result = input(locale('cinema.clock'), {
                        { type = 'slider', label = locale('cinema.hour'), default = Cinema.time and Cinema.time.hour or GetClockHours(), min = 0, max = 23 },
                        { type = 'slider', label = locale('cinema.minute'), default = Cinema.time and Cinema.time.minute or 0, min = 0, max = 59, step = 5 },
                    })
                    if result then Cinema.setTime(result[1], result[2]) end
                    openCinemaMenu()
                end,
            },
            {
                title = locale('cinema.weather'),
                description = Cinema.weather and weatherLabel(Cinema.weather) or locale('cinema.weather_server'),
                icon = 'cloud-sun',
                onSelect = function()
                    local result = input(locale('cinema.weather'), { { type = 'select', label = locale('cinema.weather_label'), options = weatherOptions, required = true } })
                    if result then Cinema.setWeather(result[1]) end
                    openCinemaMenu()
                end,
            },
            {
                title = locale('cinema.reset'),
                icon = 'rotate-left',
                disabled = not Cinema.time and not Cinema.weather,
                onSelect = function() Cinema.resetWorld() openCinemaMenu() end,
            },
        },
    })
    lib.showContext('hype_scene_cinema')
end

OpenMainMenu = function()
    Scene.cleanup()
    lib.registerContext({
        id = 'hype_scene_main',
        title = locale('title'),
        options = {
            {
                title = locale('main.spawn_vehicle'),
                icon = 'truck',
                arrow = true,
                onSelect = function() openSpawnMenu('hype_scene_vehicles', locale('main.spawn_vehicle'), Config.Vehicles, SpawnVehicle) end,
            },
            {
                title = locale('main.spawn_ped'),
                icon = 'user-plus',
                arrow = true,
                onSelect = function()
                    openSpawnMenu('hype_scene_peds', locale('main.spawn_ped'), Config.Peds, SpawnPed, {
                        title = locale('spawn.clone'),
                        description = locale('spawn.clone_desc'),
                        icon = 'clone',
                        onSelect = function()
                            local item = SpawnClone()
                            if item then OpenEntityMenu(item) end
                        end,
                    })
                end,
            },
            {
                title = locale('main.spawn_prop'),
                icon = 'box',
                arrow = true,
                onSelect = function() openSpawnMenu('hype_scene_props', locale('main.spawn_prop'), Config.Props, SpawnProp) end,
            },
            {
                title = locale('main.entities', #Scene.entities),
                icon = 'list',
                arrow = true,
                onSelect = OpenEntityList,
            },
            {
                title = locale('main.select_looked'),
                description = locale('main.select_looked_desc'),
                icon = 'crosshairs',
                onSelect = selectLookedAt,
            },
            {
                title = locale('main.self_anim'),
                description = locale('main.self_anim_desc'),
                icon = 'person-walking',
                arrow = true,
                onSelect = function() OpenAnimMenu(cache.ped, nil, 'hype_scene_main') end,
            },
            {
                title = locale('main.cinema'),
                description = locale('main.cinema_desc'),
                icon = 'video',
                arrow = true,
                onSelect = openCinemaMenu,
            },
            {
                title = locale('main.scenes'),
                description = locale('main.scenes_desc'),
                icon = 'film',
                arrow = true,
                onSelect = OpenScenesMenu,
            },
            {
                title = locale('main.delete_all'),
                description = locale('main.delete_all_desc'),
                icon = 'trash',
                iconColor = '#ef4444',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = locale('main.delete_all'),
                        content = locale('main.delete_all_confirm'),
                        centered = true,
                        cancel = true,
                    })
                    if confirm == 'confirm' then
                        Scene.clear()
                        Notify(locale('main.cleared'), 'success')
                    end
                end,
            },
        },
    })
    lib.showContext('hype_scene_main')
end

local function open()
    if IsEditing() then return end
    if not lib.callback.await('hype-scenetool:server:canUse', false) then
        return Notify(locale('common.no_permission'), 'error')
    end
    OpenMainMenu()
end

RegisterCommand(Config.Command, open, false)

if Config.Keybind then
    lib.addKeybind({
        name = 'hype_scenetool',
        description = locale('keybind.open'),
        defaultKey = Config.Keybind,
        onPressed = open,
    })
end

lib.addKeybind({
    name = 'hype_scenetool_timestop',
    description = locale('keybind.timestop'),
    defaultKey = Config.TimeStop.key,
    onPressed = function()
        if not Cinema.timeStopped and not lib.callback.await('hype-scenetool:server:canUse', false) then
            return Notify(locale('common.no_permission'), 'error')
        end
        Cinema.toggleTimeStop()
    end,
})
