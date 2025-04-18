---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    --  format with conform
    ["<leader>fm"] = {
      function()
        require("conform").format()
      end,
      "formatting",
    },
    ["<leader>gg"] = {
      ":LazyGit<CR>",
      "open lazygit",
    },
    ["<leader>sv"] = {
      ":vsplit<CR>",
      "split vertically",
    },
    ["<leader>sh"] = {
      ":split<CR>",
      "split horizontally",
    },
  },
  v = {
    [">"] = { ">gv", "indent" },
  },
}

-- more keybinds!

vim.g.clipboard = {
  name = "clipboard",
  copy = {
    ["+"] = { "pbcopy" },
    ["*"] = { "pbcopy" },
  },
  paste = {
    ["+"] = { "pbpaste" },
    ["*"] = { "pbpaste" },
  },
}

return M
