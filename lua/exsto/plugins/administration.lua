-- Exsto
-- Administration Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Administration",
	ID = "administration",
	Desc = "A plugin that monitors kicking and banning of players.",
	Owner = "Prefanatic",
	Experimental = false,
} )

require( "datastream" )
require( "glon" )

if SERVER then

	local gate = require( "gatekeeper" )

	function PLUGIN.Kick( owner, ply, reason )
		
		--if reason == "nil" then reason = "Kicked by " .. owner:Nick() end
		local nick = ply:Nick()
		
		exsto.Print( exsto_LOG_ALL, Color( 255, 0, 0 ), ply:Nick(), Color( 100, 100, 100 ), " was kicked! [ " .. reason .. " ] " )
		
		if gate then
			gatekeeper.Drop( ply:UserID(), "KICK: " .. reason )
		else
			ply:Kick( reason )
		end
		
		return {
			Activator = owner,
			Player = nick,
			Wording = " has kicked ",
			Secondary = " with reason: " .. reason
		}
		
	end
	PLUGIN:AddCommand( "kick", {
		Call = PLUGIN.Kick,
		Desc = "Kicks a player",
		FlagDesc = "Allows users to kick players.",
		Console = { "kick" },
		Chat = { "!kick" },
		ReturnOrder = "Victim-Reason",
		Args = {Victim = "PLAYER", Reason = "STRING"},
		Optional = {Reason = "Kicked by [self]"}
	})

	function PLUGIN:OnPlayerPasswordAuth( user, pass, steam, ipd )

		exsto.Print( exsto_LOG_ALL, Color( 255, 0, 0 ), user, Color( 100, 100, 100 ), " has connected from ", Color( 0, 0, 255 ), ipd )

		--exsto.Print( exsto_CONSOLE, user .. " is trying to connect with " .. pass )
		
		local data = FEL.Query( "SELECT BannedAt, Length FROM exsto_data_bans WHERE SteamID = " .. FEL.Escape( steam ) .. ";" )
		print( "Loading ban data ..." )

		if not data or not data[1] then return true end
		data = data[1]
		
		PrintTable( data )
		
		print( "ban data found!" )
		
		local len = tonumber( data.Length )
		local at = tonumber( data.BannedAt )
		
		print( len )
		
		if len == 0 then print( "HES PERMAD" ) return {false, "You are perma-banned!"} end
		
		print( "Hes not permad, so continue." )
		
		local timeleft = string.ToMinutesSeconds( ( len + at ) - os.time() )
		
		print( " He has " .. timeleft )
		
		if os.time() > len + at then FEL.RemoveData( "exsto_data_bans", "SteamID", steam ) PLUGIN.ResendToAll() return true end
		
		if bandata then return {false, "You are banned from this server!  Time left -- " .. timeleft} end
		
		print( "Not banned, continue" )
			
		return true
		
	end

	function PLUGIN.Ban( owner, ply, len, reason )

		local nick = ply:Nick()
		exsto.Print( exsto_LOG_ALL, Color( 255, 0, 0 ), ply:Nick(), Color( 100, 100, 100 ), " was banned! [ " .. reason .. " ] " )

		FEL.SaveBanInfo( ply, len, reason, owner, os.time(), gate )
		
		if gate then
			gatekeeper.Drop( ply:UserID(), "BAN: " .. reason )
		else
			ply:Ban( len, reason )
			//game.ConsoleCommand( "banid " .. len .. " " .. ply:UserID() .. "\n" )
			ply:Kick( reason )
		end
		
		PLUGIN.ResendToAll()
		
		return {
			Activator = owner,
			Player = nick,
			Wording = " has banned ",
			Secondary = " with reason: " .. reason
		}
		
	end
	PLUGIN:AddCommand( "ban", {
		Call = PLUGIN.Ban,
		Desc = "Bans a player",
		FlagDesc = "Allows users to ban players.",
		Console = { "ban" },
		Chat = { "!ban" },
		ReturnOrder = "Victim-Length-Reason",
		Args = {Victim = "PLAYER", Length = "NUMBER", Reason = "STRING"},
		Optional = {Length = 0, Reason = "Banned by [self]"}
	})

	function PLUGIN.UnBan( owner, steamid )
		steamid = string.upper( steamid ):gsub( " ", "" )

		if !gate then game.ConsoleCommand( "removeid " .. steamid .. ";writeid\n" ) end
		FEL.RemoveData( "exsto_data_bans", "SteamID", steamid )
		
		PLUGIN.ResendToAll()

		return {
			Activator = owner,
			Player = steamid,
			Wording = " has unbanned ",
		}
		
	end
	PLUGIN:AddCommand( "unban", {
		Call = PLUGIN.UnBan,
		Desc = "Unbans a player",
		FlagDesc = "Allows users to unban players.",
		Console = { "unban" },
		ReturnOrder = "SteamID",
		Chat = { "!unban" },
		Args = {SteamID = "STRING"},
	})
	
	function PLUGIN.ResendToAll()
	
		local bans = FEL.LoadTable( "exsto_data_bans" )
		
		-- Make a nice formatted table.
		local send = {}
		if bans then
			for k,v in pairs( bans ) do
				send[v.SteamID] = v
			end
		end

		datastream.StreamToClients( player.GetAll(), "exsto_RecieveBans", send )
		
	end

	function PLUGIN.RequestBans( ply )
		
		exsto.Print( exsto_CONSOLE, ply:Nick() .. " requested data send of the bans table." )
		local bans = FEL.LoadTable( "exsto_data_bans" )
		
		-- Make a nice formatted table.
		local send = {}
		if bans then
			for k,v in pairs( bans ) do
				send[v.SteamID] = v
			end
		end

		datastream.StreamToClients( ply, "exsto_RecieveBans", send )
	
	end
	concommand.Add( "_ResendBans", PLUGIN.RequestBans )
	
