require("rexdiff")

local TERM = "com.superlogical.terminal"
-- The powerline arrow that ends each starship segment. Every prompt line
-- has one after the directory; command output almost never does.
local ARROW = "\238\130\176 " -- U+E0B0

-- starship (add_newline, one line): a blank line, then the directory, the
-- git segments and the command, all on one line.
local function is_prompt(lines, i)
    return (lines[i - 1] or "") == "" and lines[i]:find(ARROW, 1, true) ~= nil
end

local function must(res, err)
    if err ~= nil then
        error(err, 0)
    end
    return res
end

local function last_output(text, with_command)
    local lines = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do
        lines[#lines + 1] = line
    end
    -- The current prompt, then the one whose command we want
    local prompts = {}
    for i = #lines, 1, -1 do
        if is_prompt(lines, i) then
            prompts[#prompts + 1] = i
            if #prompts == 2 then
                break
            end
        end
    end
    if #prompts == 0 then
        error("no command in this pane", 0)
    end
    -- Text below the last prompt means its command is still running, for
    -- example waiting for input, so that command's output runs to the end.
    local running = false
    for i = prompts[1] + 1, #lines do
        if lines[i] ~= "" then
            running = true
            break
        end
    end
    local from, to
    if running then
        from, to = prompts[1], #lines
    elseif #prompts == 2 then
        from, to = prompts[2], prompts[1] - 1
    else
        error("no previous command in this pane", 0)
    end
    local first, last = from + (with_command and 0 or 1), to
    while last >= first and lines[last] == "" do
        last = last - 1
    end
    if last < first then
        error("the last command printed nothing", 0)
    end
    return table.concat(lines, "\n", first, last)
end

local function copy_last(ctx, with_command)
    local screen = must(rex.block.call(TERM, "format", {
        block_id = ctx.block_id, trim = true, unwrap = true,
    }))
    local text = last_output(screen.content, with_command)
    local r, err = rex.exec({ "sh", "-c", 'printf %s "$1" | pbcopy', "sh", text })
    if r == nil then
        error(err, 0)
    end
    if not r.ok then
        error((r.stderr:gsub("%s+$", "")), 0)
    end
    return { copied = #text }
end

rex.action{
    name = "copy_last_output",
    title = "Copy Last Command's Output",
    run = function(ctx) return copy_last(ctx, false) end,
}
rex.action{
    name = "copy_last_command",
    title = "Copy Last Command and Its Output",
    run = function(ctx) return copy_last(ctx, true) end,
}
rex.bind("shift+cmd+o", "copy_last_output")
rex.bind("shift+cmd+alt+o", "copy_last_command")
