local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Loader = {}

function Loader.getLootboxes()
	return workspace._LOOTBOXES:GetChildren()
end

function Loader.getRooms()
	local rooms = {
		["M"] = {},
		["O3"] = {},
		["O5"] = {}
	}

	if workspace:FindFirstChild("_ROOM_FOLDER") then
		workspace._ROOM_FOLDER.Parent = ServerStorage
	end

	for _, room in pairs(ServerStorage._ROOM_FOLDER:GetChildren()) do
		if rooms[room.Name:split("_")[1]] == nil then
			warn("Unable to insert room " .. room.Name .. ": Type of room not found")
			continue
		end

		table.insert(rooms[room.Name:split("_")[1]], room)
	end

	return rooms
end

function Loader.getSpawns()
	local roomSpawns = {}

	for _, v in pairs(workspace._ROOM_SPAWNS:GetChildren()) do
		roomSpawns[v.Name] = {}

		for _, spawner in pairs(v:GetChildren()) do
			if not spawner:IsA("BasePart") then
				continue
			end

			roomSpawns[v.Name][spawner] = false
		end

		if v:FindFirstChild("Highlight") then
			v.Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		end
	end

	return roomSpawns
end

return Loader
