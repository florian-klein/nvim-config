local overrides = require "custom.configs.overrides"

--- custom configs extracted into other files
-- local jupyter = require "custom.configs.jupyter"

--- leap for faster movement
local languages_and_lsps = require "custom.configs.languages_and_lsps"

---@type NvPluginSpec[]
local plugins = {
  -- unpack plugin extracted plugins specs
  -- jupyter,
  languages_and_lsps,
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = false, -- Handled in unified Tab mapping (cmp.lua)
          accept_word = "<C-Right>",
          accept_line = "<C-Down>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
    },
    -- Tab mapping unified in cmp.lua: Copilot -> cmp -> LuaSnip -> fallback
  },
  -- Fast formatting via direct CLI calls (bypasses LSP overhead)
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre", "BufNewFile", "BufReadPost" },
    cmd = "ConformInfo",
    keys = {
      { "<leader>fm", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        rust = { "rustfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        java = { "google-java-format" },
      },
      -- Async format after save — never blocks the editor
      format_after_save = {
        lsp_format = "fallback", -- Use LSP if no CLI formatter configured (e.g. texlab for LaTeX)
        async = true,
      },
      -- Direct formatter overrides for speed
      formatters = {
        ruff_format = {
          -- --preview must come after the "format" subcommand that conform inserts
          append_args = { "--preview" },
        },
      },
    },
  },
  -- Telescope extensions
  {
    "debugloop/telescope-undo.nvim",
    lazy = true,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    lazy = true,
  },
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    opts = {},
    lazy = false,
    keys = {
      { "<leader>ff", function() require("fff").find_files() end, desc = "Find files (fff)" },
      { "<leader>fw", function() require("fff").live_grep() end, desc = "Live grep (fff)" },
    },
  },
  {
    "mikesmithgh/kitty-scrollback.nvim",
    enabled = true,
    lazy = true,
    cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
    event = { "User KittyScrollbackLaunch" },
    config = function()
      require("kitty-scrollback").setup()
    end,
  },
}

return plugins
