--[[
 NOTE: :help lspconfig-all
 cmd (table): Override the default command used to start the server
 filetypes (table): Override the default list of associated filetypes for the server
 capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
 settings (table): Override the default settings passed when initializing the server.
--]]
local servers = {
    checkmake = {},
    nil_ls = {},
    clangd = {},
    cmake = {},
    lua_ls = {
        settings = {
            Lua = {
                completion = {
                    callSnippet = "Replace",
                },
                -- diagnostics = { disable = { 'missing-fields' } },
            },
        },
    },
}

local formatters = {
    stylua = {},
    clang = {},
}

local function EnsureInstalledOrAlreadySetupLSPsIfNixOS()
    local ensure_installed = {}
    if vim.g.isNixOSSystem then
        for server, config in pairs(servers) do
            require("lspconfig")[server].setup(config)
        end
    else
        vim.list_extend(ensure_installed, servers)
        vim.list_extend(ensure_installed, formatters)
    end
    return ensure_installed
end

return {
    "neovim/nvim-lspconfig", -- LSP Configuration & Plugins
    dependencies = {
        {
            "williamboman/mason.nvim", -- Automatically install LSPs and related tools to stdpath for Neovim
            config = true,
        }, -- NOTE: Must be loaded before dependants
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        { "j-hui/fidget.nvim", opts = {} }, -- Useful status updates for LSP.
        { "folke/neodev.nvim", opts = {} }, -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
    },
    config = function()
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup(
                "kickstart-lsp-attach",
                { clear = true }
            ),
            callback = function(event)
                local map = function(keys, func, desc)
                    vim.keymap.set(
                        "n",
                        keys,
                        func,
                        { buffer = event.buf, desc = "LSP: " .. desc }
                    )
                end
                map(
                    "gd",
                    require("telescope.builtin").lsp_definitions,
                    "[G]oto [D]efinition (<C-t> to jump back))"
                )
                map(
                    "gr",
                    require("telescope.builtin").lsp_references,
                    "[G]oto [R]eferences"
                )
                map(
                    "gI",
                    require("telescope.builtin").lsp_implementations,
                    "[G]oto [I]mplementation"
                )
                map(
                    "<leader>D",
                    require("telescope.builtin").lsp_type_definitions,
                    "Type [D]efinition"
                )
                map(
                    "<leader>ds",
                    require("telescope.builtin").lsp_document_symbols,
                    "[D]ocument [S]ymbols"
                )
                map(
                    "<leader>ws",
                    require("telescope.builtin").lsp_dynamic_workspace_symbols,
                    "[W]orkspace [S]ymbols"
                )
                map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
                map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
                map("K", vim.lsp.buf.hover, "Hover Documentation")
                map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration") -- NOTE: For example, in C this would take you to the header.

                -- The following two autocommands are used to highlight references of the
                -- word under your cursor when your cursor rests there for a little while.
                --    See `:help CursorHold` for information about when this is executed
                --
                -- When you move your cursor, the highlights will be cleared (the second autocommand).
                local client = vim.lsp.get_client_by_id(event.data.client_id)
                if
                    client
                    and client.server_capabilities.documentHighlightProvider
                then
                    local highlight_augroup = vim.api.nvim_create_augroup(
                        "kickstart-lsp-highlight",
                        { clear = false }
                    )
                    vim.api.nvim_create_autocmd(
                        { "CursorHold", "CursorHoldI" },
                        {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.document_highlight,
                        }
                    )

                    vim.api.nvim_create_autocmd(
                        { "CursorMoved", "CursorMovedI" },
                        {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.clear_references,
                        }
                    )

                    vim.api.nvim_create_autocmd("LspDetach", {
                        group = vim.api.nvim_create_augroup(
                            "kickstart-lsp-detach",
                            { clear = true }
                        ),
                        callback = function(event2)
                            vim.lsp.buf.clear_references()
                            vim.api.nvim_clear_autocmds({
                                group = "kickstart-lsp-highlight",
                                buffer = event2.buf,
                            })
                        end,
                    })
                end

                -- The following autocommand is used to enable inlay hints in your
                -- code, if the language server you are using supports them
                -- This may be unwanted, since they displace some of your code
                if
                    client
                    and client.server_capabilities.inlayHintProvider
                    and vim.lsp.inlay_hint
                then
                    map("<leader>th", function()
                        vim.lsp.inlay_hint.enable(
                            not vim.lsp.inlay_hint.is_enabled()
                        )
                    end, "[T]oggle Inlay [H]ints")
                end
            end,
        })

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = vim.tbl_deep_extend(
            "force",
            capabilities,
            require("cmp_nvim_lsp").default_capabilities()
        )

        require("mason").setup()
        require("mason-tool-installer").setup({
            ensure_installed = EnsureInstalledOrAlreadySetupLSPsIfNixOS(),
        })
        require("mason-lspconfig").setup({
            handlers = {
                function(server_name)
                    local server = servers[server_name] or {}
                    server.capabilities = vim.tbl_deep_extend(
                        "force",
                        {},
                        capabilities,
                        server.capabilities or {}
                    )
                    require("lspconfig")[server_name].setup(server)
                end,
            },
        })
    end,
}
