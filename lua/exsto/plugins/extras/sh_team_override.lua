-- Exsto
-- Rank over-ride team plugin.

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Team to Rank Plugin",
	ID = "team_override",
	Desc = "A plugin that over-rides the Garry's Mod teams with Exsto ranks.",
	Owner = "Prefanatic",
	Experimental = false,
} )

if SERVER then
	
	//print( GAMEMODE.Name )
	//if GAMEMODE.Name != "Sandbox" then exsto.Print( exsto_CONSOLE, "Team to Rank Plugin --> Gamemode is not Sandbox!  Not running!" ) return end
	
	PLUGIN.Teams = {}
	
	function PLUGIN:ExSetRank( ply )
		local rank = ply:GetRank()
		local info = self.Teams[rank]
		
		if !info then ply:SetTeam( 1 ) return end
		
		for k,v in pairs( self.Teams ) do
			exsto.UMStart( "teamToRankSend", ply, v.Team, v.Name, v.Color )
		end
		ply:SetTeam( info.Team )
	end

	function PLUGIN:ExAccessReloaded()
		-- We are apparently called by the resend rank hook
		self:BuildTeams() -- They need to be updated again with new ranks.
		
		for k, ply in pairs( player.GetAll() ) do
			for k,v in pairs( self.Teams ) do
				exsto.UMStart( "teamToRankSend", ply, v.Team, v.Name, v.Color )
			end
			self:ExSetRank( ply )
		end
	end

	function PLUGIN:BuildTeams()
		local ranks = exsto.Ranks
		local index = 1
		
		for k,v in pairs( ranks ) do
			self.Teams[k] = {
				Name = v.Name,
				Short = v.Short,
				Color = v.Color,
				Team = index
			}
			
			team.SetUp( index, v.Name, v.Color )
			index = index + 1
		end

	end
	PLUGIN:BuildTeams()
	
elseif CLIENT then

	exsto.UMHook( "teamToRankSend", function( teamNum, name, color )
		team.SetUp( teamNum, name, color )
	end)

end

PLUGIN:Register()
