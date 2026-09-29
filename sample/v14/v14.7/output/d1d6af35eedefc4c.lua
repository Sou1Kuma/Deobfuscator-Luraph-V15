local StarterGui = game:GetService("StarterGui")
StarterGui:SetCore("SendNotification", { Text = "Connecting to Server... Verifying Signature.", Title = "onion13", Duration = 5 })
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local clientId = RbxAnalyticsService:GetClientId()
local serverTimeNow = workspace:GetServerTimeNow()
local response = request({
	Headers = {
		["Cache-Control"] = "no-cache",
		["Onion-HWID"] = clientId,
		["Onion-Secret"] = "onion563789",
		["Onion-Signature"] = "SIG_" .. string.format("%x", math.floor(((177573 + string.byte(tostring(clientId) .. "-" .. tostring(math.floor((serverTimeNow / 60))) .. "-onion563789", 1)) % 4294967296)))
	},
	Method = "GET",
	Url = "https://api.onion13.xyz/"
})
StarterGui:SetCore("SendNotification", { Text = response.Body, Title = "Error", Duration = 5 })
