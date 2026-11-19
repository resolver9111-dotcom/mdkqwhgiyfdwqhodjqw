
--==================================================
-- GAF NETWORK
-- Global communication module
-- Version 1.0
--==================================================

local Network = {}

local HttpService = game:GetService("HttpService")

Network.Config = {
    URL = "https://ditimcqkqbljthqzaihl.supabase.co",
    KEY = "sb_publishable_lK9zsP4B0O0IblSXcqjw0Q_48x9vx6O"
}

Network.UserId = nil
Network.Token = nil
Network.Connected = false

local function http(options)
    local fn = (syn and syn.request)
        or http_request
        or request

    assert(fn, "HTTP API unavailable")

    return fn(options)
end

local function headers()
    return {
        ["apikey"] = Network.Config.KEY,
        ["Authorization"] = "Bearer " .. Network.Token,
        ["Content-Type"] = "application/json"
    }
end

-- Connect
function Network:Connect()
    local response = http({
        Url = self.Config.URL .. "/auth/v1/signup",
        Method = "POST",
        Headers = {
            ["apikey"] = self.Config.KEY,
            ["Content-Type"] = "application/json"
        },
Body = HttpService:JSONEncode({
    data = {
        client = "GAF",
        version = "1.0"
    }
})
    })

    assert(
        response.StatusCode >= 200
        and response.StatusCode < 300,
        "Auth error: " .. tostring(response.Body)
    )

    local data = HttpService:JSONDecode(response.Body)

    assert(data.access_token, "Missing access token")
    assert(data.user and data.user.id, "Missing user ID")

    self.Token = data.access_token
    self.UserId = data.user.id
    self.Connected = true

    print("[GAF Network] Connected")
    print("[GAF Network] ID: " .. self.UserId)

    return true
end

-- Send event
function Network:SendEvent(eventType, payload)
    assert(self.Connected, "Not connected")

    local response = http({
        Url = self.Config.URL .. "/rest/v1/gaf_events",
        Method = "POST",
        Headers = (function()
            local h = headers()
            h["Prefer"] = "return=minimal"
            return h
        end)(),
        Body = HttpService:JSONEncode({
            user_id = self.UserId,
            event_type = eventType,
            payload = payload or {}
        })
    })

    assert(
        response.StatusCode >= 200
        and response.StatusCode < 300,
        "Event error: " .. tostring(response.Body)
    )

    return true
end

-- Read recent events
function Network:GetEvents(limit)
    assert(self.Connected, "Not connected")

    local response = http({
        Url = self.Config.URL
            .. "/rest/v1/gaf_events"
            .. "?select=id,user_id,event_type,payload,created_at"
            .. "&order=created_at.desc"
            .. "&limit=" .. tostring(limit or 30),
        Method = "GET",
        Headers = headers()
    })

    assert(
        response.StatusCode == 200,
        "Read error: " .. tostring(response.Body)
    )

    return HttpService:JSONDecode(response.Body)
end

return Network
