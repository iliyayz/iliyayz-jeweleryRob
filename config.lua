Config = {}

-- ============================
-- 👮 POLICE & COOLDOWNS
-- ============================

-- Jobs counted as police (if your server uses departments)
Config.PoliceJobs = { 'police', 'sheriff' }

-- Minimum number of on-duty cops required
Config.RequiredCops = 1

-- Global robbery cooldown (seconds)
Config.GlobalCooldown = 25 * 60 -- 25 minutes

-- Individual display cooldown (seconds)
Config.CaseCooldown = 10 * 60 -- 10 minute

-- ============================
-- 🔧 REQUIRED ITEM
-- ============================

-- Item needed to start the robbery (removed only if minigame succeeds)
Config.RequiredItem = 'laptop' -- must exist in qb-core/shared/items.lua


-- Player must be holding this weapon to smash glasses
Config.RequiredSmashWeapon = `WEAPON_BAT`   -- hash of weapon in hand
-- Server-side sanity check: player must at least own this item
Config.RequiredSmashItem   = 'weapon_bat'


-- ============================
-- 🔸 MINIGAME SETTINGS
-- ============================

-- Choose between: 'bl_ui', 'qb-lock', or 'ps-ui'
Config.Minigame = 'bl_ui'

-- bl_ui settings
Config.BLUI = {
    iterations = 3,   -- number of correct hits
    length = 4,       -- number of circle slices
    duration = 5000   -- milliseconds per rotation
}

-- qb-lock settings
Config.QbLock = {
    circles = 3,
    time = 20
}

-- ps-ui settings
Config.PSUI = {
    blocks = 4,
    time = 15
}

-- ============================
-- 🗺️ LOCATIONS & BLIP
-- ============================

-- Center of the jewelry store & its detection radius
Config.StoreCenter = vector3(-1368.33, -297.16, 44.03)
Config.StoreRadius = 1.0

-- Always-on blip on the map
Config.Blip = {
    enabled = true,                               -- enable blip
    coords = vector3(-1375.25, -287.85, 42.8),    -- blip location
    sprite = 617,                                 -- blip icon (diamond)
    color = 5,                                    -- blue
    scale = 0.8,                                  -- size
    label = 'Vangelico Jewelry',                  -- name
    shortRange = true                             -- true: only near + map; false: global
}

-- NEW: Persistent robbery blip shown to on-duty police during an active robbery
Config.PoliceRobberyBlip = {
    sprite = 161,           -- exclamation
    color  = 1,             -- red
    scale  = 1.0,
    label  = 'Robbery: Vangelico'
}

-- ============================
-- 💎 DISPLAY CASE LOCATIONS
-- ============================

Config.Cases = {
    { id = 1, coords = vector3(-1379.9, -293.3, 43.95), heading = 120.0 },
    { id = 2, coords = vector3(-1381.37, -294.59, 43.92), heading = 120.0 },
    { id = 3, coords = vector3(-1382.82, -295.88, 44.00), heading = 120.0 },
    { id = 4, coords = vector3(-1384.24, -297.14, 43.99), heading = 120.0 },
    { id = 5, coords = vector3(-1378.87, -294.45, 43.86), heading = 300.0 },
    { id = 6, coords = vector3(-1380.33, -295.74, 43.85), heading = 300.0 },
    { id = 7, coords = vector3(-1381.80, -297.04, 43.89), heading = 120.0 },
    { id = 8, coords = vector3(-1383.24, -298.32, 43.87), heading = 120.0 },
    { id = 9, coords = vector3(-1378.69, -296.99, 43.93), heading = 300.0 },
    { id = 10, coords = vector3(-1379.68, -297.87, 43.94), heading = 300.0 },
    { id = 11, coords = vector3(-1378.95, -299.92, 43.89), heading = 300.0 },
    { id = 12, coords = vector3(-1377.25, -301.02, 43.97), heading = 300.0 },
    { id = 13, coords = vector3(-1375.97, -299.88, 43.94), heading = 300.0 },
    { id = 14, coords = vector3(-1377.72, -304.61, 43.96), heading = 300.0 },
    { id = 15, coords = vector3(-1376.21, -303.27, 43.91), heading = 300.0 },
    { id = 16, coords = vector3(-1374.83, -302.05, 43.88), heading = 300.0 },
    { id = 17, coords = vector3(-1373.46, -300.84, 43.94), heading = 300.0 },
}

-- ============================
-- 🎁 REWARDS / LOOT TABLE
-- ============================

Config.Loot = {
    { item = 'rolex',        min = 1, max = 2, chance = 80 },
    { item = 'goldchain',    min = 1, max = 2, chance = 50 },
    { item = 'diamond_ring', min = 1, max = 2, chance = 5 },
    { item = 'goldbar',      min = 1, max = 1, chance = 5 },
}

-- ============================
-- 🚨 DISPATCH / ALERT SETTINGS
-- ============================

Config.UsePSDispatch = false          -- use ps-dispatch if available
Config.AlertOnStart = true            -- alert police only on minigame success
Config.AlertOnSmash = false           -- no alerts while looting
Config.AlertChance = 75               -- only applies if AlertOnSmash = true

-- ============================
-- 🧠 MISC SETTINGS
-- ============================

Config.DisableControls = true         -- disable movement during smash
Config.SmashTime = 6500               -- progressbar time (ms)

-- 🔊 Sound settings (Option B: GTA native sounds)
Config.Sounds = {
    useInteractSound = false,  -- IMPORTANT: false = use native soundsets
    native = {
        start  = { name = 'COLLECT_PICK_UP', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
        mid    = { name = 'COLLECT_PICK_UP', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
        smash  = { name = 'Glass_Smash',     set = 'RESIDENT' },
        finish = { name = 'PICK_UP',         set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' }
    }
}

-- ============================
-- 🔔 DISCORD LOGGING
-- ============================
Config.Discord = {
    Enabled = true,
    Webhook = "https://discord.com/api/webhooks/1427849911675654165/684PUviuIs3s8lR9gEApT-CSdXgOGo0sXMlrmI596K1vybjZIMkdTuUpX9wxyjxpOEvv",
    Colors = {
        RobberyStart = 15105570, -- orange
        Minigame     = 15844367, -- yellow
        CaseSmashed  = 3066993,  -- green
        AdminReset   = 3447003   -- blue
    }
}
