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

-- FEL

FEL = {}

	FEL.CreatedTables = {}
	FEL.Settings = {}
	FEL.Queue = {}
	FEL.ErrorTable = {}
	
	FEL.Database = 0
	FEL.QueryObj = 0

if SERVER then
	if !mysqloo then require( "mysqloo" ) end
	if !mysql then require( "mysql" ) end

	-- Functions

--[[ -----------------------------------
	Function: FEL.Init
	Description: Loads up the File Exstension Library
     ----------------------------------- ]]
	local function mysqlConnect( disableStatus )
		if !mysqloo then
			exsto.Print( exsto_ERRORNOHALT, "FEL --> Couldn't locate MySQL library!  Falling back to SQL!" )
			if mysql then
				-- We seem to have the other module...
				exsto.Print( exsto_ERRORNOHALT, "FEL --> It seems that you have the wrong MySQL module installed.  Please use the MySQLoo module!" )
			end
			FEL.Settings["MySQL"] = false
		else
			FEL.Database = mysqloo.connect( FEL.Settings["Host"], FEL.Settings["Username"], FEL.Settings["Password"], FEL.Settings["Database"], 3306 )
			FEL.Database:connect()
			FEL.Database:wait()

			if FEL.Database:status() == mysqloo.DATABASE_NOT_CONNECTED or FEL.Database:status() == mysqloo.DATABASE_INTERNAL_ERROR then
				exsto.Print( exsto_ERRORNOHALT, "FEL --> Couldn't connect to MySQL server!  Falling back to SQL!" )
				FEL.Settings["MySQL"] = false
			elseif FEL.Database:status() == mysqloo.DATABASE_CONNECTED and not disableStatus then
				exsto.Print( exsto_CONSOLE, "FEL --> Running under MySQL, DLL version " .. mysqloo.VERSION .. ", Server version " .. FEL.Database:serverVersion() .. "!" )
			end
		end
	end
	
	function FEL.Init()

		-- Lets load our settings file first!
		if !file.Exists( "exsto_settings.txt" ) then
			local data = [[
	[settings = FEL]
		MySQL		=	false
		Host			=	localhost
		Username		=	root
		Password		=	password
		Database		=	testing
	[/settings]
	]]
			file.Write( "exsto_settings.txt", data )
		end
		
		local data = file.Read( "exsto_settings.txt" ):Trim()
		
		for k,v in string.gmatch( data, "%[settings%s-=([%w%s%p]-)%](.-)%[/settings%]" ) do
			for k,v in string.gmatch( v, "([%w%p]+)%s+=%s+([%w%p]+)" ) do
				FEL.Settings[k:Trim()] = exsto.FormatValue( v:Trim(), exsto.ParseVarType( v:Trim() ) )
			end
		end				

		if FEL.Settings["MySQL"] then
			mysqlConnect()
		else
			exsto.Print( exsto_CONSOLE, "FEL --> Running under SQLite!" )
		end
	end

--[[ -----------------------------------
	Function: mysqlQuery
	Description: Helper function to query MySQL.
     ----------------------------------- ]]
	local function onError( err )
		FEL.PrintError( {
			MySQL = true,
			Running = run,
			Error = tostring( err ),
		} )
	end

	local function mysqlQuery( run, threaded, callback, print )

		if FEL.Database:status() != mysqloo.DATABASE_CONNECTED then 
			-- Check if we actually are enabled first.
			if FEL.Settings["MySQL"] then
				-- We probably disconnected.  Re-establish.
				exsto.Print( exsto_ERRORNOHALT, "FEL --> Connection lost to MySQL server.  Attempting to reconnect." )
				mysqlConnect( true )
				
				-- Check again, is the SQL server down this time?  Our settings should be false if it is.
				if !FEL.Settings["MySQL"] then return sqliteQuery( run ) end
				exsto.Print( exsto_CONSOLE, "FEL --> Reconnected to MySQL!" )
			end
		end

		FEL.QueryObj = FEL.Database:query( run )
		FEL.QueryObj:start()
		
		if print then FEL.QueryObj.OnFailure = onError end
		
		-- Check to make sure we are threaded, we don't want to halt up the server!
		if threaded then
			FEL.QueryObj.onSuccess = function()
				if type( callback ) != "function" then return end
				callback( FEL.QueryObj:getData() )
			end
			return
		end
		
		FEL.QueryObj:wait()
		
		local data = FEL.QueryObj:getData()
		
		FEL.QueryObj = nil
		
		if type( data ) != "table" then
			MsgN( tostring( run ) or "UNKNOWN RUN QUERY" )
			return nil
		end

		if table.Count( data ) < 1 then return nil end
		return data		
	end

