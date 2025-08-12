local inbox = require "inbox"

local addr = spawn_vm{
  module = "./landlock_test_sandbox_child",
  subprocess = { stdout = "share" },
}

print("[Main] Sending append command")
addr:send{
  value    = "append_file",
  reply_to = inbox,
}

local reply = inbox:receive()
print("[Main] Reply received:", tostring(reply.value))
