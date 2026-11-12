Bridge = { name = 'standalone' }

local function started(resource)
    local s = GetResourceState(resource)
    return s == 'started' or s == 'starting'
end

do
    local wanted = Config.Framework or 'auto'
    if wanted == 'auto' then
        if started('qbx_core') then Bridge.name = 'qbx'
        elseif started('qb-core') then Bridge.name = 'qb'
        elseif started('es_extended') then Bridge.name = 'esx'
        end
    else
        Bridge.name = wanted
    end
end

if Bridge.name == 'esx' then
    CreateThread(function()
        Wait(3000)
        for _, name in ipairs({ 'esx_skin', 'skinchanger' }) do
            if GetResourceState(name) == 'started' and GetResourceMetadata(name, 'name', 0) ~= GetCurrentResourceName() then
                print(('^3[%s] %s is started: remove it from server.cfg, %s replaces it (otherwise two menus open).^0'):format(
                    GetCurrentResourceName(), name, GetCurrentResourceName()))
            end
        end
    end)
end

local core
local function qb()
    if not core then core = exports['qb-core']:GetCoreObject() end
    return core
end
local function esx()
    if not core then core = exports.es_extended:getSharedObject() end
    return core
end

function Bridge.player(src)
    if Bridge.name == 'qbx' then return exports.qbx_core:GetPlayer(src) end
    if Bridge.name == 'qb' then return qb().Functions.GetPlayer(src) end
    if Bridge.name == 'esx' then return esx().GetPlayerFromId(src) end
end

local function multicharacter(src)
    if GetResourceState('pure_multicharacter') ~= 'started' then return nil end
    local ok, char = pcall(function() return exports.pure_multicharacter:GetCharacter(src) end)
    return ok and type(char) == 'table' and char or nil
end

function Bridge.identifier(src)
    if Bridge.name == 'standalone' then
        local char = multicharacter(src)
        if char and char.id then return 'pmc:' .. char.id end
        return GetPlayerIdentifierByType(src, 'license')
    end
    local p = Bridge.player(src)
    if not p then return end
    if Bridge.name == 'esx' then return p.identifier end
    return p.PlayerData and p.PlayerData.citizenid
end

function Bridge.isFemale(src)
    if Bridge.name == 'standalone' then
        local char = multicharacter(src)
        return char and tonumber(char.gender) == 1 or false
    end
    local p = Bridge.player(src)
    if not p then return false end
    if Bridge.name == 'esx' then
        local sex = p.get and p.get('sex')
        return sex == 'f' or sex == 'F'
    end
    local ci = p.PlayerData and p.PlayerData.charinfo
    return ci and tonumber(ci.gender) == 1 or false
end

function Bridge.isAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce or 'command')
end

local function money(src, account)
    local p = Bridge.player(src)
    if not p then return 0 end
    if Bridge.name == 'esx' then
        if account == 'bank' then
            local a = p.getAccount('bank')
            return a and a.money or 0
        end
        return p.getMoney()
    end
    return p.Functions.GetMoney(account) or 0
end

local function take(src, account, amount, reason)
    local p = Bridge.player(src)
    if not p then return false end
    if Bridge.name == 'esx' then
        if account == 'bank' then p.removeAccountMoney('bank', amount, reason) else p.removeMoney(amount, reason) end
        return true
    end
    return p.Functions.RemoveMoney(account, amount, reason) ~= false
end

local function payItem(src, amount)
    local item = Config.StandaloneMoneyItem
    if not item or item == '' or GetResourceState('ox_inventory') ~= 'started' then return true end
    local count = exports.ox_inventory:GetItemCount(src, item) or 0
    if count < amount then return false, amount - count end
    return exports.ox_inventory:RemoveItem(src, item, amount) and true or false, 0
end

function Bridge.pay(src, amount, reason)
    if amount <= 0 then return true end
    if Bridge.name == 'standalone' then return payItem(src, amount) end
    local first = Config.PayWith == 'bank' and 'bank' or 'cash'
    local second = first == 'cash' and 'bank' or 'cash'
    for _, account in ipairs({ first, second }) do
        if money(src, account) >= amount then
            return take(src, account, amount, reason)
        end
    end
    return false, amount - math.max(money(src, first), money(src, second))
end
