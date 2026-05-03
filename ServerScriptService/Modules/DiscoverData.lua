local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Codes = require(ServerStorage.Codes)
local RoompediaInfo = require(ServerStorage.RoompediaInfo)
local RoomNameToId = require(ServerStorage.RoomNameToId)

local dataStore = DataStoreService:GetDataStore("DiscoverData_1")

local DiscoverData = {}
DiscoverData.playerData = {} :: {[Player]: {[string]: boolean}}

local function createEmptyData(): {[string]: boolean}
	local data = {}

	for roomId: string, _ in pairs(Codes) do
		if roomId:sub(1, 1) == "!" then continue end

		data[roomId] = false
	end

	return data
end

function DiscoverData.getData(player: Player): {[string]: boolean}
	if DiscoverData.playerData[player] ~= nil then
		return DiscoverData.playerData[player]
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

function DiscoverData.updateData(player: Player, data: {[string]: boolean}?)
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

function DiscoverData.getRoomInfoToSend(player: Player): {[string]: any}
	local discoverData = DiscoverData.getData(player)
	
	local roomInfoToSend = {}

	for roomId: string, discovered in pairs(discoverData) do
		if discovered == true then
			roomInfoToSend[roomId] = RoompediaInfo[roomId]
		else
			roomInfoToSend[roomId] = {
				Serial = {
					Text = roomId
				}
			}
		end

		for _roomName: string, _roomId: string in pairs(RoomNameToId) do
			if _roomId == roomId then
				local COLORS = {
					["M"] = Color3.fromRGB(38, 120, 29),
					["O3"] = Color3.fromRGB(230, 100, 100),
					["O5"] = Color3.fromRGB(193, 87, 255)
				}
				
				roomInfoToSend[roomId].Serial.TextColor3 = COLORS[_roomName:split("_")[1]]
			end
		end
	end
	
	return roomInfoToSend
end

Players.PlayerAdded:Connect(function(player: Player)
	local discoverData = DiscoverData.getData(player)
	DiscoverData.playerData[player] = discoverData
end)

for _, player: Player in pairs(Players:GetPlayers()) do --incase some ppl already exists
	local data = DiscoverData.getData(player)
	DiscoverData.playerData[player] = data
end

Players.PlayerRemoving:Connect(function(player: Player)
	DiscoverData.updateData(player, DiscoverData.playerData[player])
	DiscoverData.playerData[player] = nil
end)

game:BindToClose(function()
	for _, player in (Players:GetPlayers()) do
		if DiscoverData.playerData[player] ~= nil then
			DiscoverData.updateData(player, DiscoverData.playerData[player])

			DiscoverData.playerData[player] = nil
		end
	end
end)

return DiscoverData
