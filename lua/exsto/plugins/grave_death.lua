-- Prefan Access Controller
-- Grave Death Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Worms Graves",
	ID = "grave-death",
	Desc = "A plugin that creates graves when you die!",
	Owner = "Prefanatic",
} )

if not SERVER then return end

PLUGIN:AddVariable({
	Pretty = "Grave Style",
	Dirty = "grave_type",
	Default = "fade",
	Description = "How the grave leaves after falling.",
	Possible = { "fade", "sink" },
})

PLUGIN:AddVariable({
	Pretty = "Grave Sink Rate",
	Dirty = "grave_sinkrate",
	Default = 5,
	Description = "How long until the grave sinks with the sink variable.",
})

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

function PLUGIN:OnPlayerDeath( victim, _, killer )
	
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
			
		end
		
	end
	hook.Add( "Think", tostring( ent ) .. "THINK", entThink )
	
end
 
PLUGIN:Register()
