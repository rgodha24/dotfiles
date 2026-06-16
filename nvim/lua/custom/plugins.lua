local overrides = require "custom.configs.overrides"

local function lumen_diff_current_branch_base()
  local function system_output(cmd)
    local output = vim.fn.systemlist(cmd)

    if vim.v.shell_error ~= 0 then
      return nil
    end

    return vim.trim(table.concat(output, "\n"))
  end

  local base_target

  if vim.fn.executable "gh" == 1 then
    local base_ref = system_output { "gh", "pr", "view", "--json", "baseRefName", "--jq", ".baseRefName" }

    if base_ref and base_ref ~= "" then
      base_target = "origin/" .. base_ref
    end
  end

  base_target = base_target or system_output { "git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" }

  for _, target in ipairs { base_target, "origin/main", "origin/master", "main", "master" } do
    if target and target ~= "" then
      local base = system_output { "git", "merge-base", "HEAD", target }

      if base and base ~= "" then
        Snacks.terminal.open("lumen diff " .. vim.fn.shellescape(base .. "..HEAD"))
        return
      end
    end
  end

  vim.notify("No branch base found for Lumen diff", vim.log.levels.ERROR)
end

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
      {
        "<leader>gp",
        lumen_diff_current_branch_base,
        desc = "Lumen Diff (current branch)",
      },
    },
    opts = { lazygit = { enabled = true }, terminal = { enabled = true } },
  },

  -- {
  --   "wakatime/vim-wakatime",
  --   lazy = false,
  -- },
  -- {
  --   "supermaven-inc/supermaven-nvim",
  --   event = "InsertEnter",
  --   opts = {
  --     keymaps = {
  --       accept_suggestion = "<C-l>",
  --     },
  --     condition = function()
  --       -- no autocomplete on school work
  --       return string.match(vim.fn.expand "%:p", vim.fn.expand "~/Classes")
  --     end,
  --   },
  -- },
  --
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    opts = {
      -- or "fzf-lua" or "snacks" or "default"
      picker = "telescope",
      -- bare Octo command opens picker of commands
      enable_builtin = true,
    },
    keys = {
      {
        "<leader>oi",
        "<CMD>Octo issue list<CR>",
        desc = "List GitHub Issues",
      },
      {
        "<leader>op",
        "<CMD>Octo pr list<CR>",
        desc = "List GitHub PullRequests",
      },
      {
        "<leader>od",
        "<CMD>Octo discussion list<CR>",
        desc = "List GitHub Discussions",
      },
      {
        "<leader>on",
        "<CMD>Octo notification list<CR>",
        desc = "List GitHub Notifications",
      },
      {
        "<leader>os",
        function()
          require("octo.utils").create_base_search_command { include_current_repo = true }
        end,
        desc = "Search GitHub",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      -- OR "ibhagwan/fzf-lua",
      -- OR "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons",
    },
  },
  {
    "sindrets/diffview.nvim",
    opts = {
      default_args = {
        DiffviewOpen = { "--imply-local" },
      },
    },
    cmd = "DiffviewOpen",
  },
}

return plugins
