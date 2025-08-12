local fs = require 'filesystem'

function test_open_create (filepath)
	local p = fs.path.new(filepath)
	fs.create_directories(p.parent_path)
	
	local fd = fs.open(p, {'write_only', 'create', 'truncate'}, fs.mode(7,7,7))
	print ("FD: ", fd)
	if fd then
		fd:close()
		print ("FD concluído com sucesso! ", tostring(p))
	else
		print("FD deu erro ", tostring(p))
	end
end

test_open_create("/home/daniel/projetos/tstlandlock/testsemlandlock/t.txt")
