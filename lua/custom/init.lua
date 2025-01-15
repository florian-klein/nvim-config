-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
vim.g.leetcode_solution_filetype = 'cpp'
vim.g.maplocalleader = ","
vim.g.copilot_disable_diagnostics = true
vim.g.leetcode_browser = 'chrome'
-- vim.opt.conceallevel = 1
vim.api.nvim_set_keymap('i', '<C-/>', 'copilot#Accept("<CR>")', {expr=true, silent=true})

vim.g.vimtex_compiler_latexmk = {
  options = {
      '-verbose',
      '-file-line-error',
      '-synctex=1',
      '-interaction=nonstopmode',
      '-shell-escape',
  }
}