--[[ -----------------------------------
	Function: sqliteQuery
	Description: Helper function to query into SQLite
     ----------------------------------- ]]
	local function sqliteQuery( run, print )
		local result = sql.Query( run )
			
		if result == false and print then
		
			FEL.PrintError( {
				SQLite = true,
				Running = run,
				Error = sql.LastError( result )
			} )
			
		end
		return result
	end

--[[ -----------------------------------
	Function: FEL.Query
	Description: Main query, returns data from SQL query
     ----------------------------------- ]]
	function FEL.Query( run, threaded, callback, printerror )
		local h = { hook.Call( "ExFELQuery", nil, run, FEL.Settings["MySQL"], threaded, callback, printerror ) }
		if h == false then
			return h[2]
		end
		
		if FEL.Settings["MySQL"] then
			if !mysqloo then
				exsto.Print( exsto_ERRORNOHALT, "FEL --> Couldn't locate MySQL library!  Falling back to SQL!" )
				FEL.Settings["MySQL"] = false
				
				return sqliteQuery( run, printerror )
			else	
				return mysqlQuery( run, threaded, callback, printerror )
			end
		else
			return sqliteQuery( run, true )
		end
	end
	
--[[ -----------------------------------
	Function: FEL.MySQLHeartbeat
	Description: Pings the MySQL server every 30 minutes to prevent going away.
     ----------------------------------- ]]
	function FEL.MySQLHeartbeat()
	
		-- If we are in MySQL
		if FEL.Settings["MySQL"] then 
			FEL.Query( "SELECT 1 + 1;", true )
		end
		
	end
	timer.Create( "FEL_MySQLHeartbeat", 5 * 60, 0, FEL.MySQLHeartbeat )

--[[ -----------------------------------
	Function: FEL.PrintError
	Description: Prints an error recieved from the FEL.Query
     ----------------------------------- ]]
	function FEL.PrintError( info )
		ErrorNoHalt( "\n---- FEL SQL Error ----\n ** Running - " .. info.Running .. " \n ** Error Msg - " .. info.Error .. "\n" );
	end
	
--[[ -----------------------------------
	Function: FEL.Escape
	Description: Makes a string nice.
     ----------------------------------- ]]
	function FEL.Escape( str )
		if FEL.Settings["MySQL"] then
			return "'" .. FEL.Database:escape( str ) .. "'"
		else
			return SQLStr( str )
		end
	end
	
