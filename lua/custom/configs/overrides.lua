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
    "pyright",
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
        git = true,
      },
    },
  },
}

return M
