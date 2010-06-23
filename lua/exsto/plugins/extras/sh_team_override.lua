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
	
	function PLUGIN:PlayerSpawn( ply )
		local rank = ply:GetRank()
		local info = self.Teams[rank]
		
		if !info then ply:SetTeam( 1 ) return end
		
		ply:SetTeam( info.Team )
	end

	function PLUGIN.SendTeamInfo( ply )
		if type( ply ) != "Player" then
			-- We are apparently called by the resend rank hook
			PLUGIN:BuildTeams() -- They need to be updated again with new ranks.
			
			for k, ply in pairs( player.GetAll() ) do
				PLUGIN:PlayerSpawn( ply )
				for k,v in pairs( PLUGIN.Teams ) do
					exsto.UMStart( "teamToRankSend", ply, v.Team, v.Name, v.Color )
				end
			end
		else
			PLUGIN:PlayerSpawn( ply )
			for k,v in pairs( PLUGIN.Teams ) do
				exsto.UMStart( "teamToRankSend", ply, v.Team, v.Name, v.Color )
			end
		end
	end
	hook.Add( "exsto_InitSpawn", "teamToRankPluginSend", PLUGIN.SendTeamInfo )
	hook.Add( "exsto_ResendRanks", "teamToRankPluginRefresh", PLUGIN.SendTeamInfo )

	function PLUGIN:BuildTeams()
		local ranks = exsto.Levels
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
