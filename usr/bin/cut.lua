local shell = require("shell")
local fs = require("filesystem")

local args = table.pack(...)
local sargs = " " .. table.concat(args, " ") .. " "

local function usage()
  print("Usage: cut OPTION... [FILE]\n"..[[
Print selected parts of lines from FILE to standard output.
With no FILE, or when FILE is -, read standard input.

	-c, --characters=LIST
		select only these characters

	-d, --delimiter=DELIM
		use DELIM instead of TAB for field delimiter

	-f, --fields=LIST
		select only these fields; also print any line that contains no delimiter character, unless the -s option is specified.

	-s, --only-delimited
		do not print lines not dontaining delimiters
	
Just check the man page tbh.
]])
end

local function argsMatch(text)
	local l = sargs:match(text)
	return l
end

local function oldargsMatch(text)
	for key,value in pairs(args) do
		if key ~= "n" then
			local l = value:match(text)
			if l ~= nil then
				return l
			end
		end
	end
	return nil
end

local function argsMatchOr(...)
	local patterns = table.pack(...)
	for key,value in pairs(patterns) do
		if key ~= "n" then
			local l = argsMatch(value)
			if l ~= nil then
				return l
			end
		end
	end
	return nil
end

local function cutFunc(line,cut)
	return line:sub(cut[1], cut[2])
end


local function Split(text, de)
	local t = {}
	for str in string.gmatch(text, "([^" .. de .. "]+)") do
		table.insert(t,str)
	end
	return t
end


--for m,n in pairs(args) do
--	print(m .. ":" .. n)
--end

local DEBUG = argsMatch("%s--debug%s")

if argsMatch("%s-h%s") or argsMatch("%s--help%s") then
  usage()
  return 1
end

local rawFile = argsMatchOr("%s(%a+)%s", "%s(%./.+)%s", "^%/%w+", "^-&") or "-"
local file = shell.resolve(rawFile)
local delimiter = argsMatchOr("%s-d\"(.)\"%s", "%s-d(.)%s", "%s%-%-delimiter=\"(.)\"%s", "%s%-%-delimiter=(.)%s") or "\t"
local rawFields = argsMatchOr("%s-f([%d,]+)%s", "%s%-%-fields=([%d,]+)%s") or ""
local fields = Split(rawFields, ",")
local onlyDelimiter = argsMatchOr("%s-s%s", "%s%-%-only-delimited%s") or false
local rawCut = argsMatchOr("%s-c%s(%d+%-%d+)%s") or ""
local cut = Split(rawCut, "-")

if DEBUG then
	print("rawFile:" .. rawFile)
	print("file:" .. file)
	print("delimiter:" .. delimiter)
	print("rawFields:" .. rawFields)
	print("onlyDelimiter:" .. tostring(onlyDelimiter))
	print("rawCut:" .. rawCut)
	print("cut:"..cut[1]..cut[2])
end

--[[if #fields == 0 then
	io.stderr:write("No fields specified")
	return 4
end]]--

local input = ""
if rawFile == "-" then --load from standard in
	repeat
		local data = io.read()
		input = input .. (data or "")
	until not data
else
	if fs.exists(file) then
		if fs.isDirectory(file) then
			io.stderr:write("This is a directory: " .. file)
			return 3
		else
			local f = fs.open(file)
			repeat
				local data = f:read(math.huge)
				input = input .. (data or "")
			until not data
			f:close()
		end
	else
		io.stderr:write("File doesn't exist: " .. file)
		return 2
	end
end

local textLines = Split(input, "\n")


for _,line in pairs(textLines) do
	local output = {}
	
	if rawCut ~= "" then
		print(cutFunc(line, cut))
	else
		local textFields = Split(line,delimiter)
		if #textFields == 1 then
			if onlyDelimiter == false then 
				table.insert(output, line)
			end
		elseif #fields == 0 then
			table.insert(output, line)
		else
			for _,m in pairs(fields) do
				table.insert(output, textFields[tonumber(m)])
			end
		end
		if #output > 0 then
			io.write(table.concat(output, delimiter) .. "\n")
		end
	end
end



