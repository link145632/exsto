-- Prefan Access Controller
-- Rocket Man Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Rocket Man",
	ID = "rocket-man",
	Desc = "A plugin that allows rocketing and igniting of players.",
	Owner = "Prefanatic",
} )

function PLUGIN.Ignite( owner, ply, duration, radius )
	ply:Ignite( duration, radius )
	
	return {
		Activator = owner,
		Player = ply,
		Wording = " has ignited ",
	}
end
PLUGIN:AddCommand( "ignite", {
	Call = PLUGIN.Ignite,
	Desc = "Ignites players.",
	FlagDesc = "Allows users to ignite other players.",
	Console = { "ignite" },
	Chat = { "!ignite", "!fire" },
	ReturnOrder = "Victim-Duration-Radius",
	Args = {Victim = "PLAYER", Duration = "NUMBER", Radius = "NUMBER"},
	Optional = {Duration = 10, Radius = 50}
})

function PLUGIN.RocketMan( owner, ply, speed ) -- Function, args Caller, Player, and Speed

	local function Explode()
		local explode = ents.Create( "env_explosion" )
			explode:SetPos( ply:GetPos() )
			explode:SetOwner( ply )
			explode:Spawn()
			explode:Fire( "Explode", 0, 0 )
			
		ply:StopParticles()
		ply:Kill() -- I want to do a ragdoll version of this too, its funnier.
		--ply:SetHealth( ply:Health() - speed / 6 ) -- Sets the health to the current, minus the speed / 6
		
		--if ply:Health() <= 0 then ply:Kill() end -- If the player has no health, kill him.
	end
	
	ply:SetMoveType( MOVETYPE_WALK )
	
	-- Randoms to make it look cooler.
	local x = math.random( -800, 800 )
	local y = math.random( -800, 800 )
	ply:SetVelocity( Vector( x, y, speed ) ) -- Set the velocity of the player to the up of the speed
	ParticleEffectAttach( "rockettrail", PATTACH_ABSORIGIN_FOLLOW, ply, 0 )
	
	timer.Simple( 2, Explode )
	
	return {
		Activator = owner,
		Player = ply,
		Wording = " has rocketed ",
	}
	
end
PLUGIN:AddCommand( "rocketman", {
	Call = PLUGIN.RocketMan,
	Desc = "Player is now rocket",
	FlagDesc = "Allows users to explode other players.",
	Console = { "rocket" },
	Chat = { "!rocket" },
	ReturnOrder = "Victim-Speed",
	Args = {Victim = "PLAYER", Speed = "NUMBER"},
	Optional = {Speed = 3000}, -- Give the optional value
})

PLUGIN:Register()
