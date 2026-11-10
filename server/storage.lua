Storage = {}

local ready = false

CreateThread(function()
    if Bridge.name == 'standalone' then
        MySQL.query.await([[CREATE TABLE IF NOT EXISTS `pure_appearance` (
            `identifier` VARCHAR(80) NOT NULL,
            `appearance` LONGTEXT NOT NULL,
            PRIMARY KEY (`identifier`)
        )]])
    end
    ready = true
end)

local function decode(raw)
    if type(raw) ~= 'string' or raw == '' then return nil end
    local ok, t = pcall(json.decode, raw)
    return ok and type(t) == 'table' and t or nil
end

function Storage.load(src)
    while not ready do Wait(50) end
    local id = Bridge.identifier(src)
    if not id then return nil end
    if Bridge.name == 'qb' or Bridge.name == 'qbx' then
        local row = MySQL.single.await('SELECT model, skin FROM playerskins WHERE citizenid = ? AND active = 1 LIMIT 1', { id })
        local skin = row and decode(row.skin)
        if skin and skin.headBlend == nil then skin.__model = row.model end
        return skin
    elseif Bridge.name == 'esx' then
        return decode(MySQL.scalar.await('SELECT skin FROM users WHERE identifier = ?', { id }))
    end
    return decode(MySQL.scalar.await('SELECT appearance FROM pure_appearance WHERE identifier = ?', { id }))
end

function Storage.save(src, appearance)
    local id = Bridge.identifier(src)
    if not id then return false end
    local raw = json.encode(appearance)
    if Bridge.name == 'qb' or Bridge.name == 'qbx' then
        local model = appearance.model
        if type(model) == 'string' then model = joaat(model) end
        MySQL.query.await('DELETE FROM playerskins WHERE citizenid = ?', { id })
        MySQL.insert.await('INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, 1)', { id, tostring(model), raw })
    elseif Bridge.name == 'esx' then
        MySQL.update.await('UPDATE users SET skin = ? WHERE identifier = ?', { raw, id })
    else
        MySQL.insert.await('INSERT INTO pure_appearance (identifier, appearance) VALUES (?, ?) ON DUPLICATE KEY UPDATE appearance = VALUES(appearance)', { id, raw })
    end
    return true
end
