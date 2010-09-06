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

	if !gatekeeper then require( "gatekeeper" ) end

	function PLUGIN:Init() 
		self.OldPlayers = {}
		exsto.BanDB = FEL.CreateDatabase( "exsto_data_bans" )
			exsto.BanDB:ConstructColumns( {
				Name = "TEXT:not_null";
				SteamID = "VARCHAR(50):primary:not_null";
				Length = "INTEGER:not_null";
				Reason = "TEXT";
				BannedBy = "TEXT:not_null";
				BannedAt = "INTEGER:not_null";
			} )
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

	-- This function is a purly a hook for Gatekeeper, and will only run if Gatekeeper is present.
	function PLUGIN:PlayerPasswordAuth( user, pass, steam, ipd ) 

		local at, len, reason = exsto.BanDB:GetData( steam, "BannedAt, Length, Reason" )
		
		if !at or !len or !reason then return end
		
		local len = tonumber( len ) * 60
		local at = tonumber( at ) 
		local reason = tostring( reason ) 

		if len == 0 then return {false, "You are perma-banned!"} end 

		local timeleft = string.ToMinutesSeconds( ( len + at ) - os.time() ) 

		if len + at <= os.time() then FEL.RemoveData( "exsto_data_bans", "SteamID", steam ) self:ResendToAll() return end 
		if data then return {false, "You are banned from this server!  Time left -- " .. timeleft .. "\nReason: " .. reason} end 

	end 

	function PLUGIN:PlayerDisconnected( ply ) 
		self.OldPlayers[ ply:SteamID() ] = ply:Nick()
	end 

	function PLUGIN:BanID( owner, id, len, reason ) 
		if type( id ) == "Player" then 
			return self:Ban( owner, id, len, reason ) 
		end 

		if !string.match( id, "STEAM_[0-5]:[0-9]:[0-9]+" ) then
			return { owner, COLOR.NAME, "Invalid SteamID.", COLOR.NORM, "A normal SteamID looks like this, ", COLOR.NAME, "STEAM_0:1:123456" }
		end
		
		-- Check and see if we can grab any information we might have from this man.
		local name = self.OldPlayers[ id ] or "Unknown"
		
		-- Save his stuff yo.		
		exsto.BanDB:AddRow( {
			Name = name;
			SteamID = id;
			Reason = reason;
			Length = len;
			BannedBy = owner:Name() or "Console";
			BannedAT = os.time();
		} )
		
		self:ResendToAll()
		
		return {
			Activator = owner,
			Object = name,
			Wording = " has banned ",
			Secondary = " for "..tostring(len).." minutes with reason: " .. reason 
		}

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
		local nick = ply:Nick()
		
		-- Save his stuff yo.		
		exsto.BanDB:AddRow( {
			Name = ply:Nick();
			SteamID = ply:SteamID();
			Reason = reason;
			Length = len;
			BannedBy = owner:Name() or "Console";
			BannedAT = os.time();
		} )
		
		if gatekeeper then 
			gatekeeper.Drop( ply:UserID(), "BAN: " .. reason ) 
		else 
			ply:Ban( len, reason ) 
			ply:Kick( reason ) 
		end 

		self:ResendToAll() 

		return { 
			Activator = owner, 
			Player = nick, 
			Wording = " has banned ", 
			Secondary = " for "..tostring(len).." minutes with reason: " .. reason 
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
	
		local dataUsed = false
		if !string.match( steamid, "STEAM_[0-5]:[0-9]:[0-9]+" ) then
			-- We don't have a match.  Try checking our ban list for his name like this.
			for _, ban in ipairs( self.Bans ) do
				if ban.Name == steamid then
					-- We found a name of a player; unban him like this.
					dataUsed = true
					steamid = ban.SteamID
					break
				end
			end
			
			-- Check our match again
			if !string.match( steamid, "STEAM_[0-5]:[0-9]:[0-9]+" ) then
				return { owner, COLOR.NORM, "That is an invalid ", COLOR.NAME, "SteamID!", COLOR.NORM, "A normal SteamID looks like this, ", COLOR.NAME, "STEAM_0:1:123456" }
			end
		end
		
		-- Check to see if this ban actually exists.
		local found = false
		for _, ban in ipairs( exsto.BanDB:GetAll() ) do
			if ban.SteamID == steamid then found = true break end
		end
		
		if !found then
			return { owner, COLOR.NAME, steamid, COLOR.NORM, " is not banned!" }
		end
		
		game.ConsoleCommand( "removeid " .. steamid .. ";writeid\n" ) -- Do this regardless.
		
		local name = "Unknown"
		for _, data in ipairs( exsto.BanDB:GetAll() ) do 
			if data.SteamID == steamid then
				name = data.Name
			end 
		end 
		
		exsto.BanDB:DropRow( steamid )
		self:ResendToAll() 

		return { 
			Activator = owner, 
			Player = steamid .. " (" .. name .. ")",
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
	 
	 function PLUGIN:Lookup( owner, data )
			 
			 local SearchType = ((string.Left(data,6) == "STEAM_") and "SteamID" or "Name")
			 if SearchType == "Steam_" then data = string.upper( data ) end
			 
			 local users = exsto.UserDB:GetAll()
			
			local ply = {}
			 for _, user in ipairs( users ) do 
				if SearchType == "SteamID" then
					if user.SteamID == data then 
						ply = user
					end
				else
					if string.lower(user.Name) == string.lower(data) then
						ply = user
					elseif string.find(string.lower(user.Name),string.lower(data)) then
						ply = ply[1] and ply or user
					end						
				end
			 end

			if !ply.Name then
				return { owner,COLOR.NORM,"No player found under the "..SearchType,COLOR.NAME," "..data }
			end
			
			local LastTime, UserTime = exsto.TimeDB:GetData( ply.SteamID, "Last, Time" )
			
			local info = {
				{"  ~ Lookup table for "..ply.Name.." ~"},
				{"SteamID:     "..ply.SteamID},
				{"Rank:        "..ply.Rank},
				{"Last Joined: "..os.date( "%c", LastTime )},
				{"Total Time : "..timeToStr(UserTime)}
			}

			local BanInfo = FEL.Query( "SELECT BannedAt, Length, Reason FROM exsto_data_bans WHERE SteamID = " .. FEL.Escape(ply.SteamID) .. ";" ) 
			if BanInfo then
				BInfo = BanInfo[1]
				table.insert(info,{" ~User is banned"})
				table.insert(info,{"Banned at: "..os.date("%c",BInfo.BannedAt)})
				table.insert(info,{"Banned to: "..(tonumber(BInfo.Length) > 0 and os.date("%c",BInfo.BannedAt + BInfo.Length) or "Permanent")})
				table.insert(info,{"Reason :   "..(BInfo.Reason or "No reason.")})
			end
			 
			 for v,k in ipairs(info) do
				if owner:EntIndex() == 0 then owner:Print(exsto_CHAT,unpack(info[v]))
				else owner:Print(exsto_CLIENT,unpack(info[v])) end
			 end
			RColor = exsto.GetRankColor(ply.Rank)
			 return { owner,COLOR.NORM,"Player: ",RColor,ply.Name,COLOR.NORM," looked up, check console for info." }
			  
	 end 
	 PLUGIN:AddCommand( "lookup", { 
			 Call = PLUGIN.Lookup, 
			 Desc = "Allows users to lookup a player's info.", 
			 Console = { "lookup" }, 
			 ReturnOrder = "FindWith", 
			 Chat = { "!lookup" }, 
			 Args = { FindWith = "STRING" }, 
			 Category = "Administration", 
	 })
	PLUGIN:RequestQuickmenuSlot( "lookup" )
	 
	function timeToStr( time )
	   if !time then return "Permanent." end
		local tmp = time
		local s = tmp % 60
		tmp = math.floor( tmp / 60 )
		local m = tmp % 60
		tmp = math.floor( tmp / 60 )
		local h = tmp % 24
		tmp = math.floor( tmp / 24 )
		local d = tmp % 7
		local w = tmp / 7
		
		local TimeString = (w>1 and w.."weeks " or "")..(d>0 and d.."days " or "")..string.format("%ih %02im %02is",h,m,s)
		TimeString = w==1 and string.gsub(TimeString,"weeks","week") or TimeString
		TimeString = d==1 and string.gsub(TimeString,"days","day") or TimeString
		
		return TimeString
	end
	  
	function PLUGIN:ResendToAll() 
		self.RequestBans( player.GetAll() )
	end 

	function PLUGIN.RequestBans( ply ) 
		for k,v in pairs( exsto.BanDB:GetAll() ) do 
			local sender = exsto.CreateSender( "ExRecBans", ply )
				sender:AddString( v.SteamID )
				sender:AddString( v.Name )
				sender:AddString( v.Reason )
				sender:AddString( v.BannedBy )
				sender:AddShort( v.Length )
				sender:AddShort( v.BannedAt )
				sender:Send()
		end 
		exsto.CreateSender( "ExSaveBans", ply ):Send()
	end 
	concommand.Add( "_ResendBans", PLUGIN.RequestBans ) 

elseif CLIENT then 

	PLUGIN.Recieved = false

	local function receive( reader )
		if !PLUGIN.Bans then PLUGIN.Bans = {} end
		local steamid = reader:ReadString()
		PLUGIN.Bans[ steamid ] = {
			SteamID = steamid,
			Name = reader:ReadString(),
			Reason = reader:ReadString(),
			BannedBy = reader:ReadString(),
			Length = reader:ReadShort(),
			BannedAt = reader:ReadShort(),
		}
	end
	exsto.CreateReader( "ExRecBans", receive )
	
	local function save()
		PLUGIN.Panel:EndLoad() 
		PLUGIN.Recieved = true
		if PLUGIN.Panel then
			if PLUGIN.List and PLUGIN.List:IsValid() then
				PLUGIN.List:Update()
			else
				PLUGIN:Build( PLUGIN.Panel )
			end
		end
	end
	exsto.CreateReader( "ExSaveBans", save )
	
	function PLUGIN:ReloadList( panel ) 
		if !self.List then return end 

		panel:PushLoad()
		self.Bans = nil 
		self.Recieved = false
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
			if type( self.Bans ) == "table" then
				for _, data in pairs( self.Bans ) do 
					local time = os.date( "%c", data.BannedAt + data.Length ) 
					if data.Length == 0 then time = "permanent" end 

					self.List:AddLine( data.Name, data.SteamID, data.Reason, data.BannedBy, time ) 
				end 
			end
		end 
		self.List:Update() 

		self.unbanButton = exsto.CreateButton( ( (panel:GetWide() / 2) - ( 74 / 2 ) ) + 50, panel:GetTall() - 40, 74, 27, "Remove", panel ) 
		self.unbanButton.OnClick = function( button ) 
			local id = self:GetSelected( 2 ) 
			if id then 
				RunConsoleCommand( "exsto", "unban", tostring( id ) ) 
				self:ReloadList( panel ) 
			else
				panel:PushGeneric( "Please select a ban to remove." )
			end
		end 
		self.unbanButton:SetStyle( "positive" ) 

		self.refreshButton = exsto.CreateButton( ( (panel:GetWide() / 2) - ( 74 / 2 ) ) - 50, panel:GetTall() - 40, 74, 27, "Refresh", panel ) 
		self.refreshButton.OnClick = function( button ) 
			self:ReloadList( panel ) 
		end      
	end 

	Menu:CreatePage({ 
		Title = "Ban List", 
		Short = "banlist", 
	},      function( panel )
		if !PLUGIN.Recieved then
			panel:PushLoad()
			RunConsoleCommand( "_ResendBans" ) 
		else
			PLUGIN:Build( panel ) 
		end
		PLUGIN.Panel = panel
	end 
	) 

end 

PLUGIN:Register() 
