local inbox = require "inbox"
local fs    = require "filesystem"
local file  = require "file"

local msg = inbox:receive()
print("[Child] Received message:", msg.value)

if msg.value == "write_on_readonly" then
  local path = fs.path.new("./t_append.txt")

  -- Ensure file exists (setup only)
  local ro_fd, ro_err = fs.open(path, { "read_only" })
  if not ro_fd then
    local tmp = file.stream.new()
    tmp:open(path, { "write_only", "create" }, fs.mode(6,6,6))
    tmp:close()
    ro_fd, ro_err = fs.open(path, { "read_only" })
    if not ro_fd then
      msg.reply_to:send{ value = "error_open_readonly:" .. tostring(ro_err) }
      return
    end
  end

  local stream = file.stream.new(ro_fd)
  local bs     = byte_span.append("should NOT be written\n")

  -- Use pcall just to capture the expected error without killing the VM
  local ok, res = pcall(function()
    return stream:write_some(bs)   -- should fail (FD is read-only)
  end)
  stream:close()

  if ok and res and res > 0 then
    msg.reply_to:send{ value = "UNEXPECTED: wrote " .. res .. " bytes" }
  else
    msg.reply_to:send{ value = "OK: write_on_readonly blocked: " .. tostring(res) }
  end

else
  msg.reply_to:send{ value = "unknown_command" }
end
