local function v3(v) return { x = v.x, y = v.y, z = v.z } end

local function serializeActivity(activity)
    if not activity then return end
    if activity.type == 'scenario' then return { type = 'scenario', name = activity.name } end

    local anim = activity.anim
    local data = { dict = anim.dict, clip = anim.clip, flag = anim.flag, talk = anim.talk }
    if anim.prop then
        data.prop = { model = anim.prop.model, bone = anim.prop.bone, pos = v3(anim.prop.pos), rot = v3(anim.prop.rot) }
    end
    return { type = 'anim', anim = data }
end

function SerializeScene()
    Scene.cleanup()
    local list, indexOf = {}, {}

    for _, item in ipairs(Scene.entities) do
        if item.owned then
            list[#list + 1] = item
            indexOf[item.handle] = #list
        end
    end

    local data = {}
    for i, item in ipairs(list) do
        local entity = item.handle
        local entry = {
            kind = item.kind,
            model = GetEntityModel(entity),
            label = item.label,
            coords = v3(GetEntityCoords(entity)),
            rot = v3(GetEntityRotation(entity, 2)),
            frozen = item.frozen,
        }

        if item.kind == 'vehicle' then
            entry.props = lib.getVehicleProperties(entity)
            entry.engine = GetIsVehicleEngineRunning(entity)
            entry.trailerOf = item.trailerOf and indexOf[item.trailerOf]
        elseif item.kind == 'ped' then
            entry.clone = item.clone
            entry.activity = serializeActivity(item.activity)
            local vehicle = GetVehiclePedIsIn(entity, false)
            if vehicle ~= 0 and indexOf[vehicle] then
                entry.vehicle = indexOf[vehicle]
                for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                    if GetPedInVehicleSeat(vehicle, seat) == entity then entry.seat = seat break end
                end
            end
        end

        data[i] = entry
    end

    return data
end

function LoadScene(data)
    local spawned = {}

    for i, entry in ipairs(data) do
        local c = entry.coords
        local point = vec4(c.x, c.y, c.z, entry.rot.z)
        local item

        if entry.kind == 'vehicle' then
            item = SpawnVehicle(entry.model, entry.label, point)
            if item and entry.props then lib.setVehicleProperties(item.handle, entry.props) end
            if item and entry.engine then SetVehicleEngineOn(item.handle, true, true, false) end
        elseif entry.kind == 'ped' then
            item = entry.clone and SpawnClone(point) or SpawnPed(entry.model, entry.label, point)
        else
            item = SpawnProp(entry.model, entry.label, point)
        end

        if item then
            local entity = item.handle
            SetEntityCoordsNoOffset(entity, c.x, c.y, c.z, false, false, false)
            if entry.kind == 'ped' then
                SetEntityHeading(entity, entry.rot.z)
            else
                SetEntityRotation(entity, entry.rot.x, entry.rot.y, entry.rot.z, 2, true)
            end
            item.frozen = entry.frozen and true or false
            FreezeEntityPosition(entity, item.frozen)
            spawned[i] = item
        end
    end

    -- second pass: links between entities
    for i, entry in ipairs(data) do
        local item = spawned[i]
        if item then
            if entry.trailerOf and spawned[entry.trailerOf] then
                AttachVehicleToTrailer(spawned[entry.trailerOf].handle, item.handle, 1.1)
                item.trailerOf = spawned[entry.trailerOf].handle
            end
            if entry.vehicle and spawned[entry.vehicle] then
                TaskWarpPedIntoVehicle(item.handle, spawned[entry.vehicle].handle, entry.seat or -1)
            end
        end
    end

    Wait(250)
    for i, entry in ipairs(data) do
        if spawned[i] and entry.activity then ApplyActivity(spawned[i].handle, entry.activity, spawned[i]) end
    end

    return #data
end

function OpenScenesMenu()
    local scenes = lib.callback.await('hype-scenetool:server:listScenes', false) or {}

    local options = {
        {
            title = 'Sahneyi kaydet',
            description = 'Oluşturduğun her şey konumu, rengi ve animasyonuyla kaydedilir',
            icon = 'floppy-disk',
            onSelect = function()
                local input = lib.inputDialog('Sahneyi kaydet', {
                    { type = 'input', label = 'Sahne adı', description = 'Harf, rakam, - ve _', required = true, max = 32 },
                })
                if not input then return OpenScenesMenu() end

                local data = SerializeScene()
                if #data == 0 then
                    Notify('Kaydedilecek bir şey yok', 'error')
                    return OpenScenesMenu()
                end

                local ok, err = lib.callback.await('hype-scenetool:server:saveScene', false, input[1], data)
                Notify(ok and ('Sahne kaydedildi: %s'):format(input[1]) or ('Kaydedilemedi: %s'):format(err or '?'),
                    ok and 'success' or 'error')
                OpenScenesMenu()
            end,
        },
    }

    for _, scene in ipairs(scenes) do
        options[#options + 1] = {
            title = scene.name,
            description = ('%d varlık · %s'):format(scene.count or 0, scene.date or ''),
            icon = 'film',
            arrow = true,
            onSelect = function()
                lib.registerContext({
                    id = 'hype_scene_saved',
                    title = scene.name,
                    menu = 'hype_scene_list',
                    options = {
                        {
                            title = 'Yükle',
                            description = 'Varlıklar kaydedildikleri yerde oluşur',
                            icon = 'play',
                            onSelect = function()
                                local data = lib.callback.await('hype-scenetool:server:loadScene', false, scene.name)
                                if not data then return Notify('Sahne okunamadı', 'error') end
                                Notify(('%d varlık yüklendi'):format(LoadScene(data)), 'success')
                            end,
                        },
                        {
                            title = 'Sil',
                            icon = 'trash',
                            iconColor = '#ef4444',
                            onSelect = function()
                                local confirm = lib.alertDialog({
                                    header = 'Sahneyi sil',
                                    content = ('**%s** kalıcı olarak silinsin mi?'):format(scene.name),
                                    centered = true,
                                    cancel = true,
                                })
                                if confirm == 'confirm' then
                                    lib.callback.await('hype-scenetool:server:deleteScene', false, scene.name)
                                    Notify('Sahne silindi', 'success')
                                end
                                OpenScenesMenu()
                            end,
                        },
                    },
                })
                lib.showContext('hype_scene_saved')
            end,
        }
    end

    lib.registerContext({ id = 'hype_scene_list', title = 'Kayıtlı sahneler', menu = 'hype_scene_main', options = options })
    lib.showContext('hype_scene_list')
end
