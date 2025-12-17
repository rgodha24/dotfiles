local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

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
  "tinymist",
  "pyright",
  "kotlin_language_server",
  "ruff",
  "clangd",
}

for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {
    on_attach = on_attach,
    capabilities = capabilities,
  })
  vim.lsp.enable(lsp)
end

vim.lsp.config("astro", {
  on_attach = on_attach,
  capabilities = capabilities,
  init_options = {
    typescript = {
      tsdk = vim.fs.normalize "~/.nix-profile/lib/node_modules/typescript/lib",
    },
  },
})

vim.lsp.enable("astro")
