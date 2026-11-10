local lastSave = {}
local freeCreation = {}

local function int(v, min, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    v = math.floor(v)
    if v < min or v > max then return default end
    return v
end

local function num(v, min, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    if v < min then return min end
    if v > max then return max end
    return math.floor(v * 100 + 0.5) / 100
end

local function cleanHeadBlend(hb, old)
    old = old or {}
    hb = type(hb) == 'table' and hb or {}
    local t = {}
    for _, k in ipairs({ 'shapeFirst', 'shapeSecond', 'shapeThird', 'skinFirst', 'skinSecond', 'skinThird' }) do
        t[k] = int(hb[k], 0, 255, int(old[k], 0, 255, 0))
    end
    for _, k in ipairs({ 'shapeMix', 'skinMix', 'thirdMix' }) do
        t[k] = num(hb[k], 0, 1, num(old[k], 0, 1, 0))
    end
    return t
end

local function cleanFeatures(ff, old)
    old = old or {}
    ff = type(ff) == 'table' and ff or {}
    local t = {}
    for _, k in ipairs(Data.FACE_FEATURES) do t[k] = num(ff[k], -1, 1, num(old[k], -1, 1, 0)) end
    return t
end

local function cleanOverlay(o, old)
    old = old or {}
    o = type(o) == 'table' and o or {}
    return {
        style = int(o.style, 0, 255, int(old.style, 0, 255, 0)),
        opacity = num(o.opacity, 0, 1, num(old.opacity, 0, 1, 0)),
        color = int(o.color, 0, 63, int(old.color, 0, 63, 0)),
        secondColor = int(o.secondColor, 0, 63, int(old.secondColor, 0, 63, 0)),
    }
end

local function cleanOverlays(ho, old)
    old = old or {}
    ho = type(ho) == 'table' and ho or {}
    local t = {}
    for _, k in ipairs(Data.HEAD_OVERLAYS) do t[k] = cleanOverlay(ho[k], old[k]) end
    return t
end

local function cleanHair(h, old)
    old = old or {}
    h = type(h) == 'table' and h or {}
    return {
        style = int(h.style, 0, 2047, int(old.style, 0, 2047, 0)),
        texture = int(h.texture, 0, 255, int(old.texture, 0, 255, 0)),
        color = int(h.color, 0, 63, int(old.color, 0, 63, 0)),
        highlight = int(h.highlight, 0, 63, int(old.highlight, 0, 63, 0)),
    }
end

local PROP_IDS = {}
for _, id in ipairs(Data.PROPS) do PROP_IDS[id] = true end

local function cleanClothes(list, isProp)
    local t = {}
    for _, c in ipairs(type(list) == 'table' and list or {}) do
        if type(c) == 'table' then
            if isProp then
                local id = int(c.prop_id, 0, 7)
                if id and PROP_IDS[id] then
                    t[#t + 1] = { prop_id = id, drawable = int(c.drawable, -1, 4095, -1), texture = int(c.texture, -1, 255, -1) }
                end
            else
                local id = int(c.component_id, 0, 11)
                if id then
                    t[#t + 1] = { component_id = id, drawable = int(c.drawable, 0, 4095, 0), texture = int(c.texture, 0, 255, 0) }
                end
            end
        end
    end
    return t
end

local function cleanTattoos(tt)
    local list = Data.tattooList().byName
    local out, seen, n = {}, {}, 0
    for _, zone in ipairs(Data.ZONES) do
        for _, t in ipairs(type(tt) == 'table' and type(tt[zone]) == 'table' and tt[zone] or {}) do
            local name = type(t) == 'table' and t.name or t
            local item = type(name) == 'string' and list[name]
            if item and item.zone == zone and not seen[name] and n < 200 then
                seen[name] = true
                n = n + 1
                out[zone] = out[zone] or {}
                out[zone][#out[zone] + 1] = { name = item.name, label = item.label, hashMale = item.hashMale,
                    hashFemale = item.hashFemale, zone = item.zone, collection = item.collection }
            end
        end
    end
    return out, seen
end

local function sameOverlay(a, b)
    a, b = a or {}, b or {}
    local oa, ob = a.opacity or 0, b.opacity or 0
    if oa == 0 and ob == 0 then return true end
    return (a.style or 0) == (b.style or 0) and math.abs(oa - ob) < 0.011 and (a.color or 0) == (b.color or 0)
end

local function sameTable(a, b, keys, tol)
    a, b = a or {}, b or {}
    for _, k in ipairs(keys) do
        if math.abs((tonumber(a[k]) or 0) - (tonumber(b[k]) or 0)) > (tol or 0) then return false end
    end
    return true
end

local function nearShop(src, mode, index)
    local shop = Config.Shops[tonumber(index) or 0]
    if not shop or shop.type ~= mode then return false end
    local pos = GetEntityCoords(GetPlayerPed(src))
    return #(pos - vector3(shop.coords.x, shop.coords.y, shop.coords.z)) <= (Config.ShopDistance or 3.0) + 2.0
end

local function isLegacy(a) return type(a) == 'table' and a.headBlend == nil end

lib.callback.register('pure_appearance:load', function(src)
    return Storage.load(src)
end)

lib.callback.register('pure_appearance:save', function(src, mode, shop, sent)
    if type(sent) ~= 'table' or not Data.SECTIONS[mode] then return false, Data.text('error') end
    if mode == 'surgeon' and Config.Surgeon == false then return false, Data.text('error') end
    local now = GetGameTimer()
    if lastSave[src] and now - lastSave[src] < 1500 then return false, Data.text('wait') end
    lastSave[src] = now

    local stored = Storage.load(src)
    if isLegacy(stored) then stored = nil end
    local new, price = {}, 0

    if mode == 'creation' then
        if stored and not freeCreation[src] and not Bridge.isAdmin(src) then return false, Data.text('notAllowed') end
        if sent.model ~= Data.MODELS.m and sent.model ~= Data.MODELS.f then return false, Data.text('error') end
        new.model = sent.model
        new.headBlend = cleanHeadBlend(sent.headBlend)
        new.faceFeatures = cleanFeatures(sent.faceFeatures)
        new.headOverlays = cleanOverlays(sent.headOverlays)
        new.hair = cleanHair(sent.hair)
        new.eyeColor = int(sent.eyeColor, 0, Data.EYE_COLORS - 1, 0)
        new.tattoos = cleanTattoos(sent.tattoos)
    else
        if not stored then return false, Data.text('noCharacter') end
        if not nearShop(src, mode, shop) then return false, Data.text('tooFar') end
        for k, v in pairs(stored) do new[k] = v end
        new.headOverlays = cleanOverlays(stored.headOverlays, nil)
        if mode == 'barber' then
            new.hair = cleanHair(sent.hair, stored.hair)
            local changed = sameTable(new.hair, stored.hair, { 'style', 'texture', 'color', 'highlight' }) and 0 or 1
            local sentOverlays = type(sent.headOverlays) == 'table' and sent.headOverlays or {}
            for _, k in ipairs(Data.BARBER) do
                new.headOverlays[k] = cleanOverlay(sentOverlays[k], stored.headOverlays and stored.headOverlays[k])
                if not sameOverlay(new.headOverlays[k], stored.headOverlays and stored.headOverlays[k]) then changed = changed + 1 end
            end
            price = changed * Config.Prices.category
        elseif mode == 'surgeon' then
            new.headBlend = cleanHeadBlend(sent.headBlend, stored.headBlend)
            new.faceFeatures = cleanFeatures(sent.faceFeatures, stored.faceFeatures)
            new.eyeColor = int(sent.eyeColor, 0, Data.EYE_COLORS - 1, stored.eyeColor or 0)
            local sentOverlays = type(sent.headOverlays) == 'table' and sent.headOverlays or {}
            local changed = not sameTable(new.headBlend, stored.headBlend,
                    { 'shapeFirst', 'shapeSecond', 'skinFirst', 'skinSecond', 'shapeMix', 'skinMix' }, 0.011)
                or not sameTable(new.faceFeatures, stored.faceFeatures, Data.FACE_FEATURES, 0.011)
                or new.eyeColor ~= (stored.eyeColor or 0)
            for _, k in ipairs(Data.SKIN) do
                new.headOverlays[k] = cleanOverlay(sentOverlays[k], stored.headOverlays and stored.headOverlays[k])
                if not sameOverlay(new.headOverlays[k], stored.headOverlays and stored.headOverlays[k]) then changed = true end
            end
            price = changed and Config.Prices.surgeon or 0
        elseif mode == 'tattoo' then
            local before = select(2, cleanTattoos(stored.tattoos))
            local after
            new.tattoos, after = cleanTattoos(sent.tattoos)
            local list = Data.tattooList().byName
            for name in pairs(after) do
                if not before[name] then price = price + (list[name].price or Config.Prices.tattoo) end
            end
            for name in pairs(before) do
                if not after[name] then price = price + (Config.Prices.tattooRemove or 0) end
            end
        end
    end

    new.components = cleanClothes(sent.components, false)
    new.props = cleanClothes(sent.props, true)

    if price > 0 then
        local paid, missing = Bridge.pay(src, price, 'pure_appearance:' .. mode)
        if not paid then return false, Data.text('noMoney', { missing = missing or price }) end
    end
    Storage.save(src, new)
    freeCreation[src] = nil
    if price > 0 then
        TriggerClientEvent('ox_lib:notify', src, { description = Data.text('paid', { price = price }), type = 'success' })
    end
    return true, nil, new
end)

RegisterNetEvent('pure_appearance:server:migrate', function(appearance)
    local src = source
    if type(appearance) ~= 'table' or type(appearance.headBlend) ~= 'table' then return end
    if appearance.model ~= Data.MODELS.m and appearance.model ~= Data.MODELS.f then return end
    local stored = Storage.load(src)
    if not isLegacy(stored) then return end
    Storage.save(src, {
        model = (appearance.model == Data.MODELS.f) and Data.MODELS.f or Data.MODELS.m,
        headBlend = cleanHeadBlend(appearance.headBlend), faceFeatures = cleanFeatures(appearance.faceFeatures),
        headOverlays = cleanOverlays(appearance.headOverlays), hair = cleanHair(appearance.hair),
        eyeColor = int(appearance.eyeColor, 0, Data.EYE_COLORS - 1, 0), tattoos = {},
        components = cleanClothes(appearance.components, false), props = cleanClothes(appearance.props, true),
    })
end)

local function saveClothes(src, appearance)
    if type(appearance) ~= 'table' then return end
    local stored = Storage.load(src)
    if not stored or isLegacy(stored) then return end
    stored.components = cleanClothes(appearance.components, false)
    stored.props = cleanClothes(appearance.props, true)
    Storage.save(src, stored)
end
RegisterNetEvent('illenium-appearance:server:saveAppearance', function(appearance) saveClothes(source, appearance) end)
RegisterNetEvent('pure_appearance:server:saveClothes', function(appearance) saveClothes(source, appearance) end)

local function sendSkin(src)
    local stored = Storage.load(src)
    if stored then
        local model = stored.model
        if type(model) == 'string' then model = joaat(model) end
        TriggerClientEvent('qb-clothes:loadSkin', src, false, model, json.encode(stored))
    else
        TriggerClientEvent('qb-clothes:loadSkin', src, true)
    end
end
RegisterNetEvent('qb-clothes:loadPlayerSkin', function() sendSkin(source) end)
RegisterNetEvent('qb-clothing:loadPlayerSkin', function() sendSkin(source) end)

RegisterCommand(Config.AdminCommand or 'appearance', function(src, args)
    if src == 0 or not Bridge.isAdmin(src) then return end
    local target = tonumber(args[1]) or src
    if not GetPlayerName(target) then return end
    freeCreation[target] = true
    TriggerClientEvent('pure_appearance:client:open', target, 'creation')
end, false)

AddEventHandler('playerDropped', function()
    lastSave[source] = nil
    freeCreation[source] = nil
end)
