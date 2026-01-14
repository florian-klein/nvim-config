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
          accept = false, -- We handle Tab manually below
          accept_word = "<C-Right>",
          accept_line = "<C-Down>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
      -- Custom Tab mapping: accept Copilot suggestion if visible, otherwise fallback to normal Tab
      vim.keymap.set("i", "<Tab>", function()
        if require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end
      end, { desc = "Accept Copilot or Tab" })
    end,
  },
  {
    "mbledkowski/neuleetcode.vim",
    lazy = true,
  },
  -- Telescope extensions
  {
    "debugloop/telescope-undo.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("telescope").load_extension("undo")
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("telescope").load_extension("ui-select")
    end,
  },
}

return plugins
