local inbox = require "inbox"

local addr = spawn_vm{
  module =  "./sandbox_read",
  subprocess = {
    stdout = "share",
  }
}

print("[Main] Sending msg to read the file")
addr:send{
  value = "reading file",
  reply_to = inbox
}
inbox:receive() 