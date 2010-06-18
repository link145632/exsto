-- Exsto
-- Restart Server Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Restart",
	ID = "restart-changelvl",
	Desc = "A plugin that allows restarting of the server, or change map!",
	Owner = "Prefanatic",
} )

if SERVER then

	PLUGIN.MapList = {}
	PLUGIN.MapCateg = {}
	PLUGIN.Gamemodes = {}
	
	// Stolen from lua-users.org
	local function StringDist( s, t )
		local d, sn, tn = {}, #s, #t
		local byte, min = string.byte, math.min
			for i = 0, sn do d[i * tn] = i end
			for j = 0, tn do d[j] = j end
			for i = 1, sn do
				local si = byte(s, i)
				for j = 1, tn do
					d[i*tn+j] = min(d[(i-1)*tn+j]+1, d[i*tn+j-1]+1, d[(i-1)*tn+j-1]+(si == byte(t,j) and 0 or 1))
				end
			end
		return d[#d]
	end

	function PLUGIN:ChangeLevel( owner, map, delay )
		
		if string.Right( map, 4 ) != ".bsp" then map = map .. ".bsp" end
	
		local mapData = self.MapList[map]
		local data = { Max = 100, Map = "" }
		local dist
		
		if !mapData then
			for k,v in pairs( self.MapList ) do
				k = k:gsub( "%.bsp", "" )
				dist = StringDist( map, k )
				if dist < data.Max then data.Max = dist data.Map = k end
			end
			
			return { owner, COLOR.NORM, "Unknown map ", COLOR.NAME, map:gsub( "%.bsp", "" ), COLOR.NORM, ".  Maybe you want ", COLOR.NAME, data.Map, COLOR.NORM, "?" }
		end
		
		if delay != 0 then
			timer.Simple( delay, game.ConsoleCommand, "changelevel " .. map:gsub( "%.bsp", "" ) .."\n" )
			
			return {
				COLOR.NORM, "Changing level to ",
				COLOR.NAME, map:gsub( "%.bsp", "" ),
				COLOR.NORM, " in ",
				COLOR.NAME, tostring( delay ),
				COLOR.NORM, " seconds!"
			}
		end

		game.ConsoleCommand( "changelevel " .. map:gsub( "%.bsp", "" ) .."\n" )
		
	end
	PLUGIN:AddCommand( "changelvl", {
		Call = PLUGIN.ChangeLevel,
		Desc = "Changes the level",
		FlagDesc = "Allows users to change the level.",
		Console = { "changelevel" },
		Chat = { "!changelevel" },
		ReturnOrder = "Map-Delay",
		Args = {Map = "STRING", Delay = "NUMBER"},
		Optional = { Map = "gm_flatgrass", Delay = 0 },
	})

	function PLUGIN:ReloadMap( owner )

		game.ConsoleCommand( "changelevel " .. string.gsub( game.GetMap(), ".bsp", "" ) .. "\n" )
		
	end
	PLUGIN:AddCommand( "reloadmap", {
		Call = PLUGIN.ReloadMap,
		Desc = "Reloads the current map",
		FlagDesc = "Allows users to reload the current level.",
		Console = { "reloadmap" },
		Chat = { "!reloadmap" },
		Args = {},
	})
	
	function SendMaps( ply )
		local curGamemode = string.Explode( "/", GAMEMODE.Folder )
		local Send = {PLUGIN.MapList, PLUGIN.Gamemodes, curGamemode[#curGamemode]}
		exsto.UMStart( "ExSendMaps", ply, Send )
	end
	concommand.Add( "_GetMapsList", SendMaps )
	
	function PLUGIN:Init()
	
		-- Build the map list. (Code copy and pasted from GMOD)
		local MapPatterns = {}
		 
		MapPatterns[ "^de_" ] = "Counter-Strike"
		MapPatterns[ "^cs_" ] = "Counter-Strike"
		MapPatterns[ "^es_" ] = "Counter-Strike"
		 
		MapPatterns[ "^cp_" ] = "Team Fortress 2"
		MapPatterns[ "^ctf_" ] = "Team Fortress 2"
		MapPatterns[ "^tc_" ] = "Team Fortress 2"
		MapPatterns[ "^pl_" ] = "Team Fortress 2"
		MapPatterns[ "^arena_" ] = "Team Fortress 2"
		MapPatterns[ "^koth_" ] = "Team Fortress 2"
		 
		MapPatterns[ "^dod_" ] = "Day Of Defeat"
		 
		MapPatterns[ "^d1_" ] = "Half-Life 2"
		MapPatterns[ "^d2_" ] = "Half-Life 2"
		MapPatterns[ "^d3_" ] = "Half-Life 2"
		MapPatterns[ "credits" ] = "Half-Life 2"
		 
		MapPatterns[ "^ep1_" ] = "Half-Life 2: Episode 1"
		MapPatterns[ "^ep2_" ] = "Half-Life 2: Episode 2"
		MapPatterns[ "^ep3_" ] = "Half-Life 2: Episode 3"
		 
		MapPatterns[ "^escape_" ] = "Portal"
		MapPatterns[ "^testchmb_" ] = "Portal"
		 
		MapPatterns[ "^gm_" ] = "Garry's Mod"
		 
		MapPatterns[ "^c0a" ] = "Half-Life: Source"
		MapPatterns[ "^c1a" ] = "Half-Life: Source"
		MapPatterns[ "^c2a" ] = "Half-Life: Source"
		MapPatterns[ "^c3a" ] = "Half-Life: Source"
		MapPatterns[ "^c4a" ] = "Half-Life: Source"
		MapPatterns[ "^c5a" ] = "Half-Life: Source"
		MapPatterns[ "^t0a" ] = "Half-Life: Source"
		 
		MapPatterns[ "boot_camp" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "bounce" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "crossfire" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "datacore" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "frenzy" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "rapidcore" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "stalkyard" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "snarkpit" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "subtransit" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "undertow" ] = "Half-Life: Source Deathmatch"
		MapPatterns[ "lambda_bunker" ] = "Half-Life: Source Deathmatch"
		 
		MapPatterns[ "dm_" ] = "Half-Life 2 Deathmatch"
		 
		//
		// Load patterns from the gamemodes
		//
		PLUGIN.Gamemodes = GetGamemodes()
		 
		for k, gm in pairs( GetGamemodes() ) do
		 
			   local info = file.Read( "../gamemodes/"..gm.Name.."/info.txt" )
			   local info = KeyValuesToTable( info )
			   local Name = info.name or "Unnammed Gamemode"
			   local Patterns = info.mappattern or {}
			  
			   for k, pattern in pairs( Patterns ) do
					 MapPatterns[ pattern ] = Name
			   end
			  
		end
		 
		local IgnoreMaps = { "background", "^test_", "^styleguide", "^devtest" }
		 
		local g_MapList = PLUGIN.MapList
		local g_MapListCategorised = PLUGIN.MapCateg
		 
		for k, v in pairs( file.Find( "../maps/*.bsp" ) ) do
		 
			   local Ignore = false
			   for _, ignore in pairs( IgnoreMaps ) do
					 if ( string.find( v, ignore ) ) then
						    Ignore = true
					 end
			   end
			  
			   // Don't add useless maps
			   if ( !Ignore ) then
			  
					 local Mat = nil
					 local Category = "Other"
					 local name = string.gsub( v, ".bsp", "" )
					 local lowername = string.lower( v )
			  
					 Mat = "maps/"..name..".vmt"
					
					 for pattern, category in pairs( MapPatterns ) do
						    if ( string.find( lowername, pattern ) ) then
								  Category = category
						    end
					 end
		 
					 g_MapList[ v ] = { Material = Mat, Name = name, Category = Category }

			   end
		 
		end
		 
		for k, v in pairs( g_MapList ) do
		 
			   g_MapListCategorised[ v.Category ] = g_MapListCategorised[ v.Category ] or {}
			   g_MapListCategorised[ v.Category ][ v.Name ] = v
		 
		end
		
		PLUGIN.MapList = g_MapList
		
	end
	
	function PLUGIN.ChangeMap( ply, _, args )
		local key = tonumber( args[1] )
		
		if key != ply.MenuAuthKey then return end
		
		local map = args[2]
		local gamemode = args[3]
		
		if !map then return end
		
		exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Changing map to ", COLOR.NAME, map, COLOR.NORM, ", gamemode ", COLOR.NAME, gamemode, COLOR.NORM, " in 10 seconds!" )
		
		timer.Simple( 10, game.ConsoleCommand, "changegamemode " .. map .. " " .. gamemode .. "\n" )
	end
	concommand.Add( "_ChangeMap", PLUGIN.ChangeMap )
	
elseif CLIENT then

	local MapsList = {}
	local GamemodeList = {}
	local currentGamemode = ""
	local selectedMap = ""
	local mapList

	function PLUGIN.RecieveMaps( list )

		MapsList = list[1]
		GamemodeList = list[2]
		currentGamemode = list[3]
		
	end
	exsto.UMHook( "ExSendMaps", PLUGIN.RecieveMaps ) 

	function PLUGIN.Reload( panel )
	
		MapsList = {}
		RunConsoleCommand( "_GetMapsList" )
		Menu.PushLoad()
		
		local function Ping()
		
			if table.Count( MapsList ) >= 1 then
				PLUGIN.Build( panel )
				Menu.EndLoad()
			else
				timer.Simple( 0.1, Ping )
			end
			
		end
		timer.Simple( 0.1, Ping )
		
	end
	
	function PLUGIN.RebuildList( category )
		mapList:Clear()
		
		for k,v in pairs( MapsList ) do
			if v.Category == category or category == "All" then
				
				local material = Material( v.Material )
				
				if material:GetName() == "___error" then	
					material = "maps/noicon"
				else
					material = v.Material
				end
				
				-- Create the map icon.
				local icon = vgui.Create( "DImageButton" )
				icon:SetMaterial( material )
				icon:SetSize( 110, 110 )
				icon:SetToolTip( v.Category .. " - " .. v.Name )
				
				icon.Map = k:gsub( "%.bsp", "" )
				
				icon.DoClick = function( self )
					selectedMap = self.Map:gsub( "%.bsp", "" )
				end
				
				mapList:AddItem( icon )
			end
		end
		
	end
	
	function PLUGIN.GetCategories()
	
		local cat = {}
		for k,v in pairs( MapsList ) do
			if !table.HasValue( cat, v.Category ) then
				table.insert( cat, v.Category )
			end
		end
		table.insert( cat, "All" )
		return cat
		
	end
	
	function PLUGIN.Build( panel )
	
		local gamemodeContainer = exsto.CreateLabeledPanel( 10, 4, panel:GetWide() - 20, 40, "Gamemode", Color( 232, 232, 232, 255 ), panel )
			gamemodeContainer.Label:SetFont( "labeledPanelFont" )
			
		local gamemodeEntry = exsto.CreateMultiChoice( 10, 10, gamemodeContainer:GetWide() - 20, 20, gamemodeContainer )
			gamemodeEntry:SetText( currentGamemode )
			
			for k,v in pairs( GamemodeList ) do
				gamemodeEntry:AddChoice( v.Name )
			end
			
			gamemodeEntry.OnSelect = function( index, value, data )
				currentGamemode = data
			end
		
		local mapListContainer = exsto.CreateLabeledPanel( 10, 60, panel:GetWide() - 20, panel:GetTall() - 130, "Click on the map you want to change to.", Color( 232, 232, 232, 255 ), panel )
			mapListContainer.Label:SetFont( "labeledPanelFont" )
			
		mapList = exsto.CreatePanelList( 5, 8, mapListContainer:GetWide() - 10, mapListContainer:GetTall() - 16, 5, true, true, mapListContainer )
			mapList.Color = Color( 0, 0, 0, 0 )
		PLUGIN.RebuildList( "Garry's Mod" )
		
		local startInfo = exsto.CreateLabeledPanel( 10, panel:GetTall() - 50, panel:GetWide() - 20, 40, "Other", Color( 232, 232, 232, 255 ), panel )
			startInfo.Label:SetFont( "labeledPanelFont" )
		
		local startCategory = exsto.CreateMultiChoice( 10, 10, 120, 20, startInfo )
			startCategory:SetText( "Garry's Mod" )
			
			for k,v in pairs( PLUGIN.GetCategories() ) do
				startCategory:AddChoice( v )
			end
			
			startCategory.OnSelect = function( index, value, data )
				PLUGIN.RebuildList( data )
			end
			
		//local startInfoLabel = exsto.CreateLabel( 50, 10, "Playing *MAP* on *GAMEMODE*", "labeledPanelFont", startInfo )
		local startButton = exsto.CreateButton( startInfo:GetWide() - 120, 5, 74, 27, "Change Map", startInfo )
			startButton.DoClick = function( self )
				if selectedMap == "" then Menu.PushError( "No map selected!" ) return end
				local map = selectedMap
				local gamemode = currentGamemode
				
				Menu.CallServer( "_ChangeMap", map, gamemode )
				self:SetVisible( false )
			end
	end
	
	Menu.CreatePage( {
		Title = "Maps List",
		Short = "mapslist",
		Flag = "mapslist",
		}, 
		function( panel )
		
			PLUGIN.Reload( panel )
			
		end
	)
	
end

PLUGIN:Register()
