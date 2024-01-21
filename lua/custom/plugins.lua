local overrides = require("custom.configs.overrides")

--- custom configs extracted into other files 
local jupyter = require("custom.configs.jupyter")
local obsidian = require("custom.configs.obsidian")
local languages_and_lsps = require("custom.configs.languages_and_lsps")

---@type NvPluginSpec[]
local plugins = {
  -- unpack plugin extracted plugins specs 
  jupyter,
  obsidian,
  languages_and_lsps,
  {
    "github/copilot.vim" , lazy = false 
  },
  {
    'mbledkowski/neuleetcode.vim', lazy = true,

  },

}

return plugins
