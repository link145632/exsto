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

function PLUGIN.Update( owner, folder )

	if !svn then
		return { owner, COLOR.NORM, "Please install the gm_svn module to use this command!" }
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
