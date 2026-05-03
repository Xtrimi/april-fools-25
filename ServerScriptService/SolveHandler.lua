local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local SolveData = require(script.SolveData)
local DiscoverData = require(script.DiscoverData)
local Codes = require(ServerStorage.Codes)
local RoompediaInfo = require(ServerStorage.RoompediaInfo)

-- DATA STUFF
Players.PlayerAdded:Connect(function(player: Player)
	ReplicatedStorage.UpdateRoompedia:FireClient(player, SolveData.getData(player), DiscoverData.getRoomInfoToSend(player))
end)

for _, player: Player in pairs(Players:GetPlayers()) do --incase ppl already exists
	ReplicatedStorage.UpdateRoompedia:FireClient(player, SolveData.getData(player), DiscoverData.getRoomInfoToSend(player))
end

-- SUBMISSION HANDLING
ReplicatedStorage.GetDoorCode.OnServerInvoke = function(player: Player, doorName, input: any)
	if Codes[doorName] == nil then
		warn("wth man . room", doorName, " code does not exist")
		return false
	end
	
	if typeof(Codes[doorName]) == "string" then
		if Codes[doorName] ~= input then
			return false
		end
	elseif typeof(Codes[doorName]) == "table" then
		for i, v in ipairs(Codes[doorName]) do
			if (input[i] ~= v) then
				return false
			end
		end
	end
	
	-- awesome! player got the code correct
	
	if doorName:sub(1, 1) == "!" then
		if doorName == "[REDACTED]" then
			player.misc.glagSecret.Value = true
		elseif doorName == "[REDACTED]" then
			ReplicatedStorage.TowerSolved:FireClient(player)
			player.misc.tower.Value = true
		end
		
		return true
	end
	
	if SolveData.playerData[player][doorName] == nil then
		warn("Unable to find room " .. doorName .. "in data keys")
	elseif SolveData.playerData[player][doorName] == false then
		SolveData.playerData[player][doorName] = true
		
		if doorName:sub(1, 1) == "M" then
			player.leaderstats["main rooms"].Value += 1
		elseif doorName:sub(1, 1) == "O" then
			player.leaderstats["optional rooms"].Value += 1
		end
		
		ReplicatedStorage.UpdateRoompedia:FireClient(player, SolveData.playerData[player], {})
	end
	
	return true
end

-- !! FOR SPECIAL ANSWER CHECKING !!
ReplicatedStorage.GetFreakyCode.OnServerInvoke = function(player: Player, doorName, input: any)
	if Codes[doorName] == nil then
		warn("wth man . room", doorName, " code does not exist")
		return false
	end

	if typeof(Codes[doorName]) ~= "function" then
		warn("This Is GetFreakyCode Bro! We Take Special Checks In This Take Your Code To Your GetDoorCode")
		return false
	else
		local correct = Codes[doorName](input, player)

		if not correct then
			return false
		end
	end

	if doorName:sub(1, 1) == "!" then
		--insert non-room exception
		
		return true
	end

	if SolveData.playerData[player][doorName] == nil then
		warn("Unable to find room " .. doorName .. "in data keys")
	elseif SolveData.playerData[player][doorName] == false then
		SolveData.playerData[player][doorName] = true

		if doorName:sub(1, 1) == "M" then
			player.leaderstats["main rooms"].Value += 1
		elseif doorName:sub(1, 1) == "O" then
			player.leaderstats["optional rooms"].Value += 1
		end

		ReplicatedStorage.UpdateRoompedia:FireClient(player, SolveData.playerData[player], {})
	end

	return true
end

ReplicatedStorage.UpdateDiscovery.Event:Connect(function(player: Player, room: string)
	if DiscoverData.playerData[player] == nil or DiscoverData.playerData[player][room] == nil then return end
    
	if RoompediaInfo[room] == nil then
		warn("Roompedia update fail: Room name not recognized")
		return
	end
    
	if DiscoverData.playerData[player][room] == false then
		DiscoverData.playerData[player][room] = true
        
		ReplicatedStorage.UpdateRoompedia:FireClient(player, SolveData.playerData[player], {
			[room] = RoompediaInfo[room]
		} or nil)
	end
end)