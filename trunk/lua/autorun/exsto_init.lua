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

if !glon then require( "glon" ) end
if !datastream then require( "datastream" ) end

AddCSLuaFile( "autorun/exsto_init.lua" )

local function PrintLoading()
	print( [[
-----------------------------------------
---        Exsto by Prefanatic        ---
---            Revision ]] .. tostring( exsto.VERSION ) .. [[            ---
--- Please ignore all modules errors. ---
-----------------------------------------
]] )

end

local function LoadVariables()

	exsto = {}
	exsto.DebugEnabled = true
	exsto.StartTime = SysTime()
	exsto.UpdateHost = "http://94.23.154.153/Exsto/"
	
	exsto.VERSION = 92
end

local saveCount = 1
local totalCount = 0
local localFiles = {}
local dbLocation = "exsto_updatecache/" 
local function saveFile( data, contents )
	if saveCount >= totalCount then
		-- Save the new pizazz
		file.Write( dbLocation .. "database.txt", glon.encode( localFiles ) )
		if exsto and exsto.Print and !CLIENT then
			exsto.Print( exsto_CHAT_ALL, COLOR.EXSTO, "Exsto ", COLOR.NORM, "update done.  Please restart the server whenever all players are ready." )
		else
			chat.AddText( "Exsto client update done!  Reloading Exsto." )
			exstoInit()
			RunConsoleCommand( "_ExRestartInitSpawn" )
		end
	else	
		print( "UPDATE --> Saving file " .. string.Trim( data[1] ) )
		file.Write( dbLocation .. string.Trim( data[1] ):gsub( ".lua", ".txt" ), contents )
		
		local has = false
		for _, obj in ipairs( localFiles ) do
			if obj[1] == data[1] then has = true break end
		end
		
		if !has then
			table.insert( localFiles, data )
		end
		saveCount = saveCount + 1
	end
end

local function getFile( url, args, callback )
	if string.Trim( url ) == "" then return end
	http.Get( exsto.UpdateHost .. "Updates/lua/exsto/" .. string.Trim( url ), "", callback, unpack( args ) )
end

local function callback( args, contents )
	contents:Trim()
	if type( contents ) == "string" and contents != "" then
		crc = Hash( contents )
	end
	if !crc or ( crc != tonumber( args[2] ) ) then print( "file not the same as server!  getting again." ) getFile( args[1], args, callback ) return end
	saveFile( args, contents ) 
end

local function grabFiles( toUpdate, client )
	totalCount = #toUpdate
	for _, data in ipairs( toUpdate ) do
		getFile( data[1], data, callback )
	end
end

local clientRequired = {}
local function updateExsto( version, client )

	if localFiles.Version == version then
		print( "UPDATE --> Local file list is up to date." )
		return
	end

	localFiles.Version = version

	local toUpdate = {}
	local run = "version.php?changes=true&old=" .. exsto.VERSION .. "&new=" .. version
	if client then run = "version.php?changes=true&all=true" end
	
	http.Get( exsto.UpdateHost .. run, "", function( contents )
		print( "UPDATE --> File list recieved!  Starting file download." )
		local files = string.Explode( "\n", contents )
		
		-- go though each file and get his info.
		for _, obj in ipairs( files ) do
			local info = string.Explode( ";", obj )
			info[1] = string.Trim( info[1] or "" )
			info[2] = string.Trim( info[2] or "" ) 
			if string.Trim( info[1] ) != "" then
				if client and ( string.find( info[1], "sh_" ) or string.find( info[1], "cl_" ) ) then
					table.insert( toUpdate, info )
				elseif !client then
					table.insert( toUpdate, info )
				end
			end
		end
		
		grabFiles( toUpdate, client )
	end )
end

local function beginExstoLoad( client, requestedVer )

	LoadVariables()
	PrintLoading()
	
	if client then dbLocation = "exsto_updatecache_client/" .. requestedVer .. "/" end

	local data = file.Read( dbLocation .. "database.txt" )
	if data then
		localFiles = glon.decode( data )
		
		-- If we are the client, we don't need to bother with anything else.
		if client then 
			print( "UPDATE --> Existing Exsto data exists for this revision.  Loading." )
			exstoInit()
			return
		end
	end
	
	if !data and client then 
		exsto.VERSION = requestedVer
		print( "LORD" )
		exstoInit()
		-- We need this client database.  Don't bother doing version checking, we need alll of it.
		updateExsto( requestedVer, client )
		return
	end

	http.Get( exsto.UpdateHost .. "version.php?simple=true", "", function( contents )
		if contents == "" then -- can't connect :(
			print( "UPDATE --> Failure connecting to Exsto update server!" )
			return
		end
		
		local ver = tonumber( contents )
		if !ver then
			print( "UPDATE --> Unknown update error!  Version contents wasn't a number!" )
			return
		end
		
		if exsto.VERSION < ver then
			-- Exsto requires an update
			print( "UPDATE --> Exsto requires an update.  Downloading file list." )
			updateExsto( ver, client )
			exsto.VERSION = ver
		end
	end )
	
	exstoInit()
