local fs   = require "filesystem"
local file = require "file"

local stream = file.stream.new()
stream:open(fs.path.new("./t_append_test.txt"), {"write_only","create","append"}, fs.mode(6,6,6))

local s  = "Test line from append_test.lua\n"

local bs = byte_span.append(s)

local n = stream:write_some(bs) 
stream:close()

print(("append_ok: wrote %d bytes"):format(n))

