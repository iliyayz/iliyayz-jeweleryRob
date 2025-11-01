local QBCore = exports['qb-core']:GetCoreObject()

local smashing = false
local activeRobbery = false
local caseState = {}

-- ===============================
-- Weapon check (must have bat equipped)
-- ===============================
local function IsWeaponEquipped(requiredHash)
    local ped = PlayerPedId()
    local inHand = GetSelectedPedWeapon(ped)
    return inHand == (requiredHash or Config.RequiredSmashWeapon)
end

local function EnsureBatEquipped()
    if IsWeaponEquipped(Config.RequiredSmashWeapon) then return true end
    QBCore.Functions.Notify(Lang:t('notify.need_bat'), 'error', 5000)
    return false
end

-- ===============================
-- 🔊 Native sound helper (Option B: GTA native sounds)
-- ===============================
local function PlayJewelSound(key, coords)
    if not Config.Sounds or Config.Sounds.useInteractSound then return end
    local entry = Config.Sounds.native and Config.Sounds.native[key]
    local name  = entry and entry.name or 'Glass_Smash'
    local set   = entry and entry.set  or 'RESIDENT'
    local c = coords or GetEntityCoords(PlayerPedId())
    PlaySoundFromCoord(-1, name, c.x, c.y, c.z, set, false, 0, false)
end

-- ===============================
-- 📀 Load Animation Dict
-- ===============================
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(0) end
    end
end

-- ===============================
-- 🗺️ Permanent Blip (always visible)
-- ===============================
CreateThread(function()
    if not Config.Blip or not Config.Blip.enabled then return end
    local blipCoord = Config.Blip.coords or Config.StoreCenter
    local blip = AddBlipForCoord(blipCoord.x, blipCoord.y, blipCoord.z)
    SetBlipSprite(blip, Config.Blip.sprite or 617)
    SetBlipColour(blip, Config.Blip.color or 5)
    SetBlipScale(blip, Config.Blip.scale or 0.8)
    SetBlipAsShortRange(blip, Config.Blip.shortRange ~= false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.label or "Vangelico Jewelry")
    EndTextCommandSetBlipName(blip)
end)

-- ===============================
-- 🎯 Target Zones
-- ===============================
CreateThread(function()
    for _, c in ipairs(Config.Cases) do
        local name = 'qb-jewelrob-case-' .. tostring(c.id)
        exports['qb-target']:AddBoxZone(name, c.coords, 0.6, 1.2, {
            name = name,
            heading = c.heading,
            debugPoly = false,
            minZ = c.coords.z - 1.0,
            maxZ = c.coords.z + 2.0
        }, {
            options = {
                {
                    icon = 'fas fa-gem',
                    label = 'Smash Display',
                    -- only when bat IS equipped
                    canInteract = function()
                        return activeRobbery and not smashing and IsWeaponEquipped(Config.RequiredSmashWeapon)
                    end,
                    action = function()
                        SmashCase(c.id, c.coords)
                    end
                },
                {
                    icon = 'fas fa-ban',
                    label = '(Need Baseball Bat equipped)',
                    -- only when bat is NOT equipped
                    canInteract = function()
                        return activeRobbery and not smashing and not IsWeaponEquipped(Config.RequiredSmashWeapon)
                    end,
                    action = function()
                        QBCore.Functions.Notify(Lang:t('notify.need_bat'), 'error', 5000)
                    end
                }
            },
            distance = 1.5
        })
    end

    exports['qb-target']:AddCircleZone('qb-jewelrob-start', Config.StoreCenter, 1.6, {
        name = 'qb-jewelrob-start', useZ = true
    }, {
        options = { {
            icon = 'fas fa-burst',
            label = 'Start Jewelry Robbery',
            action = function()
                TryStartRobbery()
            end
        } },
        distance = 2.0
    })
end)

-- ===============================
-- 🔄 Events
-- ===============================
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('qb-jewelrob:server:SyncCases')
end)

RegisterNetEvent('qb-jewelrob:client:SyncCases', function(serverState)
    caseState = serverState or {}
end)

RegisterNetEvent('qb-jewelrob:client:StopRobbery', function()
    activeRobbery = false
    QBCore.Functions.Notify(Lang:t('notify.robbery_done_player'), 'success', 7000)
end)

-- Show "which case" and "how many left" after each smash
RegisterNetEvent('qb-jewelrob:client:CasesLeft', function(caseId, remaining)
    local msg
    if remaining and remaining > 0 then
        msg = Lang:t('notify.case_smashed_left', { id = caseId, left = remaining })
    else
        msg = Lang:t('notify.case_smashed_last', { id = caseId })
    end
    QBCore.Functions.Notify(msg, 'success', 5500)
end)

