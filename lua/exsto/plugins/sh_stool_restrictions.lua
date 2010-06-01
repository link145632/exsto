-- Exsto
-- STOOL Restriction

require( "datastream" )

local PLUGIN = exsto.CreatePlugin()
	PLUGIN.Tools = {}
	PLUGIN.Denied = {} -- Key = Rank, Value = Stool

PLUGIN:SetInfo({
	Name = "STOOL Restricter",
	ID = "stool-restrictions",
	Desc = "A plugin that gives functionality to stool restrictions.",
	Owner = "Prefanatic",
} )
 

if SERVER then

	function PLUGIN:OnCanTool( ply, trace, tool )
	
		print( ply:Name(), tool )
		if self.Denied[ply:GetRank()] == tool then
			exsto.Print( exsto_CHAT, ply, COLOR.PAC, "The stool you are trying to use is ", COLOR.RED, "denied!" )
			return false
		end
		
	end

	-- Is this needed?
	function PLUGIN.BuildToolList()
	
		for k,v in pairs( file.FindInLua( "weapons/gmod_tool/stools/*.lua" ) ) do
			local tool = string.gsub( v, ".lua", "" )
			if !table.HasValue( PLUGIN.Tools, tool ) then
				table.insert( PLUGIN.Tools, tool )
			end
		end
		
		--print( "Built Tools --" )
		--PrintTable( PLUGIN.Tools )
		
	end
	
	function PLUGIN.DenyRank( ply, rank, stool )
	
		if !exsto.RankExists( rank ) then
		
			return {"[/c]Rank [c=200,50,50,200]" .. rank .. "[/c] does not exist!"}
			
		end
	
		PLUGIN.Denied[rank] = stool
		
		return {COLOR.PAC, "Denied ", COLOR.BLUE, rank, COLOR.PAC, " of ", COLOR.RED, stool}
		
	end
	PLUGIN:AddCommand( "denyrank", {
		Call = PLUGIN.DenyRank,
		Desc = "Denies ranks of stools",
		FlagDesc = "Allows users to deny ranks of stools.",
		Console = { "denyrank" },
		Chat = { "!denyrank" },
		Args = {Rank = "STRING", Stool = "STRING"},
	})
	
	-- Send the info to clients
	-- Question:  Make built in hooks?
	--[[
		PLUGIN.PlayerLoaded()
		PLUGIN.PlayerSpawned()
		PLUGIN.PlayerDeath()
		PLUGIN.Player------
		]]
		
	function PLUGIN.PlayerLoaded( ply )
		
		--print( "Sending TOOL List" )
		--PrintTable( PLUGIN.Tools )
		datastream.StreamToClients( ply, "STOOL_TableHook", PLUGIN.Tools )
		
	end
	PLUGIN:AddHook( "exsto_InitSpawn", PLUGIN.PlayerLoaded )
	concommand.Add( "_SendTools", PLUGIN.PlayerLoaded )
	
	PLUGIN.BuildToolList()
	
	PLUGIN:CreateTable( "exsto_stoolrestriction", {
		Rank = "varchar(255)",
		Deny = "varchar(255)",
		}
	)

elseif CLIENT then

	datastream.Hook( "STOOL_TableHook", function( handler, id, encoded, decoded )
		--print( "Receieved Tool List" )
		--PrintTable( decoded )
		PLUGIN.Tools = decoded
	end )

	--[[
	Menu.CreatePage( "STOOL Restriction", false, "exsto_stoolrestriction", function( panel )
	
		local toolList = CreateListView( 5, 5, panel:GetWide() - 10, panel:GetTall() - 10, panel )
			toolList:AddColumn("STOOL")
		for k,v in pairs( PLUGIN.Tools ) do
		
			toolList:AddLine( v )
			
		end
	end)	]]

end

PLUGIN:Register()
