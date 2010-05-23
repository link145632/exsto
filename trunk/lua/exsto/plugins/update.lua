-- Prefan Access Controller
-- exsto SVN Update'er

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Update",
	ID = "svn-update",
	Desc = "A plugin that allows updating of Exsto!",
	Owner = "Prefanatic",
} )

if not SERVER then return end

local svn = require( "svn" )

PLUGIN.Latest = 0
PLUGIN.Current = 0

function PLUGIN.CheckForUpdate( ply )

	PLUGIN.Current = file.Read( "exsto_version.txt" )

	http.Get( "http://94.23.154.153/Exsto/version.php?simple=true", "", function( contents, size )
		PLUGIN.Latest = tostring( contents )
		
		if PLUGIN.Latest == 0 then return end
		if ply:IsSuperAdmin() and PLUGIN.Latest > PLUGIN.Current then
			exsto.Print( exsto_CHAT, ply, COLOR.NORM, "Update Availible: Revision ", COLOR.NAME, tostring( PLUGIN.Latest ), COLOR.NORM, "!" )
			
			local style = "revision"
			if ( PLUGIN.Latest - PLUGIN.Current ) > 1 then style = "revisions" end
			
			exsto.Print( exsto_CHAT, ply, COLOR.NORM, "Exsto is currently ", COLOR.NAME, tostring( PLUGIN.Latest - PLUGIN.Current ) .. " " .. style, COLOR.NORM, " behind!" )
		end
	end )
	
end
concommand.Add( "_checkupdate", PLUGIN.CheckForUpdate )

function PLUGIN.CheckVersion( owner )

	PLUGIN.Current = file.Read( "exsto_version.txt" )
	
	exsto.Print( exsto_CHAT, owner, COLOR.NORM, "Currently running revision ", COLOR.NAME, tostring( PLUGIN.Current ), COLOR.NORM, "!" )
	
	PLUGIN.CheckForUpdate( owner )

end
PLUGIN:AddCommand( "checkversion", {
	Call = PLUGIN.CheckVersion,
	Desc = "Checks the version of Exsto.",
	FlagDesc = "Allows users to check and see the version of Exsto.",
	Console = { "version" },
	Chat = { "!version" },
	Args = {},
})

function PLUGIN.Update( owner, folder )

	if !svn then
		return { owner, COLOR.NORM, "Please install the ", COLOR.NAME, "gm_svn module", COLOR.NORM, " to update Exsto through Garry's Mod!" }
	end

	local update = svn.update( "garrysmod/addons/" .. folder )

	exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Updating Exsto to revision ", COLOR.NAME, update )

end
PLUGIN:AddCommand( "update", {
	Call = PLUGIN.Update,
	Desc = "Updates Exsto",
	FlagDesc = "Allows users to update the server via SVN.",
	Console = { "update" },
	Chat = { "!update" },
	ReturnOrder = "Folder",
	Args = { Folder = "STRING" },
	Optional = { Folder = "exsto" },
})

PLUGIN:Register()
