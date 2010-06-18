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

if SERVER then

	//if !gatekeeper then require( "gatekeeper" ) end
	gatekeeper = nil
	
	function PLUGIN:KickID( owner, id, reason )
		if type( id ) == "Player" then
			return self:Kick( owner, id, reason )
		end
	
		if string.Left( id, 6 ) != "STEAM_" then
			return { owner, COLOR.NORM, "Please input a valid ", COLOR.NAME, "SteamID", COLOR.NORM, "!" }
		end
		
		local ply = exsto.GetPlayerByID( id )
		
		if !ply then
			return { owner, COLOR.NORM, "Couldn't find a player under SteamID ", COLOR.NAME, id, COLOR.NORM, "!" }
		end
		
		return self:Kick( owner, ply, reason )
	end
	PLUGIN:AddCommand( "kickid", {
		Call = PLUGIN.KickID,
		Desc = "Kicks a player by their SteamID",
		FlagDesc = "Allows users to kick players via SteamID.",
		Console = { "kickid" },
		Chat = { "!kickid" },
		ReturnOrder = "SteamID-Reason",
		Args = {SteamID = "STRING", Reason = "STRING"},
		Optional = {SteamID = "", Reason = "Kicked by [self]"}
	})

	function PLUGIN:Kick( owner, ply, reason )
		
		--if reason == "nil" then reason = "Kicked by " .. owner:Nick() end
		local nick = ply:Nick()
		
		if gatekeeper then
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
		Optional = {Victim = nil, Reason = "Kicked by [self]"}
	})

	function PLUGIN:OnPlayerPasswordAuth( user, pass, steam, ipd )
		
		local data = FEL.Query( "SELECT BannedAt, Length, Reason FROM exsto_data_bans WHERE SteamID = " .. FEL.Escape( steam ) .. ";" )

		if not data or not data[1] then return true end
		data = data[1]
		
		local len = tonumber( data.Length )
		local at = tonumber( data.BannedAt )
		local reason = tostring( data.Reason )
		
		if len == 0 then return {false, "You are perma-banned!"} end
		len = len * 100
		
		local timeleft = string.ToMinutesSeconds( ( len + at ) - os.time() )

		if len + at <= os.time() then FEL.RemoveData( "exsto_data_bans", "SteamID", steam ) self:ResendToAll() return true end
		if data then return {false, "You are banned from this server!  Time left -- " .. timeleft .. "\nReason: " .. reason} end

		return true
	
	end
	
	PLUGIN.OldPlayers = {}
	
	function PLUGIN:OnPlayerDisconnected( ply )
		table.insert( self.OldPlayers, {
			SteamID = ply:SteamID(),
			Nick = ply:Nick(),
		} )
	end
	
	function PLUGIN:BanID( owner, id, len, reason )
		if type( id ) == "Player" then
			return self:Ban( owner, id, len, reason )
		end
	
		if string.Left( id, 6 ) != "STEAM_" then
			return { owner, COLOR.NORM, "Please input a valid ", COLOR.NAME, "SteamID", COLOR.NORM, "!" }
		end
		
		local ply = exsto.GetPlayerByID( id )
		
		if !ply then
			for k,v in ipairs( self.OldPlayers ) do
				if v.SteamID == id then ply = v end
			end
		end
		
		if !ply then
			return { owner, COLOR.NORM, "Couldn't find a player under SteamID ", COLOR.NAME, id, COLOR.NORM, "!" }
		end
		
		return self:Ban( owner, ply, len, reason )
	end
	PLUGIN:AddCommand( "banid", {
		Call = PLUGIN.BanID,
		Desc = "Bans a player by their SteamID",
		FlagDesc = "Allows users to ban players via SteamID.",
		Console = { "banid" },
		Chat = { "!banid" },
		ReturnOrder = "SteamID-Length-Reason",
		Args = {SteamID = "STRING", Length = "NUMBER", Reason = "STRING"},
		Optional = {SteamID = "", Length = 0, Reason = "Banned by [self]"}
	})

	function PLUGIN:Ban( owner, ply, len, reason )

		local nick
		local userID
		
		if type( ply ) == "table" then
			nick = ply.Nick
			userID = ply.UserID
		else
			nick = ply:Nick()
			userID = ply:UserID()
		end

		FEL.SaveBanInfo( ply, len, reason, owner, os.time(), gatekeeper )
		
		if type( ply ) != "table" then
			if gatekeeper then
				gatekeeper.Drop( userID, "BAN: " .. reason )
			else
				ply:Ban( len, reason )
				ply:Kick( reason )
			end
		end
		
		self:ResendToAll()
		
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
		Optional = {Victim = nil, Length = 0, Reason = "Banned by [self]"}
	})

	function PLUGIN:UnBan( owner, steamid )
		steamid = string.upper( steamid ):gsub( " ", "" )

		if !gatekeeper then game.ConsoleCommand( "removeid " .. steamid .. ";writeid\n" ) end
		FEL.RemoveData( "exsto_data_bans", "SteamID", steamid )
		
		self:ResendToAll()

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
	
	function PLUGIN:ResendToAll()
	
		local bans = FEL.LoadTable( "exsto_data_bans" )
		
		-- Make a nice formatted table.
		local send = {}
		if bans then
			for k,v in pairs( bans ) do
				send[v.SteamID] = v
			end
		end

		exsto.UMStart( "ExRecBans", player.GetAll(), send )
		
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

		exsto.UMStart( "ExRecBans", ply, send )
	
	end
	concommand.Add( "_ResendBans", PLUGIN.RequestBans )
	
	function PLUGIN:CreateRagdoll( ply )
		
		ply.Ragdolled = true
	
		local ragdoll = ents.Create( "prop_ragdoll" )
		
			ragdoll:SetPos( ply:GetPos() )
			ragdoll:SetAngles( ply:GetAngles() )
			ragdoll:SetModel( ply:GetModel() )
			ragdoll:Spawn()
			ragdoll:Activate()
			
			ply:SetParent( ragdoll ) 

			ply:Spectate( OBS_MODE_CHASE )
			ply:SpectateEntity( ragdoll )
		
		timer.Simple( 5, _R.Player.UnSpectate, ply )
		timer.Simple( 5, function() ply.Ragdolled = false end )
		
		return ragdoll
		
	end
	
	function PLUGIN:BanTrain( ply, callback )
	
		exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "The Heavy Ban Train is coming to pick up ", COLOR.NAME, ply:Nick(), COLOR.NORM, "!  Say your goodbyes!" )
		
		-- Create the train
		local train = ents.Create( "prop_physics" )
			train:SetModel( "models/props_vehicles/train_engine.mdl" )
			train:SetAngles( Angle( 180, 0, 180 ) )
			train:Activate()
			train:Spawn()
			
			train:SetSolid( SOLID_NONE )

		-- Place the train!
		local x = 3000
		train:SetPos( ply:GetPos() + Vector( x, 0, 5 ) )
		
		local currentInterval = 1
		local nextJump = 0
		local function entThink()
		
			for k,v in pairs( player.GetAll() ) do
				local dist = v:GetPos():Distance( train:GetPos() )
				
				if dist < 300 and !v.Ragdolled then
					local ragdoll = self:CreateRagdoll( v )
					for i=1, 14 do
						ragdoll:GetPhysicsObjectNum( i ):SetVelocity( train:GetForward() * 1900 + ( VectorRand() * 90 ) + Vector( 0, 0, 900 ) )
					end
				end
			end
		
			local dist = ply:GetPos():Distance( train:GetPos() )
			
			if dist < 300 then -- If we are pretty much on top of him.
				timer.Simple( 2, function() hook.Remove( "Think", "BanTrain_" .. ply:Nick() ) end )
			end

			local phys = train:GetPhysicsObject()
			phys:SetVelocity( Vector( -x, 0, 0 ) )
			
		end
		
	end
		
