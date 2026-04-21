VERSION = "0.1.0"

local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")
local runtime = import("runtime")
local strings = import("strings")

local PLUGIN = "systemtheme"

local state = {
    job = nil,
    stopping = false,
    current = "",
    pending = "",
    command_ok = false,
}

local function option(name)
    return config.GetGlobalOption(PLUGIN .. "." .. name)
end

local function trim(s)
    return strings.TrimSpace(s or "")
end

local function is_mode(mode)
    return mode == "light" or mode == "dark"
end

local function log(msg)
    micro.Log(PLUGIN .. ": " .. msg)
end

local function error_message(err)
    if err == nil then
        return ""
    end

    local ok, msg = pcall(function()
        return err:Error()
    end)
    if ok and msg ~= nil and msg ~= "" then
        return msg
    end

    msg = tostring(err)
    if msg == nil or msg == "<nil>" then
        return ""
    end
    return msg
end

local function notify(msg)
    if option("notifications") then
        micro.InfoBar():Message(msg)
    end
end

local function get_scheme(mode)
    if mode == "dark" then
        return option("dark")
    end
    return option("light")
end

local function apply_mode(mode)
    mode = trim(mode)
    if not is_mode(mode) then
        log("ignored invalid mode: " .. mode)
        return false
    end

    local scheme = get_scheme(mode)
    local err = config.SetGlobalOption("colorscheme", scheme)
    local msg = error_message(err)
    if msg ~= "" then
        micro.InfoBar():Error("systemtheme: " .. msg)
        return false
    end

    state.current = mode
    notify("systemtheme: " .. mode .. " -> " .. scheme)
    return true
end

local function query_defaults_mode()
    if runtime.GOOS ~= "darwin" then
        return "", "not macOS"
    end

    local out, err = shell.ExecCommand("defaults", "read", "-g", "AppleInterfaceStyle")
    if err == nil and trim(out) == "Dark" then
        return "dark", nil
    end

    return "light", nil
end

local function query_mode()
    local cmd = option("command")
    local out, err = shell.ExecCommand(cmd, "--exit")
    if err == nil then
        local mode = trim(out)
        if is_mode(mode) then
            state.command_ok = true
            return mode, nil
        end
        state.command_ok = false
        return "", "unexpected output from " .. cmd .. ": " .. mode
    end

    local mode, fallback_err = query_defaults_mode()
    if is_mode(mode) then
        state.command_ok = false
        log(cmd .. " --exit failed; used macOS defaults fallback")
        return mode, nil
    end

    state.command_ok = false
    local msg = error_message(err)
    if msg == "" then
        msg = tostring(fallback_err)
    end
    return "", msg
end

function update()
    local mode, err = query_mode()
    if not is_mode(mode) then
        micro.InfoBar():Error("systemtheme: cannot detect appearance: " .. error_message(err))
        return false
    end
    return apply_mode(mode)
end

function set_mode(mode)
    if not is_mode(mode) then
        micro.InfoBar():Error("systemtheme: mode must be light or dark")
        return false
    end
    return apply_mode(mode)
end

function toggle()
    if state.current == "light" then
        return apply_mode("dark")
    elseif state.current == "dark" then
        return apply_mode("light")
    end

    if not update() then
        return false
    end
    return toggle()
end

local function handle_output(chunk)
    state.pending = state.pending .. (chunk or "")

    while true do
        local newline = string.find(state.pending, "\n", 1, true)
        if newline == nil then
            break
        end

        local line = string.sub(state.pending, 1, newline - 1)
        state.pending = string.sub(state.pending, newline + 1)
        local mode = trim(line)
        if is_mode(mode) then
            apply_mode(mode)
        elseif mode ~= "" then
            log("ignored watcher output: " .. mode)
        end
    end
end

local function on_stdout(output, args)
    handle_output(output)
end

local function on_stderr(output, args)
    local msg = trim(output)
    if msg ~= "" then
        log("watcher stderr: " .. msg)
    end
end

local function on_exit(output, args)
    if trim(state.pending) ~= "" then
        handle_output("\n")
    end

    state.job = nil
    state.pending = ""
    if state.stopping then
        state.stopping = false
        return
    end

    local msg = trim(output)
    if msg == "" then
        msg = "watcher exited"
    end
    micro.InfoBar():Error("systemtheme: " .. msg)
end

function stop()
    if state.job == nil then
        return true
    end

    state.stopping = true
    shell.JobSend(state.job, "quit\n")
    state.job = nil
    state.pending = ""
    return true
end

function start()
    if state.job ~= nil then
        return true
    end

    if not update() then
        return false
    end
    if not state.command_ok then
        micro.InfoBar():Error("systemtheme: watcher command unavailable; applied current mode only")
        return false
    end

    local cmd = option("command")
    state.stopping = false
    state.pending = ""
    state.job = shell.JobSpawn(cmd, {}, on_stdout, on_stderr, on_exit)
    return true
end

local function command(bp, args)
    local sub = args[1] or "status"

    if sub == "start" then
        start()
    elseif sub == "stop" then
        stop()
    elseif sub == "restart" then
        stop()
        start()
    elseif sub == "update" then
        update()
    elseif sub == "toggle" then
        toggle()
    elseif sub == "light" or sub == "dark" then
        set_mode(sub)
    elseif sub == "status" then
        local watching = "stopped"
        if state.job ~= nil then
            watching = "watching"
        end
        micro.InfoBar():Message("systemtheme: " .. watching .. ", mode=" .. (state.current or ""))
    else
        micro.InfoBar():Error("usage: systemtheme [start|stop|restart|update|toggle|light|dark|status]")
    end
end

function init()
    config.RegisterGlobalOption(PLUGIN, "light", "bubblegum")
    config.RegisterGlobalOption(PLUGIN, "dark", "monokai")
    config.RegisterGlobalOption(PLUGIN, "command", "dark-notify")
    config.RegisterGlobalOption(PLUGIN, "autorun", true)
    config.RegisterGlobalOption(PLUGIN, "notifications", false)

    config.MakeCommand("systemtheme", command, config.NoComplete)
    config.AddRuntimeFile(PLUGIN, config.RTHelp, "help/systemtheme.md")

    if option("autorun") then
        start()
    end
end

function deinit()
    stop()
end
