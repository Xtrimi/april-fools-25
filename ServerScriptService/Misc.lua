local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SolveData = require(script.Parent.SolveData)

local MAIN_COMPLETION_BADGE = 1496017036615958

ReplicatedStorage.Jentafy.OnServerEvent:Connect(function(player: Player) --note: if this somehow breaks just detect mainrooms in leaderstats Lol -x
	if SolveData.solvedAllMain(player) then
		if not workspace._MISC:FindFirstChild("Winpad") then
			warn("cant find winpad Wth")
			return
		end

		player.Character:PivotTo(workspace._MISC.Winpad:GetPivot() * CFrame.new(0, 3, 0))
	end
end)

if not workspace._MISC:FindFirstChild("BadgeGiver") then
	warn("how did you even delet eht badgegiver what")
else
	local db = false
	workspace._MISC.BadgeGiver.Touched:Connect(function(hit)
		if hit.Parent == nil or not hit.Parent:FindFirstChild("Humanoid") then return end
		if db then return end

		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or SolveData.playerData[player] == nil then return end

		db = true
		if SolveData.solvedAllMain(player) then
			game:GetService("BadgeService"):AwardBadge(player.UserId, MAIN_COMPLETION_BADGE)
		end

		task.delay(.5, function()
			db = false
		end)
	end)
end