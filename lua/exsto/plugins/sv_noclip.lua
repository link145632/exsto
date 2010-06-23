 -- Exsto
 -- Noclip Plugin 

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Noclip",
	ID = "noclip",
	Desc = "A plugin that allows noclipping!",
	Owner = "Prefanatic",
} )

PLUGIN:AddVariable({
	Pretty = "Admin Only Noclip",
	Dirty = "admin_noclip",
	Default = true,
	Description = "Makes it so only admins can noclip",
	Possible = { true, false }
})

function PLUGIN:NoClip( ply, victim )

	local movetype = victim:GetMoveType()
	local changeto = MOVETYPE_NOCLIP
	local style = "noclip"
	
	if movetype == MOVETYPE_NOCLIP then
		changeto = MOVETYPE_WALK	
		style = "walk"
	end
	
	victim:SetMoveType( changeto )
	
	return {
		Activator = ply,
		Player = victim,
		Wording = " has set ",
		Secondary = " to " .. style,
	}	
	
end
PLUGIN:AddCommand( "noclip", {
	Call = PLUGIN.NoClip,
	Desc = "Noclips a player",
	FlagDesc = "Allows users to use noclip on other players.",
	Console = { "noclip" },
	Chat = { "!noclip" },
	ReturnOrder = "Victim",
	Args = { Victim = "PLAYER" },
	Optional = { Victim = nil }
})

function PLUGIN:PlayerNoClip( ply )

	if exsto.GetVar( "admin_noclip" ).Value then
		if ply:IsAdmin() then return true end -- If hes admin, then tell him he can go
		return false -- Hes not an admin, end it.
	end

end

PLUGIN:Register()
