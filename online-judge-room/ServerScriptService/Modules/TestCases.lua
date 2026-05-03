local function solve(input)
	--REDACTED
	return ans
end

local function bruteforce(input)
	--REDACTED
end

local function phsadsSolve(input)
	--REDACTED
end

local function generatePermutation(n)
	local P = {}
	for i=1,n do
		P[i] = i 
	end
	for i=1,n do
		local a = Random.new():NextInteger(1,n)
		local b = Random.new():NextInteger(1,n)
		P[a], P[b] = P[b], P[a] --swap
	end
	return P
end

local function generateTreeBfb(n,treeType,shuffle)
	--print("generating....")
	local vertices={}
	local P = {}
	if (shuffle) then P = generatePermutation(n)
	else
		for i=1,n do P[i] = i end
	end
	vertices[1] = n --get creative
	
	for i=2,n do
		if (treeType == "normal") then
			--REDACTED
		end
		if (treeType == "ultra") then
			--REDACTED
		end
		if (treeType == "binary") then
			--REDACTED
		end
		if (treeType == "line") then
			--REDACTED
		end
	end
	
	local case = table.concat(vertices, "\n")
	return case
end

local function generateCase(n, uc)
	local case = {}

	case.input = generateTreeBfb(n, uc)
	case.answer = phsadsSolve(case.input)
	return case
end

local function tryer(times)
	if (times == 0) then return end

	local case = generateTreeBfb(50)
	local a = bruteforce(case)
	local b = phsadsSolve(case)

	if (a == b) then
        tryer(times-1)
	else
        print(case)
    end
end

local TestCases = {
	[1] = generateCase(6, "normal", true),
	[2] = generateCase(10, "normal", true),
	[3] = generateCase(20, "normal", true),
	[4] = generateCase(20, "normal", true),
	[5] = generateCase(100, "normal", true),
	[6] = generateCase(200, "normal", true),
	[7] = generateCase(500, "normal", true),
	[8] = generateCase(1000, "normal", true),
	[9] = generateCase(10000, "ultra", true),
	[10] = generateCase(10000, "normal", true),
	[11] = generateCase(100000, "normal", true),
	[12] = generateCase(100000, "normal", true),
	[13] = generateCase(100000, "ultra", true),
	[14] = generateCase(100000, "line", false),
	[15] = generateCase(100000, "binary", true),
}

return TestCases