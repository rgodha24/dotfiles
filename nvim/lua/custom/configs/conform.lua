--type conform.options
local options = {
  lsp_fallback = true,

  formatters_by_ft = {
    lua = { "stylua" },

    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    htmldjango = { "prettier" },
    svelte = { "prettier" },
    astro = { "prettier" },
    python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },

    rust = { "rustfmt" },
    nix = { "alejandra" },
    typst = { "typstyle" },

    toml = { "taplo" },
    kotlin = { "ktlint" },
  },

  -- adding same formatter for multiple filetypes can look too much work for some
  -- instead of the above code you could just use a loop! the config is just a table after all!

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

require("conform").setup(options)
