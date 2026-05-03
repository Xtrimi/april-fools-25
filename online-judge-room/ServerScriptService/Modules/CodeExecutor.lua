local RunService = game:GetService("RunService")

local ENV = {
	bit32 = bit32,
	coroutine = coroutine,
	DateTime = DateTime,
	ipairs = ipairs,
	math = math,
	next = next,
	NumberRange = NumberRange,
	os = os,
	string = string,
	pairs = pairs,
	Random = Random,
	table = table,
	task = task,
	tick = tick,
	time = time,
	type = type,
	typeof = typeof,
	tonumber = tonumber,
	tostring = tostring,
	wait = wait,
}

local CodeExecutor = {}

function CodeExecutor.TestCode(code: string, input: any): (string, string)
	local fake, err = loadstring(code) --I am Xtrimi This is for my Room
	
	if fake == nil then
		return "CE", err
	end
	
	local newENV = table.clone(ENV)
	newENV.input = input
	local real, err = setfenv(fake, table.clone(newENV))
	
	if real == nil then
		return "CE", err
	end
	
	local success, judgement, result
	local evaluation: thread
	
	evaluation = function() --task.spawn()
		success, result = pcall(real)

		if not success then
			judgement = "RE"
		end
	end
	task.spawn(evaluation)

	return judgement, result
end

return CodeExecutor