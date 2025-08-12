local inbox = require "inbox"
local fs = require "filesystem"

local msg = inbox:receive()
print("[Child] Received msg:", msg.value)
msg.reply_to:send{ value = "passou" }
