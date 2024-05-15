local M = {}

M.treesitter = {
  vim.api.nvim_set_hl(0, "@punctuation.delimiter.ocaml", { link = "Boolean" });
  vim.api.nvim_set_hl(0, "@variable.parameter.ocaml", { link = "Boolean" });
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "c",
    "markdown",
    "markdown_inline",
    "python",
    "rust",
    "bash",
    "ocaml",
    "cpp",
    "asm", -- Add 'asm' to the list of languages to ensure it's installed
  },
  highlight = {
    enable = true,
    disable = {
      -- "python"
    },
  },
  indent = {
    enable = true,
    disable = {
      -- "python"
    },
  },
  textobjects = {
    lsp_interop = {
      enable = true,
      border = 'none',
      floating_preview_opts = {},
      peek_definition_code = {
        ["<S-I>"] = "@function.outer",
        ["<leader>dF"] = "@class.outer",
      },
    },
  },
}

-- Add the Assembly Treesitter parser configuration
require('nvim-treesitter.parsers').get_parser_configs().asm = {
  install_info = {
    url = 'https://github.com/rush-rs/tree-sitter-asm.git',
    files = { 'src/parser.c' },
    branch = 'main',
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "deno",

    -- python
    -- "pyright",
    "ruff",
    "ruff-lsp",
    -- rust 
    "rust_analyzer",
    -- latex 
    "texlab",
    -- ocaml 
    "ocamllsp",
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
  },

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = false,
      },
    },
  },
}

return M
