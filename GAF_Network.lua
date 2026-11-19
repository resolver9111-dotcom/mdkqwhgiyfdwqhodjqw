
--==================================================
-- GAF NETWORK
-- Global Network System
-- Version 1.2
--==================================================

local Network = {}

local HttpService = game:GetService("HttpService")

--==================================================
-- CONFIGURATION
--==================================================

Network.Config = {
    URL = "https://ditimcqkqbljthqzaihl.supabase.co",
    KEY = "sb_publishable_lK9zsP4B0O0IblSXcqjw0Q_48x9vx6O",
    VERSION = "1.2"
}

--==================================================
-- STATE
--==================================================

Network.UserId = nil
Network.Token = nil
Network.Connected = false

--==================================================
-- HTTP REQUEST
--==================================================

local function http(options)

    local fn = (syn and syn.request)
        or http_request
        or request

    assert(fn, "HTTP API unavailable")

    return fn(options)
end

--==================================================
-- HEADERS
--==================================================

local function getHeaders()

    assert(Network.Token, "Not authenticated")

    return {
        ["apikey"] = Network.Config.KEY,
        ["Authorization"] = "Bearer " .. Network.Token,
        ["Content-Type"] = "application/json"
    }
end

--==================================================
-- RESPONSE CHECK
--==================================================

local function checkResponse(response, expected, action)

    if not response then
        error("[GAF Network] No HTTP response: " .. action)
    end

    if response.StatusCode ~= expected then
        error(
            "[GAF Network] "
            .. action
            .. " failed. HTTP "
            .. tostring(response.StatusCode)
        )
    end

    return response
end

--==================================================
-- AUTHENTICATION
--==================================================

function Network:Connect()

    if self.Connected then
        return true
    end

    print("[GAF Network] Connecting...")

    -- Важно: data должен быть JSON-объектом,
    -- поэтому тело задаём строкой вручную.

    local body =
        '{"data":{"client":"GAF","version":"1.2"}}'

    local response = http({
        Url = self.Config.URL .. "/auth/v1/signup",
        Method = "POST",

        Headers = {
            ["apikey"] = self.Config.KEY,
            ["Content-Type"] = "application/json"
        },

        Body = body
    })

    if not response then
        error("[GAF Network] No response from Supabase")
    end

    if response.StatusCode < 200
        or response.StatusCode >= 300 then

        error(
            "[GAF Network] Auth failed. HTTP "
            .. tostring(response.StatusCode)
        )
    end

    local data = HttpService:JSONDecode(response.Body)

    assert(data.access_token, "Missing access token")
    assert(data.user and data.user.id, "Missing user ID")

    self.Token = data.access_token
    self.UserId = data.user.id
    self.Connected = true

    print("[GAF Network] Connected!")
    print("[GAF Network] User ID:", self.UserId)

    return true
end

--==================================================
-- SEND EVENT
--==================================================

function Network:SendEvent(eventType, payload)

    assert(self.Connected, "Not connected")

    assert(
        type(eventType) == "string"
        and #eventType > 0,
        "Invalid event type"
    )

    local response = http({
        Url = self.Config.URL .. "/rest/v1/gaf_events",
        Method = "POST",

        Headers = (function()

            local headers = getHeaders()

            headers["Prefer"] = "return=minimal"

            return headers

        end)(),

        Body = HttpService:JSONEncode({
            user_id = self.UserId,
            event_type = eventType,
            payload = payload or {}
        })
    })

    if not response then
        error("[GAF Network] No response while sending event")
    end

    if response.StatusCode < 200
        or response.StatusCode >= 300 then

        error(
            "[GAF Network] SendEvent failed. HTTP "
            .. tostring(response.StatusCode)
        )
    end

    return true
end

--==================================================
-- GET EVENTS
--==================================================

function Network:GetEvents(limit)

    assert(self.Connected, "Not connected")

    limit = math.clamp(
        tonumber(limit) or 30,
        1,
        100
    )

    local response = http({

        Url = self.Config.URL
            .. "/rest/v1/gaf_events"
            .. "?select=id,user_id,event_type,payload,created_at"
            .. "&order=created_at.desc"
            .. "&limit=" .. limit,

        Method = "GET",

        Headers = getHeaders()
    })

    checkResponse(
        response,
        200,
        "GetEvents"
    )

    local events = HttpService:JSONDecode(response.Body)

    if type(events) ~= "table" then
        error("[GAF Network] Invalid events response")
    end

    return events
end

--==================================================
-- DISCONNECT
--==================================================

function Network:Disconnect()

    self.Connected = false
    self.Token = nil
    self.UserId = nil

    print("[GAF Network] Disconnected")

end

--==================================================
-- RETURN MODULE
--==================================================

print("[GAF Network] Module loaded. Version:", Network.Config.VERSION)

return Network
