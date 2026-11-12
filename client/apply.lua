Appearance = {}

local currentTattoos = {}

local FREEMODE = { [`mp_m_freemode_01`] = 'mp_m_freemode_01', [`mp_f_freemode_01`] = 'mp_f_freemode_01' }

local function float(n) return (tonumber(n) or 0) + 0.0 end

local function round(n, d)
    return tonumber(string.format('%.' .. (d or 0) .. 'f', n))
end

function Appearance.isFreemode(ped)
    return FREEMODE[GetEntityModel(ped)] ~= nil
end

function Appearance.sex(ped)
    local m = GetEntityModel(ped or PlayerPedId())
    if m == `mp_f_freemode_01` then return 'f' end
    if m == `mp_m_freemode_01` then return 'm' end
    return IsPedMale(ped or PlayerPedId()) and 'm' or 'f'
end

function Appearance.getModel(ped)
    local hash = GetEntityModel(ped)
    return FREEMODE[hash] or hash
end

function Appearance.getComponents(ped)
    local list = {}
    for i = 1, #Data.COMPONENTS do
        local id = Data.COMPONENTS[i]
        list[i] = { component_id = id, drawable = GetPedDrawableVariation(ped, id), texture = GetPedTextureVariation(ped, id) }
    end
    return list
end

function Appearance.getProps(ped)
    local list = {}
    for i = 1, #Data.PROPS do
        local id = Data.PROPS[i]
        list[i] = { prop_id = id, drawable = GetPedPropIndex(ped, id), texture = GetPedPropTextureIndex(ped, id) }
    end
    return list
end

function Appearance.getHeadBlend(ped)
    local shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix =
        Citizen.InvokeNative(0x2746BD9D88C5C5D0, ped,
            Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0),
            Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0),
            Citizen.PointerValueFloatInitialized(0), Citizen.PointerValueFloatInitialized(0), Citizen.PointerValueFloatInitialized(0))
    local function mix(v) v = tonumber(string.sub(tostring(v or 0), 0, 4)) or 0 return math.min(1, math.max(0, v)) end
    return {
        shapeFirst = shapeFirst, shapeSecond = shapeSecond, shapeThird = shapeThird,
        skinFirst = skinFirst, skinSecond = skinSecond, skinThird = skinThird,
        shapeMix = mix(shapeMix), skinMix = mix(skinMix), thirdMix = mix(thirdMix),
    }
end

function Appearance.getFaceFeatures(ped)
    local t = {}
    for i = 1, #Data.FACE_FEATURES do
        t[Data.FACE_FEATURES[i]] = round(GetPedFaceFeature(ped, i - 1), 2)
    end
    return t
end

function Appearance.getHeadOverlays(ped)
    local t = {}
    for i = 1, #Data.HEAD_OVERLAYS do
        local _, value, _, first, second, opacity = GetPedHeadOverlayData(ped, i - 1)
        if value == 255 then value, opacity = 0, 0 else opacity = round(opacity, 2) end
        t[Data.HEAD_OVERLAYS[i]] = { style = value, opacity = opacity, color = first, secondColor = second }
    end
    return t
end

function Appearance.getHair(ped)
    return {
        style = GetPedDrawableVariation(ped, 2),
        texture = GetPedTextureVariation(ped, 2),
        color = GetPedHairColor(ped),
        highlight = GetPedHairHighlightColor(ped),
    }
end

function Appearance.getTattoos()
    return currentTattoos
end

function Appearance.get(ped)
    local eye = GetPedEyeColor(ped)
    return {
        model = Appearance.getModel(ped),
        headBlend = Appearance.getHeadBlend(ped),
        faceFeatures = Appearance.getFaceFeatures(ped),
        headOverlays = Appearance.getHeadOverlays(ped),
        components = Appearance.getComponents(ped),
        props = Appearance.getProps(ped),
        hair = Appearance.getHair(ped),
        tattoos = currentTattoos,
        eyeColor = (eye >= 0 and eye < Data.EYE_COLORS) and eye or 0,
    }
