local overrides = require "custom.configs.overrides"

---@type NvPluginSpec[]
local plugins = {
  -- Override plugin definition options

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  -- override plugin configs
  {
    "williamboman/mason.nvim",
    opts = overrides.mason,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },

  -- Install a plugin
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require "custom.configs.conform"
    end,
  },

  {
    "chomosuke/typst-preview.nvim",
    version = "1.*",
    ft = "typst",
    cmd = {
      "TypstPreview",
      "TypstPreviewStop",
      "TypstPreviewToggle",
      "TypstPreviewUpdate",
    },
    opts = {
      follow_cursor = true,
      open_cmd = "open",
      dependencies_bin = {
        tinymist = "tinymist",
      },
    },
  },

  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>gd",
        function()
          Snacks.terminal.open "lumen diff"
        end,
        desc = "Lumen Diff",
      },
      {
        "<leader>gc",
        function()
          Snacks.terminal.open "lumen diff HEAD"
        end,
        desc = "Lumen Diff (recent commit)",
      },
    },
    opts = { lazygit = { enabled = true }, terminal = { enabled = true } },
  },

  {
    "wakatime/vim-wakatime",
    lazy = false,
  },
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    opts = {
      keymaps = {
        accept_suggestion = "<C-l>",
      },
      condition = function()
        -- no autocomplete on school work
        return string.match(vim.fn.expand "%:p", vim.fn.expand "~/Classes")
      end,
    },
  },
}

return plugins
