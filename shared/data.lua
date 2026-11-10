Data = {}

Data.FACE_FEATURES = {
    'noseWidth', 'nosePeakHigh', 'nosePeakSize', 'noseBoneHigh', 'nosePeakLowering', 'noseBoneTwist',
    'eyeBrownHigh', 'eyeBrownForward', 'cheeksBoneHigh', 'cheeksBoneWidth', 'cheeksWidth', 'eyesOpening',
    'lipsThickness', 'jawBoneWidth', 'jawBoneBackSize', 'chinBoneLowering', 'chinBoneLenght', 'chinBoneSize',
    'chinHole', 'neckThickness',
}

Data.HEAD_OVERLAYS = {
    'blemishes', 'beard', 'eyebrows', 'ageing', 'makeUp', 'blush', 'complexion', 'sunDamage', 'lipstick',
    'moleAndFreckles', 'chestHair', 'bodyBlemishes',
}

Data.SKIN = { 'blemishes', 'ageing', 'complexion', 'sunDamage', 'moleAndFreckles', 'bodyBlemishes' }
Data.BARBER = { 'beard', 'eyebrows', 'chestHair', 'makeUp', 'blush', 'lipstick' }

Data.COMPONENTS = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
Data.PROPS = { 0, 1, 2, 6, 7 }

Data.EYE_COLORS = 32
Data.NATIVE_FACES = 46

Data.ZONES = { 'ZONE_HEAD', 'ZONE_TORSO', 'ZONE_LEFT_ARM', 'ZONE_RIGHT_ARM', 'ZONE_LEFT_LEG', 'ZONE_RIGHT_LEG' }

Data.SECTIONS = {
    creation = { 'heritage', 'face', 'skin', 'eyes', 'hair', 'facialhair', 'makeup', 'clothes', 'tattoos' },
    barber = { 'hair', 'facialhair', 'makeup' },
    tattoo = { 'ZONE_HEAD', 'ZONE_TORSO', 'ZONE_LEFT_ARM', 'ZONE_RIGHT_ARM', 'ZONE_LEFT_LEG', 'ZONE_RIGHT_LEG', 'worn' },
    surgeon = { 'heritage', 'face', 'skin', 'eyes' },
}

Data.MODELS = { m = 'mp_m_freemode_01', f = 'mp_f_freemode_01' }

function Data.tattooList()
    if Data._tattoos then return Data._tattoos end
    local byName, byZone = {}, {}
    local function add(t, addon)
        if type(t) ~= 'table' or type(t.name) ~= 'string' or not t.zone or not t.collection then return end
        local copy = {}
        for k, v in pairs(t) do copy[k] = v end
        copy.addon = addon or nil
        copy.price = tonumber(t.price) or Config.Prices.tattoo
        byName[t.name] = copy
        byZone[t.zone] = byZone[t.zone] or {}
        byZone[t.zone][#byZone[t.zone] + 1] = copy
    end
    for zone, list in pairs(Tattoos or {}) do
        if zone ~= 'ZONE_HAIR' then
            for i = 1, #list do add(list[i], false) end
        end
    end
    for i = 1, #(Config.AddonTattoos or {}) do add(Config.AddonTattoos[i], true) end
    Data._tattoos = { byName = byName, byZone = byZone }
    return Data._tattoos
end

local function readLocale(lang)
    local raw = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. lang .. '.json')
    if not raw then return nil end
    local ok, decoded = pcall(json.decode, raw)
    return ok and type(decoded) == 'table' and decoded or nil
end

local function merge(base, over)
    for k, v in pairs(over) do
        if type(v) == 'table' and type(base[k]) == 'table' and v[1] == nil then merge(base[k], v) else base[k] = v end
    end
    return base
end

function Data.locale()
    if Data._locale then return Data._locale end
    local lang = type(Config.Locale) == 'string' and Config.Locale:lower() or 'en'
    local all = readLocale('en') or {}
    local chosen = lang ~= 'en' and readLocale(lang)
    if chosen then merge(all, chosen) else lang = 'en' end
    Data._locale = { lang = lang, all = all }
    return Data._locale
end

function Data.text(key, vars)
    local t = (Data.locale().all.server or {})[key] or key
    return (t:gsub('{(%w+)}', function(k) return vars and vars[k] ~= nil and tostring(vars[k]) or '{' .. k .. '}' end))
end
