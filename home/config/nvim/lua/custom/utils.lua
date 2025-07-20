local M = {}

-- build a single fenced block: ```<ft> <header>\n<content>```
function M.fmt_block(filetype, header, content)
  return string.format("```%s %s\n%s\n```", filetype, header, content)
end

-- copy blocks (array of strings) to '+' register and notify
function M.copy_blocks(blocks, message, level)
  level = level or vim.log.levels.INFO
  vim.fn.setreg("+", table.concat(blocks, "\n\n"))
  vim.notify(message, level)
end

-- copy the entire current buffer as one fenced block
function M.copy_current_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")

  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
  if path == "" then
    path = "current_buffer"
  end

  local ft = vim.bo[bufnr].filetype or "text"
  local block = M.fmt_block(ft, path, content)
  M.copy_blocks({ block }, "Copied current buffer to AI chat")
end

return M
