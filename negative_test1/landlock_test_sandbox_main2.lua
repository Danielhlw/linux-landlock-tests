local inbox = require "inbox"

local addr = spawn_vm{
  module = "./landlock_test_sandbox_child2",
  subprocess = { stdout = "share" },
}

print("[Main2] Sending message to child2...")
addr:send{ value = "write_on_readonly", reply_to = inbox }
local reply = inbox:receive()
print("[Main2] Reply: ", tostring(reply.value))
