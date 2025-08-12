local inbox = require "inbox"
local fs    = require "filesystem"
local file  = require "file"

local msg = inbox:receive()
print("[Child3] Received:", msg.value)

if msg.value ~= "reopen_append_no_ll" then
  msg.reply_to:send{ value = "unknown_command" }
  return
end

local target = fs.path.new("./t_append.txt")

local ro_fd, ro_err = fs.open(target, {"read_only"})
if not ro_fd then
  print("[Child3] open(read_only) failed:", ro_err)
  msg.reply_to:send{ value = "setup_failed: "..tostring(ro_err) }
  return
end

local function find_fd_for_target(p)
  local want
  do
    local ok, canon = pcall(function() return fs.canonical(p) end)
    want = ok and tostring(canon) or tostring(p)
  end
  for n = 0, 1024 do
    local link = fs.path.new("/proc/self/fd/"..n)
    local ok, tp = pcall(function() return fs.read_symlink(link) end)
    if ok and tp then
      local got = tostring(tp)
      if got:sub(-#want) == want then
        return n
      end
    end
  end
  return nil, "fd not found in /proc/self/fd"
end

local n, why = find_fd_for_target(target)
if not n then
  file.stream.new(ro_fd):close()
  msg.reply_to:send{ value = "BLOCKED: not found: "..tostring(why) }
  return
end
print("[Child3] FD found:", n)

local wr_fd, err2 = fs.open(fs.path.new("/proc/self/fd/"..n), {"write_only","append"})
if not wr_fd then
  print("[Child3] reopen failed:", err2)
  file.stream.new(ro_fd):close()
  msg.reply_to:send{ value = "BLOCKED: reopen failed: "..tostring(err2) }
  return
end

local ra = file.random_access.new(wr_fd)
local ok, wrote_or_err = pcall(function()
    return file.write_all_at(ra, ra.size, "line via reopen (no LL)\n")
end)

ra:close()
file.stream.new(ro_fd):close()

if not ok then
  msg.reply_to:send{ value = "BLOCKED: write failed after reopen: "..tostring(wrote_or_err) }
elseif wrote_or_err and wrote_or_err > 0 then
  print("[Child3] wrote bytes:", wrote_or_err)
  msg.reply_to:send{ value = "OK: reopened and wrote "..wrote_or_err.." bytes" }
else
  msg.reply_to:send{ value = "UNEXPECTED: wrote 0 bytes" }
end
