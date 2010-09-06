--[[
	File Extension Library
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

-- Thanks to rabbish for the cache idea.

FEL = {}
	FEL.Databases = {}
	FEL.DefaultConfig = {
		host = "localhost";
		username = "username";
		password = "password";
		database = "database";
		mysql_enabled = "false";
	}
	
function FEL.Init()
	if !file.Exists( "exsto_mysql_settings.txt" ) then
		file.Write( "exsto_mysql_settings.txt", util.TableToKeyValues( FEL.DefaultConfig ) )
		FEL.Config = FEL.DefaultConfig
	else
		FEL.Config = util.KeyValuesToTable( file.Read( "exsto_mysql_settings.txt" ) )
	end
	
	if !mysqloo then require( "mysqloo" ) end
end
FEL.Init()

local db = {
	dbName;
	Cache = {};
	thinkDelay = 5;
}
db.__index = db

function FEL.CreateDatabase( dbName )
	local obj = {}
	setmetatable( obj, db )
	
	obj.dbName = dbName
	obj.Cache = { 
		_new = {};
		_changed = {};
		_cache = {};
	}
	obj._LastKey = nil
	obj._lastThink = CurTime()
	
	table.insert( FEL.Databases, obj )
	hook.Add( "Think", dbName .. "_Think", function() obj:Think() end )
	
	if FEL.Config.mysql_enabled == "true" then -- Connect to a mysql server.
		obj._mysqlDB = mysqloo.connect( FEL.Config.host, FEL.Config.username, FEL.Config.password, FEL.Config.database )
		obj._mysqlDB:connect()
		obj._mysqlDB.onConnected = function() obj:OnMySQLConnect() end
		obj._mysqlDB.onConnectionFailed = function( err ) obj:OnMySQLConnectFail( err ) end
		obj._mysqlDB:wait()
	end
	
	return obj
end

function db:OnMySQLConnect()
	print( "FEL --> " .. self.dbName .. " --> MySQL connect success!  Server Version: " .. self._mysqlDB:serverVersion() )
	self._mysqlSuccess = true
end

function db:OnMySQLConnectFail( err )
	ErrorNoHalt( "FEL --> " .. self.dbName .. " --> Connect Failure: " .. err )
	self._mysqlSuccess = false
end

function db:ConstructColumns( columnData )
	local formatted = {}
	
	for columnName, data in pairs( columnData ) do
		local split = string.Explode( ":", data )
		local clean = ""
		
		for _, str in ipairs( split ) do
			if str == "primary" then
				formatted._PrimaryKey = columnName 
			elseif str == "not_null" then
				clean = clean .. " NOT NULL"
			else
				clean = clean .. str
			end
		end
		
		formatted[ columnName ] = clean
	end
	
	if !formatted._PrimaryKey then
		error( "FEL --> Issue with constructing columns for '" .. self.dbName .. "' - No primary key was created!" )
	end

	self.Columns = formatted	
	self.Queries = {
		Create = "CREATE TABLE IF NOT EXISTS " .. self.dbName .. "(%s)";
		Datatypes = "%s %s";
		Update = "UPDATE " .. self.dbName .. " SET %s WHERE " .. formatted._PrimaryKey .. " = %s";
		Insert = "INSERT INTO " .. self.dbName .. "(%s) VALUES(%s)";
		Set = "%s = %s";
	}
	
	-- Commit and create our table!
	self:Query( self:ConstructQuery( "create" ), false )
	self.Cache._cache = self:Query( "SELECT * FROM " .. self.dbName, false ) or {}
	self:CheckIntegrity()		
end

function db:CheckIntegrity()

	local dbLocal = file.Read( "exsto_felcache/" .. self.dbName .. "_cache.txt" )
	if !dbLocal then
		file.Write( "exsto_felcache/" .. self.dbName .. "_cache.txt", glon.encode( self.Columns ) )
		return
	else
		dbLocal = glon.decode( dbLocal )
	end
	
	-- Check if the cache is old_fel.
	if type( dbLocal[1] ) == "table" and type( dbLocal[2] ) == "table" then
		print( "FEL --> " .. self.dbName .. " --> Local cache using old FEL!  Updating to support new format." )
		self:DropTable( false )
		self:Query( self:ConstructQuery( "create" ), false )
		self.Cache._new = self.Cache._cache
		
		file.Write( "exsto_felcache/" .. self.dbName .. "_cache.txt", glon.encode( self.Columns ) )
		return
	end
	
	-- Create a table of our current columns
	local currentColumns = {}
	for column in pairs( self.Columns ) do
		table.insert( currentColumns, column )
	end
	
	-- Create a table of the columns from the table
	local oldColumns = {}
	for column in pairs( dbLocal ) do
		table.insert( oldColumns, column )
	end
	
	local changedData = {}
	
	-- OK, check to see if we need to add any columns.
	for _, column in ipairs( currentColumns ) do
		if !table.HasValue( oldColumns, column ) then table.insert( changedData, { t = "add", c = column, d = self.Columns[ column ] } ) end
	end
	
	-- Now to get rid of.
	for _, column in ipairs( oldColumns ) do
		if !table.HasValue( currentColumns, column ) then table.insert( changedData, { t = "remove", c = column } ) end
	end
	
	-- Check primary keys.
	if !dbLocal._PrimaryKey and self.Columns._PrimaryKey then
		table.insert( changedData, { t = "pk", c = self.Columns._PrimaryKey } )
	end
	
	-- Commit brother!
	if table.Count( changedData ) > 0 then
		
		for _, data in ipairs( changedData ) do
			if data.t == "add" then
				self:Query( "ALTER TABLE " .. self.dbName .. " ADD " .. data.c .. " " .. data.d )
			elseif data.t == "remove" then
				self:Query( "ALTER TABLE " .. self.dbName .. " DROP COLUMN " .. data.c )
			elseif data.t == "pk" then
				self:Query( "ALTER TABLE " .. self.dbName .. " ADD PRIMARY KEY( " .. data.c .. " )" )
			end
		end
		
		print( "FEL --> " .. self.dbName .. " --> Updating SQL content!" )
		
		file.Write( "exsto_felcache/" .. self.dbName .. "_cache.txt", glon.encode( self.Columns ) )
	end
end	

function db:CheckCache( id, data )
	for _, cached in ipairs( self.Cache[ id ] ) do
		if cached[ self.Columns._PrimaryKey ] == data[ self.Columns._PrimaryKey ] then
			self._LastKey = _
			return true
		end
	end
end

function db:ConstructQuery( style, data )
	if style == "new" then
		local query = self.Queries.Insert
		
		self._clk = 1
		local count = table.Count( data )
		for column, rowData in pairs( data ) do
			if type( rowData ) == "string" then rowData = SQLStr( rowData ) end
			if self._clk == count then 
				query = string.format( query, column, rowData )
			else
				query = string.format( query, column .. ", %s", tostring( rowData ) .. ", %s" )
			end
			
			self._clk = self._clk + 1
		end
		
		return query
	elseif style == "changed" then
		local query = string.format( self.Queries.Update, "%s", type( data[ self.Columns._PrimaryKey ] ) == "string" and SQLStr( data[ self.Columns._PrimaryKey ] ) or data[ self.Columns._PrimaryKey ] )
		
		self._clk = 1
		local count = table.Count( data )
		for column, rowData in pairs( data ) do
			if type( rowData ) == "string" then rowData = SQLStr( rowData ) end
			if self._clk == count then
				query = string.format( query, string.format( self.Queries.Set, column, rowData ) )
			else
				query = string.format( query, string.format( self.Queries.Set, column, rowData ) .. ", %s" )
			end
			
			self._clk = self._clk + 1
		end
		
		return query
	elseif style == "create" then
		local query = self.Queries.Create
		
		self._clk = 1
		local count = table.Count( self.Columns )
		for column, dataType in pairs( self.Columns ) do
			if column != "_PrimaryKey" then
				if self._clk == count then
					query = string.format( query, string.format( self.Queries.Datatypes, column, dataType ) .. ", PRIMARY KEY( " .. self.Columns._PrimaryKey .. " )" )
				else
					query = string.format( query, string.format( self.Queries.Datatypes, column, dataType ) .. ", %s" )
				end
			end
			
			self._clk = self._clk + 1
		end
		
		return query
	end
end

function db:OnQueryError( err )
	ErrorNoHalt( "FEL --> " .. self.dbName .. " --> Error: " .. err )
end

function db:Query( str, threaded )
	print( str )
	if self._mysqlSuccess == true then -- We are MySQL baby
		self._mysqlQuery = self._mysqlDB:query( str )
		self._mysqlQuery.onError = function( query, err ) self:OnQueryError( err ) end
		self._mysqlQuery:start()
		
		if threaded == false then -- If we request not to be threaded.
			self._mysqlQuery:wait()
			return self._mysqlQuery:getData()
		end
	else
		local result = sql.Query( str .. ";" )
		
		if result == false then
			-- An error, holy buggers!
			self:OnQueryError( sql.LastError() )
		else
			return result
		end
	end
end

function db:Think()
	if CurTime() > self._lastThink + self.thinkDelay then
		if self._mysqlSuccess != true and self._mysqlSuccess != false then -- Wait.  Just queue up;
			self._lastThink = CurTime()
			return
		end
		
		if #self.Cache._changed > 0 then -- Hoho we have some changes!
			for _, rowData in ipairs( self.Cache._changed ) do
				self:Query( self:ConstructQuery( "changed", rowData ) )
			end
			
			self.Cache._changed = {}
		end
		
		if #self.Cache._new > 0 then
			for _, rowData in ipairs( self.Cache._new ) do
				self:Query( self:ConstructQuery( "new", rowData ) )
			end
			
			self.Cache._new = {}
		end
		
		-- Heartbeat please.
		self:Query( "SELECT 1 + 1" )
		
		self._lastThink = CurTime()
	end
end

function db:AddRow( data, options )
	options = options or {}
	if self:CheckCache( "_cache", data ) then
		if options.Update == false then return end			
		table.remove( self.Cache._cache, self._LastKey )
		table.insert( self.Cache._changed, data )
	else
		table.insert( self.Cache._new, data )
	end
	
	table.insert( self.Cache._cache, data )
end

function db:GetAll()
	return table.Copy( self.Cache._cache )
end

function db:GetRow( key )
	for _, rowData in ipairs( self.Cache._cache ) do
		if key == rowData[ self.Columns._PrimaryKey ] then return rowData end
	end
end

function db:GetData( key, reqs )
	local data = self:GetRow( key )
	
	if !data then return end
	
	local ret = {}
	for _, req in ipairs( string.Explode( ", ", reqs ) ) do
		table.insert( ret, data[ req:Trim() ] )
	end
	
	return unpack( ret )
end

function db:DropRow( key )
	for _, rowData in ipairs( self.Cache._cache ) do
		if key == rowData[ self.Columns._PrimaryKey ] then table.remove( self.Cache._cache, _ ) break end
	end
end

function db:DropTable( threaded )
	self:Query( "DROP TABLE " .. self.dbName, threaded )
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