local inbox = require "inbox"

local addr = spawn_vm{
  module = "./landlock_test_sandbox_child3",
  subprocess = { stdout = "share" },
}

print("[Main3] Sending: reopen_append_no_ll")
addr:send{ value = "reopen_append_no_ll", reply_to = inbox }

local reply = inbox:receive()
print("[Main3] Reply:", tostring(reply.value))

