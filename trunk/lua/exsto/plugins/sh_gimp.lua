-- Prefan Access Controller
-- GIMP Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Gimp",
	ID = "gimp",
	Desc = "A plugin that allows player gimping!",
	Owner = "Prefanatic",
} )

if CLIENT then
	function PLUGIN.GagPlayer( ply, ungag )
		if ply:IsMuted( ply ) and ungag then
			LocalPlayer():SetMuted( ply )
		elseif !ply:IsMuted( ply ) then
			LocalPlayer():SetMuted( ply )
		end
	end
	exsto.UMHook( "exsto_GagPlayer", PLUGIN.GagPlayer )
end

if CLIENT then return end

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
	"I hope I'm not gimpped.",
	"This server sucks lolol.",
	"Garry is my hero!",
}

function PLUGIN:Gimp( owner, ply )

	local style = " has gimmped "
	
	if self:IsGimmped( ply ) then
		ply.Gimmped = false
		style = " has un-gimmped "
	else
		ply.Gimmped = true
	end
	
	return {
		Activator = owner,
		Player = ply,
		Wording = style,
	}

end
PLUGIN:AddCommand( "gimp", {
	Call = PLUGIN.Gimp,
	Desc = "Gimps a player.",
	FlagDesc = "Allows users to gimp other players.",
	Console = { "gimp" },
	Chat = { "!gimp" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
})

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
	Desc = "Mutes a player.",
	FlagDesc = "Allows users to mute other players.",
	Console = { "mute" },
	Chat = { "!mute" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
})

local mutedList = {}

function PLUGIN:Onexsto_InitSpawn( ply )
	for k,v in pairs( mutedList ) do
		exsto.UMStart( "exsto_GagPlayer", ply, v )
	end
end

function PLUGIN:Gag( owner, ply )

	local style = " has gagged "
	local ungag = false
	
	if table.HasValue( mutedList, ply ) then
		table.remove( mutedList, exsto.GetTableID( mutedList, ply ) )
		ungag = true
		style = " has un-gagged "
	else
		table.insert( mutedList, ply )
	end
	
	for k,v in pairs( player.GetAll() ) do
		exsto.UMStart( "exsto_GagPlayer", v, ply, ungag )
	end
		
	return {
		Activator = owner,
		Player = ply,
		Wording = style,
	}
	
end
PLUGIN:AddCommand( "gag", {
	Call = PLUGIN.Gag,
	Desc = "Mutes a player's mic.",
	FlagDesc = "Allows users to gag other players.",
	Console = { "gag" },
	Chat = { "!gag" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
})

function PLUGIN:IsGimmped( ply )
	if ply.Gimmped then
		return true
	else return false end
end

function PLUGIN:IsMuted( ply )
	if ply.Muted then return true end
	return false
end

function PLUGIN:OnPlayerSay( ply, text )

	if self:IsGimmped( ply ) then

		return self.Sayings[ math.random( 1, #PLUGIN.Sayings ) ]
		
	end
	
	if self:IsMuted( ply ) then return "" end
	
end

PLUGIN:Register()
