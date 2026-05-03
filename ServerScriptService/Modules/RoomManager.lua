local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Loader = require(script.Parent.Loader)
local RoomNameToId = require(ServerStorage.RoomNameToId)
local RoompediaInfo = require(ServerStorage.RoompediaInfo)
local SolveData = require(ServerScriptService.SolveHandler.SolveData)

local CHANCES = {
	["Homework"] = {
		["M"] = 100
	},
	["Basement"] = {
		["M"] = 30, --33
		["O3"] = 50,
		["O5"] = 20
	},
	["System32"] = {
		["O3"] = 60, --60
		["O5"] = 40 --40
	}
}

local rooms = Loader.getRooms()
local playerStartTime = {} --{[player: Player] = {startTick: number}}

local RoomManager = {}
RoomManager.playerInventory = {} --{[player: Player] = {["System32", "Basement", "Homework"] = {[spawner] = false (available) or roomName: string}}}

Players.PlayerAdded:Connect(function(player)
	playerStartTime[player] = tick()
end)

for _, player: Player in pairs(Players:GetPlayers()) do
	playerStartTime[player] = tick()
end

local function modifiedPrice(base, solved)
	return base * 1.08^solved
end

local function checkPlayerReq(player, lootbox)
	local leaderstats = player.leaderstats
	if leaderstats["glaggle coins :)"].Value <
		modifiedPrice(lootbox.Coins.Value, leaderstats["main rooms"].Value+leaderstats["optional rooms"].Value) then
		return "not enough glaggle coins... Noob"
	end

	if lootbox:FindFirstChild("Rooms") then
		if leaderstats["main rooms"].Value + leaderstats["optional rooms"].Value < lootbox.Rooms.Value then
			ReplicatedStorage.MiscEvents.TriggerTutorial:FireClient(player, "Solve more rooms to use this lootbox.")
			return "not enough total rooms solved... skilli ssue"
		end
	elseif lootbox:FindFirstChild("MainRooms") then
		if leaderstats["main rooms"].Value < lootbox.MainRooms.Value then
			return "you havent solved all main rooms go back brah"
		end
	end

	return nil
end

function RoomManager.despawnRoom(player: Player, target: PVInstance)
	for lootbox, v in pairs(RoomManager.playerInventory[player]) do
		for spawner, room in pairs(v) do
			if spawner == target then
				RoomManager.playerInventory[player][lootbox][spawner] = false

				return
			end
		end
	end

	warn("Room was not found during despawning")
end

function RoomManager.spawnRoom(player: Player, room: PVInstance, spawner): CFrame
	local clone = room:Clone()

	local roomId = RoomNameToId[room.Name]
	if roomId ~= nil and RoompediaInfo[roomId] ~= nil then
		clone:SetAttribute("RoomName", RoompediaInfo[roomId].Title.Text)
	end

	if clone.PrimaryPart == nil then
		clone.PrimaryPart = clone:FindFirstChild("Center")
	end

	clone:PivotTo(spawner:GetPivot())

	local AncestorCry = Instance.new("ObjectValue")
	AncestorCry.Name = "AncestorCry"
	AncestorCry.Value = spawner
	AncestorCry.Parent = clone
	clone.Parent = player.PlayerGui:WaitForChild("RoomInventory").ReceivedRooms

	RoomManager.playerInventory[player][spawner.Parent.Name][spawner] = clone.Name

	ReplicatedStorage.UpdateDiscovery:Fire(player, RoomNameToId[room.Name] or "")
	
	return spawner.SPAWN:GetPivot() * CFrame.new(0, 7, 0)
end

function RoomManager.rollRoom(player: Player, lootbox): PVInstance
	local sum = 0
	for i, w in pairs(CHANCES[lootbox.Name]) do
		sum += w
	end

	local modifiedWeight = table.clone(CHANCES[lootbox.Name])
	local newSum = 0
	for i, w in pairs(CHANCES[lootbox.Name]) do
		modifiedWeight[i] = w ^ (1 - 4 * (tick() - playerStartTime[player]) / 86400)
		newSum += modifiedWeight[i]
	end
	
	local rng = Random.new():NextNumber(0, newSum) --L i used integer instead of numbr (-1 gone)
	for i, w in pairs(modifiedWeight) do
		if rng < w then
			local rolledRoom = rooms[i][Random.new():NextInteger(1, #rooms[i])]
			
			if SolveData.playerData[player][RoomNameToId[rolledRoom.Name]] == true then
				if Random.new():NextInteger(1, 100) <= 66 then
					return RoomManager.rollRoom(player, lootbox)
				end
			end
			
			return rolledRoom
		end

		rng -= w
	end

	print("The sky is falling (failed to roll room from", lootbox)
end

function RoomManager.andGodSaidLetThereBeRoom(player: Player, lootbox)
	local warning = checkPlayerReq(player, lootbox)

	local available = {}
	for spawner, v in pairs(RoomManager.playerInventory[player][lootbox.Name]) do
		if v == false then
			table.insert(available, spawner)
		end
	end

	if #available == 0 then
		warning = "max rooms for this lootbox reached"
		ReplicatedStorage.MiscEvents.TriggerTutorial:FireClient(player, "Delete some of the rooms in your inventory before using this lootbox again.", UDim2.new(0.103, 0, 0.317, 0), UDim2.new(0.15, 0, 0.15, 0), true)
	end

	if warning ~= nil then

		if warning == "not enough glaggle coins... Noob" then
			ReplicatedStorage.MiscEvents.TriggerTutorial:FireClient(player, "Get more \"glaggle coins\" by killing minions.", UDim2.new(0.5, 0, 0.95, 0), UDim2.new(0.3, 0, 0.1, 0), true)
		end

		if warning == "not enough total rooms solved... skilli ssue" then
			ReplicatedStorage.MiscEvents.TriggerTutorial:FireClient(player, "Solve more rooms to use this lootbox.")
		end

		ReplicatedStorage.LootboxWarning:FireClient(player, lootbox, warning)

		return
	end

	local room = RoomManager.rollRoom(player, lootbox)
	local spawner = available[Random.new():NextInteger(1, #available)]

	if room then
		local roomCFrame = RoomManager.spawnRoom(player, room, spawner)
		player.Character:PivotTo(roomCFrame)
		
		player.leaderstats["glaggle coins :)"].Value -=
			modifiedPrice(lootbox.Coins.Value, player.leaderstats["main rooms"].Value + player.leaderstats["optional rooms"].Value)
	end
end

return RoomManager