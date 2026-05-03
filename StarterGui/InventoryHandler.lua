local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PlayerGui = player.PlayerGui

local ui = script.Parent
local ReceivedRooms = ui:WaitForChild("ReceivedRooms")
local Main = ui:WaitForChild("Main")
local Toggle = ui:WaitForChild("Toggle")
local Template = script:WaitForChild("Template")

local BackgroundMusicZones = ReplicatedStorage:WaitForChild("Background Music").BackgroundMusicZones
local SpawnedRooms = Instance.new("Folder") do
	SpawnedRooms.Name = "SpawnedRooms"
	SpawnedRooms.Parent = workspace
end

local roomCoroutines: {[Model]: {coroutine}} = {}

local function despawnRoom(room: Model)
	if roomCoroutines[room] ~= nil then
		for _, v in pairs(roomCoroutines[room]) do
			coroutine.close(v)
		end
	end

	for _, v: Model in pairs(BackgroundMusicZones:GetChildren()) do
		if v:FindFirstChild("AncestorCry") then
			if v.AncestorCry.Value == room then
				--Disgusting way to work around MusicModule's error
				for _, part in pairs(v:GetChildren()) do
					if part:IsA("BasePart") then
						part.Size = Vector3.new(.001, .001, .001)
						part.Position = Vector3.new(1337, 1337, 1337)
					end
				end
				
				task.delay(5, function()
					v:Destroy()
				end)
			end 
		end
	end
	
	room:Destroy()
end

local function loadRoom(room: Model)
	if room:FindFirstChild("BackgroundMusicZones") then
		for _, v in pairs(room.BackgroundMusicZones:GetChildren()) do
			local music = v:Clone()
			local AncestorCry = Instance.new("ObjectValue")
			AncestorCry.Name = "AncestorCry"
			AncestorCry.Value = room
			AncestorCry.Parent = music
			music.Parent = BackgroundMusicZones
		end
	end

	room.Parent = SpawnedRooms

	roomCoroutines[room] = {}
	for _, v in pairs(room:GetDescendants()) do
		if v:FindFirstChild("ClientObject") and v.ClientObject:IsA("BoolValue") and v:FindFirstChild("ClientScript") then
			local module
			local success, err = pcall(function()
				module = require(v.ClientScript)
			end)

			if success and module.localplayer() == player then
				local runModule = coroutine.create(function()
					module.main()
				end)

				table.insert(roomCoroutines[room], runModule)
				coroutine.resume(runModule)
			else
				print(err)
			end
		end
	end
end

local function goDestroy(room, clone)
	ReplicatedStorage.DespawnRoom:FireServer(room.AncestorCry.Value)
	despawnRoom(room)
end

local function initRoom(receivedRoom: Model)
	local room = receivedRoom:Clone()
	ReplicatedStorage.RoomReceived:FireServer(receivedRoom)
	loadRoom(room)

	local clone = Template:Clone()
	clone.Title.Text = room:GetAttribute("RoomName") or room.Name:split("_")[2] --Is that a titletext[] reference
	clone.Name = clone.Title.Text
	clone.Parent = Main.List
	
	
	clone.BackgroundColor3 = room:WaitForChild("AncestorCry").Value.Parent:GetAttribute("color") or Color3.fromRGB(211, 211, 211)
	
	clone.Despawn.MouseButton1Down:Connect(function()
		if script.Parent.Main:FindFirstChild("prompt") ~= nil then return end
		script.Beep:Play()
		local prompt = script.prompt:Clone()
		prompt.warning.Text = "KILL "..clone.Name.." ???"
		prompt.Parent = script.Parent.Main
		
		prompt.explode.MouseButton1Click:Connect(function()
			goDestroy(room)
			script.KILLED:Play()
			prompt:Destroy()
			clone:Destroy()
		end)
		
		prompt.defuse.MouseButton1Click:Connect(function()
			prompt:Destroy()
		end)
	end)

	clone.Teleport.MouseButton1Down:Connect(function()
		if room:FindFirstChild("AncestorCry") then
			player.Character:PivotTo(room.AncestorCry.Value.SPAWN:GetPivot() * CFrame.new(0, 7, 0))
		end
	end)
end

ReceivedRooms.ChildAdded:Connect(function(receivedRoom: Model)
	initRoom(receivedRoom)
end)

ReplicatedStorage.LootboxWarning.OnClientEvent:Connect(function(lootbox: Model, warning: string)
	lootbox.Trigger.WarnUI.Frame.Warn.Text = warning
	task.delay(1, function()
		lootbox.Trigger.WarnUI.Frame.Warn.Text = ""
	end)
end)

local toggled = false
Toggle.MouseButton1Down:Connect(function()
	Main.Visible = not toggled
	toggled = not toggled
end)

for k, v in pairs(ReceivedRooms:GetChildren()) do
	initRoom(v)
end

script.Parent.Main.refresh.MouseButton1Click:Connect(function()
	for k, v in pairs(ReceivedRooms:GetChildren()) do
		initRoom(v)
	end
end)