end

function Appearance.setHeadBlend(ped, hb)
    if not hb or not Appearance.isFreemode(ped) then return end
    SetPedHeadBlendData(ped, hb.shapeFirst or 0, hb.shapeSecond or 0, hb.shapeThird or 0, hb.skinFirst or 0,
        hb.skinSecond or 0, hb.skinThird or 0, float(hb.shapeMix), float(hb.skinMix), float(hb.thirdMix), false)
end

function Appearance.setFaceFeatures(ped, ff)
    if not ff then return end
    for i = 1, #Data.FACE_FEATURES do
        SetPedFaceFeature(ped, i - 1, float(ff[Data.FACE_FEATURES[i]]))
    end
end

function Appearance.setHeadOverlays(ped, ho)
    if not ho then return end
    for i = 1, #Data.HEAD_OVERLAYS do
        local key = Data.HEAD_OVERLAYS[i]
        local o = ho[key]
        if o then
            SetPedHeadOverlay(ped, i - 1, tonumber(o.style) or 0, float(o.opacity))
            if o.color then
                local colorType = (key == 'blush' or key == 'lipstick' or key == 'makeUp') and 2 or 1
                SetPedHeadOverlayColor(ped, i - 1, colorType, o.color, o.secondColor or o.color)
            end
        end
    end
end

local function applyTattoos(ped, tattoos)
    ClearPedDecorations(ped)
    local male = Appearance.sex(ped) == 'm'
    for _, list in pairs(tattoos or {}) do
        for i = 1, #list do
            local t = list[i]
            local hash = male and t.hashMale or t.hashFemale
            if hash and hash ~= '' and t.collection then
                for _ = 1, math.max(1, math.floor((tonumber(t.opacity) or 0.1) * 10)) do
                    AddPedDecorationFromHashes(ped, joaat(t.collection), joaat(hash))
                end
            end
        end
    end
end

function Appearance.setTattoos(ped, tattoos)
    currentTattoos = tattoos or {}
    applyTattoos(ped, currentTattoos)
end

function Appearance.previewTattoos(ped, tattoos)
    applyTattoos(ped, tattoos)
end

function Appearance.setHair(ped, hair, tattoos)
    if not hair then return end
    SetPedComponentVariation(ped, 2, tonumber(hair.style) or 0, tonumber(hair.texture) or 0, 0)
    SetPedHairColor(ped, tonumber(hair.color) or 0, tonumber(hair.highlight) or 0)
    if Appearance.isFreemode(ped) then applyTattoos(ped, tattoos or currentTattoos) end
end

function Appearance.setEyeColor(ped, eye)
    if eye then SetPedEyeColor(ped, eye) end
end

function Appearance.setComponent(ped, c)
    if not c then return end
    if Appearance.isFreemode(ped) and (c.component_id == 0 or c.component_id == 2) then return end
    SetPedComponentVariation(ped, c.component_id, c.drawable, c.texture, 0)
end

function Appearance.setComponents(ped, list)
    for _, c in pairs(list or {}) do Appearance.setComponent(ped, c) end
end

function Appearance.setProp(ped, p)
    if not p then return end
    if p.drawable == -1 then ClearPedProp(ped, p.prop_id) else SetPedPropIndex(ped, p.prop_id, p.drawable, p.texture, false) end
end

function Appearance.setProps(ped, list)
    for _, p in pairs(list or {}) do Appearance.setProp(ped, p) end
end

function Appearance.set(ped, a)
    if not a then return end
    Appearance.setComponents(ped, a.components)
    Appearance.setProps(ped, a.props)
    if a.headBlend then Appearance.setHeadBlend(ped, a.headBlend) end
    if a.faceFeatures then Appearance.setFaceFeatures(ped, a.faceFeatures) end
    if a.headOverlays then Appearance.setHeadOverlays(ped, a.headOverlays) end
    if a.hair then Appearance.setHair(ped, a.hair, a.tattoos) end
    if a.eyeColor then Appearance.setEyeColor(ped, a.eyeColor) end
    if a.tattoos and ped == PlayerPedId() then Appearance.setTattoos(ped, a.tattoos) elseif a.tattoos then applyTattoos(ped, a.tattoos) end
