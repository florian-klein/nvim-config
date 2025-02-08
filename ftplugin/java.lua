local lspconfig = require("lspconfig")

local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local status_ok, java = pcall(require, "java")
if not status_ok then
  vim.notify("Java LSP (jdtls) setup failed. Ensure the 'java' module is installed.", vim.log.levels.ERROR)
else
  java.setup()
end

local lsp = "jdtls"
local setup_config = {
  on_attach = on_attach,
  capabilities = capabilities,
  progress = true,
}
lspconfig[lsp].setup(setup_config)
