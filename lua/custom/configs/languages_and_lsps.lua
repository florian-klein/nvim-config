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
  --- display lsp errors using trouble 
  {
   "folke/trouble.nvim",
   lazy = false,
   dependencies = { "nvim-tree/nvim-web-devicons" },
   opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
   },
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
    ft = "tex",
    lazy = true
  },
  -- {
  --   "neoclide/coc.nvim",
  --   lazy = false,
  --   branch ="release",
  --   build = "yarn install --frozen-lockfile"
  -- },
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
    lazy = true,
    ft = "coq"
  },
  ---- asm_lsp
  {
    'rush-rs/tree-sitter-asm',
    lazy = true,
    ft = "asm"
  },
  --- git 
  {
      "kdheepak/lazygit.nvim",
      -- optional for floating window border decoration
      dependencies = {
          "nvim-lua/plenary.nvim",
      },
  },
  --- peeking on defintion under cursor 
  {
    "https://github.com/nvim-treesitter/nvim-treesitter-textobjects.git",
    lazy = false,
  },
  {
  'stevearc/aerial.nvim',
  lazy = false,
  opts = {},
  -- Optional dependencies
  dependencies = {
     "nvim-treesitter/nvim-treesitter",
     "nvim-tree/nvim-web-devicons"
  },
  config = function()
    require('aerial'):setup({
  })
  end
  },
}

return languages_and_lsps
