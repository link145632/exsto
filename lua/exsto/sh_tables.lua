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


-- To make life a little easier...

COLOR = {}
	COLOR.NORM = Color( 255, 252, 229, 255 )
	COLOR.PAC = Color( 100, 100, 100, 255 )
	COLOR.RED = Color( 200, 50, 50, 255 )
	COLOR.GREEN = Color( 50, 200, 50, 255 )
	COLOR.BLUE = Color( 50, 50, 200, 255 )
	COLOR.EXSTO = Color( 146, 232, 136, 255 )
	COLOR.NAME = Color( 255, 105, 105, 255 )
	
-- Color to Text support
CTEXT ={}

for k,v in pairs( COLOR ) do
	CTEXT[tostring( k ):lower()] = v
end

	
-- Helper Functions
function exsto.SmartNumber( tbl )
	local number = 0
	for k,v in pairs( tbl ) do
		number = number + 1
	end
	return number
end

function exsto.GetTableID( tbl, value )
	for k,v in pairs( tbl ) do if v == value then return k end end
end

function exsto.TextToColor( text )
	return CTEXT[text] or nil
end

function exsto.ColorToText( col )
	for k,v in pairs( CTEXT ) do
		if v == col then return k end
	end
	
	return col
end

function exsto.ParseVarType( value )
	
	if type( value ) == "boolean" then return "boolean" end
	if type( value ) == "number" then return "number" end

	value = value:lower():Trim()

	if value == "true" or value == "false" then return "boolean" end
	if tonumber( value ) then return "number" end
	
	return "string"
	
end

local dataTypes = {
	string = function( data ) return tostring( data ), "string" end,
	boolean = function( data ) return tobool( data ), "boolean" end,
	number = function( data ) return tonumber( data ), "number" end,
}
	
function exsto.FormatValue( value, type )
	return dataTypes[type]( value )
end

-- RANKSSSS

exsto.DefaultRanks = {
	superadmin = {
		Name = "Super Admin",
		Desc = "Head Honcho",
		Short = "superadmin",
		Color = Color( 60, 124, 200, 200 ),
		Derive = "admin",
		Immunity = 0,
		
		Flags = {
			"command",
			"rank",
			"refreshlocations",
			"reloadplug",
			"rankeditor",
			"vareditor",
			"savepanel",
			"setpanelpos",
			"setpanelang",
			"issuperadmin",
			"luarun",
			"cexec",
		}
	},
	
	admin = {
		Name = "Admin",
		Desc = "The Guy.",
		Short = "admin",
		Color = Color( 60, 124, 100, 200 ),
		Derive = "guest",
		Immunity = 1,
		
		Flags = {
			"slay",
			"kick",
			"ban",
			"unban",
			"variable",
			"color",
			"freeze",
			"unfreeze",
			"gimp",
			"goto",
			"bring",
			"noclip",
			"playerpickup",
			"changelvl",
			"reloadmap",
			"rocketman",
			"slap",
			"spectate",
			"unspectate",
			"update",
			"banlist",
			"isadmin",
			"sethealth",
			"setarmor",
			"godmode",
			"mute",
			"gag",
			"returnweps",
			"stripweps",
			"ignite",
			"adminsay",
			"chatnotify",
			"mapslist",
			"send",
		}
	},
	
	guest = {
		Name = "Guest",
		Desc = "A visitor to the server!",
		Short = "guest",
		Color = Color( 200, 124, 200, 200 ),
		Derive = "NONE",
		Immunity = 9,
		
		Flags = {
			"search",
			"getrank",
			"togglechatanim",
			"menu",
			"updateownerrank",
			"getvariable",
			"helppage",
			"playerlist",
			"checkversion",
		}
	}
}

