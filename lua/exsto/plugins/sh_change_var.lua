-- Prefan Access Controller
-- Var changing plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Variable Changer",
	ID = "change-var",
	Desc = "A plugin that allows management over variables!",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN:CreateEnvVar( owner, dirty, value )
		
		-- If we are creating an existing one.
		local existing = exsto.GetVar( dirty )
		if existing then
			
			-- Check if it is an env var.  Update if it is.
			if existing.EnvVar == true then
				exsto.Variables[ dirty ].Value = value
				exsto.Variables[ dirty ].DataType = type( value )
				
				return { owner, COLOR.NORM, "Updating existing env var ", COLOR.NAME, dirty, COLOR.NORM, " with value: ", COLOR.NAME, value, COLOR.NORM, "!" }
			-- It is an existing Exsto hard-coded variable.  End it!
			else
				return { owner, COLOR.NORM, "An existing Exsto global variable already exists for ", COLOR.NAME, dirty, COLOR.NORM, "!" }
			end
			
		end
		
		-- Create it.
		exsto.AddEnvironmentVar( dirty, value )
		return { COLOR.NAME, owner:Nick(), COLOR.NORM, " has created a new environment variable: ", COLOR.NAME, dirty, COLOR.NORM, "!" }
			
	end
	PLUGIN:AddCommand( "createvar", {
		Call = PLUGIN.CreateEnvVar,
		Desc = "Allows users to create environment variables.",
		Console = { "createenv" },
		Chat = { "!createenv" },
		ReturnOrder = "Variable-Value",
		Args = {Variable = "STRING", Value = "STRING"},
		Category = "Variables",
	})

	function PLUGIN:ChangeVar( owner, var, value )
	
		local variable = exsto.GetVar( var )
		
		if !variable then
			return { owner, COLOR.NORM, "There is no variable named ", COLOR.NAME, var, COLOR.NORM, "!" }
		end

		local done = exsto.SetVar( var, value )
		
		if done then
			return { COLOR.NAME, var, COLOR.NORM, " has been set to ", COLOR.NAME, value, COLOR.NORM, "!" }
		else
			return { owner, COLOR.NORM, "The variables callback refuses the data set request!" }
		end
		
	end
	PLUGIN:AddCommand( "variable", {
		Call = PLUGIN.ChangeVar,
		Desc = "Allows users to change exsto variables.",
		Console = { "changevar" },
		Chat = { "!setvariable" },
		ReturnOrder = "Variable-Value",
		Args = {Variable = "STRING", Value = "STRING"},
		Category = "Variables",
	})
	
	function PLUGIN:GetVar( owner, var )
	
		local value = exsto.GetVar( var ).Value
		
		if !value then
			return { owner, COLOR.NORM, "There is no variable named ", COLOR.NAME, var, COLOR.NORM, "!" }
		else
			return { owner, COLOR.NAME, var, COLOR.NORM, " is set to ", COLOR.NAME, tostring( value ), COLOR.NORM, "!" }
		end
	end
	PLUGIN:AddCommand( "getvariable", {
		Call = PLUGIN.GetVar,
		Desc = "Allows users to view variable values.",
		Console = { "getvariable" },
		Chat = { "!getvariable" },
		ReturnOrder = "Variable",
		Args = {Variable = "STRING"},
		Category = "Variables",
	})
	
	local function SendVars( ply )
	
		local Send = {}
		for k,v in pairs( exsto.Variables ) do
			local Data = {}
				Data.Pretty = v.Pretty
				Data.Dirty = v.Dirty
				Data.Value = v.Value
				Data.DataType = v.DataType
				Data.Description = v.Description
				Data.Possible = v.Possible
				
			table.insert( Send, Data )
		end
	
		exsto.UMStart( "ExRecVars", ply, Send )
		
	end
	concommand.Add( "_RequestVars", SendVars )
	
	local function SetVar( ply, data )
		exsto.SetVar( data[1], data[2] )
	end
	exsto.ClientHook( "ExRecVarChange", SetVar )
	
