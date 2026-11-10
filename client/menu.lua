Menu = { isOpen = false }

local state

local UNDERWEAR = {
    m = { [3] = { 15, 0 }, [4] = { 14, 12 }, [6] = { 34, 0 }, [8] = { 15, 0 }, [11] = { 15, 0 } },
    f = { [3] = { 15, 0 }, [4] = { 15, 0 }, [6] = { 35, 0 }, [8] = { 14, 0 }, [11] = { 15, 0 } },
}

local function notify(text, kind)
    lib.notify({ description = text, type = kind or 'inform' })
end
Menu.notify = notify

local function text(key, vars) return Data.text(key, vars) end

function Menu.underwear(ped)
    local sex = Appearance.sex(ped)
    for i = 1, 11 do
        if i ~= 2 then SetPedComponentVariation(ped, i, 0, 0, 0) end
    end
    for id, v in pairs(UNDERWEAR[sex]) do SetPedComponentVariation(ped, id, v[1], v[2], 0) end
    for _, id in ipairs(Data.PROPS) do ClearPedProp(ped, id) end
end

local function hairItems(ped)
    local sex = Appearance.sex(ped)
    local items = {}
    local total = GetNumberOfPedDrawableVariations(ped, 2)
    for d = 0, total - 1 do
        local coll = string.lower(GetPedCollectionNameFromDrawable(ped, 2, d) or '')
        local loc = GetPedCollectionLocalIndexFromDrawable(ped, 2, d)
        local folder = coll == '' and '_base' or coll
        items[#items + 1] = {
            d = d,
            t = GetNumberOfPedTextureVariations(ped, 2, d),
            addon = not NativeCollections[coll],
            img = d > 0 and ('miniatures/' .. sex .. '/c2/' .. folder .. '/' .. loc .. '.webp') or nil,
        }
    end
    return { items = items, textures = GetNumberOfPedTextureVariations(ped, 2, GetPedDrawableVariation(ped, 2)) }
end

