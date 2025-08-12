-- test reopen with append and probe

local fs   = require "filesystem"
local file = require "file"

local target = fs.path.new("./t_append.txt")

local ro_fd = assert(fs.open(target, {"read_only"}))

local function find_fd_for_target(p)
  local want
  do
    local ok, canon = pcall(function() return fs.canonical(p) end)
    want = ok and tostring(canon) or tostring(p)
  end
  for n = 0, 1024 do
    local ok2, tp = pcall(function() return fs.read_symlink(fs.path.new("/proc/self/fd/"..n)) end)
    if ok2 and tp and tostring(tp):sub(-#want) == want then
      return n
    end
  end
  return nil, "fd not found"
end

local n = assert(find_fd_for_target(target))
print("found fd =", n)

local wr_fd = assert(fs.open(fs.path.new("/proc/self/fd/"..n), {"write_only","append"}))

local ra = file.random_access.new(wr_fd)

local written = file.write_all_at(ra, ra.size, "line via reopen (probe, all_at)\n")
print("wrote bytes:", written)

ra:close()
file.stream.new(ro_fd):close()
