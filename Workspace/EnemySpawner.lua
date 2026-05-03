-- scripted by Secondary
-- some soup added by xtrim. What the Hell is a exception while signaling: Must be a LuaSourceContainer
-- slightly modified some stuffs -phsads

local CollectionService = game:GetService("CollectionService")
local LocalizationService = game:GetService("LocalizationService")
players = game:GetService('Players')
folder = script.Parent
cooldownRange = {3,5} --was {3,5} btw (change back later)

local isVip = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0

--constants
BASE_MINION_POPULATION = 15 --15 + extra
--0-10 players: each adds 3 more
--any more and no extras
MINION_LIFETIME = 180 --180

minionTemplate = game:GetService('ServerStorage')['_MINIONS']
minionList = {}
local yapList: {[Model]: number} = {} --{minion = yap}
local forcesTouched: {[Player]: number} = {}
local playerSFRGT: {[Player]: number} = {}

function getRandomChildren(TargetttedFolder: Folder): PVInstance
	local spawns = TargetttedFolder:GetChildren()
	return spawns[math.random(1,#spawns)]
end

local function gcd(a, b)
	return if b==0 then a else gcd(b,a%b)
end

local function getPhsadsScore(minion, player: Player)
	return -- code redacted for hidden purposes
end

local function DeclaredGuilty(minion)
	minionList[minion] = nil
	yapList[minion] = nil
	minion:Destroy()
end

function hookMinionToSentence(minion)
	local died = false -- dont complain
	minion.Humanoid.Died:Once(function()
		died = true

		if minion.Humanoid:FindFirstChild("creator") then
			local player = minion.Humanoid.creator.Value
			if player and player:FindFirstChild("leaderstats") then
				player.leaderstats["glaggle coins :)"].Value += getPhsadsScore(minion, player)
			end
		end

		task.wait(1)
		DeclaredGuilty(minion)
	end)

	wait(MINION_LIFETIME)

	if not died then
		DeclaredGuilty(minion)
	end
end

function runMinion(minion)
	if #minion.Description.Message.Value > 0 then
		yapList[minion] = 1
		coroutine.wrap(function()
			while minion.Parent ~= nil and minion.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead do
				game:GetService('Chat'):Chat(minion.Head, minion.Description.Message.Value)
				yapList[minion] = (yapList[minion]*2)%(1000000007) --yapper changed to match function

				task.wait(Random.new():NextInteger(5, 10))
			end
		end)()
	end

	if minion:FindFirstChild("AI") then
		minion.AI.Enabled = true
	end

	if minion:FindFirstChild("Weapon") then
		minion.Humanoid:EquipTool(minion.Weapon)
	end

	minionList[minion] = os.clock()
	hookMinionToSentence(minion)
end

task.spawn(function() --replaced recursion bc it breaks the limit at 5000th recursion -x
	while true do
		local enemyFolder = folder.Enemies
		local playerCount = #players:GetPlayers()
		local e = 2.718281828459045
		local toSpawn = math.log(playerCount + e)
		local spawned = 0
		local spawnCap = BASE_MINION_POPULATION + 3 * math.min(playerCount, 10)
        
		while #enemyFolder:GetChildren() < spawnCap do
			if (toSpawn <= 0) then break end
			if (toSpawn <= 1) then
				if (math.random(0, 1) > toSpawn) then break end --(1 - toSpawn) chance this activates
			end

			toSpawn -= 1
			spawned = 1

			local minion = getRandomChildren(minionTemplate):Clone()
			minion:PivotTo(getRandomChildren(folder.Spawns).CFrame)
			minion.Parent = folder.Enemies
			coroutine.wrap(runMinion)(minion)
		end
		if (spawned > 0) then wait(math.random(cooldownRange[1], cooldownRange[2])) end
		task.wait(1)
	end
end)

local debounce = false
game:GetService('RunService').Heartbeat:Connect(function()
	--if debounce then return end
	debounce = true

	local copyList = table.clone(minionList)

	-- to make sure the loop process is not interrupted by deleting the minion i guess
	for minion, weaponDebounce in pairs(copyList) do
		if minion.PrimaryPart == nil then return end --Incase if minion's hrp is now in the backrooms -x

		--print("entering a minion")
		local humanoid = minion.Humanoid :: Humanoid
		local description = minion.Description

		local nearestPlayer
		local lowPriorityNearestPlayer -- pacify
		local distance = math.huge
		local lowPriorityDistance -- pacify dist
		for _,player in pairs(players:GetPlayers()) do
			if player.Character and player.Character.PrimaryPart then
				local minionPos = minion.PrimaryPart.Position
				local playerPos = player.Character.PrimaryPart.Position

				local currentDistance = (minionPos - playerPos).Magnitude
				if currentDistance < distance and not CollectionService:HasTag(player.Character, "Solving") and not player.Character:FindFirstChild("begone") then
					distance = currentDistance
					
					if player.Character:FindFirstChild("pacifist") then
						lowPriorityNearestPlayer = player -- low priority 
						lowPriorityDistance = currentDistance
					else
						nearestPlayer = player -- default priority
					end
				end
			end
		end
		
		if lowPriorityNearestPlayer ~= nil then -- if pacifist is the closest (within a range)
			if lowPriorityDistance < 30 or nearestPlayer == nil then
				nearestPlayer = lowPriorityNearestPlayer
			end
		end

		if nearestPlayer == nil then
			humanoid:MoveTo(minion.PrimaryPart.Position, minion.PrimaryPart)
			continue
		end

		humanoid:MoveTo(nearestPlayer.Character.PrimaryPart.Position, nearestPlayer.Character.PrimaryPart)

		if distance <= description.AttackRange.Value then
			if os.clock() - weaponDebounce >= 1/8 and humanoid.Health > 0 then
				description.Attack:Fire(nearestPlayer)
				minionList[minion] = os.clock()
			end
		end

		if distance <= description.JumpRange.Value then
			humanoid.Jump = true
		end
	end

	debounce = false
end)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		forcesTouched[player] = 0
	end)
end)

--now for the forcefields
for _, forcefield: Part in pairs(script.Parent.Forcefield:GetChildren()) do
	if not forcefield:IsA("BasePart") then return end
	
	forcefield.Touched:Connect(function(hit: BasePart)
		if hit.Parent == nil or (not hit.Parent:FindFirstChild("Humanoid")) then return end
		
		--Guide minion away so they dont become immobile in forcefield
		if minionList[hit.Parent] ~= nil then
			hit.Parent.Humanoid:MoveTo(getRandomChildren(folder.Spawns).Position)
			return
		end

		local player = players:GetPlayerFromCharacter(hit.Parent)
		if player == nil or forcesTouched[player] == nil then return end --latter is to prevent if player hasnt loadde yet
				
		forcesTouched[player] += 1
		
		CollectionService:AddTag(hit.Parent, "Solving") 

		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = {hit}

		repeat
			task.wait(1)
		until not table.find(workspace:GetPartsInPart(forcefield, params), hit)

		forcesTouched[player] -= 1
		
		if forcesTouched[player] <= 0 then
			CollectionService:RemoveTag(hit.Parent, "Solving")
		end
	end)
end

game:GetService("ReplicatedStorage").MiscEvents.ActivateRealFunGoodTime.OnServerEvent:Connect(function(player: Player) --STOP SUGGESTING NEW THINGS AHHHHHHHHHHHHHH -x
	if playerSFRGT[player] == nil then
		playerSFRGT[player] = workspace.DistributedGameTime
	end
end)