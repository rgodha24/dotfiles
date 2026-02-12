---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    ["<C-c>"] = {
      function()
        require("custom.utils").copy_current_buffer()
      end,
      "Copy buffer to AI Chat",
    },

    --  format with conform
    ["<leader>fm"] = {
      function()
        require("conform").format()
      end,
      "formatting",
    },
    ["<leader>sv"] = {
      ":vsplit<CR>",
      "split vertically",
    },
    ["<leader>sh"] = {
      ":split<CR>",
      "split horizontally",
    },
    ["<leader>tp"] = {
      "<cmd> TypstPreviewToggle <CR>",
      "toggle typst preview",
    },
  },
  v = {
    [">"] = { ">gv", "indent" },
  },
}

if vim.fn.has "mac" == 1 then
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
end

return M
