local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Codes = require(ServerStorage.Codes)

local dataStore = DataStoreService:GetDataStore("SolveData_1")

local SolveData = {}
SolveData.playerData = {} :: {[Player]: {[string]: boolean}}

local function createEmptyData(): {[string]: boolean}
	local data = {}
	
	for roomId: string, _ in pairs(Codes) do
		if roomId:sub(1, 1) == "!" then continue end

		data[roomId] = false
	end

	return data
end

function SolveData.solvedAllMain(player: Player): boolean
	if SolveData.playerData[player] == nil then return false end

	local allSolved = true
	for roomId: string, solved: boolean in pairs(SolveData.playerData[player]) do
		if roomId:sub(1, 1) == "M" then
			if not solved then
				allSolved = false
				break
			end
		end 
	end

	return allSolved
end

function SolveData.getData(player: Player): {[string]: boolean}
	if SolveData.playerData[player] ~= nil then
		return SolveData.playerData[player]
	end
	
	local data
	local success, err = pcall(function()
		data = dataStore:GetAsync(player.UserId)
		if data == nil then return end

		for roomId: string, _ in pairs(Codes) do --incase a new room gets added
			if roomId:sub(1, 1) == "!" then continue end

			if data[roomId] == nil then
				data[roomId] = false
			end
		end
	end)

	if success and data ~= nil then
		return data
	end

	if err then
		warn(err)
	end

	--uh oh! the player's data is gone. get a new one
	return createEmptyData()
end

function SolveData.updateData(player: Player, data: {[string]: boolean}?)
	if data == nil then
		warn("Cancelled updating data: No data received")
		return
	end

	local success, err = pcall(function()
		dataStore:UpdateAsync(player.UserId, function(oldData)
			if oldData == nil then return data end

			for i, v in pairs(data) do
				if v == false and oldData[i] == true then
					data[i] = true
				end
			end

			return data
		end)
	end)

	if err then
		warn(err)
	end
end

function SolveData.displayData(player: Player)
	local mainSolved = 0
	local optionalSolved = 0
	for i, v in pairs(SolveData.playerData[player]) do
		if v == false then continue end

		if i:sub(1, 1) == "M" then
			mainSolved += 1
		elseif i:sub(1, 1) == "O" then
			optionalSolved += 1
		end
	end

	local leaderstats = player:WaitForChild("leaderstats")
	leaderstats:WaitForChild("main rooms").Value = mainSolved
	leaderstats:WaitForChild("optional rooms").Value = optionalSolved
end

Players.PlayerAdded:Connect(function(player: Player)
	local data = SolveData.getData(player)
	SolveData.playerData[player] = data

	SolveData.displayData(player)
end)

for _, player: Player in pairs(Players:GetPlayers()) do --incase some ppl already exists
	local data = SolveData.getData(player)
	SolveData.playerData[player] = data

	SolveData.displayData(player)
end

--court is EXPLODED.
Players.PlayerRemoving:Connect(function(player: Player)
	SolveData.updateData(player, SolveData.playerData[player])
	SolveData.playerData[player] = nil
end)

game:BindToClose(function()
	for _, player in (Players:GetPlayers()) do
		if SolveData.playerData[player] ~= nil then
			SolveData.updateData(player, SolveData.playerData[player])
			SolveData.playerData[player] = nil
		end
	end
end)

return SolveData