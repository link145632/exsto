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
	
	function PLUGIN:DeleteEnvVar( owner, dirty )
		
		-- If we are an existing one.
		local existing = exsto.GetVar( dirty )
		if existing then
			exsto.Variables[ dirty ] = nil
			
			FEL.RemoveData( "exsto_data_variables", "Dirty", dirty )
			return { COLOR.NAME, owner:Nick(), COLOR.NORM, " has deleted environmental variable: ", COLOR.NAME, dirty, COLOR.NORM, "!" }
		end
		
		return { owner, COLOR.NORM, "No existing environmental variable for ", COLOR.NAME, dirty, COLOR.NORM, "!" }
		
	end
	PLUGIN:AddCommand( "deletevar", {
		Call = PLUGIN.DeleteEnvVar,
		Desc = "Allows users to delete environment variables.",
		Console = { "deleteenv" },
		Chat = { "!deleteenv" },
		ReturnOrder = "Variable",
		Args = {Variable = "STRING"},
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
				Data.EnvVar = v.EnvVar
				
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

	function PLUGIN:ExRecVars( vars )
		if !vars then return end
		self.Vars = vars
		Menu:EndLoad()
		if self.List then self.List:Refresh() end
	end
	PLUGIN:DataHook( "ExRecVars" )
	
	function PLUGIN:Build( panel )
		self.List = exsto.CreateListView( 10, 10, panel:GetWide() - 20, panel:GetTall() - 80, panel )
			self.List:AddColumn( "Name" )
			self.List:AddColumn( "ID" )
			self.List:AddColumn( "Value" )
			self.List:AddColumn( "Data Type" )
			
			self.List.Refresh = function( lst )
				lst:Clear()
				for _, data in ipairs( self.Vars ) do
					lst:AddLine( data.Pretty, data.Dirty, data.Value, data.DataType )
				end
			end
			self.List:Refresh()
			
			self.List.OnRowSelected = function( lst, line )
				self.CurrentLine = lst:GetLine( line )
				self.ShortBox:SetText( self.CurrentLine:GetValue( 2 ) )
				self.ShortBox:SetEditable( false )
				
				self.PossibleBox:Clear()
				
				for _, data in ipairs( self.Vars ) do
					if data.Dirty == self.CurrentLine:GetValue( 2 ) then
						if table.Count( data.Possible ) > 1 then
							-- He has possibles.
							self.PossibleBox:SetVisible( true )
							self.ValueBox:SetVisible( false )
							
							self.PossibleBox:SetText( tostring( self.CurrentLine:GetValue( 3 ) ) )
							
							for _, possible in ipairs( data.Possible ) do
								self.PossibleBox:AddChoice( tostring( possible ) )
							end
						else
							self.ValueBox:SetText( tostring( self.CurrentLine:GetValue( 3 ) ) )
							self.ValueBox:SetVisible( true )
							self.PossibleBox:SetVisible( false )
						end
						break
					end
				end
				
				self.DeleteVar:SetVisible( false )
				
				local found = false
				for _, data in ipairs( self.Vars ) do
					if data.Dirty == self.CurrentLine:GetValue( 2 ) then found = data break end
				end
				
				print( found )
				if type( found ) == "table" then PrintTable( found ) end
				
				if !found or tobool( found.EnvVar ) == true then
					-- Give him a delete option.
					self.DeleteVar:SetVisible( true )
				end
			end
			
		local function hideOnSelect( entry )
			if !entry.hideAble then return end
			entry:SetText( "" )
			entry.hideAble = false
		end
			
		self.ShortLabel = exsto.CreateLabel( 10, self.List:GetTall() + 20, "ID:", "arial", panel )
		self.ShortBox = exsto.CreateTextEntry( 30, self.List:GetTall() + 20, 140, 20, panel )
			self.ShortBox.OnMousePressed = hideOnSelect
			self.ShortBox.OnTextChanged = function( entry )
				self.CurrentLine:SetValue( 1, "envvar_" .. entry:GetValue() )
				self.CurrentLine:SetValue( 2, entry:GetValue() )
			end
			
		self.ValueLabel = exsto.CreateLabel( 10, self.List:GetTall() + 50, "Value:", "arial", panel )
		self.ValueBox = exsto.CreateTextEntry( 50, self.List:GetTall() + 50, 120, 20, panel )
			self.ValueBox.OnMousePressed = hideOnSelect
			self.ValueBox.OnTextChanged = function( entry )
				self.CurrentLine:SetValue( 3, entry:GetValue() )
			end
		self.PossibleBox = exsto.CreateMultiChoice( 50, self.List:GetTall() + 50, 120, 20, panel )
			self.PossibleBox:SetVisible( false )
			self.PossibleBox:SetEditable( false )
			self.PossibleBox.OnSelect = function( index, value, data )
				self.CurrentLine:SetValue( 3, data )
			end
		
		self.ChangeButton = exsto.CreateButton( panel:GetWide() - 80, panel:GetTall() - 40, 74, 27, "Change", panel )
			self.ChangeButton:SetStyle( "positive" )
			self.ChangeButton.OnClick = function( button )
				local short = self.CurrentLine:GetValue( 2 )
				local done = false
				for _, data in ipairs( self.Vars ) do
					if data.Dirty == short then
						RunConsoleCommand( "exsto", "changevar", data.Dirty, tostring( self.CurrentLine:GetValue( 3 ) ) )
						done = true
						break
					end
				end 
				if done then return end
				
				-- Apparently, its an new var
				RunConsoleCommand( "exsto", "createenv", short, self.CurrentLine:GetValue( 3 ) )
			end
			
		self.CreateVar = exsto.CreateButton( 0, panel:GetTall() - 40, 94, 27, "Create Var", panel )
			self.CreateVar:MoveLeftOf( self.ChangeButton, 15 )
			self.CreateVar:SetStyle( "positive" )
			self.CreateVar.OnClick = function( button )
				self.ShortBox.hideAble = true
				self.ValueBox.hideAble = true
				
				local line = self.List:AddLine( "envvar_create_new", "create_new", "value", "string" )
				self.List:OnClickLine( line, true )
				
				self.ShortBox:SetText( "create_new" )
				self.ShortBox:SetEditable( true )
				self.ValueBox:SetText( "value" )
				self.ValueBox:SetVisible( true )
				self.PossibleBox:SetVisible( false )
			end
			
		self.Refresh = exsto.CreateButton( 0, panel:GetTall() - 40, 74, 27, "Refresh", panel )
			self.Refresh:MoveLeftOf( self.CreateVar, 15 )
			self.Refresh.OnClick = function()
				self:RefreshVars( panel )
			end
			
		self.DeleteVar = exsto.CreateButton( 0, panel:GetTall() - 40, 74, 27, "Delete", panel )
			self.DeleteVar:MoveLeftOf( self.Refresh, 15 )
			self.DeleteVar:SetVisible( false )
			self.DeleteVar.OnClick = function()
				RunConsoleCommand( "exsto", "deleteenv", self.CurrentLine:GetValue( 2 ) )
				self:RefreshVars( panel )
			end
	end
	
	function PLUGIN:RefreshVars( panel )
		Menu:PushLoad()
		RunConsoleCommand( "_RequestVars" )
		self.Vars = nil
		self:Ping( panel )
	end 
	
	function PLUGIN:Ping( panel )
		if type( self.Vars ) != "table" then
			timer.Simple( 0.1, PLUGIN.Ping, PLUGIN, panel )
			return
		end
		if self.List then return end
		self:Build( panel )
	end
	
	Menu:CreatePage({
		Title = "Variable Editor",
		Short = "vareditor",
	}, function( panel )
		PLUGIN:RefreshVars( panel )
	end )
	
end
 
PLUGIN:Register()