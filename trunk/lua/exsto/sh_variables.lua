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


-- EVC (Exsto Var Controller)
-- Rewritten 2/22/10

if SERVER then

	FEL.MakeTable( "exsto_data_variables", {
		Pretty = "varchar(255)",
		Dirty = "varchar(255)",
		Value = "varchar(255)",
		DataType = "varchar(255)",
		Description = "varchar(255)",
		Possible = "varchar(255)"
		}
	)

	exsto.Variables = {}
	
	--[[exsto.AddVariable({
		Pretty = "Hello",
		Dirty = "hello",
		Default = true,
		OnChange = thisFunction,
		Description = "This is hello!",
		Possible = { true, false }
		})
	]]
	
	local dataTypes = {
		string = function( data ) return tostring( data ), "string" end,
		boolean = function( data ) return tobool( data ), "boolean" end,
		number = function( data ) return tonumber( data ), "number" end,
	}

	function exsto.AddVariable( data )
		if type( data ) != "table" then exsto.ErrorNoHalt( "Issue creating variable!  Not continuing in this function call!" ) return end
		
		if exsto.FindVar( data.Dirty ) then
			-- Update its callback function.  Those don't save through!
			exsto.Variables[data.Dirty].OnChange = data.OnChange
			return false
		end
		
		local filler_function = function( val ) return true end
		
		exsto.Variables[data.Dirty] = {
			Pretty = data.Pretty,
			Dirty = data.Dirty,
			Value = data.Default,
			DataType = type( data.Default ),
			Description = data.Description or "No Description Provided!",
			OnChange = data.OnChange or filler_function,
			Possible = data.Possible or {},
		}
		
		exsto.Print( exsto_CONSOLE_DEBUG, "EVC --> " .. data.Dirty .. " --> Adding from function, was not in database!" )
		exsto.SaveVarInfo( data.Dirty )

	end
	
	function exsto.SetVar( dirty, value )
		local var = exsto.FindVar( dirty ) 
		if !var then return end

		value = dataTypes[var.DataType]( value )
		
		-- If our variable has a callback, and he accepted it
		if var.OnChange and var.OnChange( value ) then
			exsto.Variables[dirty].Value = value -- Set it!
			exsto.SaveVarInfo( dirty )
			return true
		elseif !var.OnChange then -- If we happen to not have a callback, just set it and go
			exsto.Variables[dirty].Value = value
			exsto.SaveVarInfo( dirty )
			return true
		end
		
		-- If we didn't accept the value, return false
		return false		
	end
	
	function exsto.SaveVarInfo( dirty )
		local var = exsto.FindVar( dirty )		
		FEL.AddData( "exsto_data_variables", {
			Look = {
				Dirty = var.Dirty,
			},
			Data = {
				Pretty = var.Pretty,
				Dirty = var.Dirty,
				Value = var.Value,
				DataType = var.DataType,
				Description = var.Description,
				Possible = FEL.NiceEncode( var.Possible ),
			},
		} )
	end

	function exsto.GetVar( dirty )
		return exsto.Variables[dirty]
	end
	
	concommand.Add( "_PrintVarTable", function() PrintTable( exsto.Variables ) end)
	
	function exsto.ParseVarType( value )
	
		if type( value ) == "boolean" then return "boolean" end
		if type( value ) == "number" then return "number" end

		value = value:lower():Trim()
	
		if value == "true" or value == "false" then return "boolean" end
		if tonumber( value ) then return "number" end
		
		return "string"
		
	end
	
	function exsto.Variable_Load()
		local vars = FEL.LoadTable( "exsto_data_variables" )

		if !vars then return end

		for k,v in pairs( vars ) do
			
			exsto.Print( exsto_CONSOLE, "EVC --> Loading variable " .. v.Pretty .. "!" )
		
			local oldchange = exsto.Variables[v.Dirty]
			if oldchange and oldchange.OnChange then oldchange = oldchange.OnChange end
			
			-- Fix the data type.
			local datatype = exsto.ParseVarType( v.Value )
			local value = dataTypes[datatype]( v.Value )
			//print( "New type is " .. tostring( datatype ) )
			
			print( datatype, value )
			
			exsto.Variables[v.Dirty] = {
				Pretty = v.Pretty,
				Dirty = v.Dirty,
				Value = value,
				DataType = datatype,
				Description = v.Description,
				OnChange = oldchange or nil,
				Possible = FEL.NiceDecode( v.Possible ),
			}
		end
		
	end
	
	concommand.Add( "_LoadVars", function() exsto.Variable_Load() end )
	concommand.Add( "_SaveVars", function() exsto.Variable_Save() end )

	function exsto.FindVar( var )
		if !exsto.Variables then return false end
		return exsto.Variables[var]
	end

	exsto.Variable_Load()
end
