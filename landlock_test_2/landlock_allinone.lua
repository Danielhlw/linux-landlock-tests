-- landlock_allinone.lua
local inbox = require "inbox"
local fs    = require "filesystem"

local ANCHOR = "/home/daniel/tstlandlock/landlock_test_2"

local init_code = string.format([[
  errexit = true

  local rnp, enp = set_no_new_privs()
  if rnp < 0 then error("set_no_new_privs errno="..tostring(enp)) end

  local rs = C.landlock_create_ruleset({ handled_access_fs = {
    "read_file","read_dir","write_file"
  }}, nil)

  local dfd = C.open("%s", bit.bor(C.O_PATH, C.O_DIRECTORY))

  C.landlock_add_rule(rs, "path_beneath", {
    allowed_access = {"read_file","read_dir"},
    parent_fd      = dfd,
  })

  C.landlock_restrict_self(rs)
  C.close(dfd)

  io.stderr:write("[init] LL ON: '%s' read-only\n")
]], ANCHOR, ANCHOR)

local addr = spawn_vm{
  module = fs.path.new("a.lua"), 
  subprocess = {
    stdout = "share",
    stderr = "share",
    init = { script = init_code },
  },
}

print("[main] sending 'go'")
addr:send{ value = "go", reply_to = inbox }

local ok, rep = pcall(function() return inbox:receive() end)
if not ok then
  print("[main] receive failed:", rep)
else
  print("[main] reply:", tostring(rep.value))
end