--[[ -----------------------------------
	Function: FEL.CheckTable
	Description: Checks a table to see if it has all the correct columns.  Will recreate if not.
     ----------------------------------- ]]
	function FEL.CheckTable( name, data, options )
	
		local tbl = FEL.Query( "SELECT * FROM " .. name .. ";", nil, nil, false )
		local cachedData = glon.decode( file.Read( "exsto_felcache/" .. name .. "_cache.txt" ) or "" )
		
		if !tbl then return false end
		
		if !cachedData or cachedData == "" then
			exsto.Print( exsto_CONSOLE, "FEL --> No cached data exists for table '" .. name .. "'.  Dropping and updating to support new Exsto format." )
			FEL.Query( "DROP TABLE " .. name .. ";" )
			file.Write( "exsto_felcache/" .. name .. "_cache.txt", glon.encode( { data, options } ) )
			return tbl
		end
		
		local currentColumns = {}
		for column, _ in pairs( data ) do
			currentColumns[ column ] = _
		end

		local prevColumns = {}
		for column, _ in pairs( tbl[1] ) do
			prevColumns[ column ] = _
		end
		
		local changedData = {}
		
		-- Check if we removed any columns
		for column, dataType in pairs( prevColumns ) do
			if !currentColumns[ column ] then
				-- We removed a column.  Add it.
				print( "Saved data contains extra " .. column )
				table.insert( changedData, { Type = "remove", Column = column } )
			end
		end
		
		-- Check if we add any columns
		for column, dataType in pairs( currentColumns ) do
			if !prevColumns[ column ] then
				-- We added one.  Add it.
				print( "Saved data doesn't contain " .. column .. ".  Adding" )
				table.insert( changedData, { Type = "add", Column = column, Data = dataType } )
			end
		end
				
		-- Check if we changed any datatypes.
		for column, dataType in pairs( data ) do
			if !table.HasValue( cachedData[1], dataType ) then
				-- Data type updated.  Fix it.
				table.insert( changedData, { Type = "dt", Column = column, Data = dataType } )
			end
		end

		-- Our settings table changed.
		if type( cachedData[2] ) != "table" and table.Count( options ) != 0 then
			cachedData[2] = {}
			table.insert( changedData, { Type = "options" } )
		end
		
		-- Check options
		if cachedData[2] then
			if !cachedData[2].PrimaryKey and options.PrimaryKey then -- We added a primary key!
				table.insert( changedData, { Type = "pk", Data = options.PrimaryKey } )
			end
		end

		-- Finally commit our changes
		if table.Count( changedData ) != 0 then
			local begin = "ALTER TABLE " .. name 
			for _, data in ipairs( changedData ) do
				if data.Type == "remove" then
					FEL.Query( begin .. " DROP COLUMN " .. data.Column .. ";" )
				elseif data.Type == "add" then
					FEL.Query( begin .. " ADD " .. data.Column .. " " .. data.Data .. ";" )
				elseif data.Type == "dt" then
					FEL.Query( begin .. " ALTER COLUMN " .. data.Column .. " " .. data.Data .. ";" )
				elseif data.Type == "pk" then
					FEL.Query( begin .. " ADD PRIMARY KEY (" .. data.Data .. ");" )
				end
			end
			
			exsto.Print( exsto_CONSOLE, "FEL --> Updating file cache for '" .. name .. "'" )
			
			file.Write( "exsto_felcache/" .. name .. "_cache.txt", glon.encode( { data, options } ) )
			
			-- Tell the internal table maker to stop.  We don't need to perform the rest of his code.
			return true
		end
	
	end

--[[ -----------------------------------
	Function: FEL.MakeTable_Internal
	Description: Creates a table
     ----------------------------------- ]]
	function FEL.MakeTable_Internal( name, data, options )

		if type( data ) != "table" then exsto.Error( "Error while trying to create table " .. name .. "!  Data variable is not a table!" ) return end
		if type( name ) != "string" then exsto.Error( "Error while trying to create table " .. name .. "!  Name variable is not a string!" ) return end

		local columns = "";
		local num = exsto.SmartNumber( data )
		local curSlot = 1
		
		options = options or {}
		
		-- Check and make sure if there is an existing table, and it is up to date.
		local savedInfo = FEL.CheckTable( name, data, options )
		if savedInfo == true then return end -- We don't need to create the table if it already exists...
		
		for k,v in pairs( data ) do
			
			if curSlot == num then
				columns = string.format( "%s%s %s", columns, k, v )
			else
				columns = string.format( "%s%s %s, ", columns, k, v )
			end
			
			curSlot = curSlot + 1
			
		end

		local query = string.format( "CREATE TABLE IF NOT EXISTS %s (%s", name, columns );
		
		-- Check our options.
		if options then
			if options.PrimaryKey then
				query = query .. ", PRIMARY KEY (" .. options.PrimaryKey .. ")" 
			end
		end
		FEL.Query( query .. ");" );
		exsto.Print( exsto_CONSOLE_DEBUG, "FEL --> Creating table " .. name .. "!" )
		
		-- Save the data if the table had to be broken down.
		if savedInfo then 
			for k,v in pairs( savedInfo ) do
				FEL.AddData( name, {
					Data = v,
				} )
			end
		end
		
	end

--[[ -----------------------------------
	Function: FEL.MakeTable
	Description: Creates a table and inserts it into the Exsto list of tables.
     ----------------------------------- ]]
	function FEL.MakeTable( name, data, options )
		FEL.CreatedTables[name] = data;
		FEL.MakeTable_Internal( name, data, options )
	end

