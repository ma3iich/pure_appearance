local function decode(data)
    if type(data) == 'string' then
        local ok, t = pcall(json.decode, data)
        return ok and t or nil
    end
    return data
end

local function apply(saved)
    if type(saved) ~= 'table' then return false end
    if Convert.isQbClothing(saved) then
        local ped = Appearance.setPlayerModel(tonumber(saved.__model) or saved.__model or Data.MODELS.m)
        if not Appearance.isFreemode(ped) then return false end
        Wait(100)
        local a = Convert.applyQbClothing(ped, saved)
        if a.model == Data.MODELS.m or a.model == Data.MODELS.f then
            TriggerServerEvent('pure_appearance:server:migrate', a)
        end
        return true
    end
    Appearance.setPlayer(saved)
    return true
end

local function loadSaved()
    local saved = lib.callback.await('pure_appearance:load', false)
    if apply(saved) then TriggerEvent('pure_appearance:client:loaded') end
    return saved
end
exports('reloadSkin', loadSaved)

RegisterCommand(Config.ReloadCommand or 'reloadskin', function()
    if Menu.isOpen or IsPedDeadOrDying(PlayerPedId(), true) or IsPedInAnyVehicle(PlayerPedId(), false) then return end
    loadSaved()
end, false)

RegisterNetEvent('illenium-appearance:client:reloadSkin', function()
    if not Menu.isOpen then loadSaved() end
end)

RegisterNetEvent('pure_appearance:client:open', function(mode)
    Menu.open(mode)
end)

local function createCharacter(female, onSave, onCancel)
    local ped = Appearance.setPlayerModel(female and Data.MODELS.f or Data.MODELS.m)
    Appearance.reset(ped)
    Menu.underwear(ped)
    Wait(200)
    Menu.open('creation', { onSave = onSave, onCancel = onCancel })
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(500)
    loadSaved()
end)

RegisterNetEvent('qb-clothes:client:CreateFirstCharacter', function(isFemale)
    local female = isFemale == true
    if isFemale == nil then
        local pd
        if GetResourceState('qbx_core') == 'started' then
            pd = exports.qbx_core:GetPlayerData()
        elseif GetResourceState('qb-core') == 'started' then
            pd = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
        end
        female = pd and pd.charinfo and tonumber(pd.charinfo.gender) == 1 or false
    end
    createCharacter(female)
end)

RegisterNetEvent('qb-clothes:loadSkin', function(isNew, model, data)
    if isNew then return end
    local a = decode(data)
    if type(a) ~= 'table' then return end
    if Convert.isQbClothing(a) then
        a.__model = model
        apply(a)
    else
        Appearance.setPlayer(a)
    end
end)

AddEventHandler('qb-clothing:client:loadPlayerClothing', function(data, ped)
    ped = ped or PlayerPedId()
    data = decode(data)
    if type(data) ~= 'table' then return end
    if Convert.isQbClothing(data) then Convert.applyQbClothing(ped, data) else Appearance.set(ped, data) end
end)

RegisterNetEvent('qb-clothing:client:openMenu', function()
    Menu.open('creation')
end)

local OUTFIT_COMPONENTS = { pants = 4, arms = 3, ['t-shirt'] = 8, vest = 9, torso2 = 11, shoes = 6, decals = 10, accessory = 7, bag = 5, mask = 1 }
local OUTFIT_PROPS = { hat = 0, glass = 1, ear = 2, watch = 6, bracelet = 7 }

RegisterNetEvent('qb-clothing:client:loadOutfit', function(data)
    local outfit = type(data) == 'table' and (data.outfitData or data) or nil
    if type(outfit) ~= 'table' then return end
    local ped = PlayerPedId()
    for key, id in pairs(OUTFIT_COMPONENTS) do
        local v = outfit[key]
        if type(v) == 'table' and v.item then SetPedComponentVariation(ped, id, v.item, v.texture or 0, 0) end
    end
    for key, id in pairs(OUTFIT_PROPS) do
        local v = outfit[key]
        if type(v) == 'table' and v.item then
            if v.item == -1 then ClearPedProp(ped, id) else SetPedPropIndex(ped, id, v.item, v.texture or 0, true) end
        end
    end
end)

RegisterNetEvent('qb-clothing:client:openOutfitMenu', function()
    Menu.notify(Data.text('noOutfits'), 'error')
end)

AddEventHandler('pure_multicharacter:client:loaded', function(_, isNew)
    if not isNew then loadSaved() end
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(500)
    loadSaved()
end)

AddEventHandler('esx_skin:openSaveableMenu', function(onSave, onCancel)
    createCharacter(false, onSave, onCancel)
end)

AddEventHandler('skinchanger:loadSkin', function(skin, cb)
    skin = decode(skin)
    if type(skin) == 'table' and skin.headBlend then Appearance.setPlayer(skin) end
    if cb then cb() end
end)

AddEventHandler('skinchanger:getSkin', function(cb)
    if cb then cb(Appearance.get(PlayerPedId())) end
end)
