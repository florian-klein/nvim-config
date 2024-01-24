require "core"

local custom_init_path = vim.api.nvim_get_runtime_file("lua/custom/init.lua", false)[1]
-- local g:loaded_python3_provider=0; How can you do this correctly 
vim.g.python3_host_prog = "/Users/florianklein/miniconda3/bin/python3"

if custom_init_path then
  dofile(custom_init_path)
end

require("core.utils").load_mappings()
-- require("leap").add_default_mappings()

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

-- bootstrap lazy.nvim!
if not vim.loop.fs_stat(lazypath) then
  require("core.bootstrap").gen_chadrc_template()
  require("core.bootstrap").lazy(lazypath)
end

dofile(vim.g.base46_cache .. "defaults")
vim.opt.rtp:prepend(lazypath)
require "plugins"