--[[ -----------------------------------
	Function: FEL.DeleteTable
	Description: Deletes a table created by FEL
     ----------------------------------- ]]
	function FEL.DeleteTable( ply, _, args )
		local tbl = args[1]
		if ply:IsSuperAdmin() then
			if FEL.CreatedTables[tbl] then	
				FEL.Query( "DROP TABLE " .. tbl .. ";", true )			
			else	
				exsto.Print( exsto_CLIENT, ply, "No table called " .. tbl .. "!" )	
			end
		end	
	end
	concommand.Add( "FEL_DeleteTable", FEL.DeleteTable )

--[[ -----------------------------------
	Function: FEL.LoadData
	Description: Loads a select data from a table where a value is another value.
     ----------------------------------- ]]
	function FEL.LoadData( tab, select, where, where_data  )
		local syntax = "SELECT " .. select .. " FROM " .. tab
		if where and where_data then
			if type( where_data ) == "string" then where_data = FEL.Escape( where_data ) end
			
			syntax = syntax .. " WHERE " .. where .. " = " .. where_data
		end
		syntax = syntax .. ";"

		local data = FEL.Query( syntax )

		if data then for k,v in pairs( data[1] ) do return v end end	
		return
	end

--[[ -----------------------------------
	Function: FEL.Query
	Description: Main query, returns data from SQL query
     ----------------------------------- ]]
	function FEL.LoadTable( tab, threaded, callback, printerr )
		return FEL.Query( "SELECT * FROM " .. tab .. ";", threaded, callback, printerr )
	end

--[[ -----------------------------------
	Function: FEL.AddData
	Description: Inserts data into a table.
     ----------------------------------- ]]
	function FEL.AddData( tab, info )

		local look = nil
		local data = nil
		if info.Look then
			for k,v in pairs( info.Look ) do
				look = k
				data = v
			end
		end

		local style = "INSERT INTO %s"
		local syntax = "%s (%s) VALUES(%s);"
		local update = false
		local args = ""
		
		local options = info.Options or {}

		local item
		if info.Look then
			item = FEL.DataExists( tab, look, data )
			if item and options.Update == false then return end
		end
		
		if item then
			update = true
			style = "UPDATE %s SET"
			syntax = "%s %s WHERE %s = %s;"
		end
		
		style = string.format( style, tab )

		if !update then

			local build = ""
			local cur = 1
			local format
			for k,v in pairs( info.Data ) do
				
				format = "%s%s, "
				if table.Count( info.Data ) == cur then
					format = "%s%s"
				end
				
				build = string.format( format, build, k )
				cur = cur + 1
			end
			
			syntax = string.format( syntax, style, build, "%s" )
		else
			syntax = string.format( syntax, style, "%s", "%s", "%s" )
		end

		local cur = 1
		for k,v in pairs( info.Data ) do
			
			if type( v ) == "string" then v = FEL.Escape( v ) end
			if type( v ) == "boolean" then v = FEL.Escape( tostring( v ) ) end
			
			format = "%s%s, "
			
			-- UPDATE table SET %s WHERE %s = %s;
			if update then
				format = "%s%s = %s, "
				if table.Count( info.Data ) == cur then
					format = "%s%s = %s"
				end
				
				args = string.format( format, args, k, v )
			else
				if table.Count( info.Data ) == cur then
					format = "%s%s"
				end
				
				args = string.format( format, args, v )
			end
			cur = cur + 1
		end

		if update and type( data ) == "string" then data = FEL.Escape( data ) end
		
		if update then
			syntax = string.format( syntax, args, look, data )
		else
			syntax = string.format( syntax, args )
		end

		return FEL.Query( syntax, options.Threaded, options.Callback )
	end	

--[[ -----------------------------------
	Function: FEL.SaveUserInfo
	Description: Saves a player's information
     ----------------------------------- ]]
	function FEL.SaveUserInfo( ply )

		local nick = ply:Nick()
		local steamID = ply:SteamID()

		FEL.AddData( "exsto_data_users", {
			Look = {
				SteamID = steamID,
			},
			Data = {
				Name = nick,
				SteamID = steamID,
				Rank = ply:GetRank(),
//				UserFlags = FEL.NiceEncode( ply.ExUserFlags or {} )
			},
			Options = {
				Threaded = true,
				Update = true,
			}
		} )
	end

