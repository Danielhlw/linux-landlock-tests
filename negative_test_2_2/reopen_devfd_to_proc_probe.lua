local fs   = require "filesystem"
local file = require "file"

local target = fs.path.new("./t_append.txt")

local ro_fd, ro_err = fs.open(target, {"read_only"})
assert(ro_fd, "open(read_only) failed: " .. tostring(ro_err))

local s = tostring(ro_fd)
local n = s:match("^/dev/fd/(%d+)$") or s:match("^(%d+)$") or s:match("(%d+)")
assert(n, "couldn't extract fd number from tostring(fd): " .. s)

local procpath = fs.path.new("/proc/self/fd/" .. n)
print("fd:", n, "-> reopen path:", tostring(procpath))

local wr_fd, err2 = fs.open(procpath, {"write_only", "append"})
if not wr_fd then
  print("reopen failed:", err2)
  file.stream.new(ro_fd):close()
  return
end

local ra = file.random_access.new(wr_fd)
local ok, wrote_or_err = pcall(function()
  return file.write_all_at(ra, ra.size,
    "line via reopen (found via /dev/fd, reopened via /proc/self/fd)\n")
end)

ra:close()
file.stream.new(ro_fd):close()

if not ok then
  print("write failed:", wrote_or_err)
else
  print("wrote bytes:", wrote_or_err)
end
