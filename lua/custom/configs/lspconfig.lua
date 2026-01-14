local base_on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

-- Handle workspace/diagnostic/refresh properly (don't reset, let LSP push new diagnostics)
vim.lsp.handlers["workspace/diagnostic/refresh"] = function(_, result, ctx)
  -- Simply acknowledge the refresh request - rust-analyzer will push new diagnostics
  -- Don't reset diagnostics here as that would clear them before new ones arrive
  return vim.NIL
end

-- Disable rust-analyzer auto-start (handled by rustaceanvim)
vim.g.rustaceanvim_standalone = false
-- Prevent Neovim from auto-starting rust_analyzer (rustaceanvim manages it)
pcall(function()
  vim.lsp.config("rust_analyzer", { autostart = false })
end)

-- Create augroup for format on save
local format_augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })

-- LSPs that should use their native formatting (not null-ls)
-- Note: rust_analyzer is handled by rustaceanvim
local lsp_formatting_enabled = {
  clangd = true,
  html = true,
  cssls = true,
  texlab = true,
  ruff = true, -- Python formatting
}

-- Main LspAttach autocmd for keymappings and setup
-- The new vim.lsp.config/enable API doesn't call on_attach callbacks,
-- so we must use LspAttach autocmd to set up keybindings
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach_setup", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf
    if client == nil then
      return
    end

    -- Disable ruff's hover in favor of ty's hover for Python
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    -- Call the base on_attach for keymappings (gd, gr, K, etc.)
    -- This is critical - vim.lsp.config/enable doesn't call on_attach callbacks
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
          vim.lsp.buf.format({
            bufnr = bufnr,
            async = false,
            timeout_ms = 3000,
          })
        end,
      })
    end
  end,
  desc = "LSP: Setup keymappings, formatting, and capabilities",
})

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
  -- ty and ruff are configured below using lspconfig for better single-file support
}

-- LSP-specific init_options (used for ruff, ty logging, etc.)
local lsp_init_options = {
  ruff = {
    settings = {
      logLevel = "warn",
      lint = {
        enable = true,
      },
      format = {
        preview = true,
      },
      -- Exclude problematic directories
      exclude = {
        "**/miniconda3/**",
        "**/.cache/**",
        "**/site-packages/**",
        "**/__pycache__/**",
        "**/.venv/**",
        "**/venv/**",
      },
    },
  },
  ty = {
    -- Only logFile and logLevel go in init_options
    logLevel = "warn",
  },
}

-- LSP-specific settings for performance
local lsp_settings = {
  ty = {
    ty = {
      diagnosticMode = "openFilesOnly",
      completions = {
        autoImport = true,
      },
      inlayHints = {
        variableTypes = true,
        callArgumentNames = true,
      },
    },
  },
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

-- Root markers - empty table
local lsp_root_markers = {}

-- Loop through servers and set configurations
for _, lsp in ipairs(servers) do
  local setup_config = {
    capabilities = capabilities,
  }

  -- Apply settings if defined
  if lsp_settings[lsp] and next(lsp_settings[lsp]) ~= nil then
    setup_config.settings = lsp_settings[lsp]
  end

  -- Apply init_options if defined (for ruff, ty, etc.)
  if lsp_init_options[lsp] then
    setup_config.init_options = lsp_init_options[lsp]
  end

  -- Apply custom cmd if defined
  if lsp_cmd[lsp] then
    setup_config.cmd = lsp_cmd[lsp]
  end

  -- Apply custom root_markers if defined
  if lsp_root_markers[lsp] then
    setup_config.root_markers = lsp_root_markers[lsp]
  end

  -- Configure and enable the LSP server
  vim.lsp.config(lsp, setup_config)
  vim.lsp.enable(lsp)
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

-- Python LSP root_dir function: falls back to file's directory (never home)
local python_root_markers = { "ty.toml", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" }

local function python_root_dir(bufnr, on_dir)
  local root = vim.fs.root(bufnr, python_root_markers)
  if root and root ~= vim.env.HOME then
    on_dir(root)
  else
    -- Fall back to file's directory for standalone files
    local fname = vim.api.nvim_buf_get_name(bufnr)
    on_dir(vim.fn.fnamemodify(fname, ":p:h"))
  end
end

-- ty - Python type checker
vim.lsp.config("ty", {
  capabilities = capabilities,
  root_dir = python_root_dir,
  init_options = {
    logLevel = "warn",
  },
  settings = {
    ty = {
      diagnosticMode = "openFilesOnly",
      completions = {
        autoImport = true,
      },
      inlayHints = {
        variableTypes = true,
        callArgumentNames = true,
      },
    },
  },
})
vim.lsp.enable("ty")

-- ruff - Python linter + formatter
vim.lsp.config("ruff", {
  capabilities = capabilities,
  root_dir = python_root_dir,
  init_options = {
    settings = {
      logLevel = "warn",
      lint = { enable = true },
      format = { preview = true },
      exclude = {
        "**/miniconda3/**",
        "**/.cache/**",
        "**/site-packages/**",
        "**/__pycache__/**",
        "**/.venv/**",
        "**/venv/**",
      },
    },
  },
})
vim.lsp.enable("ruff")
