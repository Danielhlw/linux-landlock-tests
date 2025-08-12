local inbox = require "inbox"
local fs    = require "filesystem"
local file  = require "file"

local msg = inbox:receive()
print("[Child] Received message:", msg.value)

if msg.value == "append_file" then
  local path = fs.path.new("./t_append.txt")

  local fh, err = fs.open(path, {"write_only","create","append"}, fs.mode(6,6,6))
  if not fh then
    print("[Child] Failed to open/create for append:", err)
    msg.reply_to:send{ value = "error_open_append" }
    return
  end

  local stream = file.stream.new(fh)

  local bs = byte_span.append("Extra line via spawn_vm (append)\n")

  local n = stream:write_some(bs)  
  stream:close()

  if n > 0 then
    msg.reply_to:send{ value = "append_ok(" .. n .. " bytes)" }
  else
    msg.reply_to:send{ value = "append_failed(0 bytes)" }
  end
else
  msg.reply_to:send{ value = "unknown_command" }
end
