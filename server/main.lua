local resource = GetCurrentResourceName()
local INDEX = 'scenes/index.json'
local MAX_SIZE = 512 * 1024

local function allowed(source)
    return not Config.Ace or IsPlayerAceAllowed(source, Config.Ace)
end

local function sanitize(name)
    if type(name) ~= 'string' then return end
    name = name:gsub('%s+', '_')
    if #name < 1 or #name > 32 or name:find('[^%w_%-]') then return end
    return name
end

local function readIndex()
    local ok, list = pcall(json.decode, LoadResourceFile(resource, INDEX) or '[]')
    return ok and type(list) == 'table' and list or {}
end

local function writeIndex(list)
    SaveResourceFile(resource, INDEX, json.encode(list), -1)
end

lib.callback.register('hype-scenetool:server:canUse', function(source)
    return allowed(source)
end)

lib.callback.register('hype-scenetool:server:listScenes', function(source)
    if not allowed(source) then return {} end
    return readIndex()
end)

lib.callback.register('hype-scenetool:server:saveScene', function(source, name, data)
    if not allowed(source) then return false, 'yetki yok' end
    name = sanitize(name)
    if not name then return false, 'geçersiz ad' end
    if type(data) ~= 'table' or #data == 0 then return false, 'boş sahne' end

    local ok, encoded = pcall(json.encode, data)
    if not ok or type(encoded) ~= 'string' then return false, 'sahne kodlanamadı' end
    if #encoded > MAX_SIZE then return false, 'sahne çok büyük' end
    if not SaveResourceFile(resource, ('scenes/%s.json'):format(name), encoded, -1) then
        return false, 'dosya yazılamadı'
    end

    local list = readIndex()
    for i = #list, 1, -1 do
        if list[i].name == name then table.remove(list, i) end
    end
    table.insert(list, 1, { name = name, count = #data, date = os.date('%d.%m.%Y %H:%M'), author = GetPlayerName(source) })
    writeIndex(list)
    return true
end)

lib.callback.register('hype-scenetool:server:loadScene', function(source, name)
    if not allowed(source) then return end
    name = sanitize(name)
    if not name then return end

    local ok, data = pcall(json.decode, LoadResourceFile(resource, ('scenes/%s.json'):format(name)) or '')
    return ok and type(data) == 'table' and data or nil
end)

lib.callback.register('hype-scenetool:server:deleteScene', function(source, name)
    if not allowed(source) then return false end
    name = sanitize(name)
    if not name then return false end

    pcall(os.remove, ('%s/scenes/%s.json'):format(GetResourcePath(resource), name))

    local list = readIndex()
    for i = #list, 1, -1 do
        if list[i].name == name then table.remove(list, i) end
    end
    writeIndex(list)
    return true
end)

-- keys for vehicles spawned by the tool, so the actors can drive them
local keyResources = { 'fast-vehiclekeysv2', 'qbx_vehiclekeys' }

RegisterNetEvent('hype-scenetool:server:giveKeys', function(netId)
    local source = source
    if not allowed(source) or type(netId) ~= 'number' then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end

    for _, name in ipairs(keyResources) do
        if GetResourceState(name) == 'started' then
            if pcall(function() exports[name]:GiveKeys(source, vehicle) end) then return end
        end
    end

    if GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerClientEvent('vehiclekeys:client:SetOwner', source, GetVehicleNumberPlateText(vehicle))
    end
end)