local function addonFaces(ped)
    local ids = {}
    local model = Appearance.getModel(ped)
    if type(Config.AddonFaces) == 'table' then
        ids = Config.AddonFaces[model] or {}
    else
        local count = GetNumberOfPedDrawableVariations(ped, 0)
        for id = Data.NATIVE_FACES, count - 1 do ids[#ids + 1] = id end
    end
    local sex = Appearance.sex(ped)
    local list = {}
    for _, id in ipairs(ids) do
        local file = 'web/portraits/' .. sex .. '/' .. id .. '.webp'
        local exists = LoadResourceFile(GetCurrentResourceName(), file) ~= nil
        list[#list + 1] = { id = id, img = exists and ('portraits/' .. sex .. '/' .. id .. '.webp') or nil }
    end
    return { natives = Data.NATIVE_FACES, portrait = 'https://nui-img/char_creator_portraits/{name}', addons = list }
end

local function clothesItems(ped)
    local sex = Appearance.sex(ped)
    local images = GetResourceState('pure_clothing') == 'started'
    local cats = {}
    for _, c in ipairs(Config.CreationClothes or {}) do
        local items = {}
        for d = 0, GetNumberOfPedDrawableVariations(ped, c.id) - 1 do
            local coll = string.lower(GetPedCollectionNameFromDrawable(ped, c.id, d) or '')
            if NativeCollections[coll] or Config.CreationAddonClothes then
                local loc = GetPedCollectionLocalIndexFromDrawable(ped, c.id, d)
                items[#items + 1] = {
                    d = d,
                    t = GetNumberOfPedTextureVariations(ped, c.id, d),
                    img = images and ('https://cfx-nui-pure_clothing/web/miniatures/' .. sex .. '/c' .. c.id .. '/'
                        .. (coll == '' and '_base' or coll) .. '/' .. loc .. '.webp') or nil,
                }
            end
        end
        cats[#cats + 1] = { id = c.id, key = c.key, items = items }
    end
    return { categories = cats }
end

local function colors()
    local hair, makeup = {}, {}
    for i = 0, GetNumHairColors() - 1 do hair[#hair + 1] = { GetPedHairRgbColor(i) } end
    for i = 0, GetNumMakeupColors() - 1 do makeup[#makeup + 1] = { GetPedMakeupRgbColor(i) } end
    return { hair = hair, makeup = makeup }
end

local function overlays()
    local t = {}
    for i = 1, #Data.HEAD_OVERLAYS do t[Data.HEAD_OVERLAYS[i]] = GetPedHeadOverlayNum(i - 1) end
    return t
end

local function tattoos(ped)
    local male = Appearance.sex(ped) == 'm'
    local out = {}
    for zone, list in pairs(Data.tattooList().byZone) do
        local z = {}
        for i = 1, #list do
            local t = list[i]
            local hash = male and t.hashMale or t.hashFemale
            if hash and hash ~= '' then
                z[#z + 1] = { name = t.name, label = t.label, collection = t.collection, zone = zone, price = t.price,
                    addon = t.addon, hashMale = t.hashMale, hashFemale = t.hashFemale }
            end
        end
        out[zone] = z
    end
    return out
end

local function payload(mode, ped)
    local loc = Data.locale()
    local data = Appearance.get(ped)
    data.props = nil
    return {
        mode = mode,
        lang = loc.lang,
        locale = loc.all.ui,
        sections = Data.SECTIONS[mode],
        ui = Config.Ui,
        keys = Config.Keys,
        canChangeSex = mode == 'creation',
        sex = Appearance.sex(ped),
        models = Data.MODELS,
        prices = { category = Config.Prices.category, surgeon = Config.Prices.surgeon, tattooRemove = Config.Prices.tattooRemove },
        heritage = addonFaces(ped),
        hair = hairItems(ped),
        colors = colors(),
        overlays = overlays(),
        eyeColors = Data.EYE_COLORS,
        tattoos = (mode == 'tattoo' or mode == 'creation') and tattoos(ped) or {},
        clothes = mode == 'creation' and clothesItems(ped) or nil,
        data = data,
    }
end

local FIRST_FRAME = { creation = 'face', barber = 'face', surgeon = 'face', tattoo = 'face' }

function Menu.open(mode, opts)
    if Menu.isOpen or not Data.SECTIONS[mode] then return end
    if mode == 'surgeon' and Config.Surgeon == false then return end
    opts = opts or {}
    local ped = PlayerPedId()
    if not Appearance.isFreemode(ped) then
        return notify(text('notFreemode'), 'error')
    end
    Menu.isOpen = true
    state = { mode = mode, shop = opts.shop, onSave = opts.onSave, onCancel = opts.onCancel, origin = Appearance.get(ped) }
    RequestStreamedTextureDict('char_creator_portraits', false)
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    Camera.start(FIRST_FRAME[mode])
    CreateThread(function()
        local limit = GetGameTimer() + 1500
        while not HasStreamedTextureDictLoaded('char_creator_portraits') and GetGameTimer() < limit do Wait(0) end
        if not Menu.isOpen then return end
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', data = payload(mode, PlayerPedId()) })
    end)
end

function Menu.close(restore)
    if not Menu.isOpen then return end
    local s = state
    Menu.isOpen = false
    state = nil
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    Camera.stop()
    SetStreamedTextureDictAsNoLongerNeeded('char_creator_portraits')
    if restore and s then
        local ped = Appearance.setPlayer(s.origin)
        Appearance.setTattoos(ped, s.origin.tattoos)
    end
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    return s
end

local function ped() return PlayerPedId() end

RegisterNUICallback('pa_head_blend', function(hb, cb)
    cb({})
    if state and type(hb) == 'table' then Appearance.setHeadBlend(ped(), hb) end
end)

RegisterNUICallback('pa_face_feature', function(ff, cb)
    cb({})
    if state and type(ff) == 'table' then Appearance.setFaceFeatures(ped(), ff) end
end)

RegisterNUICallback('pa_head_overlay', function(ho, cb)
    cb({})
    if state and type(ho) == 'table' then Appearance.setHeadOverlays(ped(), ho) end
end)

RegisterNUICallback('pa_hair', function(hair, cb)
    if not state or type(hair) ~= 'table' then return cb({}) end
    local p = ped()
    Appearance.setHair(p, hair, Appearance.getTattoos())
    cb({ textures = GetNumberOfPedTextureVariations(p, 2, tonumber(hair.style) or 0) })
end)

RegisterNUICallback('pa_eye_color', function(eye, cb)
    cb({})
    if state then Appearance.setEyeColor(ped(), tonumber(eye)) end
end)

RegisterNUICallback('pa_tattoos', function(data, cb)
    cb({})
    if state and type(data) == 'table' and type(data.tattoos) == 'table' then
        Appearance.previewTattoos(ped(), data.tattoos)
    end
end)

RegisterNUICallback('pa_model', function(data, cb)
    if not state or state.mode ~= 'creation' or type(data) ~= 'table' then return cb(false) end
    local model = data.model
    if model ~= Data.MODELS.m and model ~= Data.MODELS.f then return cb(false) end
    local p = Appearance.setPlayerModel(model)
    Appearance.reset(p)
    FreezeEntityPosition(p, true)
    SetEntityInvincible(p, true)
    Menu.underwear(p)
    local a = Appearance.get(p)
    a.props = nil
    cb({ heritage = addonFaces(p), hair = hairItems(p), clothes = clothesItems(p), data = a })
end)

local CLOTHES = {}
for _, c in ipairs(Config.CreationClothes or {}) do CLOTHES[c.id] = true end

RegisterNUICallback('pa_component', function(data, cb)
    cb({})
    if not state or state.mode ~= 'creation' or type(data) ~= 'table' then return end
    local id, d, t = tonumber(data.component_id), tonumber(data.drawable), tonumber(data.texture)
    if not id or not CLOTHES[id] or not d or not t then return end
    SetPedComponentVariation(ped(), id, d, t, 0)
end)

RegisterNUICallback('pa_camera', function(name, cb)
    cb({})
    Camera.frame(name)
end)

RegisterNUICallback('pa_cam_rotate', function(data, cb)
    cb({})
    if type(data) == 'table' then Camera.rotate(data.dx) end
end)

RegisterNUICallback('pa_cam_zoom', function(data, cb)
    cb({})
    if type(data) == 'table' then Camera.zoom(data.dir) end
end)

RegisterNUICallback('pa_save', function(data, cb)
    if not state then return cb({ ok = false }) end
    local s = state
    local p = ped()
    local appearance = Appearance.get(p)
    if s.mode == 'tattoo' or s.mode == 'creation' then
        appearance.tattoos = type(data) == 'table' and type(data.appearance) == 'table' and data.appearance.tattoos or {}
    end
    local ok, err, saved = lib.callback.await('pure_appearance:save', false, s.mode, s.shop, appearance)
    if not ok then return cb({ ok = false, error = err or text('error') }) end
    cb({ ok = true })
    Menu.close(false)
    if saved then Appearance.setTattoos(p, saved.tattoos) end
    if s.onSave then s.onSave(saved or appearance) end
    TriggerEvent('pure_appearance:client:saved', s.mode, saved or appearance)
end)

RegisterNUICallback('pa_cancel', function(_, cb)
    cb({})
    if not state or state.mode == 'creation' then return end
    local s = Menu.close(true)
    if s and s.onCancel then s.onCancel() end
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() and Menu.isOpen then
        SetNuiFocus(false, false)
        Camera.stop()
        local p = PlayerPedId()
        FreezeEntityPosition(p, false)
        SetEntityInvincible(p, false)
    end
end)

exports('openMenu', function(mode, opts) Menu.open(mode, opts) end)
exports('isMenuOpen', function() return Menu.isOpen end)
