local QBCore = exports['qb-core']:GetCoreObject()

local GlobalCooldownUntil = 0
local CaseCooldowns = {} -- [caseId] = expireTime

-- Active robbery session state:
-- remaining:   set of case ids still not broken
-- pendingLoot: map[src] = { {item=..., amount=...}, ... } gathered during the run; paid out at the end
-- participants:set[src] = true (players who smashed at least one case)
local ActiveRobbery = nil -- { remaining = {}, pendingLoot = {}, participants = {} }

-- =========================
-- Discord logging helper
-- =========================
local function SendDiscordLog(title, description, color)
    if not Config.Discord or not Config.Discord.Enabled or not Config.Discord.Webhook or Config.Discord.Webhook == "" then
        return
    end

    local embed = {
        {
            title = title,
            description = description,
            color = color or 16711680,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    local payload = { username = "qb-jewelrob", embeds = embed }

    PerformHttpRequest(
        Config.Discord.Webhook,
        function(errCode, _body, _headers)
            if errCode ~= 204 and errCode ~= 200 then
                print(("^1[qb-jewelrob] Discord webhook error: %s^0"):format(tostring(errCode)))
            end
        end,
        'POST',
        json.encode(payload),
        { ['Content-Type'] = 'application/json' }
    )
end

-- =========================
-- LEO helper
-- =========================
local function IsOnDutyLeo(p)
    if not p or not p.PlayerData or not p.PlayerData.job then return false end
    local job = p.PlayerData.job
    local onduty = job.onduty or job.isonduty

    -- Prefer QBCore job.type where available
    if job.type and tostring(job.type):lower() == 'leo' then
        return onduty
    end

    -- Fallback: named departments (edit to your server's jobs)
    local policeJobs = {
        police = true,
        lspd   = true,
        bcso   = true,
        sasp   = true,
        sahp   = true,
        sheriff = true,
        sapr   = true,
    }
    local name = (job.name or ''):lower()
    return policeJobs[name] and onduty
end

-- =========================
-- Utilities
-- =========================
local function CountOnDutyCops()
    local cops = 0
    for _, pid in pairs(QBCore.Functions.GetPlayers()) do
        local p = QBCore.Functions.GetPlayer(pid)
        if IsOnDutyLeo(p) then
            cops = cops + 1
        end
    end
    return cops
end

local function PlayerNameCID(Player, src)
    local name = ("Player-%d"):format(src or 0)
    local cid  = "N/A"
    if Player and Player.PlayerData then
        cid = Player.PlayerData.citizenid or cid
        if Player.PlayerData.charinfo then
            name = ("%s %s"):format(Player.PlayerData.charinfo.firstname or "John", Player.PlayerData.charinfo.lastname or "Doe")
        end
    end
    return name, cid
end

local function AlertPolice(_player)
    local pos = Config.StoreCenter
    if Config.UsePSDispatch and GetResourceState('ps-dispatch') == 'started' then
        exports['ps-dispatch']:CustomAlert({
            coords = pos,
            message = 'Possible robbery in progress at Vangelico',
            dispatchCode = '10-90',
            relatedCode = '10-90',
            radius = 0, sprite = 617, color = 1, scale = 1.0, length = 7500
        })
    else
        for _, pid in pairs(QBCore.Functions.GetPlayers()) do
            local p = QBCore.Functions.GetPlayer(pid)
            if IsOnDutyLeo(p) then
                TriggerClientEvent('QBCore:Notify', pid, '911: Robbery in progress at Vangelico!', 'error', 7500)
                TriggerClientEvent('police:client:policeAlert', pid, pos)
            end
        end
    end
end

-- =========================
-- Police blip (persistent)
-- =========================
local function StartPoliceRobberyBlip()
    local pos = Config.StoreCenter
    for _, pid in pairs(QBCore.Functions.GetPlayers()) do
        local p = QBCore.Functions.GetPlayer(pid)
        if IsOnDutyLeo(p) then
            TriggerClientEvent('qb-jewelrob:client:PoliceBlipStart', pid, pos)
        end
    end
end

local function StopPoliceRobberyBlip()
    for _, pid in pairs(QBCore.Functions.GetPlayers()) do
        local p = QBCore.Functions.GetPlayer(pid)
        if IsOnDutyLeo(p) then
            TriggerClientEvent('qb-jewelrob:client:PoliceBlipStop', pid)
        end
    end
end

local function NotifyPolice(msg, type, length)
    for _, pid in pairs(QBCore.Functions.GetPlayers()) do
        local p = QBCore.Functions.GetPlayer(pid)
        if IsOnDutyLeo(p) then
            TriggerClientEvent('QBCore:Notify', pid, msg, type or 'primary', length or 7000)
        end
    end
end

-- =========================
-- Sync cases to a client
-- =========================
RegisterNetEvent('qb-jewelrob:server:SyncCases', function()
    TriggerClientEvent('qb-jewelrob:client:SyncCases', source, CaseCooldowns)
end)

-- =========================
-- Start check callback
-- =========================
QBCore.Functions.CreateCallback('qb-jewelrob:server:CanStart', function(src, cb)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return cb(false, 'unknown') end

    if CountOnDutyCops() < Config.RequiredCops then
        return cb(false, 'cops')
    end

    if os.time() < GlobalCooldownUntil then
        return cb(false, 'cooldown')
    end

    if not Player.Functions.GetItemByName(Config.RequiredItem) then
        return cb(false, 'item')
    end

    cb(true)
end)

-- =========================
-- Start robbery (consume item, init session)
-- =========================
RegisterNetEvent('qb-jewelrob:server:StartRobbery', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if CountOnDutyCops() < Config.RequiredCops then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.not_enough_cops'), 'error'); return
    end
    if os.time() < GlobalCooldownUntil then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.cooldown'), 'error'); return
    end

    local req = Player.Functions.GetItemByName(Config.RequiredItem)
    if not req or (req.amount or 0) < 1 then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.no_item', {
            item = (QBCore.Shared.Items[Config.RequiredItem] and QBCore.Shared.Items[Config.RequiredItem].label) or Config.RequiredItem
        }), 'error'); return
    end

    -- consume item
    local removed = Player.Functions.RemoveItem(Config.RequiredItem, 1, req.slot) or Player.Functions.RemoveItem(Config.RequiredItem, 1)
    if not removed then return end
    if QBCore.Shared.Items[Config.RequiredItem] then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RequiredItem], 'remove')
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.consume', { item = QBCore.Shared.Items[Config.RequiredItem].label }), 'success')
    end

    GlobalCooldownUntil = os.time() + Config.GlobalCooldown

    -- New session
    ActiveRobbery = { remaining = {}, pendingLoot = {}, participants = {} }
    for _, c in ipairs(Config.Cases) do
        ActiveRobbery.remaining[c.id] = true
    end

    -- Discord: start
    local name, cid = PlayerNameCID(Player, src)
    local desc = ("**Robbery started**\n**Player:** %s\n**Source:** %d\n**CitizenID:** %s\n**Store:** Vangelico (%s)")
        :format(name, src, cid, tostring(Config.StoreCenter))
    SendDiscordLog("Jewelry Robbery Started", desc, Config.Discord and Config.Discord.Colors and Config.Discord.Colors.RobberyStart or 15105570)
