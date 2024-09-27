local overrides = require("custom.configs.overrides")

--- custom configs extracted into other files 
local jupyter = require("custom.configs.jupyter")

--- leap for faster movement 
local languages_and_lsps = require("custom.configs.languages_and_lsps")

---@type NvPluginSpec[]
local plugins = {
  -- unpack plugin extracted plugins specs 
  jupyter,
  languages_and_lsps,
  {
    "github/copilot.vim" , lazy = false 
  },
  {
    'mbledkowski/neuleetcode.vim', lazy = true,

  },

}

return plugins