--[[ -----------------------------------
	Function: FEL.LoadUserInfo
	Description: Loads user's information
     ----------------------------------- ]]
	function FEL.LoadUserInfo( ply )
		local data = FEL.Query( "SELECT Rank FROM exsto_data_users WHERE SteamID = " .. FEL.Escape( ply:SteamID() ) .. ";" )
		if type( data ) == "table" then data = data[1] else data = {} end
		return data.Rank, data.UserFlags
	end

--[[ -----------------------------------
	Function: FEL.SaveBanInfo
	Description: Saves a player's banned information.
     ----------------------------------- ]]
	function FEL.SaveBanInfo( ply, len, reason, banned_by, time )
	
		local name, id
		if type( ply ) == "Player" then
			name, id = ply:Name(), ply:SteamID()
		else
			name, id = ply[1], ply[2]
		end
		
		FEL.AddData( "exsto_data_bans", {
			Look = {
				SteamID = id,
			},
			Data = {
				Name = name,
				SteamID = id,
				Length = len,
				Reason = reason,
				BannedBy = banned_by:Nick() or "Console",
				BannedAt = time,
			},
			Options = {
				Threaded = true,
				Update = true,
			}
		} )
		exsto.Print( exsto_CONSOLE_DEBUG, "Saving data for " .. name .. "(" .. id .. ") !" )
		
	end

--[[ -----------------------------------
	Function: FEL.LoadBanInfo
	Description: Loads user ban information.
     ----------------------------------- ]]
	function FEL.LoadBanInfo( SteamID )
		
		local data = FEL.Query( "SELECT Length, BannedAt FROM exsto_data_bans WHERE SteamID = " .. FEL.Escape( SteamID ) .. ";" )
		
		local time = data.Length
		local bantime = data.BannedAt
		
		return time, bantime
		
	end

--[[ -----------------------------------
		FEL Helper Functions
     ----------------------------------- ]]
	function FEL.DataExists( tab, where, value )

		if type( value ) == "string" then value = FEL.Escape( value ) end

		return FEL.Query( "SELECT " .. where .. " FROM " .. tab .. " WHERE " .. where .. " = " .. value.. ";" )
	end

	function FEL.VerifyData( tab, column, value )

		if type( value ) == "string" then value = FEL.Escape( value ) end

		return FEL.Query( "SELECT " .. column .. " FROM " .. tab .. " WHERE " .. column .. " = " .. value .. ";" )
	end

	function FEL.RemoveData( tab, column, value )

		if type( value ) == "string" then value = FEL.Escape( value ) end

		return FEL.Query( "DELETE FROM " .. tab .. " WHERE " .. column .. " = " .. value .. ";", true )
	end

--[[ -----------------------------------
	Function: FEL.ConvertToDatabase
	Description: Converts a database to one style.
     ----------------------------------- ]]
	function FEL.ConvertToDatabase( style )
		style = style:lower():Trim()
		
		if !mysql then exsto.ErrorNoHalt( "Couldn't transfer to MySQL, couldn't find the module!" ) return end
		
		exsto.Print( exsto_CONSOLE, "FEL --> Currently transfering data to a new database style.  The server might lock up, don't panic!" )
		local query = mysqlQuery
		local endQuery = sqliteQuery
		
		if style == "mysql" then 
			query = sqliteQuery
			endQuery = mysqlQuery
			
			-- We need to connect to MySQL if hes not already.
			if FEL.Database == 0 then
				FEL.Database, error = mysql.connect( FEL.Settings["Host"], FEL.Settings["Username"], FEL.Settings["Password"], FEL.Settings["Database"] )
				if FEL.Database == 0 then
					exsto.ErrorNoHalt( "Couldn't connect to the MySQL server for transfer, aborting!" )
					return
				end
			end
		end
		
		local loadedData = {}
		for k,v in pairs( FEL.CreatedTables ) do
			exsto.Print( exsto_CONSOLE, "FEL --> Loading data out of " .. k .. "!" )
			
			local data = query( "SELECT * FROM " .. k .. ";" )
			
			loadedData[k] = data
		end
		
		exsto.Print( exsto_CONSOLE, "FEL --> Finished loading data, transfering into new tables." )
		
		-- For now, we need to just switch FEL.Query for a moment.
		local oldFELQuery = FEL.Query
		FEL.Query = endQuery
		for k,v in pairs( loadedData ) do
			exsto.Print( exsto_CONSOLE, "FEL --> Saving data into " .. k .. "!" )
			FEL.Query( "DROP TABLE " .. k .. "; " )
			
			FEL.MakeTable( k, FEL.CreatedTables[k] )
			
			for _,v in pairs( v ) do
				FEL.AddData( k, {
					Data = v,
					Options = {
						Update = true,
					}
				} )
			end
		end
		-- Done, move back FEL.Query
		FEL.Query = oldFELQuery
		
		exsto.Print( exsto_CONSOLE, "FEL --> Finished converting database!" )
		
	end
	concommand.Add( "FEL_ConvertDatabase", function( ply, _, args )
		if !ply:IsSuperAdmin() then exsto.Print( exsto_CLIENT, ply, "You are not admin!" ) return end
		FEL.ConvertToDatabase( args[1] )
	end )

