local overrides = require("custom.configs.overrides");
local languages_and_lsps = {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- format & linting
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          require "custom.configs.null-ls"
        end,
      },
    },
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  -- overrde plugin configs
  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },
  {
    "alaviss/nim.nvim",
    lazy = true
  },
  {
    "lervag/vimtex",
    lazy = true
  },
  {
    "neoclide/coc.nvim",
    lazy = false,
    branch ="release",
    build = "yarn install --frozen-lockfile"
  },
  {
    "ianks/vim-tsx",
    lazy = true
  },
  {
  "neovim/nvim-lspconfig",

   dependencies = {
     "jose-elias-alvarez/null-ls.nvim",
     config = function()
       require "custom.configs.null-ls"
     end,
   },
   config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
   end,
  },
  ---- coq 
  {
    "whonore/Coqtail",
    lazy = false,
  }
}

return languages_and_lsps
