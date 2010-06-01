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
	
	local settingParse = {
		["FEL"] = function( v )
					local capture = string.gmatch( v, "([%w%p]+)%s+=%s+([%w%p]+)" )
					for k,v in capture do
						local type = exsto.ParseVarType( v:Trim() )
						FEL.Settings[k:Trim()] = exsto.FormatValue( v:Trim(), type )
					end
				end,
	}
	
	FEL.Database = 0

	FEL.Queue = {}
	
	FEL.ErrorTable = {}

if SERVER then
	--require( "mysqloo" )
	require( "mysql" )
	
	local query = sql.Query

	-- Functions

--[[ -----------------------------------
	Function: FEL.Init
	Description: Loads up the File Exstension Library
     ----------------------------------- ]]
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
		local strStart, strEnd, strType = string.find( data, "%[settings%s-=([%w%s%p]-)%]" )
		local endStart, endEnd = string.find( data, "%[/settings%]" )
		
		if !strStart or !endStart then print( "no!") return end
		
		local sub = string.sub( data, strEnd + 1, endStart - 1 ):Trim()
		
		settingParse[strType:Trim()](sub)

		if FEL.Settings["MySQL"] then
			if !mysql then
				exsto.Print( exsto_CONSOLE, "FEL --> Couldn't locate MySQL library!  Falling back to SQL!" )
				FEL.Settings["MySQL"] = false
			else
				--[[FEL.Database = mysqloo.connect( FEL.Settings["Host"], FEL.Settings["Username"], FEL.Settings["Password"], FEL.Settings["Database"], 3306 )
				FEL.Database:connect()
				--FEL.Database:wait()

				if FEL.Database:status() == mysqloo.DATABASE_NOT_CONNECTED or FEL.Database:status() == mysqloo.DATABASE_INTERNAL_ERROR then
					exsto.Print( exsto_CONSOLE, "FEL --> Couldn't connect to MySQL server!  Falling back to SQL!" )
					FEL.Settings["MySQL"] = false
				end]]
				
				FEL.Database, error = mysql.connect( FEL.Settings["Host"], FEL.Settings["Username"], FEL.Settings["Password"], FEL.Settings["Database"] )
				if FEL.Database == 0 then
					exsto.Print( exsto_CONSOLE, "FEL --> Couldn't connect to MySQL server!  Falling back to SQL!" )
					FEL.Settings["MySQL"] = false
				else
					exsto.Print( exsto_CONSOLE, "FEL --> Running under MySQL!" )
				end
			end
		end
	end

--[[ -----------------------------------
	Function: mysqlQuery
	Description: Helper function to query MySQL.
     ----------------------------------- ]]
	local function mysqlQuery( run, threaded )
		local data, success, err = mysql.query( FEL.Database, run, mysql.QUERY_FIELDS )
		
		--[[if FEL.Database:status() != mysqloo.DATABASE_CONNECTED then return nil end
		
		local query = FEL.Database:query( run )
		query:start()
		
		query.OnFailure = function( err ) 
			FEL.PrintError( {
				MySQL = true,
				Running = run,
				Error = tostring( err ),
			} )
		end
		
		-- Check to make sure we are threaded, we don't want to halt up the server!
		if !threaded then
			query:wait()
		end
		
		local data = query:getData()]]
		
		if err != "OK" then
			FEL.PrintError( {
				MySQL = true,
				Running = run,
				Error = tostring( err ),
			} )
			return false
		end

		if table.Count( data ) < 1 then return nil end
		return data		
	end

--[[ -----------------------------------
	Function: sqliteQuery
	Description: Helper function to query into SQLite
     ----------------------------------- ]]
	local function sqliteQuery( run )
		local result = sql.Query( run )
			
		if result == false then
		
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
	function FEL.Query( run, treaded )

		exsto.Print( exsto_CONSOLE_DEBUG, "FEL --> Running - " .. run )
		
		if FEL.Settings["MySQL"] then
		
			if !mysql then
				exsto.Print( exsto_CONSOLE, "FEL --> Couldn't locate MySQL library!  Falling back to SQL!" )
				FEL.Settings["MySQL"] = false
			else
				
				return mysqlQuery( run, threaded )
			end
			
		else

			return sqliteQuery( run )
			
		end
		
	end
	
--[[ -----------------------------------
	Function: FEL.MySQLHeartbeat
	Description: Pings the MySQL server every 30 minutes to prevent going away.
     ----------------------------------- ]]
	function FEL.MySQLHeartbeat()
	
		-- If we are in MySQL
		if FEL.Settings["MySQL"] then 
			FEL.Query( "SELECT 1 + 1;" )
		end
		
	end
	timer.Create( "FEL_MySQLHeartbeat", 30 * 60, 0, FEL.MySQLHeartbeat )