--[[ -----------------------------------
	Function: FEL.DropAllTables
	Description: Cleans all tables from FEL and drops them.
     ----------------------------------- ]]
	function FEL.DropAllTables()

		for k,v in pairs( FEL.CreatedTables ) do
			FEL.Query( "DROP TABLE " .. k .. ";", true )
		end
		
	end
	concommand.Add( "FEL_DropAllTables", function( ply, _, args )
		if !ply:IsSuperAdmin() then exsto.Print( exsto_CLIENT, ply, "You are not admin!" ) return end
		FEL.DropAllTables()
	end )
		
	FEL.Init()

	FEL.MakeTable( "exsto_data_users", {
			SteamID = "varchar(255)",
			Name = "varchar(255)",
			Rank = "varchar(255)",
		},
		{
			PrimaryKey = "SteamID",
		}
	)

	FEL.MakeTable( "exsto_data_bans", {
			Name = "varchar(255)",
			SteamID = "varchar(255)",
			Length = "int",
			Reason = "varchar(255)",
			BannedBy = "varchar(255)",
			BannedAt = "int",
		},
		{
			PrimaryKey = "SteamID",
		}
	)
		
end

--[[ -----------------------------------
	Function: FEL.NiceColor
	Description: Makes a color nice.
     ----------------------------------- ]]
function FEL.NiceColor( color )
	return "[c=" .. color.r .. "," .. color.g .. "," .. color.b .. "," .. color.a .. "]"
end

--[[ -----------------------------------
	Function: FEL.MakeColor
	Description: Makes a nice color a color.
     ----------------------------------- ]]
function FEL.MakeColor( str )
	local startCol, endCol, r, g, b, a = string.find( str, "%[c=(%d+),(%d+),(%d+),(%d+)%]" )
	if startCol then
		return Color( tonumber( r ), tonumber( g ), tonumber( b ), tonumber( a ) )
	else
		return Color( 255, 255, 255, 255 )
	end
end

--[[ -----------------------------------
	Function: FEL.NiceEncode
	Description: Encodes a table to a readable string.
     ----------------------------------- ]]
function FEL.NiceEncode( data )
	
	local form = type( data )
	local encoded = "[form=" .. form .. "]";
	local oldData = data
	
	if form == "Vector" then
		data = {}
			data[1] = oldData.x
			data[2] = oldData.y
			data[3] = oldData.z
	elseif form == "Angle" then
		data = {}
			data[1] = oldData.p
			data[2] = oldData.y
			data[3] = oldData.r
	end

	if !type( data ) == "table" then exsto.ErrorNoHalt( "Unknown data format!" ) return end
	
	local index = 0
	local stringIndex = false
	local cur = 1
	for k,v in pairs( data ) do

		index = cur
		if type( k ) == "string" then index = k stringIndex = true end
		encoded = encoded .. "["..index.."]" .. tostring( v )
		
		cur = cur +1
	end
	encoded = encoded .. "[/form, " .. index .. ", " .. tostring( stringIndex ) .. "]"
	
	return encoded
end

--[[ -----------------------------------
	Function: FEL.NiceDecode
	Description: Decodes a nice string into a table
     ----------------------------------- ]]
