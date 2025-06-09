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
else
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = { "clip.exe" },
      ["*"] = { "clip.exe" },
    },
    paste = {
      ["+"] = { "powershell.exe", "-c", '[Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))' },
      ["*"] = { "powershell.exe", "-c", '[Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))' },
    },
  }
end

return M
