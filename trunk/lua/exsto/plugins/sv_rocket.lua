-- Prefan Access Controller
-- Rocket Man Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Rocket Man",
	ID = "rocket-man",
	Desc = "A plugin that allows rocketing and igniting of players.",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()
	self.Rocketeers = {}
end

function PLUGIN:Ignite( owner, ply, duration, radius )
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

function PLUGIN:CanNoclip( ply )
	if ply.IsRocket then return false end
end

function _R.Player:RocketExplode()
	self.Stage = 3
	local explode = ents.Create( "env_explosion" )
		explode:SetPos( self:GetPos() )
		explode:SetOwner( self )
		explode:Spawn()
		explode:Fire( "Explode", 0, 0 )
		
	self:StopParticles()
	self:KillSilent()
	
	for _, ply in ipairs( PLUGIN.Rocketeers ) do
		if ply.Player == self then
			ply.Text:Remove()
			table.remove( PLUGIN.Rocketeers, _ )
			break
		end
	end

end

function _R.Player:RocketPrep()
	-- Set his pos just high enough so we can smooth launch.
	self:SetVelocity( Vector( 0, 0, 0 ) )
	self:EmitSound( "buttons/button1.wav" )
	self:SetPos( self:GetPos() + Vector( 0, 0, 40 ) )
	ParticleEffectAttach( "rockettrail", PATTACH_ABSORIGIN_FOLLOW, self, 0 )
	timer.Create( "ExRocket" .. self:EntIndex(), 6, 1, function() self:RocketExplode() end )
end

--[[ Stages
	1 = Waiting
	2 = Launching
	3 = Done
]]

function PLUGIN:Think()
	for _, ply in pairs( self.Rocketeers ) do
		
		if ply.Stage == 1 then
			if ply.NextRocketTick <= CurTime() then
				ply.NextRocketTick = CurTime() + 1
				
				if ply.Delay <= 0 then
					ply.NextRocketTick = CurTime() - 1
					
					ply.Player:RocketPrep()
					ply.Stage = 2
				else
					ply.Delay = ply.Delay - 1
					ply.Text:SetText( "Liftoff in " .. ply.Delay )
					ply.Player:EmitSound( "buttons/blip1.wav" )
				end
			end
		elseif ply.Stage == 2 then -- We are flying!
			if ply.NextRocketTick <= CurTime() then
				ply.NextRocketTick = CurTime() + 0.1
				ply.Player:SetVelocity( ply.RandomLaunchVec )
				ply.RandomLaunchVec.z = ply.RandomLaunchVec.z + 3
				ply.NumberTicksSinceLaunch = ply.NumberTicksSinceLaunch + 1
				
				-- If we hit something, stop
				if ply.Player:GetVelocity().z <= 60 and ply.NumberTicksSinceLaunch >= 20 then 
					timer.Destroy( "ExRocket" .. ply.Player:EntIndex() )
					ply.Player:RocketExplode()
				end
			end
		end
		
	end
end

function PLUGIN:RocketMan( owner, ply, delay )
	local text = ents.Create( "3dtext" )
		text:SetPos( ply:GetPos() + Vector( 0, 0, 80 ) )
		text:SetAngles( Angle( 0, 0, 0 ) )
		text:Spawn()
		text:SetPlaceObject( ply )
		text:SetText( "Liftoff in " .. delay )
		text:SetScale( 0.1 )
		text:SetParent( ply )
		
	ply.IsRocket = true
	
	table.insert( self.Rocketeers, {
		Player = ply,
		Stage = 1,
		Text = text,
		Delay = delay,
		NextRocketTick = 0,
		RandomLaunchVec = Vector( 0, 0, 50 ),
		NumberTicksSinceLaunch = 0
	} )
	
	return { COLOR.NAME, owner:Nick(), COLOR.NORM, " has scheduled ", COLOR.NAME, ply:Nick(), COLOR.NORM, " to be launched into space!" }
	
end
PLUGIN:AddCommand( "rocketman", {
	Call = PLUGIN.RocketMan,
	Desc = "Player is now rocket",
	FlagDesc = "Allows users to explode other players.",
	Console = { "rocket" },
	Chat = { "!rocket" },
	ReturnOrder = "Victim-Delay",
	Args = {Victim = "PLAYER", Delay = "NUMBER"},
	Optional = { Delay = 5 },
})

PLUGIN:Register()