--[[ -----------------------------------
	Function: FEL.PrintError
	Description: Prints an error recieved from the FEL.Query
     ----------------------------------- ]]
	function FEL.PrintError( info )
		ErrorNoHalt( "\n---- FEL SQL Error ----\n ** Running - \n ** Error Msg - " .. info.Error .. "\n" );
	end
	
--[[ -----------------------------------
	Function: FEL.Escape
	Description: Makes a string nice.
     ----------------------------------- ]]
	function FEL.Escape( str )

		if FEL.Settings["MySQL"] then
		
			return "'" .. str .. "'"
			
		else
		
			return SQLStr( str )
			
		end
		
	end
	
--[[ -----------------------------------
	Function: FEL.CheckTable
	Description: Checks a table to see if it has all the correct columns.  Will recreate if not.
     ----------------------------------- 
	function FEL.CheckTable( name, data )
	
		-- First, lets check if the table exists.
		local tbl = FEL.Query( "SELECT * FROM " .. name .. ";" )
		
		if !tbl then return false end
		
		-- He exists, lets see if his columns are all correct.
		local columns = {}
		for k,v in pairs( tbl[1] ) do
			table.insert( columns, k )
		end
		
		local missing = false
		for k,v in pairs( data ) do
			if !table.HasValue( columns, k ) then
				-- The saved data is missing a SQL column!
				missing = true
				break
			end
		end
		
		if !missing then return false end
		
		-- We already have the table data stored, so lets delete the old table and transfer in the new data.
		FEL.Query( "DROP TABLE " .. name .. ";" ) -- Bye.
		exsto.Print( exsto_CONSOLE_DEBUG, "FEL --> Table " .. name .. " doesn't contain all required columns!  Recreating!" )
		
		return tbl 
		
	end]]

--[[ -----------------------------------
	Function: FEL.MakeTable_Internal
	Description: Creates a table
     ----------------------------------- ]]
	function FEL.MakeTable_Internal( name, data )

		if type( data ) != "table" then exsto.Error( "Error while trying to create table " .. name .. "!  Data variable is not a table!" ) return end
		if type( name ) != "string" then exsto.Error( "Error while trying to create table " .. name .. "!  Name variable is not a string!" ) return end

		local columns = "";
		local num = exsto.SmartNumber( data )
		local curSlot = 1
		
		-- Check and make sure if there is an existing table, and it is up to date.
		--local savedInfo = FEL.CheckTable( name, data )
		
		for k,v in pairs( data ) do
			
			if curSlot == num then
				columns = string.format( "%s%s %s", columns, k, v )
			else
				columns = string.format( "%s%s %s, ", columns, k, v )
			end
			
			curSlot = curSlot + 1
			
		end

		local query = string.format( "CREATE TABLE IF NOT EXISTS %s (%s);", name, columns );
		FEL.Query( query );
		exsto.Print( exsto_CONSOLE_DEBUG, "SQL --> Creating table " .. name .. "!" )
		
		--[[ Save the data if the table had to be broken down.
		if savedInfo then 
			for k,v in pairs( savedInfo ) do
				FEL.AddData( name, {
					Data = v,
				} )
			end
		end	]]	
		
	end

--[[ -----------------------------------
	Function: FEL.MakeTable
	Description: Creates a table and inserts it into the Exsto list of tables.
     ----------------------------------- ]]
	function FEL.MakeTable( name, data )
		FEL.CreatedTables[name] = data;
		FEL.MakeTable_Internal( name, data )
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
	function FEL.LoadTable( tab, mysql )
		return FEL.Query( "SELECT * FROM " .. tab .. ";", mysql )
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
			for k,v in pairs( info.Data ) do
				
				local format = "%s%s, "
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
			
			local format = "%s%s, "
			
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
		
		return FEL.Query( syntax, options.Threaded )
	end	

--[[ -----------------------------------
	Function: FEL.SaveUserInfo
	Description: Saves a player's information
     ----------------------------------- ]]
	function FEL.SaveUserInfo( ply )

		local nick = ply:Nick()
		local steamID = ply:SteamID()
		local rank = ply:GetRank()

		FEL.AddData( "exsto_data_users", {
			Look = {
				SteamID = steamID,
			},
			Data = {
				Name = nick,
				SteamID = steamID,
				Rank = rank,
			},
			Options = {
				Threaded = true,
				Update = true,
			}
		} )
		
		exsto.Print( exsto_CONSOLE_DEBUG, "Saving data for " .. ply:Nick() .. "!" )
		
	end

--[[ -----------------------------------
	Function: FEL.LoadUserInfo
	Description: Loads user's information
     ----------------------------------- ]]
	function FEL.LoadUserInfo( ply )
		return FEL.LoadData( "exsto_data_users", "Rank", "SteamID", ply:SteamID() )
	end