end)

-- =========================
-- Minigame result (✅/❌)
-- =========================
RegisterNetEvent('qb-jewelrob:server:MinigameResult', function(success)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Log result
    local name, cid = PlayerNameCID(Player, src)
    local emoji = success and "✅" or "❌"
    local resultText = success and "SUCCESS" or "FAILED"
    local desc = ("**Result:** %s %s\n**Player:** %s\n**Source:** %d\n**CitizenID:** %s")
        :format(resultText, emoji, name, src, cid)
    SendDiscordLog("Jewelry Minigame", desc, Config.Discord and Config.Discord.Colors and Config.Discord.Colors.Minigame or 15844367)

    -- Alert & blip only if success
    if success and Config.AlertOnStart and ActiveRobbery then
        AlertPolice(Player)
        StartPoliceRobberyBlip()
    end
end)

-- =========================
-- Loot helpers
-- =========================
local function RollLoot()
    local out = {}
    for _, r in ipairs(Config.Loot) do
        if math.random(100) <= r.chance then
            local amount = math.random(r.min, r.max)
            out[#out+1] = { item = r.item, amount = amount }
        end
    end
    return out
end

local function AddPendingLoot(src, drops)
    if not ActiveRobbery then return end
    ActiveRobbery.pendingLoot[src] = ActiveRobbery.pendingLoot[src] or {}
    for _, it in ipairs(drops) do
        table.insert(ActiveRobbery.pendingLoot[src], { item = it.item, amount = it.amount })
    end
end

local function PayoutAll()
    if not ActiveRobbery then return end

    for src, list in pairs(ActiveRobbery.pendingLoot) do
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and list and #list > 0 then
            local summary = {}
            for _, it in ipairs(list) do
                Player.Functions.AddItem(it.item, it.amount)
                if QBCore.Shared.Items[it.item] then
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[it.item], 'add')
                end
                summary[it.item] = (summary[it.item] or 0) + it.amount
            end

            local text = ""
            for item, amt in pairs(summary) do
                local label = (QBCore.Shared.Items[item] and QBCore.Shared.Items[item].label) or item
                text = text .. string.format("%s x%d, ", label, amt)
            end
            if text ~= "" then text = text:sub(1, #text - 2) end

            TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.payout_received', { loot = text }), 'success', 9000)
        end
    end
end

-- =========================
-- Smash a display case (loot is banked, paid at end)
-- =========================
RegisterNetEvent('qb-jewelrob:server:SmashCase', function(caseId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or type(caseId) ~= 'number' then return end

    -- Server-side sanity: must own the bat item
    if Config.RequiredSmashItem and Config.RequiredSmashItem ~= '' then
        local bat = Player.Functions.GetItemByName(Config.RequiredSmashItem)
        if not bat then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.need_bat'), 'error', 5000)
            return
        end
    end

    if CaseCooldowns[caseId] and os.time() < CaseCooldowns[caseId] then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.empty'), 'error')
        return
    end

    -- Roll loot but DO NOT give now; bank it to session
    local drops = RollLoot()
    if ActiveRobbery then
        AddPendingLoot(src, drops)
        ActiveRobbery.participants[src] = true
    end

    CaseCooldowns[caseId] = os.time() + Config.CaseCooldown
    TriggerClientEvent('qb-jewelrob:client:SyncCases', -1, CaseCooldowns)

    local remainingCountAfter = nil

    if ActiveRobbery and ActiveRobbery.remaining then
        if ActiveRobbery.remaining[caseId] then
            ActiveRobbery.remaining[caseId] = nil
        end

        local count = 0
        for _ in pairs(ActiveRobbery.remaining) do count = count + 1 end
        remainingCountAfter = count

        -- Tell smasher which case & how many left
        TriggerClientEvent('qb-jewelrob:client:CasesLeft', src, caseId, remainingCountAfter)

        if count == 0 then
            -- Pay everyone their pending loot now
            PayoutAll()

            -- End-of-session: stop blip, end robbery, notify police
            StopPoliceRobberyBlip()
            TriggerClientEvent('qb-jewelrob:client:StopRobbery', -1)
            NotifyPolice('Vangelico: Robbery is complete. Suspects may be fleeing the area.', 'primary', 9000)

            -- Discord payout summary
            local lines = {}
            for pid, list in pairs(ActiveRobbery.pendingLoot) do
                local p = QBCore.Functions.GetPlayer(pid)
                local pname = p and (p.PlayerData.charinfo and (p.PlayerData.charinfo.firstname .. " " .. p.PlayerData.charinfo.lastname)) or ("Player-" .. tostring(pid))
                local tallies = {}
                for _, it in ipairs(list) do
                    tallies[it.item] = (tallies[it.item] or 0) + it.amount
                end
                local s = ""
                for item, amt in pairs(tallies) do
                    local lbl = (QBCore.Shared.Items[item] and QBCore.Shared.Items[item].label) or item
                    s = s .. string.format("%s x%d, ", lbl, amt)
                end
                if s ~= "" then s = s:sub(1, #s - 2) end
                lines[#lines+1] = string.format("- %s: %s", pname, s ~= "" and s or "No loot")
            end
            SendDiscordLog("Jewelry Robbery Complete (Payout)", table.concat(lines, "\n"),
                Config.Discord and Config.Discord.Colors and Config.Discord.Colors.CaseSmashed or 3066993)

            ActiveRobbery = nil
        end
    end

    -- Minimal Discord log for smash
    local name, cid = PlayerNameCID(Player, src)
    local desc = ("**Case:** %d\n**Player:** %s\n**Source:** %d\n**CitizenID:** %s\n**Remaining After:** %s")
        :format(caseId, name, src, cid, tostring(remainingCountAfter or "N/A"))
    SendDiscordLog("Jewelry Case Smashed", desc, Config.Discord and Config.Discord.Colors and Config.Discord.Colors.CaseSmashed or 3066993)
end)

-- =========================
-- Admin reset command
-- =========================
QBCore.Commands.Add('resetjewels', 'Reset jewelry case cooldowns', {}, false, function(src, _)
    GlobalCooldownUntil = 0
    CaseCooldowns = {}
    TriggerClientEvent('qb-jewelrob:client:SyncCases', -1, CaseCooldowns)

    ActiveRobbery = nil
    StopPoliceRobberyBlip()

    local adminName = "Console"
    if src and src > 0 then
        local admin = QBCore.Functions.GetPlayer(src)
        if admin and admin.PlayerData and admin.PlayerData.charinfo then
            adminName = ("%s %s"):format(admin.PlayerData.charinfo.firstname or "John", admin.PlayerData.charinfo.lastname or "Doe")
        else
            adminName = ("Player-%d"):format(src)
        end
    end

    local desc = ("**Cooldowns reset by:** %s\n**Time:** %s"):format(adminName, os.date("%Y-%m-%d %H:%M:%S"))
    SendDiscordLog("Jewelry Cooldowns Reset", desc, Config.Discord and Config.Discord.Colors and Config.Discord.Colors.AdminReset or 3447003)
end, 'admin')


-- =========================
-- Debug: check counted LEOs
-- =========================
QBCore.Commands.Add('checkcops', 'Show counted on-duty LEOs for JewelRob', {}, false, function(src)
    local n = CountOnDutyCops()
    if src and src > 0 then
        TriggerClientEvent('QBCore:Notify', src, ('JewelryRobbery detects %d LEO(s) on duty'):format(n), 'primary', 7000)
    else
        print(('[qb-jewelrob] Counted LEOs: %d'):format(n))
    end
end, 'admin')
