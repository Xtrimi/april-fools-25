local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local CodeExecutor = require(script.CodeExecutor)
local TestCases = require(script.TestCases)

local function hash(x, y, p): number
	local res = 1
	x %= p
	while y>0 do
		if y%2==1 then res = (res*x)%p end
		y = y//2
		x = (x*x)%p
	end
		
	return res%p
end

ReplicatedStorage.GetDoorCode.OnServerInvoke = function(player: Player, _: string, code: string)
	for i, v in ipairs(TestCases) do
		
		local startTime = DateTime.now().UnixTimestampMillis
		local endTime = DateTime.now().UnixTimestampMillis
		local timePassed = 0
		
		local judgement, result, con
        
		local uhhm = task.spawn(
			function()
				local a,J = pcall(function()
					local j, r = CodeExecutor.TestCode(code, v.input)
					return {j, r}
				end)

				judgement = J[1]
				result = J[2]

				if (not a) then judgement = "TLE" end
			end
		)
		
		while judgement == nil do
			local endTime = DateTime.now().UnixTimestampMillis
			local timePassed = (endTime - startTime)/1000

			if result ~= nil then
				if typeof(result) ~= "string" then
					judgement = "PE"
					result = "Output must be a string"
				elseif #result:split("\n") ~= #v.answer:split("\n") then
					judgement = "PE"
					result = "Check your newlines"
				elseif #result:split(" ") ~= #v.answer:split(" ") then
					judgement = "PE"
					result = "Check your spaces"
				elseif result == v.answer then
					judgement = "AC"
				else
					judgement = "WA"
					result = "Wrong answer on test " .. tostring(i) 
				end
			end
			if timePassed > 1.5 then
				task.cancel(uhhm)
				judgement = "TLE"
				result = "Time limit exceeded on test " .. tostring(i)
			end
		end
		
		if (judgement == nil) then judgement = "IDK" end
		if (judgement == "RE") then result = "Runtime error on test " .. tostring(i) .. "\n" .. result end
		
		if judgement ~= "AC" then
			return judgement, result
		end
		
	end
	
	BadgeService:AwardBadgeAsync(player.UserId, 3014880791384982)
	
	return "AC", ("Your code is: %i"):format(hash(player.UserId, "REDACTED", "REDACTED"))
end