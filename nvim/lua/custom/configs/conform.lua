--type conform.options
local options = {
  lsp_fallback = true,

  formatters_by_ft = {
    lua = { "stylua" },

    javascript = { "prettierd" },
    javascriptreact = { "prettierd" },
    typescript = { "prettierd" },
    typescriptreact = { "prettierd" },
    css = { "prettierd" },
    html = { "prettierd" },
    htmldjango = { "prettierd" },
    svelte = { "prettierd" },
    astro = { "prettierd" },
    markdown = { "prettierd" },
    json = { "prettierd" },
    python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },

    rust = { "rustfmt" },
    nix = { "alejandra" },
    typst = { "typstyle" },

    toml = { "taplo" },
    kotlin = { "ktlint" },
  },
  format_on_save = function()
    if not vim.g.autoformat_enabled then
      return nil
    end
    return {
      timeout_ms = 1000,
      lsp_fallback = true,
    }
  end,
}

require("conform").setup(options)
