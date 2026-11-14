local OpenMainMenu, OpenEntityMenu, OpenEntityList

local function input(title, rows)
    return lib.inputDialog(title, rows)
end

--- Picker list of presets plus a free model field. spawn(model, label) is called with the choice.
local function openSpawnMenu(id, title, presets, spawn, extra)
    local options = extra and { extra } or {}

    options[#options + 1] = {
        title = 'Model adı yaz',
        description = 'Oyundaki ya da sunucuya eklenmiş herhangi bir model',
        icon = 'keyboard',
        onSelect = function()
            local result = input(title, { { type = 'input', label = 'Model', required = true } })
            if result then
                local item = spawn(result[1], result[1])
                if item then return OpenEntityMenu(item) end
            end
            lib.showContext(id)
        end,
    }

    for _, preset in ipairs(presets) do
        options[#options + 1] = {
            title = preset.label,
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
    local options = { { value = '-1', label = 'Sürücü' } }
    for seat = 0, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        options[#options + 1] = { value = tostring(seat), label = ('Yolcu %d'):format(seat + 1) }
    end
    return options
end

local function chooseSeat(vehicle)
    local result = input('Koltuk seç', {
        { type = 'select', label = 'Koltuk', options = seatOptions(vehicle), default = '-1', required = true },
    })
    return result and tonumber(result[1])
end

local function waypoint()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then
        Notify('Önce haritada bir waypoint işaretle', 'error')
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
        { type = 'number', label = 'Yön (heading)', default = r.z, precision = 2, step = 1, required = true },
    }
    if item.kind ~= 'ped' then
        rows[#rows + 1] = { type = 'number', label = 'Eğim (pitch)', default = r.x, precision = 2, step = 1 }
        rows[#rows + 1] = { type = 'number', label = 'Yatış (roll)', default = r.y, precision = 2, step = 1 }
    end

    local result = input('Konum ve rotasyon', rows)
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
            title = 'Bin',
            description = 'Seçtiğin koltuğa ışınlan',
            icon = 'car-side',
            onSelect = function()
                local seat = chooseSeat(vehicle)
                if seat then TaskWarpPedIntoVehicle(cache.ped, vehicle, seat) end
            end,
        },
        {
            title = 'Dorse bağla',
            description = 'Tırın arkasına dorse oluşturup bağlar',
            icon = 'trailer',
            onSelect = function()
                local options = {}
                for _, trailer in ipairs(Config.Trailers) do
                    options[#options + 1] = { value = trailer.model, label = trailer.label }
                end
                local result = input('Dorse bağla', {
                    { type = 'select', label = 'Dorse', options = options, required = true, searchable = true },
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
            title = 'Motor aç / kapa',
            icon = 'power-off',
            onSelect = function()
                RequestControl(vehicle)
                SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), true, true)
                reopen()
            end,
        },
        {
            title = 'Farlar',
            icon = 'lightbulb',
            onSelect = function()
                local result = input('Farlar', {
                    { type = 'select', label = 'Durum', required = true, default = '2', options = {
                        { value = '1', label = 'Kapalı' },
                        { value = '2', label = 'Açık' },
                        { value = '3', label = 'Uzun far' },
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
            title = 'Korna çal',
            description = '2 saniye',
            icon = 'bullhorn',
            onSelect = function()
                StartVehicleHorn(vehicle, 2000, joaat('HELDDOWN'), false)
                reopen()
            end,
        },
        {
            title = 'Kapılar',
            icon = 'door-open',
            onSelect = function()
                local doors = {
                    { value = '0', label = 'Sol ön' }, { value = '1', label = 'Sağ ön' },
                    { value = '2', label = 'Sol arka' }, { value = '3', label = 'Sağ arka' },
                    { value = '4', label = 'Kaput' }, { value = '5', label = 'Bagaj' },
                }
                local open = {}
                for i = 0, 5 do
                    if GetVehicleDoorAngleRatio(vehicle, i) > 0.1 then open[#open + 1] = tostring(i) end
                end
                local result = input('Açık kapılar', {
                    { type = 'multi-select', label = 'Kapılar', options = doors, default = open },
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
            title = 'Renk, plaka, livery',
            icon = 'palette',
            onSelect = function()
                local liveries = GetVehicleLiveryCount(vehicle)
                local result = input('Görünüm', {
                    { type = 'color', label = 'Ana renk', default = '#ffffff' },
                    { type = 'color', label = 'İkinci renk', default = '#ffffff' },
                    { type = 'input', label = 'Plaka', default = GetVehicleNumberPlateText(vehicle), max = 8 },
                    { type = 'number', label = ('Livery (0-%d)'):format(math.max(liveries - 1, 0)),
                      default = math.max(GetVehicleLivery(vehicle), 0), min = 0, max = math.max(liveries - 1, 0) },
                    { type = 'checkbox', label = 'Renkleri değiştir', checked = false },
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
            title = 'Kir ve hasar',
            icon = 'car-burst',
            onSelect = function()
                local result = input('Kir ve hasar', {
                    { type = 'slider', label = 'Kir', default = math.floor(GetVehicleDirtLevel(vehicle)), min = 0, max = 15 },
                    { type = 'select', label = 'Hasar', default = 'none', options = {
                        { value = 'none', label = 'Değiştirme' },
                        { value = 'fix', label = 'Tamir et' },
                        { value = 'light', label = 'Hafif hasar (ön)' },
                        { value = 'heavy', label = 'Ağır hasar' },
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
            title = 'Animasyon ve senaryo',
            icon = 'person-walking',
            arrow = true,
            onSelect = function() OpenAnimMenu(ped, item, 'hype_scene_entity') end,
        },
        {
            title = 'Araca bindir',
            description = 'Sahnedeki bir araca ışınlar',
            icon = 'car-side',
            onSelect = function()
                local vehicles = Scene.vehicles()
                if #vehicles == 0 then
                    Notify('Sahnede araç yok', 'error')
                    return reopen()
                end
                local options = {}
                for _, vehicleItem in ipairs(vehicles) do
                    options[#options + 1] = { value = tostring(vehicleItem.id), label = ('#%d %s'):format(vehicleItem.id, vehicleItem.label) }
                end
                local result = input('Araca bindir', {
                    { type = 'select', label = 'Araç', options = options, required = true },
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
            title = 'Araçtan in',
            icon = 'right-from-bracket',
            onSelect = function()
                RequestControl(ped)
                TaskLeaveAnyVehicle(ped, 0, 0)
                reopen()
            end,
        },
        {
            title = "Waypoint'e sür",
            description = 'NPC sürücü koltuğundaysa haritadaki noktaya gider',
            icon = 'route',
            onSelect = function()
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
                    Notify('NPC bir aracın sürücü koltuğunda olmalı', 'error')
                    return reopen()
                end
                local target = waypoint()
                if target then
                    local result = input("Waypoint'e sür", {
                        { type = 'number', label = 'Hız (km/s)', default = math.floor(Config.Drive.speed * 3.6), min = 5, max = 200 },
                    })
                    if result then
                        RequestControl(ped)
                        RequestControl(vehicle)
                        FreezeEntityPosition(vehicle, false)
                        SetVehicleEngineOn(vehicle, true, true, false)
                        TaskVehicleDriveToCoordLongrange(ped, vehicle, target.x, target.y, target.z,
                            result[1] / 3.6, Config.Drive.style, 10.0)
                        Notify('NPC yola çıktı', 'success')
                    end
                end
                reopen()
            end,
        },
        {
            title = 'Rastgele dolaş',
            description = 'Araçtaysa trafikte sürer, yayaysa yürür',
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
            title = "Waypoint'e yürü",
            icon = 'person-walking-arrow-right',
            onSelect = function()
                local target = waypoint()
                if target then
                    local result = input("Waypoint'e yürü", {
                        { type = 'select', label = 'Hız', default = '1.0', options = {
                            { value = '1.0', label = 'Yürü' }, { value = '2.0', label = 'Koş' }, { value = '3.0', label = 'Depar' },
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
            title = 'Beni takip et',
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
            title = 'Bana dön',
            icon = 'arrows-rotate',
            onSelect = function()
                RequestControl(ped)
                local a, b = GetEntityCoords(ped), GetEntityCoords(cache.ped)
                SetEntityHeading(ped, GetHeadingFromVector_2d(b.x - a.x, b.y - a.y))
                reopen()
            end,
        },
        {
            title = 'Görevi durdur',
            icon = 'hand',
            onSelect = function()
                StopActivity(ped, item)
                reopen()
            end,
        },
        {
            title = 'Rastgele kıyafet',
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
        Notify('Varlık artık yok', 'error')
        return OpenEntityList()
    end

    local entity = item.handle
    local reopen = function() OpenEntityMenu(item) end
    local options = {
        {
            title = 'Konumu düzenle',
            description = 'Klavyeyle taşı ve döndür',
            icon = 'up-down-left-right',
            onSelect = function() StartEditor(item, reopen) end,
        },
        {
            title = 'Koordinat gir',
            description = 'X, Y, Z ve rotasyonu elle yaz',
            icon = 'crosshairs',
            onSelect = function()
                exactTransform(item)
                reopen()
            end,
        },
        {
            title = 'Önüme getir',
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
            title = item.frozen and 'Sabitlemeyi kaldır' or 'Sabitle',
            description = 'Sabitlenen varlık fizikten etkilenmez, yerinden oynamaz',
            icon = item.frozen and 'lock-open' or 'lock',
            onSelect = function()
                RequestControl(entity)
                item.frozen = not item.frozen
                FreezeEntityPosition(entity, item.frozen)
                reopen()
            end,
        },
        {
            title = 'Koordinatı kopyala',
            icon = 'copy',
            onSelect = function()
                local coords, rot = FormatTransform(entity)
                lib.setClipboard(('%s -- rot %s'):format(coords, rot))
                Notify('Panoya kopyalandı', 'success')
                reopen()
            end,
        },
    }

    local extra = item.kind == 'vehicle' and vehicleOptions(item) or item.kind == 'ped' and pedOptions(item) or {}
    for _, option in ipairs(extra) do options[#options + 1] = option end

    options[#options + 1] = {
        title = 'Sil',
        icon = 'trash',
        iconColor = '#ef4444',
        onSelect = function()
            Scene.remove(item)
            OpenEntityList()
        end,
    }

    lib.registerContext({
        id = 'hype_scene_entity',
        title = ('#%d %s'):format(item.id, item.label),
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
            title = ('#%d %s'):format(item.id, item.label),
            description = ('%.0f m uzakta%s%s'):format(#(coords - GetEntityCoords(cache.ped)),
                item.frozen and ' · sabit' or '', item.owned and '' or ' · dünyadan seçildi'),
            icon = icons[item.kind],
            arrow = true,
            onSelect = function() OpenEntityMenu(item) end,
        }
    end

    if #options == 0 then
        options[1] = { title = 'Sahnede hiçbir şey yok', disabled = true }
    end

    lib.registerContext({ id = 'hype_scene_entities', title = 'Sahnedeki varlıklar', menu = 'hype_scene_main', options = options })
    lib.showContext('hype_scene_entities')
end

local function selectLookedAt()
    local hit, entity = lib.raycast.fromCamera(2 | 4 | 8 | 16, 4, 40.0)
    if not hit or not entity or entity == 0 or not DoesEntityExist(entity) then
        return Notify('Baktığın yerde araç, NPC ya da obje yok', 'error')
    end

    local kind = GetEntityKind(entity)
    if not kind then return Notify('Bu varlık seçilemez', 'error') end
    if kind == 'ped' and IsPedAPlayer(entity) then return Notify('Oyuncular seçilemez', 'error') end

    local item = Scene.find(entity)
        or Scene.add(entity, kind, GetEntityModel(entity), ('Seçilen %s'):format(kind == 'ped' and 'NPC' or kind == 'vehicle' and 'araç' or 'obje'), false)
    OpenEntityMenu(item)
end

local function openCinemaMenu()
    local weatherOptions = {}
    for _, weather in ipairs(Config.Weathers) do weatherOptions[#weatherOptions + 1] = { value = weather, label = weather } end

    lib.registerContext({
        id = 'hype_scene_cinema',
        title = 'Çekim ayarları',
        menu = 'hype_scene_main',
        options = {
            {
                title = Cinema.hideHud and 'HUD ve haritayı göster' or 'HUD ve haritayı gizle',
                description = 'Oyunun kendi HUD’u. Sunucunun özel HUD’u ayrıca kapatılmalı',
                icon = 'eye-slash',
                onSelect = function() Cinema.toggleHud() openCinemaMenu() end,
            },
            {
                title = Cinema.noTraffic and 'Trafiği ve yayaları aç' or 'Trafiği ve yayaları kapat',
                description = 'Sadece senin ekranında. Temiz çekim için',
                icon = 'road',
                onSelect = function() Cinema.toggleTraffic() openCinemaMenu() end,
            },
            {
                title = Cinema.timeStopped and 'Zamanı devam ettir' or 'Zamanı durdur',
                description = ('%dm içindeki NPC, araç ve sahne objeleri olduğu yerde donar, sen serbestsin. Kısayol: Ayarlar > Tuş Atamaları > FiveM'):format(math.floor(Config.TimeStop.radius)),
                icon = Cinema.timeStopped and 'play' or 'pause',
                onSelect = function() Cinema.toggleTimeStop() openCinemaMenu() end,
            },
            {
                title = Talk.gestures and 'Konuşurken el hareketi: Açık' or 'Konuşurken el hareketi: Kapalı',
                description = ('Sesli sohbette konuşunca ellerin hareket eder. Herkes /%s ile kendisi için açabilir'):format(Config.Talk.command),
                icon = 'hands',
                onSelect = function() Talk.toggleGestures() openCinemaMenu() end,
            },
            {
                title = Talk.lipSync and 'Dudak senkronu: Açık' or 'Dudak senkronu: Kapalı',
                description = 'Konuşan oyuncuların ağzı oynar (senin ekranında)',
                icon = 'comment-dots',
                onSelect = function() Talk.toggleLipSync() openCinemaMenu() end,
            },
            {
                title = 'Etrafı temizle',
                description = 'Yakındaki NPC ve trafik araçlarını kaldırır (sahne ve oyuncu araçları kalır)',
                icon = 'broom',
                onSelect = function()
                    local result = input('Etrafı temizle', { { type = 'slider', label = 'Yarıçap (m)', default = 50, min = 10, max = 200 } })
                    if result then Cinema.clearArea(result[1] + 0.0) end
                    openCinemaMenu()
                end,
            },
            {
                title = 'Saat',
                description = Cinema.time and ('%02d:%02d sabit'):format(Cinema.time.hour, Cinema.time.minute) or 'Sunucu saati',
                icon = 'clock',
                onSelect = function()
                    local result = input('Saat', {
                        { type = 'slider', label = 'Saat', default = Cinema.time and Cinema.time.hour or GetClockHours(), min = 0, max = 23 },
                        { type = 'slider', label = 'Dakika', default = Cinema.time and Cinema.time.minute or 0, min = 0, max = 59, step = 5 },
                    })
                    if result then Cinema.setTime(result[1], result[2]) end
                    openCinemaMenu()
                end,
            },
            {
                title = 'Hava durumu',
                description = Cinema.weather or 'Sunucu havası',
                icon = 'cloud-sun',
                onSelect = function()
                    local result = input('Hava durumu', { { type = 'select', label = 'Hava', options = weatherOptions, required = true } })
                    if result then Cinema.setWeather(result[1]) end
                    openCinemaMenu()
                end,
            },
            {
                title = 'Saat ve havayı sunucuya bağla',
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
        title = 'Sahne Aracı',
        options = {
            {
                title = 'Araç oluştur',
                icon = 'truck',
                arrow = true,
                onSelect = function() openSpawnMenu('hype_scene_vehicles', 'Araç oluştur', Config.Vehicles, SpawnVehicle) end,
            },
            {
                title = 'NPC oluştur',
                icon = 'user-plus',
                arrow = true,
                onSelect = function()
                    openSpawnMenu('hype_scene_peds', 'NPC oluştur', Config.Peds, SpawnPed, {
                        title = 'Kendi kopyam',
                        description = 'Karakterinin aynısı. Tek kişiyle iki rolü çekmek için',
                        icon = 'clone',
                        onSelect = function()
                            local item = SpawnClone()
                            if item then OpenEntityMenu(item) end
                        end,
                    })
                end,
            },
            {
                title = 'Obje oluştur',
                icon = 'box',
                arrow = true,
                onSelect = function() openSpawnMenu('hype_scene_props', 'Obje oluştur', Config.Props, SpawnProp) end,
            },
            {
                title = ('Sahnedeki varlıklar (%d)'):format(#Scene.entities),
                icon = 'list',
                arrow = true,
                onSelect = OpenEntityList,
            },
            {
                title = 'Baktığımı seç',
                description = 'Nişangahın üstündeki araç, NPC ya da objeyi düzenle',
                icon = 'crosshairs',
                onSelect = selectLookedAt,
            },
            {
                title = 'Bana animasyon',
                description = 'Kendi karakterinde animasyon ve senaryo oynat',
                icon = 'person-walking',
                arrow = true,
                onSelect = function() OpenAnimMenu(cache.ped, nil, 'hype_scene_main') end,
            },
            {
                title = 'Çekim ayarları',
                description = 'HUD, trafik, saat ve hava',
                icon = 'video',
                arrow = true,
                onSelect = openCinemaMenu,
            },
            {
                title = 'Sahneler',
                description = 'Kaydet ve sonra aynen geri yükle',
                icon = 'film',
                arrow = true,
                onSelect = OpenScenesMenu,
            },
            {
                title = 'Hepsini sil',
                description = 'Araçtan oluşturduğun her şeyi siler',
                icon = 'trash',
                iconColor = '#ef4444',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Hepsini sil',
                        content = 'Oluşturduğun bütün araç, NPC ve objeler silinsin mi?',
                        centered = true,
                        cancel = true,
                    })
                    if confirm == 'confirm' then
                        Scene.clear()
                        Notify('Sahne temizlendi', 'success')
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
        return Notify('Bu aracı kullanma yetkin yok', 'error')
    end
    OpenMainMenu()
end

RegisterCommand(Config.Command, open, false)

if Config.Keybind then
    lib.addKeybind({
        name = 'hype_scenetool',
        description = 'Sahne aracını aç',
        defaultKey = Config.Keybind,
        onPressed = open,
    })
end

lib.addKeybind({
    name = 'hype_scenetool_timestop',
    description = 'Sahne aracı: zamanı durdur / devam ettir',
    defaultKey = Config.TimeStop.key,
    onPressed = function()
        if not Cinema.timeStopped and not lib.callback.await('hype-scenetool:server:canUse', false) then
            return Notify('Bu aracı kullanma yetkin yok', 'error')
        end
        Cinema.toggleTimeStop()
    end,
})
