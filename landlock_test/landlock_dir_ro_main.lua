local inbox = require "inbox"

local addr = spawn_vm{
  module = "./landlock_dir_ro_child",
  subprocess = {
    stdout = "share",
    stderr = "share",
    init = {
      script = [[
        -- Aq vai abrir '.' como O_PATH|O_DIRECTORY e dup2 pra o FD 200 
        local flags = bit.bor(C.O_PATH, C.O_DIRECTORY)
        local dfd = C.open(".", flags)
        assert(dfd >= 0, "C.open('.') O_PATH failed")
        assert(C.dup2(dfd, 200) >= 0, "dup2 200 failed")
        C.close(dfd)
        -- verificar dnv se funciona e ler a doc
      ]]
    }
  }
}

print("[Main] Sending: go")
addr:send{ value = "go", reply_to = inbox }

local reply = inbox:receive()
print("[Main] Reply:", tostring(reply.value))
