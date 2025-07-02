local M = {}
local utils = require "custom.utils"

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
    "nix",
    "astro",
    "svelte",
  },
  indent = {
    enable = true,
    -- disable = {
    --   "python"
    -- },
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "deno",
    "prettier",

    -- c/cpp stuff
    "clangd",
    "clang-format",
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
  },

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
  on_attach = function(bufnr)
    local api = require "nvim-tree.api"

    -- Apply default mappings first
    api.config.mappings.default_on_attach(bufnr)

    local function copy_marked_to_clipboard()
      local log = require "nvim-tree.log"

      local marked_nodes = api.marks.list()
      if not marked_nodes or vim.tbl_isempty(marked_nodes) then
        vim.notify("NvimTree: No items marked.", vim.log.levels.INFO)
        return
      end

      local files_to_process = {}

      -- Collect all file paths, recursing into directories
      for _, node in ipairs(marked_nodes) do
        if node.type == "directory" then
          -- Use vim.fn.globpath for recursive file finding
          -- The pattern '**/*' finds all files recursively
          -- true, true returns absolute paths and includes files
          local files_in_dir = vim.fn.globpath(node.absolute_path, "**/*", true, true)
          -- Filter out directories potentially returned by globpath (though less likely with 'true' flag)
          for _, file_path in ipairs(files_in_dir) do
            if vim.fn.isdirectory(file_path) == 0 then
              table.insert(files_to_process, file_path)
            end
          end
        elseif node.type == "file" then
          table.insert(files_to_process, node.absolute_path)
        end
      end

      if vim.tbl_isempty(files_to_process) then
        vim.notify("NvimTree: No files found in marked items (maybe only empty directories?).", vim.log.levels.WARN)
        return
      end

      local final_content_blocks = {}
      local read_errors = 0

      for _, file_path in ipairs(files_to_process) do
        -- Get path relative to current working directory
        local relative_path = vim.fn.fnamemodify(file_path, ":.")
        -- Attempt to get filetype
        local filetype = vim.filetype.match { filename = file_path } or "unknown"

        -- Read file content safely
        local ok, lines = pcall(vim.fn.readfile, file_path)
        local content = ""
        if ok and lines then
          content = table.concat(lines, "\n")
        else
          log.error("Failed to read file: " .. file_path)
          content = "-- Error reading file --"
          read_errors = read_errors + 1
        end

        table.insert(final_content_blocks, utils.fmt_block(filetype, relative_path, content))
      end

      local message = string.format("NvimTree: Copied content of %d file(s) to clipboard.", #files_to_process)
      local level = read_errors > 0 and vim.log.levels.WARN or vim.log.levels.INFO
      utils.copy_blocks(final_content_blocks, message, level)
    end

    -- https://github.com/nvim-tree/nvim-tree.lua/issues/2994#issuecomment-2688559143
    local function mark_visually(action)
      local view = require "nvim-tree.view"

      -- Check if nvim-tree is visible
      if not view.is_visible() then
        print "This function can only be run in nvim-tree."
        return
      end

      -- Check if we are in visual line mode
      local mode = vim.api.nvim_get_mode().mode
      if mode ~= "V" then
        print "This function can only be run in visual line selection mode."
        return
      end

      -- Exit Visual Mode (simulate pressing <Esc>)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

      -- Get the nvim-tree window and buffer
      local winid = view.get_winnr()
      local bufnr = vim.api.nvim_win_get_buf(winid)

      -- Switch to the nvim-tree window
      vim.api.nvim_set_current_win(winid)

      -- Get the start and end lines of the selection (in the context of nvim-tree)
      local start_line = vim.fn.line "'<"
      local end_line = vim.fn.line "'>"

      -- Validate the selection boundaries
      local last_line = vim.api.nvim_buf_line_count(bufnr)
      start_line = math.max(1, math.min(start_line, last_line))
      end_line = math.max(1, math.min(end_line, last_line))

      -- Iterate over the selected lines
      for i = start_line, end_line do
        vim.api.nvim_win_set_cursor(winid, { i, 0 })
        local node = api.tree.get_node_under_cursor()
        if node and node.absolute_path then
          if action == "toggle" then
            api.marks.toggle(node)
          elseif action == "add_marks" then
            if not api.marks.get(node) then
              api.marks.toggle(node)
            end
          elseif action == "delete_marks" then
            if api.marks.get(node) then
              api.marks.toggle(node)
            end
          end
        end
      end

      vim.api.nvim_set_current_win(vim.fn.win_getid())
    end

    local function opts(desc)
      return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    vim.keymap.set("n", "<leader>y", copy_marked_to_clipboard, opts "Copy to AI chat")
    vim.keymap.set("x", "<leader>mt", function()
      mark_visually "toggle"
    end, opts "Toggle Markings")

    vim.keymap.set("x", "<leader>ma", function()
      mark_visually "add_marks"
    end, { desc = "Add markings in visual selection" })

    vim.keymap.set("x", "<leader>md", function()
      mark_visually "delete_marks"
    end, { desc = "Delete markings in visual selection" })

    vim.keymap.set("n", "<leader>mD", function()
      api.marks.clear()
    end, { desc = "Delete all nvim-tree markings" })

    vim.keymap.set("n", "o", function()
      local node = api.tree.get_node_under_cursor()
      if node then
        vim.fn.system("fish -c 'open " .. vim.fn.shellescape(node.absolute_path) .. "'")
      end
    end, opts "Open file with system default")

    vim.keymap.set("n", "O", function()
      local node = api.tree.get_node_under_cursor()
      if node then
        local folder_path = node.type == "directory" and node.absolute_path or vim.fn.fnamemodify(node.absolute_path, ":h")
        vim.fn.system("fish -c 'open " .. vim.fn.shellescape(folder_path) .. "'")
      end
    end, opts "Open enclosing folder")
  end,
}

return M
