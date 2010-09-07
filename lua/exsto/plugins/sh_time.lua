-- Exsto
-- Time plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Time Monitor",
	ID = "time",
	Desc = "A plugin that keeps track of player time.",
	Owner = "Prefanatic",
} )

if SERVER then

	exsto.TimeDB = FEL.CreateDatabase( "exsto_plugin_time" )
		exsto.TimeDB:ConstructColumns( {
			Player = "TEXT";
			SteamID = "VARCHAR(50):primary:not_null";
			Time = "INTEGER:not_null";
			Last = "INTEGER:not_null";
			Test = "STRING";
		} )
	
	function PLUGIN:ExInitSpawn( ply, sid, uid )

		local nick = ply:Nick()
		
		local time, last = exsto.TimeDB:GetData( sid, "Time, Last" )

		if type( time ) == "nil" then
			
			exsto.TimeDB:AddRow( {
				Player = nick;
				SteamID = sid; 
				Time = 0;
				Last = os.time();
			} )
			
			ply:SetFixedTime( 0 )
			
			timer.Simple( 1, function()
				exsto.Print( exsto_CHAT, ply, COLOR.NORM, "Welcome ", COLOR.NAME, nick, COLOR.NORM, ".  It seems this is your first time here, have fun!" )
			end )
			
		else
		
			local LastDay = os.date( "%c", last )
			ply:SetFixedTime( time )
			timer.Simple( 1, function()
				exsto.Print( exsto_CHAT, ply, COLOR.NORM, "Welcome back ", COLOR.NAME, nick, COLOR.NORM, "!" )
				exsto.Print( exsto_CHAT, ply, COLOR.NORM, "You last visited ", COLOR.RED, LastDay )
			end )
			
		end
		
		ply:SetJoinTime( CurTime() )
		
	end
	
	function PLUGIN:PlayerDisconneced( ply )
	
		local sid = ply:SteamID()
		
		exsto.TimeDB:AddRow( {
			Player = nick;
			SteamID = sid; 
			Time = ply:GetTotalTime();
			Last = os.time();
		} )
		
	end
	
	function PLUGIN:ShutDown()
		PLUGIN.Interval()
	end
	
	function PLUGIN.Interval()
		for k,v in pairs( player.GetAll() ) do
			PLUGIN.PlayerDisconneced( PLUGIN, v )
		end
	end
	timer.Create( "Time_IntervalSave", 60 * 5, 0, PLUGIN.Interval )
	
end

-- Meta funcions
local meta = FindMetaTable( "Player" )

function meta:SetJoinTime( time )
	self:SetNWInt( "Time_Join", time )
end

function meta:GetJoinTime( time )
	return self:GetNWInt( "Time_Join" )
end

function meta:SetFixedTime( time )
	self:SetNWInt( "Time_Fixed", time )
end

function meta:GetFixedTime()
	return self:GetNWInt( "Time_Fixed" )
end

function meta:GetSessionTime()
	return CurTime() - self:GetJoinTime()
end

function meta:GetTotalTime()
	return self:GetFixedTime() + self:GetSessionTime()
end

PLUGIN:Register()