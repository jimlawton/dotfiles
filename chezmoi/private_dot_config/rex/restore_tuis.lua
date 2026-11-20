local state_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/rex-active-cmds"

local function restore_active_tuis()
  -- Check which state files exist via rex.exec
  local res = rex.exec({ "ls", "-1", state_dir })
  if not res or res.code ~= 0 or res.stdout == "" then
    return
  end

  -- Query current blocks from the Rex server API
  local sessions = rex.call("session.list", {})
  if not sessions then return end

  for block_id in res.stdout:gmatch("[^\r\n]+") do
    local filepath = state_dir .. "/" .. block_id
    local f = io.open(filepath, "r")
    if f then
      local line = f:read("*l")
      f:close()
      os.remove(filepath) -- Consume once so config reloads don't re-run it

      if line then
        local cwd, cmd = line:match("^([^\t]+)\t(.+)$")
        if cmd then
          -- Send text + newline directly to the restored block ID
          rex.call("block.send_text", {
            block_id = block_id,
            text = cmd .. "\n",
          })
        end
      end
    end
  end
end

-- Delay slightly so Rex finishes recreating blocks on server boot
rex.after(800, restore_active_tuis)
