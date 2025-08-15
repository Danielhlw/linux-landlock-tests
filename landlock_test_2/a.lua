local inbox = require "inbox"
local fs    = require "filesystem"
local file  = require "file"

local BASE = "/home/daniel/tstlandlock/landlock_test_2"
local msg  = inbox:receive()
print("[child] go")

local path = fs.path.new(BASE .. "/t_append.txt")

local ok_open, fd_or_err, maybe_err = pcall(function()
  return fs.open(path, {"write_only","append"})
end)

if not ok_open then
  print("[child] blocked on open (thrown):", fd_or_err)
  msg.reply_to:send({ value = "blocked on open (thrown): "..tostring(fd_or_err) })
  return
end

local fd = fd_or_err
if not fd then
  print("[child] blocked on open:", maybe_err)
  msg.reply_to:send({ value = "blocked on open: "..tostring(maybe_err) })
  return
end

local ra = file.random_access.new(fd)
local ok_w, res = pcall(function()
  return file.write_all_at(ra, ra.size, "should be blocked by Landlock\n")
end)
ra:close()

if ok_w then
  print("[child]: wrote bytes:", res)
  msg.reply_to:send({ value = "UNEXPECTED: wrote "..tostring(res).." bytes" })
else
  print("[child] write blocked:", res)
  msg.reply_to:send({ value = "write blocked: "..tostring(res) })
end
