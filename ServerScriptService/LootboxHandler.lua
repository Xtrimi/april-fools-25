local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Loader = require(script.Loader)
local RoomManager = require(script.RoomManager)

local roomDataStore = DataStoreService:GetDataStore("RoomData_1")

local lootboxes = Loader.getLootboxes()
Loader.getRooms()
local spawns = Loader.getSpawns()
local playerDebounce = {} --{[player: Player] = roomSpawnDebounce: boolean}

function getRandomChildren(haystack: Folder): any
	local needles = haystack:GetChildren()
	return needles[Random.new():NextInteger(1, #needles)]
end

local function init(player: Player)
	local data = roomDataStore:GetAsync(player.UserId) or {} --{["System32", "Basement", "Homework"] = {roomName: string}}
	local storedRooms = ServerStorage._ROOM_FOLDER

	RoomManager.playerInventory[player] = Loader.getSpawns()

	for lootbox: string, t in pairs(data) do
		local available = {}

		for spawner, v in pairs(RoomManager.playerInventory[player][lootbox]) do
			table.insert(available, spawner)
		end

		for _, roomName: string | boolean in pairs(t) do
			if roomName == false then continue end

			if storedRooms[roomName] ~= nil then
				local rand = Random.new():NextInteger(1, #available)

				RoomManager.spawnRoom(player, storedRooms[roomName], available[rand])
				table.remove(available, rand)
			else
				warn("ermmm....",roomName,"is",storedRooms[roomName])
			end
		end
	end
end

Players.PlayerAdded:Connect(init)
for _, player: Player in pairs(Players:GetPlayers()) do --incase ppl already exists
	init(player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	local data = RoomManager.playerInventory[player]
	
	roomDataStore:SetAsync(player.UserId, RoomManager.playerInventory[player] or {})
end)

for _, lootbox in pairs(lootboxes) do
	lootbox.Trigger.Touched:Connect(function(hit)
		if hit.Parent == nil or not hit.Parent:FindFirstChild("Humanoid") then return end
		
		local player = Players:GetPlayerFromCharacter(hit.Parent) 
		if player == nil then return end
		if playerDebounce[player] == true then return end
		
		playerDebounce[player] = true
		
		RoomManager.andGodSaidLetThereBeRoom(player, lootbox)

		task.delay(1, function()
			playerDebounce[player] = false
		end)
	end)
	
	if lootbox:FindFirstChild("Trigger4X") then
		lootbox.Trigger4X.Touched:Connect(function(hit)
			if hit.Parent == nil or not hit.Parent:FindFirstChild("Humanoid") then return end

			local player = Players:GetPlayerFromCharacter(hit.Parent) 
			if player == nil then return end
			if playerDebounce[player] == true then return end

			playerDebounce[player] = true

			for i = 1, 4 do
				RoomManager.andGodSaidLetThereBeRoom(player, lootbox)
			end

			task.delay(1, function()
				playerDebounce[player] = false
			end)
		end)
	end
end

ReplicatedStorage.DespawnRoom.OnServerEvent:Connect(function(player: Player, spawner)
	RoomManager.despawnRoom(player, spawner)
end)

ReplicatedStorage.RoomReceived.OnServerEvent:Connect(function(player, room: Model)
	print(room)
	room:Destroy()
end)