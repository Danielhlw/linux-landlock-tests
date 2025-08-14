local fs   = require "filesystem"
local file = require "file"

local target = fs.path.new("./t_append.txt")

local ro_fd = assert(fs.open(target, {"read_only"}))

local s = tostring(ro_fd)
print('Print do S: ',s)
local n = s:match("^/dev/fd/(%d+)$") or s:match("^(%d+)$") or s:match("(%d+)")
assert(n, "couldn't extract fd number from tostring(fd): "..s)

print("ro_fd:", tostring(ro_fd))

local devfd_path = fs.path.new("/dev/fd/" .. n)
print("devfd path:", tostring(devfd_path))

local wr_fd, err2 = fs.open(devfd_path, {"write_only","append"})
if not wr_fd then
  print("reopen failed:", err2)
  file.stream.new(ro_fd):close()
  return
end

local ra = file.random_access.new(wr_fd)
local written = file.write_all_at(ra, ra.size, "line via /dev/fd reopen (probe2212)\n")

ra:close()
file.stream.new(ro_fd):close()

print("wrote bytes:", written)
