Config = {}

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- GENERAL
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- Language of the menu and messages: 'en', 'fr', 'es', 'de', 'it', 'pt', 'nl', 'pl' or 'tr' (files in locales/).
Config.Locale = 'en'

-- 'auto' finds qbx_core, qb-core or es_extended. Otherwise: 'qbx', 'qb', 'esx' or 'standalone'.
Config.Framework = 'auto'

-- Prints one line in the server console when a newer version exists on GitHub.
Config.CheckUpdates = true

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- LOOK OF THE MENU
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

Config.Ui = {
    scale = 1.0,       -- size of the whole menu: 0.8 = smaller, 1.2 = bigger
    side = 'left',     -- 'left' or 'right' side of the screen
    logo = '',         -- image next to the title: a file of web/ (ex. 'logo.png') or an https:// link; '' = none
    font = 'Poppins',  -- any font installed in FiveM; Poppins is included
    colors = {
        accent = '#c62a3c',                     -- outline of the chosen section, warnings
        text = '#ffffff',
        textSoft = 'rgba(255, 255, 255, 0.62)', -- small texts
        box = 'rgba(0, 0, 0, 0.55)',            -- background of the boxes
        boxHover = 'rgba(0, 0, 0, 0.65)',
        boxActive = 'rgba(0, 0, 0, 0.72)',
        outline = '#ffffff',                    -- outline of the hovered / chosen tile
    },
}

-- Keys of the menu (one letter or number).
Config.Keys = {
    hide = 'H',   -- hide / show the menu to look at the character
    face = '1',   -- camera on the face
    chest = '2',  -- camera on the chest
    body = '3',   -- camera on the whole body
}

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- MONEY
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- Account paid first ('cash' or 'bank'); the other one pays when the first is not enough.
Config.PayWith = 'cash'

-- Standalone: money item taken in ox_inventory / pure_inventory. Without inventory, everything is free.
Config.StandaloneMoneyItem = 'money'

-- Prices shown in the menu. The server always computes them again.
Config.Prices = {
    category = 300,    -- barber: per category changed (hair, beard, eyebrows, chest hair, makeup, blush, lipstick)
    surgeon = 2500,    -- plastic surgeon: flat fee when anything changed
    tattoo = 500,      -- a tattoo without its own price (a tattoo can have `price` in shared/tattoos.lua)
    tattooRemove = 0,  -- removing a tattoo (0 = free)
}

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- CHARACTER CREATION
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- Starting outfit chosen at the creation (free). Pictures come from pure_clothing when it runs.
Config.CreationClothes = {
    { id = 11, key = 'tops' },
    { id = 8, key = 'undershirt' },
    { id = 3, key = 'arms' },
    { id = 4, key = 'legs' },
    { id = 6, key = 'shoes' },
}
-- true = clothes of add-on packs can be chosen at the creation too.
Config.CreationAddonClothes = false

-- Faces added by packs: 0 to 45 are the game faces. 'auto' reads how many faces the game has.
-- Or a list per model, ex. { mp_m_freemode_01 = { 46, 47, 48 }, mp_f_freemode_01 = { 46 } }.
Config.AddonFaces = 'auto'

-- Tattoos of an add-on pack (shown under "New" at the tattoo parlor), same fields as shared/tattoos.lua, ex.:
-- { name = 'MYPACK_001', label = 'Koi Fish', hashMale = 'mypack_001_m', hashFemale = 'mypack_001_f',
--   zone = 'ZONE_TORSO', collection = 'mypack_overlays', price = 900 },
Config.AddonTattoos = {}

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- SHOPS
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- Distance (meters) at which the player can open a shop. The server checks it too.
Config.ShopDistance = 3.0

-- Plastic surgeon (face, parents, skin, eyes after the creation). false = no surgeon at all:
-- no shopkeeper, no map icon, no menu. Admins can still use /appearance.
Config.Surgeon = true

-- Map icons (sprite and color numbers: docs.fivem.net/docs/game-references/blips). false = no icon for this type.
Config.Blips = {
    barber = { sprite = 71, color = 0, scale = 0.7 },
    tattoo = { sprite = 75, color = 0, scale = 0.7 },
    surgeon = { sprite = 102, color = 0, scale = 0.7 },
}

-- type = 'barber', 'tattoo' or 'surgeon'; ped = shopkeeper (false = none); blip = false hides this one.
-- Interaction: pure-target / ox_target / qb-target when started, otherwise the E key.
Config.Shops = {
    { type = 'barber', coords = vec4(-814.3, -183.8, 37.6, 116.9), ped = 's_f_m_fembarber' },
    { type = 'barber', coords = vec4(136.8, -1708.4, 29.3, 140.0), ped = 's_f_m_fembarber' },
    { type = 'barber', coords = vec4(-1282.6, -1116.8, 7.0, 89.3), ped = 's_f_m_fembarber' },
    { type = 'barber', coords = vec4(1931.5, 3729.7, 32.8, 210.0), ped = 's_f_m_fembarber' },
    { type = 'barber', coords = vec4(1212.8, -472.9, 66.2, 60.9), ped = 's_f_m_fembarber' },
    { type = 'barber', coords = vec4(-32.9, -152.3, 57.1, 335.2), ped = 's_f_m_fembarber' },
    { type = 'barber', coords = vec4(-278.1, 6228.5, 31.7, 45.0), ped = 's_f_m_fembarber' },

    { type = 'tattoo', coords = vec4(1322.6, -1651.9, 52.2, 42.5), ped = 'u_m_y_tattoo_01' },
    { type = 'tattoo', coords = vec4(-1154.0, -1425.3, 4.95, 23.2), ped = 'u_m_y_tattoo_01' },
    { type = 'tattoo', coords = vec4(322.6, 180.3, 103.6, 156.2), ped = 'u_m_y_tattoo_01' },
    { type = 'tattoo', coords = vec4(-3169.5, 1074.9, 20.8, 253.3), ped = 'u_m_y_tattoo_01' },
    { type = 'tattoo', coords = vec4(1864.6, 3747.7, 33.0, 30.0), ped = 'u_m_y_tattoo_01' },
    { type = 'tattoo', coords = vec4(-293.7, 6200.0, 31.5, 230.0), ped = 'u_m_y_tattoo_01' },

    { type = 'surgeon', coords = vec4(298.8, -572.8, 43.3, 114.3), ped = 's_m_m_doctor_01' },
}

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- Admins (players with this ACE permission, ex. group.admin) open the full menu for free with /appearance [id].
Config.AdminAce = 'command'
Config.AdminCommand = 'appearance'

-- Puts the saved appearance back when the character looks wrong.
Config.ReloadCommand = 'reloadskin'