end

local modelBusy = false

function Appearance.setPlayerModel(model)
    if type(model) == 'string' then model = joaat(model) end
    if not model or not IsModelInCdimage(model) then return PlayerPedId() end
    while modelBusy do Wait(50) end
    if GetEntityModel(PlayerPedId()) == model then return PlayerPedId() end
    modelBusy = true
    RequestModel(model)
    local limit = GetGameTimer() + 30000
    while not HasModelLoaded(model) and GetGameTimer() < limit do Wait(50) end
    if not HasModelLoaded(model) then
        modelBusy = false
        return PlayerPedId()
    end
    SetPlayerModel(PlayerId(), model)
    Wait(150)
    SetModelAsNoLongerNeeded(model)
    modelBusy = false
    local ped = PlayerPedId()
    if Appearance.isFreemode(ped) then
        SetPedDefaultComponentVariation(ped)
        if model == `mp_f_freemode_01` then
            SetPedHeadBlendData(ped, 45, 21, 0, 20, 15, 0, 0.3, 0.1, 0.0, false)
        else
            SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
        end
    end
    currentTattoos = {}
    return ped
end

function Appearance.reset(ped)
    if not Appearance.isFreemode(ped) then return end
    SetPedDefaultComponentVariation(ped)
    if GetEntityModel(ped) == `mp_f_freemode_01` then
        SetPedHeadBlendData(ped, 45, 21, 0, 20, 15, 0, 0.3, 0.1, 0.0, false)
    else
        SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
    end
    for i = 0, #Data.FACE_FEATURES - 1 do SetPedFaceFeature(ped, i, 0.0) end
    for i = 0, #Data.HEAD_OVERLAYS - 1 do SetPedHeadOverlay(ped, i, 255, 0.0) end
    SetPedComponentVariation(ped, 2, 0, 0, 0)
    SetPedHairColor(ped, 0, 0)
    SetPedEyeColor(ped, 0)
    ClearPedDecorations(ped)
    if ped == PlayerPedId() then currentTattoos = {} end
end

function Appearance.setPlayer(a)
    if not a then return end
    local before = PlayerPedId()
    local health, armour = GetEntityHealth(before), GetPedArmour(before)
    local ped = Appearance.setPlayerModel(a.model)
    Appearance.set(ped, a)
    if ped ~= before and health > 100 then
        SetEntityMaxHealth(ped, 200)
        SetEntityHealth(ped, health)
        SetPedArmour(ped, armour)
    end
    return ped
end

for name, fn in pairs({
    getPedModel = Appearance.getModel, getPedComponents = Appearance.getComponents, getPedProps = Appearance.getProps,
    getPedHeadBlend = Appearance.getHeadBlend, getPedFaceFeatures = Appearance.getFaceFeatures,
    getPedHeadOverlays = Appearance.getHeadOverlays, getPedHair = Appearance.getHair, getPedAppearance = Appearance.get,
    getPedTattoos = function() return Appearance.getTattoos() end,
    setPlayerModel = Appearance.setPlayerModel, setPedHeadBlend = Appearance.setHeadBlend,
    setPedFaceFeatures = Appearance.setFaceFeatures, setPedHeadOverlays = Appearance.setHeadOverlays,
    setPedHair = Appearance.setHair, setPedEyeColor = Appearance.setEyeColor, setPedComponent = Appearance.setComponent,
    setPedComponents = Appearance.setComponents, setPedProp = Appearance.setProp, setPedProps = Appearance.setProps,
    setPlayerAppearance = Appearance.setPlayer, setPedAppearance = Appearance.set, setPedTattoos = Appearance.setTattoos,
}) do
    exports(name, fn)
end
