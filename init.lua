-- NOTE: :help modeline, don't know what that is, example "vim: ts=2 sts=2 sw=2 et"

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("globals")
require("options")
require("keymaps")
require("autocmd")

require("lazy-install")
require("lazy").setup("plugins", { ui = require("ui-icons") })
