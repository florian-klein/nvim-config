local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")

-- Set Rust toolchain to nightly
vim.env.RUSTUP_TOOLCHAIN = "nightly"

-- Increase Node.js max listeners for large projects
local success, emitter = pcall(require, "vim.lsp.protocol._emitter")
if success and emitter and emitter.setMaxListeners then
  emitter:setMaxListeners(20) -- Increase max listeners
end

local servers = { "html", "cssls", "clangd", "rust_analyzer", "texlab", "ocamllsp", "asm_lsp", "jedi_language_server", "ruff", "jdtls" }

-- Check if the required LSP servers are installed
for _, server in ipairs(servers) do
  if not lspconfig[server] then
    vim.notify("LSP server '" .. server .. "' is not installed. Skipping configuration.", vim.log.levels.WARN)
  end
end

-- Conditional setup for JDTLS (Java)
if vim.tbl_contains(servers, "jdtls") then
  local status_ok, java = pcall(require, "java")
  if not status_ok then
    vim.notify("Java LSP (jdtls) setup failed. Ensure the 'java' module is installed.", vim.log.levels.ERROR)
  else
    java.setup()
  end
end

-- Loop through servers and set configurations
for _, lsp in ipairs(servers) do
  local settings = {}
  if lsp == "rust_analyzer" then
    settings = {
      ["rust-analyzer"] = {
        lru = {
          capacity = 8192, -- Increase cache capacity
        },
        cargo = {
          loadOutDirsFromCheck = true,
          allFeatures = true,
        },
        procMacro = {
          enable = true,
        },
        checkOnSave = {
          allFeatures = true,
          command = "clippy",
          extraArgs = {
            "--",
            "--no-deps",
            "-Wclippy::correctness",
            "-Wclippy::perf",
            "-Wclippy::complexity",
            "-Wclippy::suspicious",
          },
        },
      },
    }
  end

  local setup_config = {
    on_attach = on_attach,
    capabilities = capabilities,
  }

  -- Apply settings only if non-empty
  if next(settings) ~= nil then
    setup_config.settings = settings
  end

  -- Check if the LSP server exists before setting up
  if lspconfig[lsp] then
    lspconfig[lsp].setup(setup_config)
  else
    vim.notify("LSP server '" .. lsp .. "' is not available for setup.", vim.log.levels.ERROR)
  end
end

-- Function to dynamically update Rust Analyzer features
function UpdateRustAnalyzerFeatures(features, no_default_features)
  local params = {
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          loadOutDirsFromCheck = true,
          features = features or {},
          noDefaultFeatures = no_default_features or false,
        },
      },
    },
  }
  local clients = vim.lsp.get_active_clients()
  for _, client in ipairs(clients) do
    if client.name == "rust_analyzer" then
      local status_ok, err = pcall(client.notify, client, "workspace/didChangeConfiguration", params)
      if not status_ok then
        vim.notify("Failed to update Rust Analyzer configuration: " .. err, vim.log.levels.ERROR)
      else
        vim.notify("Rust Analyzer features updated successfully.", vim.log.levels.INFO)
      end
    end
  end
end

-- Command to switch Rust Analyzer features dynamically
vim.api.nvim_create_user_command('RustSwitchFeatures', function(args)
  if args.args == "" then
    vim.notify("No features provided. Please specify features separated by commas.", vim.log.levels.ERROR)
    return
  end
  local features = vim.split(args.args, ",")
  UpdateRustAnalyzerFeatures(features)
end, {
  nargs = 1,
  desc = "Switch rust-analyzer features dynamically",
})

-- Command to disable all non-default Rust Analyzer features
vim.api.nvim_create_user_command('RustDisableNonDefaultFeatures', function()
  UpdateRustAnalyzerFeatures({}, true)
end, {
  nargs = 0,
  desc = "Disable all non-default features in rust-analyzer",
})
