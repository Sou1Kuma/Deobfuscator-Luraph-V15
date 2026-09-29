local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Modules = ReplicatedStorage:WaitForChild("Modules", 5)
local Net = Modules:WaitForChild("Net", 5)
local REEasterServiceRE = Net:FindFirstChild("RE/EasterServiceRE")
getgenv().AutoVirtualEgg = false
getgenv().OnionVirtualEggUI = ScreenGui
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
local UICorner2 = Instance.new("UICorner")
UICorner2.CornerRadius = UDim.new(0, 6)
local TextButton = Instance.new("TextButton")
TextButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
TextButton.Font = Enum.Font.GothamBold
TextButton.Name = "ToggleBtn"
TextButton.Position = UDim2.new(0.1, 0, 0.4, 0)
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.Text = "Start Spam"
TextButton.TextSize = 14
TextButton.Size = UDim2.new(0.8, 0, 0, 40)
UICorner2.Parent = TextButton
UICorner.Parent = Frame
TextButton.Parent = Frame
	getgenv().AutoVirtualEgg = true
	task.spawn(function(...)
		REEasterServiceRE:FireServer("CollectVirtualEgg", { VirtualEggName = "Eggspensive Egg" })
		task.wait(0.15)
		REEasterServiceRE:FireServer("CollectVirtualEgg", { VirtualEggName = "Eggspensive Egg" })
		task.wait(0.15)
	end)
end)