elseif CLIENT then

	local bans = {}
	local Recieved = false
	local banlist

	local function IncommingHook( handler, id, encoded, decoded )
	
		bans = decoded or {}
		Recieved = true
		
		if banlist then banlist.UpdatePlayers() end
		
	end
	datastream.Hook( "exsto_RecieveBans", IncommingHook )

	Menu.CreatePage( {
		Title = "Ban List",
		Short = "banlist",
		Flag = "banlist",
	},
		function( panel )
			
			Menu.PushLoad()
			RunConsoleCommand( "_ResendBans" )
			PLUGIN.Main( panel )	
		end
	)
	
	function PLUGIN.Main( panel )
	
		if !Recieved then
			timer.Simple( 1, PLUGIN.Main, panel )
			return
		end

		PLUGIN.Build( panel )
		Menu.EndLoad()
		
	end
	
	function PLUGIN.ReloadList( panel )
		Menu.PushLoad()
		Recieved = false
		RunConsoleCommand( "_ResendBans" )
		
		local function wait()
			if !Recieved then
				timer.Simple( 1, wait )
				return
			end
			
			banlist.UpdatePlayers()
		end
	end
	
	function PLUGIN.Build( panel )
		banlist = exsto.CreateListView( 10, 10, panel:GetWide() - 20, panel:GetTall() - 60, panel )
			banlist.Color = Color( 224, 224, 224, 255 )
			
			banlist.HoverColor = Color( 229, 229, 229, 255 )
			banlist.SelectColor = Color( 149, 227, 134, 255 )
			
			banlist:SetHeaderHeight( 40 )
			banlist.Round = 8
			banlist.ColumnFont = "exstoPlyColumn"
			banlist.ColumnTextCol = Color( 140, 140, 140, 255 )

			banlist.LineFont = "exstoDataLines"
			banlist.LineTextCol = Color( 164, 164, 164, 255 )
			
			banlist:AddColumn( "Player" )
			banlist:AddColumn( "SteamID" ):SetFixedWidth( 145 )
			banlist:AddColumn( "Length" ):SetFixedWidth( 55 )
			banlist:AddColumn( "Banned By" )
			
			for k,v in pairs( bans ) do
				banlist:AddLine( v.Name, v.SteamID, v.Length, v.BannedBy )
			end
			
			banlist.UpdatePlayers = function()
				Menu.EndLoad()
				banlist:Clear()
			
				for k,v in pairs( bans ) do
					banlist:AddLine( v.Name, v.SteamID, v.Length, v.BannedBy )
				end
			end
			
		local function GetSelected( column )
			column = column or 1
			if banlist:GetSelected()[1] then
				if banlist:GetSelected()[1]:GetValue(column) then
					return banlist:GetSelected()[1]:GetValue(column)
				else return nil end
			else return nil end
		end
		
		local unbanButton = exsto.CreateButton( (panel:GetWide() / 2) - ( 74 / 2 ), panel:GetTall() - 40, 74, 27, "Remove", panel )
			unbanButton.DoClick = function( button )
				local steam = GetSelected( 2 )
				if steam then
					LocalPlayer():ConCommand( "exsto_Unban \'" .. steam .. "\'" ) 
					PLUGIN.ReloadList()
				end
			end
			unbanButton.Color = Color( 171, 255, 155, 255 )
			unbanButton.HoverCol = Color( 143, 255, 126, 255 )
			unbanButton.DepressedCol = Color( 123, 255, 106, 255 )
	end

end

PLUGIN:Register()
