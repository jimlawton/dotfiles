-- ~/.config/rex/restore_tuis.lua
local state_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/rex-active-cmds"

local function write_to_block(block_id, text)
  -- Try block.method wrapper first, fallback to direct block-scoped call
  local ok = pcall(rex.call, "block.method", {
    block_id = block_id,
    method = "com.superlogical.terminal.write",
    params = { data = text },
  })
  if not ok then
    pcall(rex.call, "com.superlogical.terminal.write", {
      block_id = block_id,
      data = text,
    })
  end
end

local function restore_active_tuis()
  local res = rex.exec({ "ls", "-1", state_dir })
  if not res or res.code ~= 0 or res.stdout == "" then
    return
  end

  local blocks_res = rex.call("session.list_blocks", {})
  local live_blocks = (blocks_res and blocks_res.blocks) or blocks_res or {}

  -- Index live blocks by ID and by PWD for fallback matching
  local by_id = {}
  local by_pwd = {}
  for _, b in ipairs(live_blocks) do
    local id = b.id or b.block_id
    if id then
      by_id[id] = true
      local pwd_res = rex.call("com.superlogical.terminal.pwd", { block_id = id })
      local pwd = pwd_res and (pwd_res.pwd or pwd_res.path)
      if pwd then
        by_pwd[pwd] = id
      end
    end
  end

  for saved_id in res.stdout:gmatch("[^\r\n]+") do
    local filepath = state_dir .. "/" .. saved_id
    local f = io.open(filepath, "r")
    if f then
      local line = f:read("*l")
      f:close()
      os.remove(filepath) -- Consume once so config reloads never re-trigger

      if line then
        local saved_pwd, cmd = line:match("^([^\t]+)\t(.+)$")
        local target_id = by_id[saved_id] and saved_id or by_pwd[saved_pwd]
        if target_id and cmd then
          write_to_block(target_id, cmd .. "\r")
        end
      end
    end
  end
end

-- Wait briefly for Rex to finish recreating restored blocks and PTYs on startup
rex.after(1000, restore_active_tuis)