-- ===============================
-- 🚨 Start Robbery Logic
-- ===============================
function TryStartRobbery()
    if activeRobbery then return end

    QBCore.Functions.TriggerCallback('qb-jewelrob:server:CanStart', function(can, reason)
        if not can then
            if reason == 'item' then
                local label = (QBCore.Shared.Items[Config.RequiredItem] and QBCore.Shared.Items[Config.RequiredItem].label) or Config.RequiredItem
                QBCore.Functions.Notify(Lang:t('notify.no_item', { item = label }), 'error')
            elseif reason == 'cops' then
                QBCore.Functions.Notify(Lang:t('notify.not_enough_cops'), 'error')
            elseif reason == 'cooldown' then
                QBCore.Functions.Notify(Lang:t('notify.cooldown'), 'error')
            else
                QBCore.Functions.Notify(Lang:t('notify.unknown'), 'error')
            end
            return
        end

        local success = RunMinigame()

        -- Always log result & start session
        TriggerServerEvent('qb-jewelrob:server:MinigameResult', success)

        if success then
            TriggerServerEvent('qb-jewelrob:server:StartRobbery')
            activeRobbery = true
            QBCore.Functions.Notify(Lang:t('notify.minigame_success'), 'success')
        else
            QBCore.Functions.Notify(Lang:t('notify.minigame_fail'), 'error')
        end
    end)
end

-- ===============================
-- 🎮 Minigame Handler
-- ===============================
function RunMinigame()
    local ok = false

    if Config.Minigame == 'bl_ui' and exports['bl_ui'] then
        local it  = (Config.BLUI and Config.BLUI.iterations) or 3
        local len = (Config.BLUI and Config.BLUI.length) or 4
        local dur = (Config.BLUI and Config.BLUI.duration) or 5000
        ok = exports['bl_ui']:CircleSum(it, { length = len, duration = dur }) and true or false

    elseif Config.Minigame == 'qb-lock' and exports['qb-lock'] then
        local result = exports['qb-lock']:StartLockPickCircle(Config.QbLock.circles, Config.QbLock.time)
        ok = (result == 1 or result == true)

    elseif Config.Minigame == 'ps-ui' and exports['ps-ui'] then
        local finished = false
        exports['ps-ui']:Circle(function(success)
            ok = success
            finished = true
        end, Config.PSUI.blocks, Config.PSUI.time)
        local t = GetGameTimer()
        while not finished and GetGameTimer() - t < 20000 do Wait(10) end

    else
        Wait(1200)
        ok = (math.random(100) <= 75)
    end

    return ok
end

-- ===============================
-- 💎 Smash Display Case
-- ===============================
function SmashCase(caseId, coords)
    if smashing then return end
    if not EnsureBatEquipped() then return end
    smashing = true

    local ped = PlayerPedId()
    if #(GetEntityCoords(ped) - coords) > 3.0 then
        smashing = false
        return
    end

    PlayJewelSound('start', coords)

    local dict, anim = 'missheist_jewel', 'smash_case'
    LoadAnimDict(dict)
    -- Keep bat equipped (do NOT switch to unarmed)

    if Config.DisableControls then
        LocalPlayer.state:set('inv_busy', true, true)
    end

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)

    CreateThread(function()
        local hits = 2
        local step = math.floor(Config.SmashTime / (hits + 1))
        for _ = 1, hits do
            Wait(step)
            PlayJewelSound('mid', coords)
        end
    end)

    QBCore.Functions.Progressbar(
        'jewelrob_smash',
        Lang:t('progress.smash'),
        Config.SmashTime,
        false,
        true,
        {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        },
        {
            animDict = dict,
            anim = anim,
            flags = 49
        },
        {},
        {},
        function() -- onFinish
            ClearPedTasks(ped)
            if Config.DisableControls then
                LocalPlayer.state:set('inv_busy', false, true)
            end
            PlayJewelSound('smash', coords)
            SetTimeout(200, function() PlayJewelSound('finish', coords) end)
            TriggerServerEvent('qb-jewelrob:server:SmashCase', caseId)
            smashing = false
        end,
        function() -- onCancel
            ClearPedTasks(ped)
            if Config.DisableControls then
                LocalPlayer.state:set('inv_busy', false, true)
            end
            smashing = false
        end
    )
end

-- ===============================
-- 👮 Police-only persistent robbery blip
-- ===============================
local function IsPolice()
    local pd = QBCore.Functions.GetPlayerData()
    return pd and pd.job and pd.job.name == 'police' and pd.job.onduty
end

local PoliceRobberyBlip = nil

RegisterNetEvent('qb-jewelrob:client:PoliceBlipStart', function(pos)
    if not IsPolice() then return end
    if DoesBlipExist(PoliceRobberyBlip) then RemoveBlip(PoliceRobberyBlip) end

    PoliceRobberyBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(PoliceRobberyBlip, (Config.PoliceRobberyBlip and Config.PoliceRobberyBlip.sprite) or 161)
    SetBlipColour(PoliceRobberyBlip, (Config.PoliceRobberyBlip and Config.PoliceRobberyBlip.color) or 1)
    SetBlipScale(PoliceRobberyBlip, (Config.PoliceRobberyBlip and Config.PoliceRobberyBlip.scale) or 1.0)
    SetBlipAsShortRange(PoliceRobberyBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString((Config.PoliceRobberyBlip and Config.PoliceRobberyBlip.label) or 'Robbery: Vangelico')
    EndTextCommandSetBlipName(PoliceRobberyBlip)
end)

RegisterNetEvent('qb-jewelrob:client:PoliceBlipStop', function()
    if DoesBlipExist(PoliceRobberyBlip) then
        RemoveBlip(PoliceRobberyBlip)
    end
    PoliceRobberyBlip = nil
end)