function FEL.NiceDecode( str )
	
	local startPos, endPos, startTag, form = string.find( str, "(%[form=(%a+)%])" )
	local endStart, endEnd, endTag, count, stringIndex = string.find( str, "(%[/form, (%d+), (%a+)%])" )
	
	if !startPos or !endStart then
		exsto.ErrorNoHalt( "Couldn't decode, no START found!" )
		return
	end
	
	if !form then exsto.ErrorNoHalt( "Couldn't locate decoding form!" ) return end
	if !stringIndex then exsto.ErrorNoHalt( "Couldn't tell if decoding a stringed index!" ) return end
	if !count then exsto.ErrorNoHalt( "Couldn't count the amount of data in the encoded string!" ) return end
	
	count = tonumber( count )
	stringIndex = tobool( stringIndex )

	local sub = string.sub( str, endPos + 1, endStart - 1 )
	local data = {}
	
	for k,v in string.gmatch( sub, "%[([%d%%.]+)%]([%a%d-%._]+)" ) do
		if !stringIndex then
			data[tonumber(k)] = v
		else
			data[k] = v
		end
	end

	if form == "table" then 
		return data
	elseif form == "Vector" then
		return Vector( data[1], data[2], data[3] )
	elseif form == "Angle" then
		return Angle( data[1], data[2], data[3] )
	end
	
	return data
	
end

--[[ -----------------------------------
	Function: FEL.FindTableDifference
	Description: Finds a difference in a table.
     ----------------------------------- ]]
function FEL.FindTableDifference( original, new )

	local addTo = {}
	
	local tableChanged = false
	
	-- First, we need to check the original to see if hes missing any from new.
	for k,v in pairs( original ) do
		if !table.HasValue( new, k ) then
			tableChanged = true
			-- Hes mising a flag!
			addTo[k] = v
		end
	end
	
	if tableChanged then	
		return addTo
	end

end

--[[ -----------------------------------
	Function: FEL.LoadSettingsFile
	Description: Loads a file with settings in it.
     ----------------------------------- ]]
function FEL.LoadSettingsFile( id )
	
	if file.Exists( id .. ".txt" ) then
		
		local data = file.Read( id .. ".txt" ):Trim()

		local strStart, strEnd, strType = string.find( data, "%[settings%s-=%s-\"([%w%s%p]-)\"%]" )
		local endStart, endEnd = string.find( data, "%[/settings%]" )
		
		if !strStart or !endStart then exsto.ErrorNoHalt( "FEL --> Error loading " .. id .. ".  No settings start!" ) return end
		
		local sub = string.sub( data, strEnd + 1, endStart - 1 ):Trim()
		local capture = string.gmatch( sub, "([%w%p]+)%s+=%s+([%w%p]+)" )
		
		local tbl = {}
		for k,v in capture do
			local type = exsto.ParseVarType( v:Trim() )
			tbl[k:Trim()] = exsto.FormatValue( v:Trim(), type )
		end
		
		return tbl
		
	else
		return {}
	end
	
end

--[[ -----------------------------------
	Function: FEL.CreateSettingsFile
	Description: Creates a .txt settings file.
     ----------------------------------- ]]
function FEL.CreateSettingsFile( id, tbl )
	local readData	
	local header = "[settings = \"" .. id .. "\"]"
	local body = ""
	local footer = "[/settings]"

	for k,v in pairs( tbl ) do
		body = body .. k .. " = " .. tostring( v ) .. "\n"
	end
	
	local data = header .. "\n" .. body .. footer
	
	file.Write( id .. ".txt", data )
end

--[[ -----------------------------------
	Function: FEL.DumpErrorLog
	Description: Dumps all known errors to a .txt file.
     ----------------------------------- ]]
function FEL.DumpErrorLog()

	local data = "************ EXSTO ERROR LOG ************\n"
	
	for k,v in pairs( FEL.ErrorTable ) do
		data = data .. "[" .. k .. "] " .. v .. "\n"
	end
	
	file.Write( "exsto_error_dump.txt", data )
	
	if SERVER then
		-- Dump the SQL tables.
		for k,v in pairs( FEL.CreatedTables ) do
			FEL.LoadTable( k, true, function( query )
				file.Write( "dump_" .. k .. ".txt", query:getData() )
			end )
		end
	end
	
end
concommand.Add( "FEL_DumpErrors", FEL.DumpErrorLog )