-- Prefan Access Controller
-- Command Searcher

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Command Searcher",
	ID = "com-search",
	Desc = "A plugin that allows searching the command list!",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN.Search( ply, command )
		
		if !ply.LastSearch then ply.LastSearch = CurTime() end
		if CurTime() < ply.LastSearch then return { ply, COLOR.NORM, "Please wait, you are trying to search for commands too ", COLOR.NAME, "fast", COLOR.NORM, "!" } end
		ply.LastSearch = CurTime() + 10
		
		local data = {}
		-- Grab all the commands that contain the command
		for k,v in pairs( exsto.Commands ) do
			
			-- Check chat.
			for _, com in pairs( v.Chat ) do
				if string.find( com, command, 1, true ) then data[k] = v end
			end
			
			-- Check console.
			for _, com in pairs( v.Console ) do
				if string.find( com, command, 1, true ) then data[k] = v end
			end
			
		end
		
		-- Loop through the commands and send them to client print.
		exsto.Print( exsto_CLIENT, ply, " ---- Printing Exsto commands to console! ----" )
		exsto.Print( exsto_CLIENT, ply, " All console commands are proceded by 'exsto', I.E exsto rocket\n\n" )
		
		for k,v in pairs( data ) do
			-- Print the ID of the plugin, and description.
			exsto.Print( exsto_CLIENT_NOLOGO, ply, " Command ID: " .. k .. " - " .. v.Desc )
			exsto.Print( exsto_CLIENT_NOLOGO, ply, " 	-- Flag Description: " .. v.FlagDesc )
			
			-- Build the return order
			local retorder = ""
			local insert = ", "
			for k, arg in ipairs( v.ReturnOrder ) do
				if k == #v.ReturnOrder then insert = "" end
				retorder = retorder .. arg .. insert
			end
			
			exsto.Print( exsto_CLIENT_NOLOGO, ply, " 	-- Argument Order: " .. retorder )
			
			-- Build console commands
			local concommands = ""
			local numCommands = " Command: "
			local insert = ""
			if table.Count( v.Console ) > 1 then numCommands = " Commands: " insert = " OR " end
			for k, command in ipairs( v.Console ) do
				if k == #v.Console then insert = "" end
				concommands = concommands .. command .. insert
			end
			
			exsto.Print( exsto_CLIENT_NOLOGO, ply, " 	-- Console" .. numCommands .. concommands )
			
			-- Build chat commands
			local chatcommands = ""
			local numCommands = " Command: "
			local insert = ""
			if table.Count( v.Chat ) > 1 then numCommands = " Commands: " insert = " OR " end
			for k, command in ipairs( v.Chat ) do	
				if k == #v.Chat then insert = "" end
				chatcommands = chatcommands .. command .. insert
			end
			
			exsto.Print( exsto_CLIENT_NOLOGO, ply, " 	-- Chat" .. numCommands .. chatcommands )
			exsto.Print( exsto_CLIENT_NOLOGO, ply, "\n" )
		end
		
		exsto.Print( exsto_CLIENT, ply, " ---- End of Exsto help ---- \n" )
		
		return { ply, COLOR.NORM, "Printing all commands to your ", COLOR.NAME, "console", COLOR.NORM, "!" }
	end
	PLUGIN:AddCommand( "search", {
		Call = PLUGIN.Search,
		Desc = "Searches or lists commands",
		FlagDesc = "Allows users to search for commands.",
		Console = { "commands" },
		Chat = { "!search" },
		ReturnOrder = "Command",
		Args = {Command = "STRING"},
		Optional = {Command = ""},
	})
	
end

PLUGIN:Register()