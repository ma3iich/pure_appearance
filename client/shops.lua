local function started(name)
    local s = GetResourceState(name)
    return s == 'started' or s == 'starting'
end

local function label(kind) return Data.text('shop_' .. kind) end

local function open(index)
    if Menu.isOpen then return end
    local shop = Config.Shops[index]
    Menu.open(shop.type, { shop = index })
end

local function blip(shop)
    local b = Config.Blips[shop.type]
    if not b or shop.blip == false then return end
    local id = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
    SetBlipSprite(id, b.sprite)
    SetBlipColour(id, b.color or 0)
    SetBlipScale(id, b.scale or 0.7)
    SetBlipAsShortRange(id, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label(shop.type))
    EndTextCommandSetBlipName(id)
end

local function spawnPed(shop)
    if not shop.ped then return end
    local model = joaat(shop.ped)
    lib.requestModel(model, 5000)
    local c = shop.coords
    local ped = CreatePed(4, model, c.x, c.y, c.z - 1.0, c.w, false, true)
    SetModelAsNoLongerNeeded(model)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    return ped
end

local useOx = started('ox_target')
local useQb = not useOx and started('qb-target')

local function setup(index, shop)
    blip(shop)
    local c = vector3(shop.coords.x, shop.coords.y, shop.coords.z)
    local name = 'pure_appearance_' .. index

    if useOx then
        exports.ox_target:addSphereZone({
            coords = c, radius = 1.6, debug = false,
            options = { { name = name, icon = 'fa-solid fa-scissors', label = label(shop.type),
                distance = Config.ShopDistance, onSelect = function() open(index) end } },
        })
    elseif useQb then
        exports['qb-target']:AddCircleZone(name, c, 1.6, { name = name, useZ = true }, {
            options = { { icon = 'fas fa-scissors', label = label(shop.type), action = function() open(index) end } },
            distance = Config.ShopDistance,
        })
    end

    local point = lib.points.new({ coords = c, distance = 40.0 })
    function point:onEnter() self.ped = spawnPed(shop) end
    function point:onExit()
        if self.ped and DoesEntityExist(self.ped) then DeleteEntity(self.ped) end
        self.ped = nil
    end
    if not useOx and not useQb then
        local key = lib.points.new({ coords = c, distance = Config.ShopDistance })
        function key:onEnter() lib.showTextUI(Data.text('press', { shop = label(shop.type) })) end
        function key:onExit() lib.hideTextUI() end
        function key:nearby()
            if not Menu.isOpen and IsControlJustReleased(0, 38) then
                lib.hideTextUI()
                open(index)
            end
        end
    end
end

for index, shop in ipairs(Config.Shops) do
    if shop.type ~= 'surgeon' or Config.Surgeon ~= false then setup(index, shop) end
end

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for _, p in ipairs(lib.points.getAllPoints()) do
        if p.ped and DoesEntityExist(p.ped) then DeleteEntity(p.ped) end
    end
end)
