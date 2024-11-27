local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

require('java').setup()
local lspconfig = require("lspconfig")

-- if you just want default config for the servers then put them in a table
local servers = { "html", "cssls", "clangd", "rust_analyzer", "texlab", "ocamllsp", "asm_lsp", "jedi_language_server", "ruff_lsp", "jdtls"}

for _, lsp in ipairs(servers) do
  -- if lsp is rust-analyzer then do special setup 
  local settings = {}
  if lsp == "rust_analyzer" then
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          loadOutDirsFromCheck = true,
        },
        -- Add clippy lints for Rust.
        checkOnSave = {
          allFeatures = true,
          command = "clippy",
          extraArgs = {
            "--",
            "--no-deps",
            "-Dclippy::perf",
          },
        },
        procMacro = {
          enable = true,
          ignored = {
            ["async-trait"] = { "async_trait" },
            ["napi-derive"] = { "napi" },
            ["async-recursion"] = { "async_recursion" },
          },
        },
      }
      }
  end
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = settings
  }
end

-- Function to dynamically update the features for rust-analyzer
function UpdateRustAnalyzerFeatures(features, no_default_features)
  lspconfig.rust_analyzer.setup({
    settings = {
    ["rust-analyzer"] = {
        cargo = {
          loadOutDirsFromCheck = true,
          features = features,        -- Pass the features dynamically
          noDefaultFeatures = no_default_features, -- Disable default features if true
        },
        -- Add clippy lints for Rust.
        checkOnSave = {
          allFeatures = true,
          command = "clippy",
          extraArgs = {
            "--",
            "--no-deps",
            "-Dclippy::correctness",
            "-Dclippy::complexity",
            "-Wclippy::perf",
            "-Wclippy::pedantic",
          },
        },
        procMacro = {
          enable = true,
          ignored = {
            ["async-trait"] = { "async_trait" },
            ["napi-derive"] = { "napi" },
            ["async-recursion"] = { "async_recursion" },
          },
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
