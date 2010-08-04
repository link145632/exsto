-- Prefan Access Controller
-- GIMP Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Gimp",
	ID = "gimp",
	Desc = "A plugin that allows player gimping!",
	Owner = "Prefanatic",
} )

PLUGIN.Sayings = {
	"You smell like me.",
	"Fucking is so fucking awesome.",
	"I sense that you all love me, very, very much.",
	"Seeing is believing.",
	"You look :)",
	"How do I speak llama?",
	"Semper ubi sub ubi!",
	"I realize the truth in your opinion, and swiftly deny it.",
	"I know everything.",
	"Ban me, please.",
	"I hope I'm not gimped.",
	"This server sucks lolol.",
	"Garry is my hero!",
}

function PLUGIN:Init()
	if !file.Exists( "exsto_gimps.txt" ) then
		file.Write( "exsto_gimps.txt", string.Implode( "\n", self.Sayings ) )
	else
		self.Sayings = string.Explode( "\n", file.Read( "exsto_gimps.txt" ) )
	end
end

function PLUGIN:AddGimp( owner, message )
	filex.Append( "exsto_gimps.txt", message .. "\n" )
	
	return { owner, COLOR.NORM, "Adding message to ", COLOR.NAME, "gimp data!" }
end
PLUGIN:AddCommand( "addgimp", {
	Call = PLUGIN.AddGimp,
	Desc = "Allows users to add gimp messages.",
	Console = { "addgimp" },
	Chat = { "!addgimp" },
	ReturnOrder = "Message",
	Args = {Message = "STRING"},
	Category = "Chat",
})

function PLUGIN:Gimp( owner, ply )

	local style = " has gimped "
	
	if self:IsGimped( ply ) then
		ply.Gimped = false
		style = " has un-gimped "
	else
		ply.Gimped = true
	end
	
	return {
		Activator = owner,
		Player = ply,
		Wording = style,
	}

end
PLUGIN:AddCommand( "gimp", {
	Call = PLUGIN.Gimp,
	Desc = "Allows users to gimp other players.",
	Console = { "gimp", "ungimp" },
	Chat = { "!gimp", "!ungimp" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
	Category = "Chat",
})
PLUGIN:RequestQuickmenuSlot( "gimp" )

function PLUGIN:Mute( owner, ply )

	local style = " has muted "
	
	if ply.Muted then
		ply.Muted = false	
		style = " has un-muted "
	else
		ply.Muted = true
	end
		
	return {
		Activator = owner,
		Player = ply,
		Wording = style,
	}
	
end
PLUGIN:AddCommand( "mute", {
	Call = PLUGIN.Mute,
	Desc = "Allows users to mute other players.",
	Console = { "mute" },
	Chat = { "!mute" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
	Category = "Chat",
})
PLUGIN:RequestQuickmenuSlot( "mute" )

function PLUGIN:Gag( owner, ply )

	local style = " has un-gagged "
	if self:IsGagged( ply ) then
		self:SetGag( ply, false )
	else
		style = " has gagged "
		self:SetGag( ply, true )
	end
		
	return {
		Activator = owner,
		Player = ply,
		Wording = style,
	}
	
end
PLUGIN:AddCommand( "gag", {
	Call = PLUGIN.Gag,
	Desc = "Allows users to gag other players.",
	Console = { "gag" },
	Chat = { "!gag" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
	Category = "Chat",
})
PLUGIN:RequestQuickmenuSlot( "gag" )

function PLUGIN:SetGag( ply, bool )
	ply.Gagged = bool
end

function PLUGIN:IsGagged( ply )
	if ply.Gagged then return true end
end

function PLUGIN:IsGimped( ply )
	if ply.Gimped then return true end
end

function PLUGIN:IsMuted( ply )
	if ply.Muted then return true end
end

function PLUGIN:PlayerCanHearPlayersVoice( listen, talker )
	return self:IsGagged( talker ) end
end

function PLUGIN:PlayerSay( ply, text )
	if self:IsGimped( ply ) then
		return self.Sayings[ math.random( 1, #PLUGIN.Sayings ) ]
	end
	if self:IsMuted( ply ) then return "" end
end

PLUGIN:Register()
