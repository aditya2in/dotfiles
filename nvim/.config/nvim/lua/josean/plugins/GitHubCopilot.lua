-- ~/.config/nvim/lua/plugins/init.lua (or your lazy.nvim plugins file)

return {
    -- This is the table being returned.
    -- All plugin definitions are elements within this table.

    -- GitHub Copilot.vim plugin definition
    {
        "github/copilot.vim",
        build = ":Copilot setup",
        event = "VeryLazy", -- Load this plugin as late as possible to keep startup fast
        config = function()
            -- Enable Copilot for all filetypes by default.
            vim.g.copilot_filetypes = {
                ["*"] = true, -- Enable Copilot for all filetypes
            }
            -- This command initiates the Copilot setup process within Neovim.
            vim.cmd([[Copilot setup]])
        end,
    },

    -- Any other plugins you have would be listed here as well, separated by commas.
    -- Example:
    -- {
    --   'nvim-tree/nvim-tree.lua',
    --   lazy = false,
    --   config = function()
    --     require("nvim-tree").setup {}
    --   end
    -- },
}
