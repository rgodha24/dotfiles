local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"

-- if you just want default config for the servers then put them in a table
local servers = {
  "html",
  "cssls",
  "ts_ls",
  "svelte",
  "rust_analyzer",
  "tailwindcss",
  "prismals",
  "jdtls",
  "gopls",
  "matlab_ls",
  "typst_lsp",
  "pyright",
  "kotlin_language_server",
}

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

lspconfig.astro.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  init_options = {
    typescript = {
      tsdk = vim.fs.normalize "~/.nix-profile/lib/node_modules/typescript/lib",
    },
  },
}

--
-- lspconfig.pyright.setup { blabla}
