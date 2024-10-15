local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")

-- if you just want default config for the servers then put them in a table
local servers = { "html", "cssls", "ts_ls", "clangd", "rust_analyzer", "texlab", "ocamllsp", "asm_lsp", "jedi_language_server", "ruff_lsp"}

-- require('java').setup()

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- Function to dynamically update the features for rust-analyzer
function UpdateRustAnalyzerFeatures(features, no_default_features)
  lspconfig.rust_analyzer.setup({
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          features = features,        -- Pass the features dynamically
          noDefaultFeatures = no_default_features, -- Disable default features if true
        },
      },
    },
  })
  -- Restart the rust-analyzer to apply the new features
  vim.lsp.stop_client(vim.lsp.get_active_clients())
  lspconfig.rust_analyzer.launch()
end

vim.api.nvim_create_user_command('RustSwitchFeatures', function(args)
  local features = vim.split(args.args, ",")
  UpdateRustAnalyzerFeatures(features)
end, {
  nargs = 1,
  complete = nil,
  desc = "Switch rust-analyzer features dynamically",
})

vim.api.nvim_create_user_command('RustDisableNonDefaultFeatures', function()
  UpdateRustAnalyzerFeatures({}, true) -- Disable all non-default features
end, {
  nargs = 0,
  desc = "Disable all non-default features in rust-analyzer",
})
