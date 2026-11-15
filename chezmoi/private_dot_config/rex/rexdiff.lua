-- "rexdiff install" wrote this file. To remove it, run "rexdiff uninstall".
--
-- These are the settings of rexdiff. The README of rexdiff lists them.
-- To change a setting, edit it, then run "rex config reload".
-- Install and upgrades keep this part.
local settings = {
  -- key = "shift+cmd+r", -- the key of the toggle, or false for none
  -- placement = "split", -- split, zoomed, tab, or overlay
  -- layout = "split",
}

-- rexdiff_toggle.lua has the toggle action, and rexdiff writes it. If it
-- fails, the rest of Rex's config still loads, and the key shows why.
local ok, err = pcall(function() require("rexdiff_toggle")(settings) end)
if not ok then
  rex.action{ name = "rexdiff_toggle", title = "Toggle rexdiff",
    run = function() error("rexdiff: " .. tostring(err), 0) end }
  local key = type(settings) == "table" and settings.key
  if key == nil then key = "shift+cmd+r" end
  if key then rex.bind(key, "rexdiff_toggle") end
end
