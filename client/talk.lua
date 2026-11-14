Talk = {
    lipSync = false,    -- mouths of talking players move (voice chat), switched on from the menu
    gestures = false,   -- your hands move while you talk
    selfAnim = false,   -- set while a scene animation plays on you, gestures wait for it
}

local FACIAL_DICT, FACIAL_TALK = 'mp_facial', 'mic_chatter'
local IDLE_DICT, IDLE_FACE = 'facials@gen_male@variations@normal', 'mood_normal_1'
local talkingPeds = {}  -- [ped] = true for NPCs playing a talking animation
local running = false

local function talk(ped) PlayFacialAnim(ped, FACIAL_TALK, FACIAL_DICT) end
local function idle(ped) PlayFacialAnim(ped, IDLE_FACE, IDLE_DICT) end

local function shouldRun()
    return Talk.lipSync or Talk.gestures or next(talkingPeds) ~= nil
end

local function run()
    if running or not shouldRun() then return end
    running = true

    CreateThread(function()
        pcall(lib.requestAnimDict, FACIAL_DICT, 5000)
        pcall(lib.requestAnimDict, IDLE_DICT, 5000)
        pcall(lib.requestAnimDict, Config.Talk.gestureDict, 5000)

        local playerState = {}  -- [serverId] = { talking, refreshed }
        local gestureClip, nextGesture = nil, 0

        while shouldRun() do
            Wait(100)
            local now = GetGameTimer()
            local myCoords = GetEntityCoords(cache.ped)

            -- lip sync for players talking in voice chat
            if Talk.lipSync then
                for _, player in ipairs(GetActivePlayers()) do
                    local ped = GetPlayerPed(player)
                    local id = GetPlayerServerId(player)
                    if #(GetEntityCoords(ped) - myCoords) <= Config.Talk.lipSyncDistance then
                        local talking = NetworkIsPlayerTalking(player)
                        local state = playerState[id]
                        if not state or state.talking ~= talking or (talking and now - state.refreshed > 3000) then
                            if talking then talk(ped) else idle(ped) end
                            playerState[id] = { talking = talking, refreshed = now }
                        end
                    end
                end
            end

            -- NPCs with a talking animation keep moving their lips
            for ped, refreshed in pairs(talkingPeds) do
                if not DoesEntityExist(ped) then
                    talkingPeds[ped] = nil
                elseif now - refreshed > 3000 then
                    talk(ped)
                    talkingPeds[ped] = now
                end
            end

            -- hand gestures for yourself while you talk
            if Talk.gestures and not Talk.selfAnim and not IsEditing()
                and NetworkIsPlayerTalking(PlayerId())
                and not IsPedInAnyVehicle(cache.ped, false)
                and not IsPedUsingAnyScenario(cache.ped)
                and not IsPedRagdoll(cache.ped) then
                local busy = gestureClip and IsEntityPlayingAnim(cache.ped, Config.Talk.gestureDict, gestureClip, 3)
                if not busy and now >= nextGesture then
                    local clips = Config.Talk.gestures
                    local clip = clips[math.random(#clips)]
                    for _ = 1, 3 do  -- avoid the same gesture twice in a row
                        if clip ~= gestureClip then break end
                        clip = clips[math.random(#clips)]
                    end
                    gestureClip = clip
                    TaskPlayAnim(cache.ped, Config.Talk.gestureDict, clip, 4.0, -4.0, -1, 48, 0.0, false, false, false)
                    nextGesture = now + math.random(Config.Talk.pause[1], Config.Talk.pause[2])
                elseif busy then
                    nextGesture = now + math.random(Config.Talk.pause[1], Config.Talk.pause[2])
                end
            elseif gestureClip and not NetworkIsPlayerTalking(PlayerId()) then
                -- stop mid-gesture when you stop talking
                if IsEntityPlayingAnim(cache.ped, Config.Talk.gestureDict, gestureClip, 3) then
                    StopAnimTask(cache.ped, Config.Talk.gestureDict, gestureClip, 2.0)
                end
                gestureClip = nil
            end
        end

        running = false
    end)
end

function SetPedTalking(ped, enabled)
    if ped == cache.ped then return end
    talkingPeds[ped] = enabled and GetGameTimer() or nil
    if enabled then talk(ped) end
    run()
end

function Talk.toggleLipSync()
    Talk.lipSync = not Talk.lipSync
    run()
end

function Talk.toggleGestures()
    Talk.gestures = not Talk.gestures
    run()
    Notify(Talk.gestures and 'Konuşurken el hareketi açık' or 'Konuşurken el hareketi kapalı',
        Talk.gestures and 'success' or 'inform')
end

-- harmless, so every actor can switch it on without the tool permission
RegisterCommand(Config.Talk.command, Talk.toggleGestures, false)

CreateThread(run)