end

local function internalLoad( data )
	CompileString( data, "ExCloudLoad" )
end

local toClientSend = {}
local function newInclude( fl, clientSend )
	for _, data in ipairs( localFiles ) do
		if "exsto/" .. string.Trim( data[1] ) == string.Trim( fl ) then
			-- Insert it into a little string table to send to the client.
			if clientSend then 
				table.insert( toClientSend, data[1] )
			else
				-- We found something in our saved file table.  Check CRC values and go.
				local luaFile = file.Read( "../lua/" .. fl )
				local crc = nil
				if type( luaFile ) == "string" and luaFile != "" then
					//crc = Hash( luaFile )
				end
				
				if !crc or ( tonumber( crc ) != tonumber( data[2] ) ) then
					-- The data file is probably newer, load that.
					local f = file.Read( dbLocation .. fl:gsub( "exsto/", "" ):gsub( ".lua", ".txt" ) )
					
					if !f then return end
					
					local status, err = pcall( CompileString( f, "ExCloudLoad" ) )

					//local status, err = pcall( CompileString( f, "ExCloudLoad" ) )
					if !status then
						print( "UPDATE --> Error parsing update file '" .. fl .. "'.  Loading from local." )
						return
					end
					
					return true
				end
			end
		end
	end
end

function exstoInclude( fl )
	--if newInclude( fl ) != true then include( fl ) end
	include( fl )
end
	
function exstoAddCSLuaFile( fl )
	//if !newInclude( fl, true ) then AddCSLuaFile( fl ) end
	--newInclude( fl, true )
	AddCSLuaFile( fl )
end

function exstoInit()
	
	if exsto then
		if exsto.Print then
			exsto.Print( exsto_CHAT_ALL, COLOR.EXSTO, "Exsto", COLOR.NORM, " is reloading the core!" )
		end
		if exsto.Plugins and exsto.RemoveChatCommand then
			exsto.UnloadAllPlugins()
		end
	end			
	
	LoadVariables()
	PrintLoading()
	
	if SERVER then
		exstoInclude( "exsto/sv_init.lua" )
		exstoAddCSLuaFile( "exsto/cl_init.lua" )
	elseif CLIENT then
		exstoInclude( "exsto/cl_init.lua" )
	end
end

exsto_HOOKCALL = exsto_HOOKCALL or hook.Call
hook.Call = function( name, gm, ... )
	if !exsto or !exsto.Plugins or !exsto.HookCall then
		return exsto_HOOKCALL( name, gm, ... )
	end
	
	return exsto.HookCall( name, gm, ... )
end

if SERVER then
	exstoInit()
	--beginExstoLoad()
	
	concommand.Add( "exsto_cl_load", function( ply, _, args )
		//if table.Count( toClientSend ) == 0 then
			umsg.Start( "clexsto_load", ply )
				umsg.Short( exsto.VERSION )
			umsg.End()
		//else
			//datasream.StreamToClients( ply, "ExAutoUpdate", { toClientSend, exsto.VERSION })
		//end
	end )
	
	concommand.Add( "_ExRestartInitSpawn", function( ply, _, args )
		hook.Call( "ExInitSpawn", nil, ply, ply:SteamID(), ply:UniqueID() )
		hook.Call( "exsto_InitSpawn", nil, ply, ply:SteamID(), ply:UniqueID() )
	end )
	
elseif CLIENT then

	local function init( UM )
		--beginExstoLoad( true, UM:ReadShort() )
		exstoInit()
		hook.Call( "ExInitialized" )
	end
	usermessage.Hook( "clexsto_load", init )

	datastream.Hook( "ExAutoUpdate", function( handler, id, encoded, decoded )
		clientRequired = decoded[1]
		
		beginExstoLoad( true, decoded[2] )
	end )

	function onEntCreated( ent )
		if LocalPlayer():IsValid() then
			LocalPlayer():ConCommand( "exsto_cl_load\n" )
			hook.Remove( "OnEntityCreated", "ExSystemLoad" )
		end
	end
	hook.Add( "OnEntityCreated", "ExSystemLoad", onEntCreated )
end