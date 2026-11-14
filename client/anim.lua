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
        return Notify(locale('error.anim_not_found', anim.dict), 'error')
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

local function flagOptions()
    return {
        { value = '1', label = locale('anim.flag_loop') },
        { value = '49', label = locale('anim.flag_loop_upper') },
        { value = '0', label = locale('anim.flag_once') },
        { value = '48', label = locale('anim.flag_once_upper') },
        { value = '2', label = locale('anim.flag_hold') },
    }
end

--- item is nil when the target is your own character.
function OpenAnimMenu(ped, item, parent)
    local options = {
        {
            title = locale('anim.stop'),
            icon = 'stop',
            onSelect = function()
                StopActivity(ped, item)
                OpenAnimMenu(ped, item, parent)
            end,
        },
        {
            title = locale('anim.custom'),
            description = locale('anim.custom_desc'),
            icon = 'keyboard',
            onSelect = function()
                local input = lib.inputDialog(locale('anim.custom'), {
                    { type = 'input', label = 'Dict', placeholder = 'anim@heists@box_carry@', required = true },
                    { type = 'input', label = 'Clip', placeholder = 'idle', required = true },
                    { type = 'select', label = locale('anim.playback'), options = flagOptions(), default = '1', required = true },
                })
                if input then
                    PlayAnim(ped, { dict = input[1], clip = input[2], flag = tonumber(input[3]) }, item)
                end
                OpenAnimMenu(ped, item, parent)
            end,
        },
        {
            title = locale('anim.custom_scenario'),
            description = locale('anim.custom_scenario_desc'),
            icon = 'keyboard',
            onSelect = function()
                local input = lib.inputDialog(locale('anim.custom_scenario'), {
                    { type = 'input', label = locale('anim.scenario_name'), required = true },
                })
                if input then PlayScenario(ped, input[1]:upper(), item) end
                OpenAnimMenu(ped, item, parent)
            end,
        },
    }

    for _, anim in ipairs(Config.Animations) do
        options[#options + 1] = {
            title = Label(anim.label),
            description = anim.prop and locale('anim.with_prop') or anim.talk and locale('anim.talking') or nil,
            icon = 'person-walking',
            onSelect = function()
                PlayAnim(ped, anim, item)
                OpenAnimMenu(ped, item, parent)
            end,
        }
    end

    for _, scenario in ipairs(Config.Scenarios) do
        options[#options + 1] = {
            title = Label(scenario.label),
            description = locale('anim.scenario'),
            icon = 'clapperboard',
            onSelect = function()
                PlayScenario(ped, scenario.name, item)
                OpenAnimMenu(ped, item, parent)
            end,
        }
    end

    lib.registerContext({
        id = 'hype_scene_anim',
        title = item and locale('anim.title', Label(item.label)) or locale('anim.title_self'),
        menu = parent,
        options = options,
    })
    lib.showContext('hype_scene_anim')
end