elseif CLIENT then

	local title;
	local list;
	local ClientVars = {}
	
	local function RefreshClientView()
	
		list:Clear()
	
		for k,v in pairs( ClientVars ) do

			list:AddLine( v.Pretty, v.Dirty, v.Value ):SetTooltip( v.Description or "No Description Provided" )
			
		end
		
	end
	
	function PLUGIN.RecieveVars( vars )
	
		ClientVars = vars
		RefreshClientView()
		Menu.EndLoad()
		
	end
	exsto.UMHook( "ExRecVars", PLUGIN.RecieveVars )

	--[[Menu.CreatePage( {
		Title = "Variable Editor",
		Short = "vareditor",
		Flag = "vareditor",
		}, 
		function( panel )
	
		local curVar;
		local curLine;

		list = exsto.CreateListView( 5, 5, panel:GetWide() - 10, 400, panel )
			list.Color = Color( 224, 224, 224, 255 )
			
			list.HoverColor = Color( 229, 229, 229, 255 )
			list.SelectColor = Color( 149, 227, 134, 255 )
			
			list:SetHeaderHeight( 40 )
			list.Round = 8
			list.ColumnFont = "exstoPlyColumn"
			list.ColumnTextCol = Color( 140, 140, 140, 255 )

			list.LineFont = "exstoDataLines"
			list.LineTextCol = Color( 164, 164, 164, 255 )
			
			list:AddColumn( "Pretty" )
			list:AddColumn( "Dirty" ):SetFixedWidth( 200 )
			list:AddColumn( "Value" ):SetFixedWidth( 45 )
			
		Menu.PushLoad()
		RunConsoleCommand( "_RequestVars" )
		
		local PrettyPanel = exsto.CreateLabeledPanel( 5, 415, (panel:GetWide() / 2) - 20, 40, "Name", Color( 232, 232, 232, 255 ), panel )
		local PrettyEntry = exsto.CreateTextEntry( 5, 10, PrettyPanel:GetWide() - 10, 20, PrettyPanel )
			PrettyEntry:SetEditable( false )
			PrettyPanel.Label:SetFont( "labeledPanelFont" )
		
		local DirtyPanel = exsto.CreateLabeledPanel( 5, 475, (panel:GetWide() / 2) - 20, 40, "Short", Color( 232, 232, 232, 255 ), panel )
		local DirtyEntry = exsto.CreateTextEntry( 5, 10, DirtyPanel:GetWide() - 10, 20, DirtyPanel )
			DirtyEntry:SetEditable( false )
			DirtyPanel.Label:SetFont( "labeledPanelFont" )
		
		local ValuePanel = exsto.CreateLabeledPanel( (panel:GetWide() / 2), 475, (panel:GetWide() / 2) - 20, 40, "Value", Color( 232, 232, 232, 255 ), panel )
		local ValueEntry = exsto.CreateTextEntry( 5, 10, ValuePanel:GetWide() - 10, 20, ValuePanel )
		local NCValueEntry = exsto.CreateMultiChoice( 5, 10, ValuePanel:GetWide() - 10, 20, ValuePanel )
			NCValueEntry:SetVisible( false )
			NCValueEntry:SetEditable( false )
			ValuePanel.Label:SetFont( "labeledPanelFont" )
		
		local TypePanel = exsto.CreateLabeledPanel( (panel:GetWide() / 2), 415, (panel:GetWide() / 2) - 20, 40, "Data Type", Color( 232, 232, 232, 255 ), panel )
		local TypeEntry = exsto.CreateTextEntry( 5, 10, TypePanel:GetWide() - 10, 20, TypePanel )
			TypeEntry:SetEditable( false )
			TypePanel.Label:SetFont( "labeledPanelFont" )
			
		local RefreshButton = exsto.CreateButton( 5, 525, 112, 27, "Refresh Vars", panel )
		local UpdateButton = exsto.CreateButton( 120, 525, 107, 27, "Update Vars", panel )
		
		RefreshButton.DoClick = function() Menu.PushLoad() RunConsoleCommand( "_RequestVars" ) end
		UpdateButton.DoClick = function() exsto.SendToServer( "ExRecVarChange", list:GetSelected()[1]:GetValue( 2 ), list:GetSelected()[1]:GetValue( 3 ) ) end
		
		local oldClick = list.OnClickLine
		list.OnClickLine = function( parent, line, selected )
			oldClick( parent, line, selected )
			
			local varTable = -1
			
			for k,v in pairs( ClientVars ) do
				if v.Pretty == line:GetValue(1) then varTable = ClientVars[k] end
			end
			
			if varTable == -1 then return end
			curVar = varTable
			curLine = line
			
			PrettyEntry:SetText( tostring( varTable.Pretty ) )
			DirtyEntry:SetText( tostring( varTable.Dirty ) )
			TypeEntry:SetText( tostring( PLUGIN.ParseType( varTable.Value ) ) )
			NCValueEntry:Clear()
			
			if #varTable.Possible >= 1 then
				
				NCValueEntry:SetText( tostring( varTable.Value ) )

				for k,v in pairs( varTable.Possible ) do

					NCValueEntry:AddChoice( tostring( v ) )

				end
				
				ValueEntry:SetVisible( false )
				NCValueEntry:SetVisible( true )
				
			else
			
				ValueEntry:SetText( tostring( varTable.Value ) )
				ValueEntry:SetVisible( true )
				NCValueEntry:SetVisible( false )
				
			end
			
		end
		
		local function PerformSelect( entry )
		
			if !curVar or !curLine then return end
			if type( entry ) == "string" then entry = entry else entry = entry:GetValue() end
			
			curLine:SetValue( 3, entry )
			TypeEntry:SetText( PLUGIN.ParseType( entry ) )
			
		end
		ValueEntry.OnTextChanged = PerformSelect
		NCValueEntry.OnSelect = function( index, value, data ) PerformSelect( data ) end

	end )
	
	function PLUGIN.ParseType( text )
	
		if type( text ) == "boolean" then return "boolean" end
		if type( text ) == "number" then return "integer" end
		
		if type( text ) != "string" then return "unknown" end
	
		text = text:lower():Trim()
	
		if text == "true" or text == "false" then return "boolean" end
		if tonumber( text ) then return "integer" end
		
		return "string"
		
	end]]
	
end
 
PLUGIN:Register()