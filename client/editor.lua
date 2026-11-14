local editing = false

local KEY = {
    forward = 32, back = 33, left = 34, right = 35,  -- W S A D
    down = 44, up = 38,                              -- Q E
    yawLeft = 174, yawRight = 175,                   -- arrow left / right
    pitchUp = 172, pitchDown = 173,                  -- arrow up / down
    rollLeft = 20, rollRight = 26,                   -- Z C
    fast = 21, slow = 36,                            -- Shift Ctrl
    ground = 47,                                     -- G
    crosshair = 74,                                  -- H
    resetRot = 45,                                   -- R
    freeze = 73,                                     -- X
    confirm = 191,                                   -- Enter
    cancel = 194,                                    -- Backspace
}

local HELP = table.concat({
    '**Düzenleme modu**',
    '[W/A/S/D] Taşı · [Q/E] Aşağı / Yukarı',
    '[←/→] Döndür · [↑/↓] Eğ · [Z/C] Yatır',
    '[Shift] Hızlı · [Ctrl] Yavaş',
    '[H] Baktığın yere taşı · [G] Yere oturt',
    '[R] Eğimi sıfırla · [X] Sabitle aç/kapa',
    '[Enter] Kaydet · [Backspace] İptal',
}, '  \n')

local function pressed(control) return IsDisabledControlPressed(0, control) end
local function justPressed(control) return IsDisabledControlJustPressed(0, control) end

local function groundZ(pos)
    local found, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.5, false)
    return found and z or pos.z
end

local function applyTransform(entity, isPed, pos, rot)
    SetEntityCoordsNoOffset(entity, pos.x, pos.y, pos.z, false, false, false)
    if isPed then
        SetEntityHeading(entity, rot.z)
    else
        SetEntityRotation(entity, rot.x, rot.y, rot.z, 2, true)
    end
end

function IsEditing() return editing end

function StartEditor(item, onDone)
    if editing then return end
    local entity = item.handle
    if not DoesEntityExist(entity) then return Notify('Varlık artık yok', 'error') end
    if item.kind == 'ped' and IsPedInAnyVehicle(entity, false) then
        return Notify('NPC araçta. Aracı düzenle ya da önce indir.', 'error')
    end
    if not RequestControl(entity) then return Notify('Varlığın kontrolü alınamadı', 'error') end

    editing = true
    local isPed = item.kind == 'ped'
    local startPos, startRot = GetEntityCoords(entity), GetEntityRotation(entity, 2)
    local pos, rot = startPos, startRot
    local _, maxDim = GetModelDimensions(GetEntityModel(entity))
    local markerHeight = maxDim.z + 0.6

    FreezeEntityPosition(entity, true)
    lib.showTextUI(HELP, { position = 'left-center' })

    CreateThread(function()
        local saved = false

        while editing do
            Wait(0)
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)   -- look
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 249, true) -- push to talk

            if not DoesEntityExist(entity) then break end

            local multiplier = pressed(KEY.fast) and Config.Editor.fastMultiplier
                or pressed(KEY.slow) and Config.Editor.slowMultiplier or 1.0
            local step = Config.Editor.moveStep * multiplier
            local turn = Config.Editor.rotateStep * multiplier

            -- movement follows the camera direction
            local yaw = math.rad(GetGameplayCamRot(2).z)
            local forward = vec3(-math.sin(yaw), math.cos(yaw), 0.0)
            local right = vec3(math.cos(yaw), math.sin(yaw), 0.0)
            local move = vec3(0.0, 0.0, 0.0)

            if pressed(KEY.forward) then move = move + forward end
            if pressed(KEY.back) then move = move - forward end
            if pressed(KEY.right) then move = move + right end
            if pressed(KEY.left) then move = move - right end
            if pressed(KEY.up) then move = move + vec3(0.0, 0.0, 1.0) end
            if pressed(KEY.down) then move = move - vec3(0.0, 0.0, 1.0) end
            pos = pos + move * step

            local rx, ry, rz = rot.x, rot.y, rot.z
            if pressed(KEY.yawLeft) then rz = rz + turn end
            if pressed(KEY.yawRight) then rz = rz - turn end
            if not isPed then
                if pressed(KEY.pitchUp) then rx = rx + turn end
                if pressed(KEY.pitchDown) then rx = rx - turn end
                if pressed(KEY.rollLeft) then ry = ry - turn end
                if pressed(KEY.rollRight) then ry = ry + turn end
            end
            if justPressed(KEY.resetRot) then rx, ry = 0.0, 0.0 end
            rot = vec3(rx, ry, rz)

            if justPressed(KEY.crosshair) then
                local hit, _, coords = lib.raycast.fromCamera(1, 4, 60.0)
                if hit then pos = vec3(coords.x, coords.y, isPed and coords.z + 1.0 or coords.z) end
            end

            applyTransform(entity, isPed, pos, rot)

            if justPressed(KEY.ground) then
                if item.kind == 'vehicle' then
                    SetVehicleOnGroundProperly(entity)
                elseif item.kind == 'prop' then
                    PlaceObjectOnGroundProperly(entity)
                else
                    SetEntityCoordsNoOffset(entity, pos.x, pos.y, groundZ(pos) + 1.0, false, false, false)
                end
                pos, rot = GetEntityCoords(entity), GetEntityRotation(entity, 2)
            end

            if justPressed(KEY.freeze) then
                item.frozen = not item.frozen
                Notify(item.frozen and 'Sabitlendi (fizik kapalı)' or 'Sabitleme kaldırıldı', 'inform')
            end

            DrawMarker(0, pos.x, pos.y, pos.z + markerHeight, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.4, 0.4, 0.4, 255, 160, 40, 200, true, true, 2, false, nil, nil, false)
            DrawText2D(('X %.2f  Y %.2f  Z %.2f   |   Eğim %.1f  Yatış %.1f  Yön %.1f   |   %s'):format(
                pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, item.frozen and 'SABİT' or 'SERBEST'), 0.5, 0.92, 0.38)

            if justPressed(KEY.confirm) then
                saved = true
                break
            elseif justPressed(KEY.cancel) then
                break
            end
        end

        if DoesEntityExist(entity) then
            if not saved then applyTransform(entity, isPed, startPos, startRot) end
            FreezeEntityPosition(entity, item.frozen)
        end

        lib.hideTextUI()
        editing = false
        Notify(saved and 'Konum kaydedildi' or 'Düzenleme iptal edildi', saved and 'success' or 'inform')
        if onDone then onDone() end
    end)
end