exsto.GMHooks = {
	"AcceptStream",
	"CanExitVehicle",
	"CanPlayerSuicide",
	"CanPlayerUnfreeze",
	"CreateEntityRagdoll",
	"DoPlayerDeath",
	"EntityTakeDamage",
	"GravGunOnDropped",
	"GravGunOnPickedUp",
	"GravGunPickupAllowed",
	"GetFallDamage",
	"IsSpawnpointSuitable",
	"OnDamagedByExplosion",
	"OnNPCKilled",
	"OnPhysgunFreeze",
	"OnPhysgunReload",
	"OnPlayerChangedTeam",
	"PlayerCanHearPlayersVoice",
	"PlayerCanJoinTeam",
	"PlayerCanPickupWeapon",
	"PlayerCanSeePlayersChat",
	"PlayerDeath",
	"PlayerHurt",
	"PlayerSilentDeath",
	"PlayerDeathSound",
	"PlayerDeathThink",
	"PlayerDisconnected",
	"PlayerInitialSpawn",
	"PlayerJoinTeam",
	"PlayerLeaveVehicle",
	"PlayerLoadout",
	"PlayerNoClip",
	"PlayerRequestTeam",
	"PlayerSay",
	"PlayerSelectSpawn",
	"PlayerSelectTeamSpawn",
	"PlayerSetModel",
	"PlayerSpawn",
	"PlayerSpawnAsSpectator",
	"PlayerSpray",
	"PlayerSwitchFlashlight",
	"PlayerUse",
	"ScaleNPCDamage",
	"ScalePlayerDamage",
	"SetPlayerAnimation",
	"SetupPlayerVisibility",
	"ShowHelp",
	"ShowSpare1",
	"ShowSpare2",
	"WeaponEquip",
	"CanPlayerEnterVehicle",
	"CompletedIncomingStream",
	"ContextScreenClick",
	"CreateTeams",
	"EntityKeyValue",
	"EntityRemoved",
	"FinishMove",
	"GetGameDescription",
	"GravGunPunt",
	"InitPostEntity",
	"Initialize",
	"KeyPress",
	"KeyRelease",
	"Move",
	"OnEntityCreated",
	"OnPlayerHitGround",
	"PhysgunDrop",
	"PhysgunPickup",
	"PlayerAuthed",
	"PlayerConnect",
	"PlayerEnteredVehicle",
	"PlayerFootstep",
	"PlayerShouldTakeDamage",
	"PlayerStepSoundTime",
	"PlayerTraceAttack",
	"PropBreak",
	"Restored",
	"Saved",
	"SetPlayerSpeed",
	"SetupMove",
	"ShouldCollide",
	"ShowTeam",
	"ShutDown",
	"Think",
	"Tick",
	"UpdateAnimation",
	"exsto_InitSpawn",
	"exsto_ResendRanks",
	"PlayerPasswordAuth",
	"AddDeathNotice",
	"AdjustMouseSensitivity",
	"CalcVehicleThirdPersonView",
	"CalcView",
	"CallScreenClickHook",
	"ChatText",
	"ChatTextChanged",
	"CreateMove",
	"DrawDeathNotice",
	"FinishChat",
	"ForceDermaSkin",
	"GUIMouseDoublePressed",
	"GUIMousePressed",
	"GUIMouseReleased",
	"GetMotionBlurValues",
	"GetTeamColor",
	"GetTeamNumColor",
	"GetTeamScoreInfo",
	"GetVehicles",
	"HUDAmmoPickedUp",
	"HUDDrawPickupHistory",
	"HUDDrawScoreBoard",
	"HUDDrawTargetID",
	"HUDItemPickedUp",
	"HUDPaint",
	"HUDPaintBackground",
	"HUDShouldDraw",
	"HUDWeaponPickedUp",
	"InputMouseApply",
	"OnChatTab",
	"OnContextMenuOpen",
	"OnContextMenuClose",
	"OnPlayerChat",
	"OnSpawnMenuOpen",
	"OnSpawnMenuClose",
	"PlayerBindPress",
	"PlayerEndVoice",
	"PlayerStartVoice",
	"PopulateToolMenu",
	"PostPlayerDraw",
	"PostDrawSkybox",
	"PostDrawOpaqueRenderables",
	"PostDrawTranslucentRenderables",
	"PostProcessPermitted",
	"PostReloadToolsMenu",
	"PostRenderVGUI",
	"PrePlayerDraw",
	"PreDrawSkybox",
	"PreDrawOpaqueRenderables",
	"PreDrawTranslucentRenderables",
	"PreReloadToolsMenu",
	"RenderScene",
	"RenderScreenspaceEffects",
	"ScoreboardHide",
	"ScoreboardShow",
	"ShouldDrawLocalPlayer",
	"StartChat",
	"SuppressHint",
}