elseif CLIENT then

	local bans = {}
	local Recieved = false
	local banlist

	function PLUGIN.RecieveBans( b )
	
		bans = b or {}
		Recieved = true
		
		if banlist then banlist.UpdatePlayers() end
		
	end
	exsto.UMHook( "ExRecBans", PLUGIN.RecieveBans )

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
		
		local unbanButton = exsto.CreateButton( ( (panel:GetWide() / 2) - ( 74 / 2 ) ) + 50, panel:GetTall() - 40, 74, 27, "Remove", panel )
			unbanButton.DoClick = function( button )
				local steam = GetSelected( 2 )
				if steam then
					RunConsoleCommand( "exsto", "unban", tostring( steam ) )
					PLUGIN.ReloadList()
				end
			end
			unbanButton.Color = Color( 171, 255, 155, 255 )
			unbanButton.HoverCol = Color( 143, 255, 126, 255 )
			unbanButton.DepressedCol = Color( 123, 255, 106, 255 )
			
		local refreshButton = exsto.CreateButton( ( (panel:GetWide() / 2) - ( 74 / 2 ) ) - 50, panel:GetTall() - 40, 74, 27, "Refresh", panel )
			refreshButton.DoClick = function( button )
				PLUGIN.ReloadList()
			end

	end
	
	Menu.CreatePage( {
	Title = "Player List",
	Short = "playerlist",
	Default = true,
	Flag = "playerlist",
	},
	function( panel )
		local Reasons = {
			"Mingebag",
			"Requested",
			"Asshat",
			"\"We don't like you\"",
			"\"Sorry bro.\"",
			"\"No Reason\"",
		}
		
		local Times = {
			"Forever",
			"1 Hour",
			"5 Hours",
			"1 Day",
			"1 Week",
			"1 Month",
		}
		
		local plylist = exsto.CreateListView( 10, 10, panel:GetWide() - 20, panel:GetTall() - 60, panel )
			plylist.Color = Color( 224, 224, 224, 255 )
			
			plylist.HoverColor = Color( 229, 229, 229, 255 )
			plylist.SelectColor = Color( 149, 227, 134, 255 )
			
			plylist:SetHeaderHeight( 40 )
			plylist.Round = 8
			plylist.ColumnFont = "exstoPlyColumn"
			plylist.ColumnTextCol = Color( 140, 140, 140, 255 )

			plylist.LineFont = "exstoDataLines"
			plylist.LineTextCol = Color( 164, 164, 164, 255 )
			
			plylist:AddColumn( "Player" )
			plylist:AddColumn( "SteamID" ):SetFixedWidth( 145 )
			plylist:AddColumn( "Rank" )
			plylist:AddColumn( "Ping" ):SetFixedWidth( 45 )
			
			plylist.UpdatePlayers = function()
				plylist.Players = {}
				plylist:Clear()
				
				for k,v in pairs( player.GetAll() ) do
					table.insert( plylist.Players, v )
				end
				
				for k,v in pairs( plylist.Players ) do
					local line = plylist:AddLine( v:Name(), v:SteamID(), v:GetRank(), v:Ping() )
					local oldScheme = line.ApplySchemeSettings
					-- Rank Color
					local oldSettings = line.Columns[3].ApplySchemeSettings
					line.Columns[3].ApplySchemeSettings = function( self )
						oldSettings( self )
						self:SetTextColor( exsto.GetRankColor( v:GetRank() ) )
					end
					
					-- Pingggggg
					local oldSettings = line.Columns[4].ApplySchemeSettings
					line.Columns[4].ApplySchemeSettings = function( self )
						oldSettings( self )
						if v:Ping() > 150 then
							self:SetTextColor( COLOR.NAME )
						end
					end
				end
			end
			
			local lastThink = 1;
			plylist.Think = function()
				if CurTime() > lastThink then
					lastThink = CurTime() + 10
					plylist.UpdatePlayers()
				end
			end
			plylist.UpdatePlayers()
			
		local function GetSelected()
			if plylist:GetSelected()[1] then
				if plylist:GetSelected()[1]:GetValue(1) then
					return plylist:GetSelected()[1]:GetValue(1)
				else return nil end
			else return nil end
		end
			
		if LocalPlayer():IsAdmin() then
			local kickButton = exsto.CreateButton( (panel:GetWide() / 2) - 74 * 2, panel:GetTall() - 40, 74, 27, "Kick", panel )
				kickButton.DoClick = function( button )
					local ply = GetSelected()
					if ply then
						local menu = DermaMenu()
						for k,v in pairs( Reasons ) do
							menu:AddOption( v, function() RunConsoleCommand( "exsto", "kick",  ply, v ) plylist.UpdatePlayers() end )
						end
						menu:Open()
					end
				end
				kickButton.Color = Color( 255, 155, 155, 255 )
				kickButton.HoverCol = Color( 255, 126, 126, 255 )
				kickButton.DepressedCol = Color( 255, 106, 106, 255 )
				
			local banButton = exsto.CreateButton( (panel:GetWide() / 2) - ( 74 / 2 ), panel:GetTall() - 40, 74, 27, "Ban", panel )
				banButton.DoClick = function( button )
					local ply = GetSelected()
					if ply then
						local menu = DermaMenu()
						for k,v in pairs( Times ) do
							if v == "Forever" then v = 0 end
							if v == "1 Hour" then v = 60 end
							if v == "5 Hours" then v = 60 * 5 end
							if v == "1 Day" then v = 60 * 24 end
							if v == "1 Week" then v = (60 * 24) * 7 end
							if v == "1 Month" then v = ((60 * 24) * 7) * 4 end
							menu:AddOption( v, function() RunConsoleCommand( "exsto", "ban", ply, v ) plylist.UpdatePlayers() end )
						end
						menu:Open()
					end
				end
				banButton.Color = Color( 255, 155, 155, 255 )
				banButton.HoverCol = Color( 255, 126, 126, 255 )
				banButton.DepressedCol = Color( 255, 106, 106, 255 )
				
			local rankButton = exsto.CreateButton( (panel:GetWide() / 2) + 74, panel:GetTall() - 40, 74, 27, "Rank", panel )
				rankButton.DoClick = function( button )
					local ply = GetSelected()
					if ply then
						if ply == LocalPlayer():Nick() then
							Menu.PushError( "Error: You cannot change your own rank!" )
							return
						end
						local menu = DermaMenu()
						for k,v in pairs( exsto.Levels ) do
							menu:AddOption( v.Name, function() RunConsoleCommand( "exsto", "rank", ply, v.Short ) plylist.UpdatePlayers() end )
						end
						menu:Open()
					end
				end
				rankButton.Color = Color( 171, 255, 155, 255 )
				rankButton.HoverCol = Color( 143, 255, 126, 255 )
				rankButton.DepressedCol = Color( 123, 255, 106, 255 )
		end
	end
)

end

PLUGIN:Register()
