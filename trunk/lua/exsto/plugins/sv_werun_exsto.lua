-- Exsto
-- Lets notify players that they are protected by Exsto!

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Notifyer",
	ID = "notify",
	Desc = "A plugin that notifies players of Exsto!",
	Owner = "Prefanatic",
} )

local function OnVarChange( val )
	timer.Create( "exsto_TELL", tonumber( exsto.GetVar( "notify_delay" ).Value ) * 60, 0, exsto.TellExsto )
	return true
end
PLUGIN:AddVariable({
	Pretty = "Exsto Credit Delay",
	Dirty = "notify_delay",
	Default = 5,
	Description = "How long in minutes till players are notified of Exsto.",
	OnChange = OnVarChange
})

function exsto.TellExsto()

	exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "This server is proudly protected by ", COLOR.EXSTO, "Exsto" )
	
end

PLUGIN:Register()

local length = tonumber( exsto.GetVar( "notify_delay" ).Value ) * 60

timer.Create( "exsto_TELL", length, 0, exsto.TellExsto )