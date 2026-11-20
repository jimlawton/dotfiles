local state_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/rex-active-cmds"
local log_file = "/tmp/rex-restore-tuis.log"

local function log(msg)
  local f = io.open(log_file, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S ") .. msg .. "\n")
    f:close()
  end
end

local function normalize_pwd(raw)
  if not raw then return nil end
  local path = raw:gsub("^file://[^/]*", "")
  path = path:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  return path
end

local function write_to_block(session_id, block_id, text)
  local ok, res = pcall(rex.call, "com.superlogical.terminal.write", {
    session_id = session_id,
    block_id = block_id,
    args = { data = text },
  })
  log(string.format("write_to_block(%s, %s) -> ok=%s err=%s", tostring(session_id), tostring(block_id), tostring(ok), tostring(res)))
  return ok
end

local function restore_active_tuis()
  log("restore_active_tuis triggered")
  local res = rex.exec({ "ls", "-1", state_dir })
  if not res or res.code ~= 0 or res.stdout == "" then
    log("no state files found in " .. state_dir)
    return
  end

  local ok_s, sessions_res = pcall(rex.call, "session.list", {})
  if not ok_s then
    log("session.list failed: " .. tostring(sessions_res))
    return
  end
  local sessions = (sessions_res and sessions_res.sessions) or sessions_res or {}

  local by_block_id = {}
  local by_pwd = {}

  for _, s in ipairs(sessions) do
    local sid = s.session_id or s.id
    if sid then
      local ok_b, blocks_res = pcall(rex.call, "session.list_blocks", { session_id = sid })
      local blocks = (ok_b and blocks_res and blocks_res.blocks) or {}
      for _, b in ipairs(blocks) do
        local bid = b.block_id
        if bid then
          by_block_id[bid] = sid
          local ok_p, pwd_res = pcall(rex.call, "com.superlogical.terminal.pwd", {
            session_id = sid,
            block_id = bid,
            args = {},
          })
          if ok_p and pwd_res and pwd_res.pwd then
            local clean_pwd = normalize_pwd(pwd_res.pwd)
            if clean_pwd then
              by_pwd[clean_pwd] = { session_id = sid, block_id = bid }
            end
          end
        end
      end
    end
  end

  for saved_bid in res.stdout:gmatch("[^\r\n]+") do
    local filepath = state_dir .. "/" .. saved_bid
    local f = io.open(filepath, "r")
    if f then
      local line = f:read("*l")
      f:close()
      os.remove(filepath)

      if line then
        local saved_pwd, cmd = line:match("^([^\t]+)\t(.+)$")
        log(string.format("found saved_bid=%s pwd=%s cmd=%s", saved_bid, tostring(saved_pwd), tostring(cmd)))
        if cmd then
          if by_block_id[saved_bid] then
            write_to_block(by_block_id[saved_bid], saved_bid, cmd .. "\r")
          elseif saved_pwd and by_pwd[saved_pwd] then
            local target = by_pwd[saved_pwd]
            write_to_block(target.session_id, target.block_id, cmd .. "\r")
          else
            log("no matching live block found for " .. saved_bid)
          end
        end
      end
    end
  end
end

rex.after(2000, restore_active_tuis)

