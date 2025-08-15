local inbox  = require "inbox"
local fs     = require "filesystem"
local file   = require "file"
local system = require "system"

local msg = inbox:receive()
print("[Child] Received:", msg.value)

local ok_link, link200 = pcall(function() return fs.read_symlink(fs.path.new("/proc/self/fd/200")) end)
print("[Child] FD200 resolves to:", ok_link and tostring(link200) or ("<unavailable: "..tostring(link200)..">"))

local abi = assert(system.landlock_create_ruleset(nil, {"version"}))
local handled = {
  "execute","write_file","read_file","read_dir","remove_dir","remove_file",
  "make_char","make_dir","make_reg","make_sock","make_fifo","make_block","make_sym",
}
if abi >= 2 then table.insert(handled, "refer") end
if abi >= 3 then table.insert(handled, "truncate") end

local rs = assert(system.landlock_create_ruleset({ handled_access_fs = handled }, nil))

local ok_rule, err_rule = pcall(system.landlock_add_rule, rs, "path_beneath", {
  allowed_access = { "read_file", "read_dir" },
  parent_fd= 200,
})
if not ok_rule then
  print("[Child] landlock_add_rule failed:", err_rule)
  msg.reply_to:send{ value = "ERROR: add_rule: "..tostring(err_rule) }
  return
end
print("[Child] Rule added: '.' read-only (parent_fd=200, O_PATH)")

assert(system.landlock_restrict_self(rs))
print("[Child] Ruleset enforced")

local target = fs.path.new("./t_append.txt")
local wr_fd, open_err = fs.open(target, {"write_only","append"})
if not wr_fd then
  print("[Child] OK: open for write blocked:", open_err)
  msg.reply_to:send{ value = "OK: open blocked: " .. tostring(open_err) }
  return
end

local ra = file.random_access.new(wr_fd)
local ok, wrote_or_err = pcall(function()
  return file.write_all_at(ra, ra.size, "should be blocked by '.' read-only\n")
end)
ra:close()

if ok then
  print("[Child] UNEXPECTED: wrote bytes:", wrote_or_err)
  msg.reply_to:send{ value = "ERROR: wrote " .. tostring(wrote_or_err) .. " bytes (unexpected)" }
else
  print("[Child] OK: write blocked after open:", wrote_or_err)
  msg.reply_to:send{ value = "OK: write blocked: " .. tostring(wrote_or_err) }
end
