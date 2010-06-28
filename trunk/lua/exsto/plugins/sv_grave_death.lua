-- Prefan Access Controller
-- Grave Death Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Worms Graves",
	ID = "grave-death",
	Desc = "A plugin that creates graves when you die!",
	Owner = "Prefanatic",
} )

PLUGIN:AddVariable({
	Pretty = "Grave Style",
	Dirty = "grave_type",
	Default = "leaveonspawn",
	Description = "How the grave leaves after falling.",
	Possible = { "fade", "sink", "leaveonspawn" },
})

PLUGIN:AddVariable({
	Pretty = "Grave Sink Rate",
	Dirty = "grave_sinkrate",
	Default = 5,
	Description = "How long until the grave sinks with the sink variable.",
})

function PLUGIN:Init()
	
	self.RandomDeathMessages = { "He couldn't load the death messages file." }

	http.Get( "http://dl.dropbox.com/u/717734/Exsto/DO%20NOT%20DELETE/deathmessages.txt", "", function( contents )
		self.RandomDeathMessages = string.Explode( "\n", contents )
		exsto.Print( exsto_CONSOLE, "PLUGINS --> Grave Death --> Retreived death messages!" )
	end )
	
end

function PLUGIN:PlayerSpawn( ply )
	if ply.GraveData then
		ply.GraveData.Text:Remove()
		ply.GraveData.Ent:Remove()
		ply.GraveData.Message:Remove()
		
		ply.GraveData = nil
	end
end

local function BuildWormsMessage( ent, ply )

	if !ply.GraveData then
		local text = ents.Create( "3dtext" )
			text:SetPos( ent:GetPos() + Vector( 0, 0, ( ent.Height / 2 ) + 13 ) )
			text:SetAngles( Angle( 0, 0, 0 ) )
			text:Spawn()
			text:SetPlaceObject( ent )
			text:SetText( "Here lies " .. ply:Nick() )
			text:SetScale( 0.05 )
			
		local message = ents.Create( "3dtext" )
			message:SetPos( ent:GetPos() + Vector( 0, 0, ( ent.Height / 2 ) + 6 ) )
			message:SetAngles( Angle( 0, 0, 0 ) )
			message:Spawn()
			message:SetPlaceObject( ent )
			message:SetText( PLUGIN.RandomDeathMessages[math.random( 1, #PLUGIN.RandomDeathMessages )]  )
			message:SetScale( 0.05 )
		
		ply.GraveData = { Text = text, Ent = ent, Message = message }
	end
	hook.Remove( "Think", tostring( ent ) .. "THINK" )
	
end

local function Sink( ent )

	if ent.FallenTime + tonumber( exsto.GetVar( "grave_sinkrate" ).Value ) < CurTime() then
		
		local pos = ent:GetPos()
		local to = ent.HitPos.z - ( ent.Height )
		
		local dist = pos.z - to
		local speed = dist / 20
		
		
		if pos.z < to then
		
			hook.Remove( "Think", tostring( ent ) .. "THINK" )
			
			ent:Remove()
			
		else
		
			ent:SetPos( Vector( pos.x, pos.y, pos.z - speed ) )
		
		end
		
	end
	
end

local function Fade( ent )

	local r, g, b, a = ent:GetColor()
	local alpha = a - 1

	if alpha <= 1 then
	
		hook.Remove( "Think", tostring( ent ) .. "THINK" )
		
		ent:Remove()
		
	else

		ent:SetColor( r, g, b, alpha )
		
	end
	
end

function PLUGIN:PlayerDeath( victim, _, killer )
	
	local opos = victim:GetPos()
	local trace = {}
		trace.start = opos
		trace.endpos = opos - Vector( 0, 0, 5000 )
		
	local hitpos = util.TraceLine( trace ).HitPos
	local spos = opos + Vector( 0, 0, 2000 )
	
	local start = CurTime()
	local nextr = 0
	
	local ent = ents.Create( "prop_physics" )
	
		ent:SetModel( "models/props_c17/gravestone00" .. math.random( 1, 4 ) .. "a.mdl" )
	
		ent:Spawn()
		ent:Activate()
		
		ent:PhysicsInit( SOLID_NONE )
		ent:SetMoveType( MOVETYPE_NONE )
		ent:SetSolid( SOLID_NONE )
		
		ent:SetPos( spos )
		
		ent.MinZ = ent:OBBMins().z
		ent.MaxZ = ent:OBBMaxs().z
		ent.Height = ( ent.MinZ * -1 ) + ent.MaxZ
		
	local function entThink()
			
		local dist = hitpos:Distance( ent:GetPos() )
		local speed = dist / 30
		
		if not ent.Fallen then
		
			if dist < ( ent.MinZ * -1 ) then
				
				ent:EmitSound( "physics/concrete/boulder_impact_hard" .. math.random( 1, 4 ) .. ".wav" )
				
				ent.Fallen = true
				ent.FallenTime = CurTime()
				ent.HitPos = ent:GetPos()
				
				--[[
				local effect = EffectData()
					effect:SetOrigin( ent:GetPos() )
					effect:SetStart( ent:GetPos() )
					effect:SetMagnitude( 10 )
				
				util.Effect( "grave_fall", effect )]]
				
			else
				
				ent:SetPos( ent:GetPos() - Vector( 0, 0, 1 * speed ) )
				
			end
			
		elseif ent.Fallen then

			if exsto.GetVar( "grave_type" ).Value == "fade" then Fade( ent ) end
			if exsto.GetVar( "grave_type" ).Value == "sink" then Sink( ent ) end
			if exsto.GetVar( "grave_type" ).Value == "leaveonspawn" then BuildWormsMessage( ent, victim ) end
			
		end
		
	end
	hook.Add( "Think", tostring( ent ) .. "THINK", entThink )
	
end
 
PLUGIN:Register()
