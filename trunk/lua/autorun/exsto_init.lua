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

-- Hashing lib
local max = 2^32 -1

local CRC32 = {
    0,79764919,159529838,222504665,319059676,
    398814059,445009330,507990021,638119352,
    583659535,797628118,726387553,890018660,
    835552979,1015980042,944750013,1276238704,
    1221641927,1167319070,1095957929,1595256236,
    1540665371,1452775106,1381403509,1780037320,
    1859660671,1671105958,1733955601,2031960084,
    2111593891,1889500026,1952343757,2552477408,
    2632100695,2443283854,2506133561,2334638140,
    2414271883,2191915858,2254759653,3190512472,
    3135915759,3081330742,3009969537,2905550212,
    2850959411,2762807018,2691435357,3560074640,
    3505614887,3719321342,3648080713,3342211916,
    3287746299,3467911202,3396681109,4063920168,
    4143685023,4223187782,4286162673,3779000052,
    3858754371,3904687514,3967668269,881225847,
    809987520,1023691545,969234094,662832811,
    591600412,771767749,717299826,311336399,
    374308984,453813921,533576470,25881363,
    88864420,134795389,214552010,2023205639,
    2086057648,1897238633,1976864222,1804852699,
    1867694188,1645340341,1724971778,1587496639,
    1516133128,1461550545,1406951526,1302016099,
    1230646740,1142491917,1087903418,2896545431,
    2825181984,2770861561,2716262478,3215044683,
    3143675388,3055782693,3001194130,2326604591,
    2389456536,2200899649,2280525302,2578013683,
    2640855108,2418763421,2498394922,3769900519,
    3832873040,3912640137,3992402750,4088425275,
    4151408268,4197601365,4277358050,3334271071,
    3263032808,3476998961,3422541446,3585640067,
    3514407732,3694837229,3640369242,1762451694,
    1842216281,1619975040,1682949687,2047383090,
    2127137669,1938468188,2001449195,1325665622,
    1271206113,1183200824,1111960463,1543535498,
    1489069629,1434599652,1363369299,622672798,
    568075817,748617968,677256519,907627842,
    853037301,1067152940,995781531,51762726,
    131386257,177728840,240578815,269590778,
    349224269,429104020,491947555,4046411278,
    4126034873,4172115296,4234965207,3794477266,
    3874110821,3953728444,4016571915,3609705398,
    3555108353,3735388376,3664026991,3290680682,
    3236090077,3449943556,3378572211,3174993278,
    3120533705,3032266256,2961025959,2923101090,
    2868635157,2813903052,2742672763,2604032198,
    2683796849,2461293480,2524268063,2284983834,
    2364738477,2175806836,2238787779,1569362073,
    1498123566,1409854455,1355396672,1317987909,
    1246755826,1192025387,1137557660,2072149281,
    2135122070,1912620623,1992383480,1753615357,
    1816598090,1627664531,1707420964,295390185,
    358241886,404320391,483945776,43990325,
    106832002,186451547,266083308,932423249,
    861060070,1041341759,986742920,613929101,
    542559546,756411363,701822548,3316196985,
    3244833742,3425377559,3370778784,3601682597,
    3530312978,3744426955,3689838204,3819031489,
    3881883254,3928223919,4007849240,4037393693,
    4100235434,4180117107,4259748804,2310601993,
    2373574846,2151335527,2231098320,2596047829,
    2659030626,2470359227,2550115596,2947551409,
    2876312838,2788305887,2733848168,3165939309,
    3094707162,3040238851,2985771188,
}

local function xor(a, b)
    local calc = 0    

    for i = 32, 0, -1 do
	local val = 2 ^ i
	local aa = false
	local bb = false

	if a == 0 then
	    calc = calc + b
	    break
	end

	if b == 0 then
	    calc = calc + a
	    break
	end

	if a >= val then
	    aa = true
	    a = a - val
	end

	if b >= val then
	    bb = true
	    b = b - val
	end

	if not (aa and bb) and (aa or bb) then
	    calc = calc + val
	end
    end

    return calc
end

local function lshift(num, left)
    local res = num * (2 ^ left)
    return res % (2 ^ 32)
end

local function rshift(num, right)
    local res = num / (2 ^ right)
    return math.floor(res)
end

function Hash(str)
	debug.sethook()
    local count = string.len(tostring(str))
    local crc = max
    
    local i = 1
    while count > 0 do
	local byte = string.byte(str, i)

	crc = xor(lshift(crc, 8), CRC32[xor(rshift(crc, 24), byte) + 1])

	i = i + 1
	count = count - 1
    end

    return crc
end

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
	
	exsto.VERSION = 83
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

	LoadVariables()
	PrintLoading()
	
	if exsto then
		if exsto.Print then
			exsto.Print( exsto_CHAT_ALL, COLOR.EXSTO, "Exsto", COLOR.NORM, " is reloading the core!" )
		end
		if exsto.Plugins and exsto.RemoveChatCommand then
			exsto.UnloadAllPlugins()
		end
	end			
	
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