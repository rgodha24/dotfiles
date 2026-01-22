-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })

vim.wo.relativenumber = true

vim.g.autoformat_enabled = true
vim.api.nvim_create_user_command("FormatToggle", function()
  vim.g.autoformat_enabled = not vim.g.autoformat_enabled
  if vim.g.autoformat_enabled then
    vim.notify("Autoformat enabled", vim.log.levels.INFO)
  else
    vim.notify("Autoformat disabled", vim.log.levels.INFO)
  end
end, { desc = "Toggle autoformat on save" })
