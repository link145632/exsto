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

	PLUGIN:CreateTable( "exsto_plugin_time", {
		Player = "varchar(255)",
		SteamID = "varchar(255)",
		Time = "int",
		Last = "int"
		}
	)
	
	function PLUGIN:Onexsto_InitSpawn( ply, sid, uid )

		local nick = ply:Nick()
		
		local data = FEL.Query( "SELECT Time, Last FROM exsto_plugin_time WHERE SteamID = '" .. sid .. "';" );

		if !data then

			FEL.AddData( "exsto_plugin_time", {
				Look = {
					SteamID = sid,
				},
				Data = {
					Player = nick,
					SteamID = sid, 
					Time = 0,
					Last = os.time(),
				},
				Options = {
					Update = true,
					Threaded = true,
				}
			} )
			
			ply:SetFixedTime( 0 )
			
			timer.Simple( 1, function()
				exsto.Print( exsto_CHAT, ply, COLOR.NORM, "Welcome ", COLOR.NAME, nick, COLOR.NORM, ".  It seems this is your first time here, have fun!" )
			end )
			
		else
		
			local LastDay = os.date( "%c", data.Last )
			ply:SetFixedTime( data.Time )
			timer.Simple( 1, function()
				exsto.Print( exsto_CHAT, ply, COLOR.NORM, "Welcome back ", COLOR.NAME, nick, COLOR.NORM, "!" )
				exsto.Print( exsto_CHAT, ply, COLOR.NORM, "You last visited ", COLOR.RED, LastDay )
			end )
			
		end
		
		ply:SetJoinTime( CurTime() )
		
	end
	
	function PLUGIN:OnPlayerDisconneced( ply )
	
		local sid = ply:SteamID()
		
		FEL.AddData( "exsto_plugin_time", {
			Look = {
				SteamID = sid,
			},
			Data = {
				Player = ply:Nick(),
				SteamID = sid, 
				Time = ply:GetTotalTime(),
				Last = os.time(),
			},
			Options = {
				Update = true,
				Threaded = true,
			}
		} )
		
	end
	
	function PLUGIN.Interval()
	
		for k,v in pairs( player.GetAll() ) do
			
			PLUGIN.OnPlayerDisconneced( PLUGIN, v )
			
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