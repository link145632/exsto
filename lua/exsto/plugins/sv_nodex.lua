 -- Exsto
 -- ECS Compatibility

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Nodex",
	ID = "nodex_stuff",
	Desc = "A plugin that creates a layer between Exsto and Nodex.",
	Owner = "Prefanatic",
} )

-- Create flags.
exsto.CreateFlag( "ecs", "Grants users basic ECS rights." )
exsto.CreateFlag( "ecs0advanced", "Grants users more advanced ECS rights." )
exsto.CreateFlag( "ecs0admin", "Grants users ECS Administration rights." )
exsto.CreateFlag( "noweapons", "Makes users spawn with no weapons." )

PLUGIN:Register()
