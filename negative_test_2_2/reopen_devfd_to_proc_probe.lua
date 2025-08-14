local fs   = require "filesystem"
local file = require "file"

local target = fs.path.new("./t_append.txt")

-- 1) Mantém o arquivo aberto em RO (garante que o FD exista)
local ro_fd, ro_err = fs.open(target, {"read_only"})
assert(ro_fd, "open(read_only) failed: " .. tostring(ro_err))

-- 2) Extrai o número do FD a partir de tostring(fd) (formatos possíveis: "3", "/dev/fd/3", "file_descriptor(3)")
local s = tostring(ro_fd)
local n = s:match("^/dev/fd/(%d+)$") or s:match("^(%d+)$") or s:match("(%d+)")
assert(n, "couldn't extract fd number from tostring(fd): " .. s)

-- 3) Faz o REOPEN via /proc/self/fd/<n> (não /dev/fd), com WRITE|APPEND
local procpath = fs.path.new("/proc/self/fd/" .. n)
print("fd:", n, "-> reopen path:", tostring(procpath))

local wr_fd, err2 = fs.open(procpath, {"write_only", "append"})
if not wr_fd then
  print("reopen failed:", err2)
  file.stream.new(ro_fd):close()
  return
end

-- 4) Escreve pelo descritor reaberto (string direta; write_all_at evita short writes)
local ra = file.random_access.new(wr_fd)
local ok, wrote_or_err = pcall(function()
  return file.write_all_at(ra, ra.size,
    "line via reopen (found via /dev/fd, reopened via /proc/self/fd)\n")
end)

-- 5) Fecha tudo
ra:close()
file.stream.new(ro_fd):close()

-- 6) Resultado
if not ok then
  print("write failed:", wrote_or_err)
else
  print("wrote bytes:", wrote_or_err)
end