--[[ -----------------------------------
	Function: FEL.SaveBanInfo
	Description: Saves a player's banned information.
     ----------------------------------- ]]
	function FEL.SaveBanInfo( ply, len, reason, banned_by, time )

		local nick = ply:Nick()
		local banned_by = banned_by:Nick()
		local steam = ply:SteamID()
		local reason = reason

		FEL.AddData( "exsto_data_bans", {
			Look = {
				SteamID = steam,
			},
			Data = {
				Name = nick,
				SteamID = steam,
				Length = len,
				Reason = reason,
				BannedBy = banned_by,
				BannedAt = time,
			},
			Options = {
				Threaded = true,
				Update = true,
			}
		} )
		exsto.Print( exsto_CONSOLE_DEBUG, "Saving data for " .. ply:Nick() .. "!" )
		
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
			}
		)

	FEL.MakeTable( "exsto_data_bans", {
			Name = "varchar(255)",
			SteamID = "varchar(255)",
			Length = "int",
			Reason = "varchar(255)",
			BannedBy = "varchar(255)",
			BannedAt = "int",
			}
		)
		
end

--[[ -----------------------------------
	Function: FEL.MakeSteamNice
	Description: Main query, returns data from SQL query
     ----------------------------------- 
function FEL.MakeSteamNice( steamid, reverse )

	if !reverse then
		steamid = string.gsub( steamid, ":", "-" )
	else
		steamid = string.gsub( steamid, "-", ":" )
	end
	
	return steamid
	
end]]

--[[ -----------------------------------
	Function: FEL.NiceColor
	Description: Makes a color nice.
     ----------------------------------- ]]
function FEL.NiceColor( color )
	return "c," .. color.r .. "," .. color.g .. "," .. color.b .. "," .. color.a
end

--[[ -----------------------------------
	Function: FEL.MakeColor
	Description: Makes a nice color a color.
     ----------------------------------- ]]
function FEL.MakeColor( str )
	local split = string.Explode( ",", str )
	table.remove( split, 1 )
	
	for k,v in pairs( split ) do split[k] = split[k]:Trim() end
	
	for k,v in pairs( split ) do split[k] = tonumber( split[k] ) end
	
	return Color( split[1], split[2], split[3], split[4] )
end

--[[ -----------------------------------
	Function: FEL.NiceEncode
	Description: Encodes a table to a readable string.
     ----------------------------------- ]]
function FEL.NiceEncode( data )
	
	local form = type( data )
	local encoded = "[form=" .. form .. "]";
	
	if form == "Vector" then
		local oldData = data
		data = {}
			data[1] = oldData.x
			data[2] = oldData.y
			data[3] = oldData.z
	elseif form == "Angle" then
		local oldData = data
		data = {}
			data[1] = oldData.p
			data[2] = oldData.y
			data[3] = oldData.r
	end

	if !type( data ) == "table" then exsto.Error( "Unknown data format!" ) return end
	
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
	
	if !form then exsto.Error( "Couldn't locate decoding form!" ) return end
	if !stringIndex then exsto.Error( "Couldn't tell if decoding a stringed index!" ) return end
	if !count then exsto.Error( "Couldn't count the amount of data in the encoded string!" ) return end
	
	count = tonumber( count )
	stringIndex = tobool( stringIndex )

	local sub = string.sub( str, endPos + 1, endStart - 1 )
	local capture = string.gmatch( sub, "%[([%d%%.]+)%]([%a%d-%.]+)" )
	local data = {}
	
	for k,v in capture do
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
--[[
function FEL.MakeDir( dir )

	if !file.IsDir( dir ) then
		file.CreateDir( dir )
	end
	
end

function FEL.Read( f, g )

	local data = file.Read( f )
	
	if g then data = glon.decode( data ) end
	
	return data
	
end

function FEL.Write( f, ... )

	file.Write( f, glon.encode( {...} ) )
	
end]]

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
		
		exsto.ErrorNoHalt( "FEL --> Couldn't find " .. id .. " setting!" )
		return {}
	end
	
end

--[[ -----------------------------------
	Function: FEL.CreateSettingsFile
	Description: Creates a .txt settings file.
     ----------------------------------- ]]
function FEL.CreateSettingsFile( id, tbl )
	local readData
	
	--[[if file.Exists( id .. ".txt" ) then
		
		readData = FEL.LoadSettingsFile( id )
		local difference = FEL.FindTableDifference( readData, tbl )
		
		if difference then
			table.Merge( tbl, difference )
		end
		
	end]]
	
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
	
	if SERVER then
		data = data .. "\n\n ******* SQL TABLES ****** \n\n"
		-- Dump the SQL tables.
		
		for k,v in pairs( FEL.CreatedTables ) do
			//local data = data .. " **** " .. k .. " ****\n\n" .. FEL.LoadTable( k ) .. "\n\n"
		end
	end
	
	file.Write( "exsto_error_dump.txt", data )
end
concommand.Add( "FEL_DumpErrors", FEL.DumpErrorLog )