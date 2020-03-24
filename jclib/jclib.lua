local args = args or {...}
local sargs = table.concat(args, " ")
local shell = require("shell")

local jclib = {}

local function stringLineSplit(str)
		lines = {}
		for s in str:gmatch("[^\r\n]+") do
			table.insert(lines, s)
		end
		return lines
	end


-- Executes a command and returns status, stdout, stderr
-- @param command The string containing the command + args
-- @param stdin The stdin string
function jclib.executeCommand(command, stdin)
	local my_stdin = stdin or ""
	local my_stdout = ""
	local my_stderr = ""
	assert(type(command) == "string")
	--assert(type(my_stdin) == "string")

	local orig_io_write = io.write
	local orig_io_read = io.read
	local orig_io_stdin_read = io.stdin.read
	local orig_print = print
	local orig_io_input = io.input

	function io.write(...)
		local sargs = table.concat({...}, "")
		my_stdout = my_stdout .. sargs
	end
	
	function io.read()
		return my_stdin
	end

	function print(...)
		local sargs = table.concat({...}, " ")
		io.write(sargs.."\n")
	end
	
	function io.input()
		local fake = {}
		fake._currentLine = 1
		fake.read = function(self, le)
			--orig_io_write("fake read called with " .. le)
			if le == "*l" then
				local t = stringLineSplit(my_stdin)[self._currentLine]
				self._currentLine = self._currentLine + 1
				return t
			else
				return my_stdin
			end
		end
		fake.close = function() end
	
		return fake
	end
	
	--orig_io_write("Running\n")
	local status = shell.execute(command)

	--put them back!
	io.write = orig_io_write
	io.read = orig_io_read
	io.stdin.read = orig_io_stdin_read
	print = orig_print
	io.input = orig_io_input
	

	return status, my_stdout, my_stderr
end


return jclib

--local s,o,e = jclib.ExecuteCommand("echo \"hello\nthere\ngeneral\"")
--s,o,e = jclib.ExecuteCommand("grep l", o)
--print("Status:" .. tostring(s))
--print("Out:" .. o)
--print("Error:" .. e)