--[[
	Exsto
	Copyright (C) 2010  Prefanatic

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]


-- User Control System (UCS)

-- Variables

exsto.Ranks = {}
exsto.LoadedRanks = {}
exsto.RankErrors = {} -- For storing errors from ranks.

if SERVER then
	FEL.MakeTable( "exsto_data_access", {
			Name = "varchar(255)",
			Description = "varchar(255)",
			Short = "varchar(255)",
			Derive = "varchar(255)",
			Immunity = "int",
			Color = "varchar(255)",
			Flags = "text",
			DefaultFlags = "text",
		}
	)
	
--[[ -----------------------------------
	Function: ACCESS_CreateDefaults
	Description: Creates the default ranks from sh_tables.
	----------------------------------- ]]
	function ACCESS_CreateDefaults()
		for k,v in pairs( exsto.DefaultRanks ) do
		
			FEL.AddData( "exsto_data_access", {
				Look = {
					Short = v.Short,
				},
				Data = {
					Name = v.Name,
					Description = v.Desc,
					Short = v.Short,
					Derive = v.Derive,
					Color = FEL.NiceColor( v.Color ),
					Immunity = v.Immunity,
					Flags = FEL.NiceEncode( v.Flags ),
					DefaultFlags = FEL.NiceEncode( v.Flags ),
				},
				Options = {
					Update = false,
				}
			} )

		end
		
	end

--[[ -----------------------------------
	Function: ACCESS_LoadFiles
	Description: Loads all the ranks.
	----------------------------------- ]]
	function ACCESS_LoadFiles()
		for k,v in pairs( FEL.LoadTable( "exsto_data_access" ) ) do

			if v.DefaultFlags != "NULL" and v.DefaultFlags != nil then
				exsto.LoadedRanks[v.Short] = {
					Name = v.Name,
					Desc = v.Description,
					Short = v.Short,
					Derive = v.Derive,
					Color = FEL.MakeColor( v.Color ),
					Immunity = v.Immunity,
					Flags = FEL.NiceDecode( v.Flags ),
					DefaultFlags = FEL.NiceDecode( v.DefaultFlags ),
					CanRemove = false, -- Hes a default, we don't want him deleted.
				}
				
				-- Check to make sure his default flags are up to date.
				ACCESS_UpdateDefaultFlags( v.Short )
			else
				exsto.LoadedRanks[v.Short] = {
					Name = v.Name,
					Desc = v.Description,
					Short = v.Short,
					Derive = v.Derive,
					Color = FEL.MakeColor( v.Color ),
					Immunity = v.Immunity,
					Flags = FEL.NiceDecode( v.Flags ),
					CanRemove = true,
				}
			end
		end
	end		

--[[ -----------------------------------
	Function: ACCESS_UpdateDefaultFlags
	Description: Updates the saved default flags with the new ones in sh_tables.
	----------------------------------- ]]
	function ACCESS_UpdateDefaultFlags( short )
		local data = table.Copy( exsto.LoadedRanks[short] )
		local defaultData = exsto.DefaultRanks[short]
		local checkedFlags = table.Copy( data.DefaultFlags )
		local addToFlags = table.Copy( data.Flags )
		
		local tableChanged = false
			
		-- First, we need to check and see if hes missing any.
		for k,v in pairs( defaultData.Flags ) do
			if !table.HasValue( data.DefaultFlags, v ) then
				tableChanged = true
				-- Hes mising a flag!
				table.insert( addToFlags, v )
				table.insert( checkedFlags, v )
			end
		end
		
		-- Now, we need to check and see if the saved data has one more than it should.
		if #data.DefaultFlags > #defaultData.Flags then
			for k,v in pairs( data.DefaultFlags ) do
				if !table.HasValue( defaultData.Flags, v ) then
					tableChanged = true
					table.remove( addToFlags, k )
					table.remove( checkedFlags, k )
				end
			end
		end
		
		if tableChanged then
		
			exsto.Print( exsto_CONSOLE, "RANKS --> " .. short .. " --> Rank has been updated with new flag information!" )

			FEL.AddData( "exsto_data_access", {
				Look = {
					Short = data.Short,
				},
				Data = {
					Name = data.Name,
					Description = data.Desc,
					Short = data.Short,
					Derive = data.Derive,
					Color = FEL.NiceColor( data.Color ),
					Immunity = data.Immunity,
					Flags = FEL.NiceEncode( addToFlags ),
					DefaultFlags = FEL.NiceEncode( checkedFlags ),
				},
				Options = {
					Update = true,
				}
			} )
				
			exsto.LoadedRanks[short] = {
				Name = data.Name,
				Desc = data.Desc,
				Short = data.Short,
				Derive = data.Derive,
				Color = data.Color,
				Immunity = data.Immunity,
				Flags = addToFlags,
				DefaultFlags = checkedFlags,
			}
			
		end
	end

--[[ -----------------------------------
	Function: RANK_Loaded
	Description: Returns true if the rank is loaded
	----------------------------------- ]]
	function RANK_Loaded( rank )
		if exsto.Ranks[rank] then return true end
		return false
	end
	
--[[ -----------------------------------
	Function: ACCESS_CheckIfEndless
	Description: Checks if a rank is broken, or gets stuck in an endless derive
	----------------------------------- ]]
	function ACCESS_CheckIfEndless( rank )
	
		local checkedRanks = { rank }
		local currentRank = rank
		for I = 1, 30 do -- Lets only go 10 in.
			if currentRank == "NONE" then -- Don't worry, hes the NONE.
				return false
			end

			local info = exsto.LoadedRanks[currentRank]
			
			-- if hes broken, just don't continue.
			if !info then return true end

			if info.Derive == "" or !info.Derive then -- He has no derive somehow
				exsto.RankErrors[info.Short] = {info, "nonexistant derive"}
				return true
			end
			
			if table.HasValue( checkedRanks, info.Derive) then -- We already touched on this rank, kill, were in a loop.
				exsto.RankErrors[info.Short] = {info, "endless derive"}
				return true
			end
			
			if info.Derive == info.Short then -- How the hell can this happen?  CHECK ANYWAY!
				exsto.RankErrors[info.Short] = {info, "self derive"}
				return true
			end
			
			local exists = false
			-- Check to see if that derive exists.
			for k,v in pairs( exsto.LoadedRanks ) do
				if ( info.Derive == v.Short ) and ( info.Short != v.Short ) then
					-- The derive exists, return OK.
					exists = true
				end
			end
			
			-- He passed the check for derives
			if exists == false and info.Derive != "NONE" then
				exsto.RankErrors[info.Short] = {info, "nonexistant derive"}
				return true
			else	
				-- He found a derive I guess, return OK
				return false
			end
			
			if info.Derive != "NONE" then 
				table.insert( checkedRanks, info.Derive )
				currentRank = info.Derive
			else
				return false
			end
			
		end
		
		if currentRank != "NONE" then -- We probably got stuck in a loop.
			exsto.RankErrors[rank] = {exsto.LoadedRanks[rank], "nonexistant derive"}
			return true
		end
		
	end

--[[ -----------------------------------
	Function: ACCESS_LoadRank
	Description: Loads a rank
	----------------------------------- ]]	
	function ACCESS_LoadRank( short )

		local data = exsto.LoadedRanks[ short ]

		-- We need to load him
		if !RANK_Loaded( short ) then
			
			exsto.Ranks[ short ] = {
				Name = data.Name,
				Desc = data.Desc,
				Short = data.Short,
				Color = data.Color,
				Immunity = data.Immunity,
				Flags = table.Copy( data.Flags ),
				AllFlags = {},
				Derive = data.Derive,
				CanRemove = data.CanRemove,
			}
			
			-- Derive flags if we can.
			if data.Derive != "NONE" then

				-- Load him if he isn't alive.
				if !RANK_Loaded( data.Derive ) then
					ACCESS_LoadRank( data.Derive )
				end
				
				-- Copy his flags to our AllFlags section.
				exsto.Ranks[ short ].AllFlags = table.Add( table.Copy( exsto.Ranks[ short ].Flags ), exsto.Ranks[ data.Derive ].AllFlags )
			else
				exsto.Ranks[ short ].AllFlags = table.Copy( exsto.Ranks[ short ].Flags )
			end
			exsto.Print( exsto_CONSOLE, "RANKS --> Loading " .. data.Name .. "!" )
		end
	end
	
--[[ -----------------------------------
	Function: ACCESS_InitLevels
	Description: Initializes all the ranks
	----------------------------------- ]]
	function ACCESS_InitRanks()
		for short, data in pairs( exsto.LoadedRanks ) do
			if !RANK_Loaded( short ) then
				local endless = ACCESS_CheckIfEndless( short )
				
				if endless then
					exsto.Print( exsto_CONSOLE, "RANKS --> " .. data.Name .. " has been stuck into an endless derive loop!  Ending his life!" )
				else
					ACCESS_LoadRank( short )
				end
			end
		end
		
		if table.Count( exsto.RankErrors ) >= 1 then
			exsto.Print( exsto_CONSOLE, "RANKS --> Finished loading with errors!" )
		else
			exsto.Print( exsto_CONSOLE, "RANKS --> Loaded successfully!" )
		end
	end

--[[ -----------------------------------
	Function: ACCESS_PrepReload
	Description: Deletes the rank tables
	----------------------------------- ]]
	function ACCESS_PrepReload()
		exsto.Ranks = {}
		exsto.LoadedRanks = {}
	end
	
--[[ -----------------------------------
	Function: ACCESS_Reload
	Description: Reloads the rank controller
	----------------------------------- ]]
	function ACCESS_Reload()
		ACCESS_PrepReload()
		ACCESS_LoadFiles()
		ACCESS_InitRanks()
		hook.Call( "ExAccessReloaded" )
	end
	
--[[ -----------------------------------
	Function: ACCESS_LoadController
	Description: Completely loads the rank controller.
	----------------------------------- ]]
	function ACCESS_LoadController()
		ACCESS_PrepReload()
		ACCESS_CreateDefaults()
		ACCESS_LoadFiles()
		ACCESS_InitRanks()
	end
	
--[[ -----------------------------------
	Function: ACCESS_ResendRanks
	Description: Resends the ranks to all players
	----------------------------------- ]]
	function ACCESS_ResendRanks()
		exsto.SendRanks( player.GetAll() )
	end

--[[ -----------------------------------
	Function: ACCESS_LoadFromULX
	Description: Loads data from ULX
	----------------------------------- ]]
	function ACCESS_LoadFromULX( ply, style )
		
		if file.Exists( "Ulib/users.txt" ) and style == "users" then
			ply:Print( exsto_CLIENT, "UCS --> Loading user information from ULX!" )
			
			local data = file.Read( "Ulib/users.txt" )
			local info = {}
			
			-- lol, start attempt to read a stupid ULX user list, why did they have to make it so dumb?
			for steamID, data in string.gmatch( data, "\"(STEAM_[0-9]:[0-9]:[0-9]-)\"%c-{([%a%c%p%s{}]+)}" ) do
				info[steamID] = {}
				-- Grab all the key entries that don't have tables following them.
				for key, value in string.gmatch( data, "\"(%a-)\"%s-\"(%a-)\"" ) do
					info[steamID][key] = value
				end
			end
			
			for k,v in pairs( info ) do
			
				if exsto.RankExists( v.group ) then -- That rank exists in Exsto!
				
					FEL.AddData( "exsto_data_users", {
						Look = {
							SteamID = k,
						},
						Data = {
							Name = v.name or "Unknown",
							SteamID = k,
							Rank = v.group,
						},
						Options = {
							Update = true,
							Threaded = true,
						},
					} )
					
				end
				
			end
		end
		
		if file.Exists( "Ulib/bans.txt" ) and style == "bans" then
			exsto.Print( exsto_CONSOLE, "UCS --> Loading bans from ULX!" )
			
			local data = file.Read( "Ulib/bans.txt" )
			local info = {}

			for steamID, data in string.gmatch( data, "\"(STEAM_[0-9]:[0-9]:[0-9]-)\"%c-{(.-)}" ) do
				info[steamID] = {}
				-- Grab all the key entries that don't have tables following them.
				for key, value in string.gmatch( data, "\"(.-)\"%s-\"(.-)\"" ) do
					info[steamID][key:gsub( "\'", "" )] = value:gsub( "\'", "" )
				end
			end
			
			for k,v in pairs( info ) do
				local userInfo = info[k]
				local name = v["name"] or "Unknown"
				local reason = v["reason"]
				if reason then
					reason = reason:gsub( "\\", "" )
				end
				
				FEL.AddData( "exsto_data_bans", {
					Look = {
						SteamID = k,
					},
					Data = {
						Name = name,
						SteamID = k,
						Length = v["unban"],
						Reason = reason or "None",
						BannedBy = v["admin"] or "Unknown",
						BannedAt = v["time"],
					},
					Options = {
						Update = true,
						Threaded = true,
					},
				} )
				exsto.Print( exsto_CONSOLE_DEBUG, "Saving data for " .. name or "Unknown" .. "!" )
			end
			
			ply:Print( exsto_CLIENT, "UCS --> Imported all ULX bans to Exsto!" )
		end
		
	end
	concommand.Add( "ACCESS_LoadFromULX", function( ply, _, arg )
		if !ply:IsSuperAdmin() then exsto.Print( exsto_CLIENT, ply, "You are not an admin!" ) return end
		ACCESS_LoadFromULX( ply, arg[1]:Trim():lower() )
	end)
	
	function ACCESS_RecreateRanks( ply )
		ply:Print( exsto_CLIENT, "ACCESS --> Deleting and recreating the rank table!" )
		FEL.Query( "DROP TABLE exsto_data_access;" )
		
		local tblInfo = FEL.CreatedTables["exsto_data_access"]
		
		FEL.MakeTable_Internal( "exsto_data_access", tblInfo )
		
		ACCESS_CreateDefaults()
		ACCESS_LoadFiles()
	end
	concommand.Add( "ACCESS_DeleteAllRanks", function( ply, _, arg )
		if !ply:IsSuperAdmin() then ply:Print( exsto_CLIENT, ply, "You are not an admin!" ) return end
		ACCESS_RecreateRanks( ply )
	end )
	
	ACCESS_LoadController()

end

-- Functions

if SERVER then

--[[ -----------------------------------
	Function: exsto.SetAccess
	Description: Sets a player's rank.
	----------------------------------- ]]
	function exsto.SetAccess( ply, user, short )
	
		if short == "operator" then
			ply:SetOperator()
			exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Giving operator status to ", COLOR.NAME, user:Nick() )
			return
		end
		
		local rank = exsto.Ranks[short]
		
		if !rank then
			local closeRank = exsto.GetClosestString( short, exsto.Ranks, "Short", ply, "Unknown rank" )
			return
		end
		
		exsto.Print( exsto_CHAT_ALL, COLOR.NAME, user:Nick(), COLOR.NORM, " has been given rank ", COLOR.NAME, rank.Name )
		
		user:SetRank( rank.Short )
		
	end
	exsto.AddChatCommand( "rank", {
		Call = exsto.SetAccess,
		Desc = "Sets a user access",
		Console = { "rank" },
		Chat = { "!rank" },
		ReturnOrder = "Victim-Rank",
		Args = {Victim = "PLAYER", Rank = "STRING"},
		Optional = {Rank = "guest"},
		Category = "Administration",
		DisallowOwner = true,
	})
	
--[[ -----------------------------------
	Function: exsto.PrintRank
	Description: Prints a users rank
	----------------------------------- ]]
	function exsto.PrintRank( ply, victim )
		local rank = victim:GetNWString( "ExRankHidden" )
		if rank == "" then rank = victim:GetRank() end
		exsto.Print( exsto_CHAT, ply, COLOR.NAME, victim:Name(), COLOR.NORM, " is a ", COLOR.NAME, rank, COLOR.NORM, "!" )
	end
	exsto.AddChatCommand( "getrank", {
		Call = exsto.PrintRank,
		Desc = "Gets the players rank",
		Console = { "getrank" },
		Chat = { "!getrank" },
		ReturnOrder = "Victim",
		Args = {Victim = "PLAYER"},
		Optional = {Victim = nil},
		Category = "Administration",
	})
	
--[[ -----------------------------------
	Function: exsto.AddUsersOnJoin
	Description: Monitors on join, and prints any relevant information to the chat.
	----------------------------------- ]]
	function exsto.AddUsersOnJoin( ply, steamid, uniqueid )

		local plydata = FEL.LoadUserInfo( ply )

		ply:SetRank( plydata or "guest" )	
		
		if !plydata then
			-- Its his first time here!  Welcome him to the beautiful environment of Exsto.
			ply:Print( exsto_CHAT, COLOR.NORM, "Hello!  This server is proudly running ", COLOR.NAME, "Exsto", COLOR.NORM, "!  For more information, visit the !menu" )
		end

		if !isDedicatedServer() then
			if ply:IsListenServerHost() and not plydata then
				ply:SetNWString( "rank", "superadmin" )
			elseif ply:IsListenServerHost() and ply:GetRank() != "superadmin" then
				-- If hes the host, but has a different rank, we need to give him the option to re-set as superadmin.
				ply:Print( exsto_CHAT, COLOR.NORM, "Exsto seems to have noticed you are the host of this listen server, yet your rank isnt superadmin!" )
				ply:Print( exsto_CHAT, COLOR.NORM, "If you want to reset your rank to superadmin, run this chat command. ", COLOR.NAME, "!updateowner" )
			end
		else
			-- We are running a dedicated server, and someone joined.  Lets check to see if there are any admins.
			if !exsto.AnyAdmins() then
				ply:Print( exsto_CHAT, COLOR.NORM, "Exsto has detected this is a ", COLOR.NAME, "dedicated server environment", COLOR.NORM, ", and there are no superadmins set yet." )
				ply:Print( exsto_CHAT, COLOR.NORM, "If you are the owner of this server, please rcon the following command:" )
				ply:Print( exsto_CHAT, COLOR.NORM, "exsto rank " .. ply:Name() .. " superadmin" )
			end
		end
	
	end
	hook.Add( "exsto_InitSpawn", "exsto_AddUsersOnJoin", exsto.AddUsersOnJoin )
	
--[[ -----------------------------------
	Function: exsto.UpdateOwnerRank
	Description: Updates a player to superadmin if enough info is given.
	----------------------------------- ]]
	function exsto.UpdateOwnerRank( self, rcon, location )
		if !isDedicatedServer() then
			if self:IsListenServerHost() then
				self:SetNWString( "rank", "superadmin" )
				FEL.SaveUserInfo( self )
				
				return { self, COLOR.NORM, "You have reset your rank to ", COLOR.NAME, "superadmin", COLOR.NORM, "!" }
			else
				return { self, COLOR.NORM, "You are not the host of this listen server!" }
			end
		else
			if !self.UpdateRecommendSent then
				self.UpdateRecommendSent = true
				
				self:Print( exsto_CHAT, COLOR.NAME, "Hey!", COLOR.NORM, "  Before you use this command, maybe you just want to set yourself through ", COLOR.NAME, "rcon?" )
				self:Print( exsto_CHAT, COLOR.NORM, "Just run the command as rcon: ", COLOR.NAME, "exsto rank " .. self:Name() .. " superadmin" )
				
				return { self, COLOR.NORM, "If you still want to run the !updateowner command, run it ", COLOR.NAME, "again." }
			end
			
			if rcon == "" then return { self, COLOR.NORM, "No RCON password inputed!" } end
			local rconPass = exsto.ReadRCONPass( location )
			if !rconPass then return { self, COLOR.NORM, "There was an issue reading the RCON pass!" } end
			rconPass = string.Trim( rconPass )
			
			if rconPass == rcon then
				self:SetNWString( "rank", "superadmin" )
				FEL.SaveUserInfo( self )
				
				return { self, COLOR.NORM, "RCON password verified!  Your status has been set as ", COLOR.NAME, "superadmin", COLOR.NORM, "!" }
			else
				return { self, COLOR.NORM, "Bad RCON password!" }
			end
		end
	end
	exsto.AddChatCommand( "updateownerrank", {
		Call = exsto.UpdateOwnerRank,
		Desc = "Updates listen server host's rank.",
		Console = { "updateowner" },
		Chat = { "!updateowner" },
		ReturnOrder = "RCON-Location",
		Args = { RCON = "STRING", Location = "STRING" },
		Optional = { RCON = "", Location = "cfg/server.cfg" },
		Category = "Administration",
	})
	
--[[ -----------------------------------
	Function: exsto.ReadRCONPass
	Description: Reads the rcon pass from a location
	----------------------------------- ]]
	function exsto.ReadRCONPass( location )
		local cfg = file.Read( "../" .. location )
		
		local pass = string.match( cfg, "[%c%s]-rcon_password[%s]-\"([%w%p]-)\"" )
		if !pass then
			pass = string.match( cfg, "[%c%s]-\"rcon_password\"[%s]-\"([%w%p]-)\"" )
		end
		
		return pass
	end
	
--[[ -----------------------------------
	Function: exsto.AnyAdmins
	Description: Checks to see if there are any admin in the data server.
	----------------------------------- ]]
	function exsto.AnyAdmins()
		local plys = FEL.LoadTable( "exsto_data_users" )
		if !plys then return false end
		
		for k,v in pairs( plys ) do
			local rank = exsto.Ranks[v.Rank]
			
			if rank then
				if table.HasValue( rank.Flags, "issuperadmin" ) then return true end
			end
		end
		
		return false
	end
	
--[[ -----------------------------------
	Function: exsto.SendRankData
	Description: Sends the rank table.
	----------------------------------- ]]
	function exsto.SendRankData( ply, sid, uid )
		exsto.SendRankErrors( ply )
		exsto.SendFlags( ply )
		exsto.SendRanks( ply )
	end
	hook.Add( "exsto_InitSpawn", "exsto_SendRankData", exsto.SendRankData )
	concommand.Add( "_ResendRanks", exsto.SendRankData )
	
--[[ -----------------------------------
	Function: exsto.FixInitSpawn
	Description: Pings the client and waits till hes loaded, then calls the exsto_InitSpawn hook.
	----------------------------------- ]]
	local function PingForClient( ply, sid, uid )
		if ply.InitSpawn then -- If the client is clear to load.
			hook.Call( "ExInitSpawn", nil, ply, sid, uid )
			hook.Call( "exsto_InitSpawn", nil, ply, sid, uid ) -- Legacy
		else
			timer.Simple( 0.1, PingForClient, ply, sid, uid )
		end
	end
	
	local function MainLoad( ply, sid, uid )
		if ply:SteamID() == "STEAM_ID_PENDING" or !ply:IsValid() or !ply:IsPlayer() then
			exsto.ErrorNoHalt( ply:Nick() .. " does not have a SteamID!  Waiting a little bit to check again." )
			ply.HasID = false
			timer.Simple( 0.1, MainLoad, ply, sid, uid )
			return
		end
		
		ply.HasID = true	
		uid = tonumber( uid )

		PingForClient( ply, sid, uid )
	end
	
	function exsto.FixInitSpawn( ply, sid, uid )
		MainLoad( ply, sid, uid )
	end
	hook.Add( "PlayerAuthed", "FakeInitialSpawn", exsto.FixInitSpawn )
	
	concommand.Add( "_exstoInitSpawn", function( ply, _, args )
		exsto.Print( exsto_CONSOLE_DEBUG, "InitSpawn --> " .. ply:Nick() .. " is ready for initSpawn!" )
		ply.InitSpawn = true
	end )
	
	hook.Add( "PlayerInitialSpawn", "PlayerAuthSpawn", function() end )
	
--[[ -----------------------------------
	Function: player:SetRank
	Description: Sets a player's rank.
	----------------------------------- ]]
	function _R.Player:SetRank( rank )
		if self:IsOperator() then self.ExOperator = false end
		self:SetNetworkedString( "rank", rank )
		FEL.SaveUserInfo( self )
		hook.Call( "ExSetRank", nil, self, rank )
	end
	
--[[ -----------------------------------
	Function: player:SetUserGroup
	Description: Sets a player's usergroup.
	----------------------------------- ]]
	function _R.Player:SetUserGroup( rank )
		self:SetRank( rank )
	end
	
--[[ -----------------------------------
	Function: player:SetOperator
	Description: Gives a player operator status.
	----------------------------------- ]]
	function _R.Player:SetOperator()
		self.ExOperator = true
	end
	
--[[ -----------------------------------
	Function: player:IsOperator
	Description: Returns operator status.
	----------------------------------- ]]
	function _R.Player:IsOperator()
		return self.ExOperator
	end

elseif CLIENT then
	
	-- exsto_InitSpawn client call.  Instead of assuming when the client is active, we can use this to call the hook.  Allows for awesomeness.
	hook.Add( "ExInitialized", "exsto_InitSpawnClient", function()
		RunConsoleCommand( "_exstoInitSpawn" )
	end )
	
end

--[[ -----------------------------------
	Function: exsto.GetRankData
	Description: Returns the rank information based on short or name.
	----------------------------------- ]]
function exsto.GetRankData( rank )
	for k,v in pairs( exsto.Ranks ) do
		if v.Short == rank or v.Name == rank then return v end
	end
	return nil
end

--[[ -----------------------------------
	Function: exsto.GetRankColor
	Description: Returns the rank color, or white if there is none.
	----------------------------------- ]]
function exsto.GetRankColor( rank )
	for k,v in pairs( exsto.Ranks ) do
		if v.Short == rank or v.Name == rank then return v.Color end
	end
	return Color( 255, 255, 255, 255 )	
end

--[[ -----------------------------------
	Function: exsto.RankExists
	Description: Returns true if a rank exists
	----------------------------------- ]]
function exsto.RankExists( rank )
	if exsto.Ranks[rank] then return true end
	return false
end

--[[ -----------------------------------
	Function: player:IsAllowed
	Description: Checks to see if a player has a flag, and is immune
	----------------------------------- ]]
function _R.Player:IsAllowed( flag, victim )
	if self:EntIndex() == 0 then return true end -- If we are console :3
	if !CLIENT and self:IsOperator() then return true end -- If we are operatoring.

	local rank = exsto.GetRankData( self:GetRank() )
	
	if !rank then return false end
	
	if victim then
	
		local victimRank = exsto.GetRankData( victim:GetRank() )
		if !rank.Immunity or !victimRank.Immunity then -- Just ignore it if they don't exist, we don't want to break Exsto.
			if table.HasValue( rank.AllFlags, flag ) then return true end
		elseif rank.Immunity <= victimRank.Immunity then
			if table.HasValue( rank.AllFlags, flag ) then return true end
		else
			return false, "immunity"
		end
	else
		if table.HasValue( rank.AllFlags, flag ) then return true end
	end
	
	return false
end

--[[ -----------------------------------
	Function: player:GetRank
	Description: Returns the rank of a player.
	----------------------------------- ]]
function _R.Player:GetRank()
	if !CLIENT and self:IsOperator() then return "operator" end

	local rank = self:GetNetworkedString( "rank" )
	
	if rank == "" then return "guest" end
	if !rank then return "guest" end
	if !exsto.RankExists( rank ) then return "guest" end
	
	return rank
end

--[[ -----------------------------------
	Function: player:IsAdmin
	Description: Returns true if the player is an admin
	----------------------------------- ]]
function _R.Player:IsAdmin()
	if !CLIENT and self:IsOperator() then return true end
	if self:EntIndex() == 0 then return true end -- If we are console :3
	if self:IsAllowed( "isadmin" ) then return true end
	if self:IsSuperAdmin() then return true end
	return false
end

--[[ -----------------------------------
	Function: player:IsSuperAdmin
	Description: Returns true if the player is a superadmin
	----------------------------------- ]]
function _R.Player:IsSuperAdmin()
	if !CLIENT and self:IsOperator() then return true end
	if self:EntIndex() == 0 then return true end -- If we are console :3
	if self:IsAllowed( "issuperadmin" ) then return true end
	return false
end

--[[ -----------------------------------
	Function: player:IsUserGroup
	Description: Checks if a player is a rank.
	----------------------------------- ]]
function _R.Player:IsUserGroup( id )	
	return self:GetRank() == id
end