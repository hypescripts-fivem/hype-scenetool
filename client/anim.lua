local pedProps = {} -- [ped] = object held in the hand

function DetachPedProp(ped)
    local object = pedProps[ped]
    if not object then return end
    pedProps[ped] = nil
    if DoesEntityExist(object) then
        SetEntityAsMissionEntity(object, true, true)
        DeleteEntity(object)
    end
end

local function attachProp(ped, prop)
    local hash = LoadModel(prop.model)
    if not hash then return end

    local coords = GetEntityCoords(ped)
    local object = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, false)
    SetModelAsNoLongerNeeded(hash)
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, prop.bone),
        prop.pos.x, prop.pos.y, prop.pos.z, prop.rot.x, prop.rot.y, prop.rot.z,
        true, true, false, true, 1, true)
    pedProps[ped] = object
end

function StopActivity(ped, item)
    DetachPedProp(ped)
    RequestControl(ped)
    ClearPedTasks(ped) -- not the Immediately variant, so a seated ped stays in the vehicle
    SetPedTalking(ped, false)
    if ped == cache.ped then Talk.selfAnim = false end
    if item then item.activity = nil end
end

--- anim = { dict, clip, flag, prop? }
function PlayAnim(ped, anim, item)
    if not pcall(lib.requestAnimDict, anim.dict, 5000) then
        return Notify(('Animasyon bulunamadı: %s'):format(anim.dict), 'error')
    end

    DetachPedProp(ped)
    TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, anim.flag or 1, 0.0, false, false, false)
    if anim.prop then attachProp(ped, anim.prop) end
    SetPedTalking(ped, anim.talk)
    if ped == cache.ped then Talk.selfAnim = true end

    if item then item.activity = { type = 'anim', anim = anim } end
end

function PlayScenario(ped, name, item)
    DetachPedProp(ped)
    ClearPedTasks(ped)
    SetPedTalking(ped, false)
    TaskStartScenarioInPlace(ped, name, 0, true)
    if item then item.activity = { type = 'scenario', name = name } end
end

function ApplyActivity(ped, activity, item)
    if not activity then return end
    if activity.type == 'anim' then
        -- vectors come back from json as plain tables
        local anim = activity.anim
        if anim.prop then
            anim.prop.pos = vec3(anim.prop.pos.x, anim.prop.pos.y, anim.prop.pos.z)
            anim.prop.rot = vec3(anim.prop.rot.x, anim.prop.rot.y, anim.prop.rot.z)
        end
        PlayAnim(ped, anim, item)
    elseif activity.type == 'scenario' then
        PlayScenario(ped, activity.name, item)
    end
end

local flagOptions = {
    { value = '1', label = 'Döngü (tüm vücut)' },
    { value = '49', label = 'Döngü (üst gövde, yürüyebilir)' },
    { value = '0', label = 'Bir kez' },
    { value = '48', label = 'Bir kez (üst gövde)' },
    { value = '2', label = 'Bir kez, son karede kal' },
}

--- item is nil when the target is your own character.
function OpenAnimMenu(ped, item, parent)
    local options = {
        {
            title = 'Durdur',
            icon = 'stop',
            onSelect = function()
                StopActivity(ped, item)
                OpenAnimMenu(ped, item, parent)
            end,
        },
        {
            title = 'Özel animasyon',
            description = 'Dict ve clip adını kendin yaz',
            icon = 'keyboard',
            onSelect = function()
                local input = lib.inputDialog('Özel animasyon', {
                    { type = 'input', label = 'Dict', placeholder = 'anim@heists@box_carry@', required = true },
                    { type = 'input', label = 'Clip', placeholder = 'idle', required = true },
                    { type = 'select', label = 'Oynatma', options = flagOptions, default = '1', required = true },
                })
                if input then
                    PlayAnim(ped, { dict = input[1], clip = input[2], flag = tonumber(input[3]) }, item)
                end
                OpenAnimMenu(ped, item, parent)
            end,
        },
        {
            title = 'Özel senaryo',
            description = 'Örn. WORLD_HUMAN_CLIPBOARD',
            icon = 'keyboard',
            onSelect = function()
                local input = lib.inputDialog('Özel senaryo', {
                    { type = 'input', label = 'Senaryo adı', required = true },
                })
                if input then PlayScenario(ped, input[1]:upper(), item) end
                OpenAnimMenu(ped, item, parent)
            end,
        },
    }

    for _, anim in ipairs(Config.Animations) do
        options[#options + 1] = {
            title = anim.label,
            description = anim.prop and 'Elinde obje ile' or anim.talk and 'Konuşma, dudakları oynar' or nil,
            icon = 'person-walking',
            onSelect = function()
                PlayAnim(ped, anim, item)
                OpenAnimMenu(ped, item, parent)
            end,
        }
    end

    for _, scenario in ipairs(Config.Scenarios) do
        options[#options + 1] = {
            title = scenario.label,
            description = 'Senaryo',
            icon = 'clapperboard',
            onSelect = function()
                PlayScenario(ped, scenario.name, item)
                OpenAnimMenu(ped, item, parent)
            end,
        }
    end

    lib.registerContext({
        id = 'hype_scene_anim',
        title = item and ('Animasyon: %s'):format(item.label) or 'Animasyon: Ben',
        menu = parent,
        options = options,
    })
    lib.showContext('hype_scene_anim')
end
