local function ReadFileAndClose(filepath)
    local content = ""
    local file = io.open(filepath, "r")
    if file then
        content = file:read("*all")
        file:close()
    end
    return content
end

vim.g.isWindowsSystem = vim.fn.has("win32") == 1
vim.g.isLinuxSystem = (function()
    return vim.loop.os_uname().sysname == "Linux"
end)()
vim.g.isNixOSSystem = (function()
    if not vim.g.isLinuxSystem then
        return false
    end
    return string.find(ReadFileAndClose("/etc/os-release"), "ID=nixos")
end)()

vim.g.have_nerd_font = true
