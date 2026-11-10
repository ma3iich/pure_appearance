if not Config.CheckUpdates then return end

local REPOSITORY = 'ma3iich/pure_appearance'
local DELAY = 10000
local resource = GetCurrentResourceName()

local function parseVersion(text)
    if type(text) ~= 'string' then return end
    local major, minor, patch = text:match('^%s*v?(%d+)%.(%d+)%.?(%d*)')
    if not major then return end
    return { tonumber(major), tonumber(minor), tonumber(patch) or 0 }
end

local function isNewer(remote, current)
    for i = 1, 3 do
        if remote[i] > current[i] then return true end
        if remote[i] < current[i] then return false end
    end
    return false
end

local function formatVersion(v)
    return ('%d.%d.%d'):format(v[1], v[2], v[3])
end

CreateThread(function()
    Wait(DELAY)

    local current = parseVersion(GetResourceMetadata(resource, 'version', 0))
    if not current then return end

    local url = ('https://api.github.com/repos/%s/releases/latest'):format(REPOSITORY)
    local headers = {
        ['User-Agent'] = resource,
        ['Accept'] = 'application/vnd.github+json',
    }

    PerformHttpRequest(url, function(status, body)
        if status ~= 200 or type(body) ~= 'string' then return end

        local ok, release = pcall(json.decode, body)
        if not ok or type(release) ~= 'table' then return end

        local latest = parseVersion(release.tag_name)
        if not latest then return end

        if isNewer(latest, current) then
            print(('^3[%s] Update available: %s -> %s  https://github.com/%s/releases/latest^0'):format(
                resource, formatVersion(current), formatVersion(latest), REPOSITORY))
        else
            print(('[%s] Up to date (%s)'):format(resource, formatVersion(current)))
        end
    end, 'GET', '', headers)
end)
