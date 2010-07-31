-- Exsto
-- Ragdoll Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Ragdoll Plugin",
	ID = "ragdoll",
	Desc = "A plugin that allows ragdolling players.",
	Owner = "Prefanatic",
} )

function PLUGIN:ExCommandCalled( id, plug, caller, ... )
	if type( arg[1] ) == "Player" and arg[1].ExRagdolled then
		if id == "jail" or id == "rocket" or id == "slay" or id == "slap" then return false, { COLOR.NAME, args[1]:Nick(), COLOR.NORM, " is ", COLOR.NAME, "ragdolled!" } end
		if id == "kick" or id == "ban" then if ply.ExRagdoll and ply.ExRagdoll:IsValid() then ply.ExRagdoll:Remove() end end
	end
end

function PLUGIN:CanPlayerSuicide( ply )
	if ply.ExRagdolled then return false end
end

function PLUGIN:PlayerDisconnected( ply )
	if ply.ExRagdoll and ply.ExRagdoll:IsValid() then ply.ExRagdoll:Remove() end
end

function PLUGIN:PlayerSpawn( ply )
	if ply.ExRagdolled then
		if ply.ExRagdoll and ply.ExRagdoll:IsValid() then
			ply.ExRagdoll:Remove()
		end
		
		ply:UnSpectate()
		for _, wep in ipairs( ply.ExRagdoll_Weps ) do
			if wep and wep:IsValid() then
				ply:Give( wep:GetClass() )
			end
		end
		ply:SetParent()
		ply.ExRagdolled = false
	end
end

function PLUGIN:Ragdoll( self, ply )

	if !ply.ExRagdolled then
		ply.ExRagdolled = true
		
		ply.ExRagdoll_Weps = ply:GetWeapons()
		ply:StripWeapons()
		
		local doll = ents.Create( "prop_ragdoll" )
			doll:SetModel( ply:GetModel() )
			doll:SetPos( ply:GetPos() )
			doll:SetAngles( ply:GetAngles() )
			doll:Spawn()
			doll:Activate()
			doll:SetVelocity( ply:GetVelocity() )
			
		ply.ExRagdoll = doll
		ply:SpectateEntity( doll )
		ply:Spectate( OBS_MODE_CHASE )
		ply:SetParent( doll )
		
		return {
			Activator = self,
			Player = ply,
			Wording = " has ragdolled "
		}
	else
		ply.ExRagdolled = false
		if ply.ExRagdoll and ply.ExRagdoll:IsValid() then ply.ExRagdoll:Remove() end
		
		ply:UnSpectate()
		for _, wep in ipairs( ply.ExRagdoll_Weps ) do
			if wep and wep:IsValid() then
				ply:Give( wep:GetClass() )
			end
		end
		ply:SetParent()
		ply:Spawn()
	
		return {
			Activator = self,
			Player = ply,
			Wording = " has unragdolled "
		}
	end
end
PLUGIN:AddCommand( "ragdoll", {
	Call = PLUGIN.Ragdoll,
	Desc = "Allows users to ragdoll players.",
	Console = { "ragdoll", "unragdoll", },
	Chat = { "!ragdoll", "!unragdoll" },
	ReturnOrder = "Victim",
	Args = { Victim = "PLAYER" },
	Category = "Fun"
})
PLUGIN:RequestQuickmenuSlot( "ragdoll" )

PLUGIN:Register()
