Convert = {}

local function v(data, key) return data[key] or { item = 0, texture = 0 } end

function Convert.isQbClothing(data)
    return type(data) == 'table' and data.headBlend == nil and (data.face ~= nil or data.facemix ~= nil or data['t-shirt'] ~= nil)
end

local COMPONENTS = { pants = 4, arms = 3, ['t-shirt'] = 8, vest = 9, torso2 = 11, shoes = 6, mask = 1, decals = 10, accessory = 7, bag = 5 }
local PROPS = { hat = 0, glass = 1, ear = 2, watch = 6, bracelet = 7 }
local OVERLAYS = { eyebrows = 2, beard = 1, blush = 5, lipstick = 8, makeup = 4, ageing = 3 }
local FEATURES = { 'nose_0', 'nose_1', 'nose_2', 'nose_3', 'nose_4', 'nose_5', 'eyebrown_high', 'eyebrown_forward',
    'cheek_1', 'cheek_2', 'cheek_3', 'eye_opening', 'lips_thickness', 'jaw_bone_width', 'jaw_bone_back_lenght',
    'chimp_bone_lowering', 'chimp_bone_lenght', 'chimp_bone_width', 'chimp_hole', 'neck_thikness' }

function Convert.applyQbClothing(ped, data)
    for i = 0, 11 do SetPedComponentVariation(ped, i, 0, 0, 0) end
    for i = 0, 7 do ClearPedProp(ped, i) end
    local face, face2, mix = v(data, 'face'), data.face2 or { item = 0, texture = 0 }, data.facemix or { shapeMix = 0.0, skinMix = 0.0 }
    SetPedHeadBlendData(ped, face.item, face2.item, 0, face.texture, face2.texture, 0,
        (tonumber(mix.shapeMix) or 0) + 0.0, (tonumber(mix.skinMix) or 0) + 0.0, 0.0, false)
    local hair = v(data, 'hair')
    SetPedComponentVariation(ped, 2, hair.item, 0, 0)
    SetPedHairColor(ped, hair.texture, hair.texture)
    for key, id in pairs(OVERLAYS) do
        local o = v(data, key)
        SetPedHeadOverlay(ped, id, o.item, 1.0)
        SetPedHeadOverlayColor(ped, id, 1, o.texture, 0)
    end
    for key, id in pairs(COMPONENTS) do
        local c = v(data, key)
        SetPedComponentVariation(ped, id, c.item, c.texture, 0)
    end
    for key, id in pairs(PROPS) do
        local p = v(data, key)
        if p.item ~= -1 and p.item ~= 0 then SetPedPropIndex(ped, id, p.item, p.texture, true) else ClearPedProp(ped, id) end
    end
    local eye = v(data, 'eye_color')
    if eye.item and eye.item > 0 then SetPedEyeColor(ped, eye.item) end
    local moles = v(data, 'moles')
    if moles.item and moles.item > 0 then SetPedHeadOverlay(ped, 9, moles.item, (moles.texture or 0) / 10) end
    for i = 1, #FEATURES do
        SetPedFaceFeature(ped, i - 1, (v(data, FEATURES[i]).item or 0) / 10)
    end
    return Appearance.get(ped)
end
