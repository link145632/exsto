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
	
	function PLUGIN:Init()
		self.Bans = FEL.LoadTable( "exsto_data_bans" ) or {}
	end

	function PLUGIN:Kick( owner, ply, reason )
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
		Desc = "Allows users to kick players.",
		Console = { "kick" },
		Chat = { "!kick" },
		ReturnOrder = "Victim-Reason",
		Args = {Victim = "PLAYER", Reason = "STRING"},
		Optional = {Reason = "Kicked by [self]"},
		Category = "Administration",
		DisallowCaller = true,
	})
	PLUGIN:RequestQuickmenuSlot( "kick", {
		Reason = {
			{ Display = "General Asshat" },
			{ Display = "Breaking the rules." },
			{ Display = "Minge" },
			{ Display = "We hate you." },
		},
	} )

	function PLUGIN:PlayerPasswordAuth( user, pass, steam, ipd )
		
		local data = FEL.Query( "SELECT BannedAt, Length, Reason FROM exsto_data_bans WHERE SteamID = " .. FEL.Escape( steam ) .. ";" )

		if not data or not data[1] then return end
		data = data[1]
		
		local len = tonumber( data.Length )
		local at = tonumber( data.BannedAt )
		local reason = tostring( data.Reason )
		
		if len == 0 then return {false, "You are perma-banned!"} end
		len = len * 100
		
		local timeleft = string.ToMinutesSeconds( ( len + at ) - os.time() )

		if len + at <= os.time() then FEL.RemoveData( "exsto_data_bans", "SteamID", steam ) self:ResendToAll() return end
		if data then return {false, "You are banned from this server!  Time left -- " .. timeleft .. "\nReason: " .. reason} end

	end
	
	PLUGIN.OldPlayers = {}
	
	function PLUGIN:PlayerDisconnected( ply )
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
		Desc = "Allows users to ban players via SteamID.",
		Console = { "banid" },
		Chat = { "!banid" },
		ReturnOrder = "SteamID-Length-Reason",
		Args = {SteamID = "STRING", Length = "NUMBER", Reason = "STRING"},
		Optional = {SteamID = "", Length = 0, Reason = "Banned by [self]"},
		Category = "Administration",
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
		
		table.insert( self.Bans, {
			Name = nick,
			SteamID = ply:SteamID(),
			Reason = reason,
			Length = len,
			BannedBy = owner:Nick(),
			BannedAt = os.time(),
		} )
		
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
		Desc = "Allows users to ban players.",
		Console = { "ban" },
		Chat = { "!ban" },
		ReturnOrder = "Victim-Length-Reason",
		Args = {Victim = "PLAYER", Length = "NUMBER", Reason = "STRING"},
		Optional = {Length = 0, Reason = "Banned by [self]"},
		Category = "Administration",
		DisallowCaller = true,
	})
	PLUGIN:RequestQuickmenuSlot( "ban", {
		Length = {
			{ Display = "Forever", Data = 0 },
			{ Display = "5 minutes", Data = 5 },
			{ Display = "10 minutes", Data = 10 },
			{ Display = "30 minutes", Data = 30 },
			{ Display = "One hour", Data = 60 },
			{ Display = "Five hours", Data = 5 * 60 },
			{ Display = "One day", Data = 24 * 60 },
			{ Display = "Two days", Data = 48 * 60 },
			{ Display = "One week", Data = ( 24 * 60 ) * 7 },
		},
		Reason = {
			{ Display = "General Asshat" },
			{ Display = "Breaking the rules." },
			{ Display = "Minge" },
			{ Display = "We hate you." },
		},
	} )

	function PLUGIN:UnBan( owner, steamid )
		steamid = string.upper( steamid ):gsub( " ", "" )

		if !gatekeeper then game.ConsoleCommand( "removeid " .. steamid .. ";writeid\n" ) end
		FEL.RemoveData( "exsto_data_bans", "SteamID", steamid )
		
		for _, data in ipairs( self.Bans ) do
			if data.SteamID == steamid then self.Bans[ _ ] = nil end
		end
		
		self:ResendToAll()

		return {
			Activator = owner,
			Player = steamid,
			Wording = " has unbanned ",
		}
		
	end
	PLUGIN:AddCommand( "unban", {
		Call = PLUGIN.UnBan,
		Desc = "Allows users to unban players.",
		Console = { "unban" },
		ReturnOrder = "SteamID",
		Chat = { "!unban" },
		Args = {SteamID = "STRING"},
		Category = "Administration",
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
		
		-- Make a nice formatted table.
		local send = {}
		if PLUGIN.Bans then
			for k,v in pairs( PLUGIN.Bans ) do
				send[v.SteamID] = v
			end
		end
		
		print( "Sending" )

		PLUGIN:SendData( "ExRecBans", ply, send )
	
	end
	concommand.Add( "_ResendBans", PLUGIN.RequestBans )

elseif CLIENT then

	function PLUGIN:ExRecBans( bans )
		if bans == nil then return end
		self.Bans = bans or {}
		Menu:EndLoad()
		if self.List then self.List:Update() end
	end
	PLUGIN:DataHook( "ExRecBans" )
	
	function PLUGIN:ReloadList( panel )
		if !self.List then return end
		
		Menu:PushLoad()
		self.Bans = nil
		RunConsoleCommand( "_ResendBans" )
	end

	function PLUGIN:GetSelected( column )
		if self.List:GetSelected()[1] then
			return self.List:GetSelected()[1]:GetValue( column or 1 )
		end
	end
	
	function PLUGIN:Build( panel )
		self.List = exsto.CreateListView( 10, 10, panel:GetWide() - 20, panel:GetTall() - 60, panel )
			self.List:AddColumn( "Player" )
			self.List:AddColumn( "SteamID" )
			self.List:AddColumn( "Reason" )
			self.List:AddColumn( "Banned By" )
			self.List:AddColumn( "Unban Date" )
			
			self.List.Update = function()
				self.List:Clear()
				for _, data in pairs( self.Bans ) do
					local time = os.date( "%c", data.BannedAt + data.Length )
					if data.Length == 0 then time = "permanent" end
					
					self.List:AddLine( data.Name, data.SteamID, data.Reason, data.BannedBy, time )
				end
			end
			self.List:Update()
			
			self.unbanButton = exsto.CreateButton( ( (panel:GetWide() / 2) - ( 74 / 2 ) ) + 50, panel:GetTall() - 40, 74, 27, "Remove", panel )
				self.unbanButton.DoClick = function( button )
					local id = self:GetSelected( 2 )
					if id then
						RunConsoleCommand( "exsto", "unban", tostring( id ) )
						self:ReloadList( panel )
					end
				end
				self.unbanButton:SetStyle( "positive" )
			
			self.refreshButton = exsto.CreateButton( ( (panel:GetWide() / 2) - ( 74 / 2 ) ) - 50, panel:GetTall() - 40, 74, 27, "Refresh", panel )
				self.refreshButton.DoClick = function( button )
					self:ReloadList( panel )
				end	
	end

	function PLUGIN:Ping( panel )
		if type( self.Bans ) != "table" then
			timer.Simple( 1, self.Ping, PLUGIN, panel )
			return
		end
		Menu:EndLoad()
		self:Build( panel )
	end
	
	Menu:CreatePage({
		Title = "Ban List",
		Short = "banlist",
	},	function( panel )
			if type( PLUGIN.Bans ) != "table" then
				Menu:PushLoad()
				RunConsoleCommand( "_ResendBans" )
				PLUGIN:Ping( panel )
				return
			end
			PLUGIN:Build( panel )
		end
	)

end

PLUGIN:Register()