local inbox = require "inbox"
local fs    = require "filesystem"
local file  = require "file"

local msg = inbox:receive()
print("[Child2] Received:", msg.value)

local fd, err = fs.open(fs.path.new("./t_append.txt"), { "read_only" })
if not fd then
  print("[Child2] open(read_only) failed:", err)
  msg.reply_to:send{ value = "setup_failed: " .. tostring(err) }
  return
end

local st = file.stream.new(fd)
local ok, res = pcall(function()
  return st:write_some(byte_span.append("should NOT be written\n"))
end)
st:close()

if ok and res and res > 0 then
  print("[Child2] unexpected: wrote", res, "bytes")
  msg.reply_to:send{ value = "unexpected: wrote " .. res .. " bytes" }
else
  print("[Child2] Blocked as expected:", res)
  msg.reply_to:send{ value = "OK: blocked: " .. tostring(res) }
end
