local base_on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = vim.lsp.config

-- Add handler for workspace/diagnostic/refresh (suppresses warning)
vim.lsp.handlers["workspace/diagnostic/refresh"] = function(_, _, ctx)
  local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
  pcall(vim.diagnostic.reset, ns)
  return true
end

-- Disable rust-analyzer auto-start (handled by rustaceanvim)
vim.g.rustaceanvim_standalone = false
vim.lsp.config["rust_analyzer"] = { enabled = false }

-- Create augroup for format on save
local format_augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })

-- LSPs that should use their native formatting (not null-ls)
-- Note: rust_analyzer is handled by rustaceanvim
local lsp_formatting_enabled = {
  clangd = true,
  html = true,
  cssls = true,
  texlab = true,
}

-- Custom on_attach that adds format on save
local on_attach = function(client, bufnr)
  -- Call base on_attach first
  base_on_attach(client, bufnr)

  -- Re-enable formatting for specified LSPs (NvChad disables it by default)
  if lsp_formatting_enabled[client.name] then
    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true
  end

  -- Format on save if the LSP supports formatting
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = format_augroup,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr, async = false })
      end,
    })
  end
end
-- Set Rust toolchain to nightly
vim.env.RUSTUP_TOOLCHAIN = "nightly"

-- Increase Node.js max listeners for large projects
local success, emitter = pcall(require, "vim.lsp.protocol._emitter")
if success and emitter and emitter.setMaxListeners then
  emitter:setMaxListeners(20) -- Increase max listeners
end

local servers = {
  "html",
  "cssls",
  "clangd",
  -- "rust_analyzer", -- Handled by rustaceanvim
  "texlab",
  "asm_lsp",
  "jedi_language_server",
}

-- Check if the required LSP servers are installed
for _, server in ipairs(servers) do
  if not vim.lsp.config[server] then
    vim.notify("LSP server '" .. server .. "' is not installed. Skipping configuration.", vim.log.levels.WARN)
  end
end

-- Conditional setup for JDTLS (Java)
-- if vim.tbl_contains(servers, "jdtls") then
--   local status_ok, java = pcall(require, "java")
--   if not status_ok then
--     vim.notify("Java LSP (jdtls) setup failed. Ensure the 'java' module is installed.", vim.log.levels.ERROR)
--   else
--     java.setup()
--   end
-- end

-- lspconfig.pylyzer.setup({
--   cmd = { "pylyzer", "--server" },
--   filetypes = { "python" },
--   root_dir = function(fname)
--     local root_files = {
--       "setup.py",
--       "tox.ini",
--       "requirements.txt",
--       "Pipfile",
--       "pyproject.toml",
--     }
--     return lspconfig.util.root_pattern(unpack(root_files))(fname)
--       or vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
--   end,
--   single_file_support = true,
--   settings = {
--     python = {
--       diagnostics = false,
--       inlayHints = true,
--       smartCompletion = true,
--       checkOnType = true,
--     },
--   },
-- })

-- LSP-specific settings for performance
local lsp_settings = {
  rust_analyzer = {
    ["rust-analyzer"] = {
      lru = { capacity = 4096 },
      cargo = {
        allFeatures = false,
        buildScripts = { enable = true },
      },
      procMacro = { enable = true },
      diagnostics = {
        enable = true,
        experimental = { enable = false },
      },
      checkOnSave = {
        enable = true,
        command = "check",
        extraArgs = { "--target-dir", "target/analyzer" },
      },
      workspace = {
        symbol = { search = { limit = 128 } },
      },
      inlayHints = {
        parameterHints = { enable = false },
        chainingHints = { enable = false },
        closingBraceHints = { enable = false },
        typeHints = { enable = true },
        lifetimeElisionHints = { enable = "skip_trivial" },
      },
      completion = {
        limit = 50,
        autoimport = { enable = true },
      },
      rustfmt = {
        extraArgs = {},
        overrideCommand = nil,
      },
    },
  },
  clangd = {
    -- clangd settings are passed via cmd args, not settings
  },
}

-- LSP-specific command overrides
local lsp_cmd = {
  clangd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
    "--header-insertion=iwyu",
    "--pch-storage=memory",
    "-j=4", -- Parallel indexing jobs
    "--malloc-trim", -- Release memory after indexing
  },
}

-- Loop through servers and set configurations
for _, lsp in ipairs(servers) do
  local setup_config = {
    on_attach = on_attach,
    capabilities = capabilities,
  }

  -- Apply settings if defined
  if lsp_settings[lsp] and next(lsp_settings[lsp]) ~= nil then
    setup_config.settings = lsp_settings[lsp]
  end

  -- Apply custom cmd if defined
  if lsp_cmd[lsp] then
    setup_config.cmd = lsp_cmd[lsp]
  end

  -- Check if the LSP server exists before setting up
  if lspconfig[lsp] then
    vim.lsp.config(lsp, setup_config)
    vim.lsp.enable(lsp)
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
vim.api.nvim_create_user_command("RustSwitchFeatures", function(args)
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
vim.api.nvim_create_user_command("RustDisableNonDefaultFeatures", function()
  UpdateRustAnalyzerFeatures({}, true)
end, {
  nargs = 0,
  desc = "Disable all non-default features in rust-analyzer",
})
