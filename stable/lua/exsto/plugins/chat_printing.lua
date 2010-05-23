-- Prefan Access Controller
-- ULX Style Printing

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Chat Printing Extras",
	ID = "chat-printing",
	Desc = "A plugin that contains a bunch of ULX style printing.",
	Owner = "Prefanatic",
} )

if CLIENT then return end

function PLUGIN.ChatNotify( ply, text )
	for k,v in pairs( player.GetAll() ) do
		exsto.Print( exsto_CHAT_NOLOGO, v, text )
	end
end
PLUGIN:AddCommand( "chatnotify", {
	Call = PLUGIN.ChatNotify,
	Desc = "Talks to all users.",
	FlagDesc = "Allows users to talk to do a chat notify on all players.",
	Console = { "chatnotify" },
	Chat = { "@@" },
	ReturnOrder = "Text",
	Args = { Text = "STRING" },
	Optional = { }
})

function PLUGIN.AdminSay( ply, text )
	for k,v in pairs( player.GetAll() ) do
		if v:IsAdmin() or v:IsSuperAdmin() then
			print( v:Nick() )
			exsto.Print( exsto_CHAT_NOLOGO, v, COLOR.NAME, "(ADMIN) ", ply, COLOR.NORM, ": " .. text )
		end
	end
end
PLUGIN:AddCommand( "adminsay", {
	Call = PLUGIN.AdminSay,
	Desc = "Talks to admins only.",
	FlagDesc = "Allows users to talk to admins privatly.",
	Console = { "adminsay" },
	Chat = { "@", "!admin" },
	ReturnOrder = "Text",
	Args = { Text = "STRING" },
	Optional = { }
})

PLUGIN:Register()