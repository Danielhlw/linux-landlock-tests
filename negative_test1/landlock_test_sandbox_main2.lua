-- Basic negative test (the goal is to fail)

local inbox = require "inbox"

local addr = spawn_vm{
  module = "./landlock_test_sandbox_child2",
  subprocess = { stdout = "share" },
}

print("[Main2] Sending negative test (write_on_readonly)")
addr:send{
  value    = "write_on_readonly",
  reply_to = inbox,
}

local ok, reply_or_err = pcall(function()
  return inbox:receive()
end)

if not ok then
  print("[Main2] Receive failed:", reply_or_err)
else
  print("[Main2] Reply received:", tostring(reply_or_err.value))
end
