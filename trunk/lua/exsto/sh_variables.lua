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
	
	local dataTypes = {
		string = function( data ) return tostring( data ), "string" end,
		boolean = function( data ) return tobool( data ), "boolean" end,
		number = function( data ) return tonumber( data ), "number" end,
	}

	--[[ -----------------------------------
	Function: exsto.AddVariable
	Description: Creates a variable and inserts it into the Exsto table.
     ----------------------------------- ]]
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
	
	--[[ -----------------------------------
	Function: exsto.SetVar
	Description: Sets a variable to be a certian value, then calls the callback.
     ----------------------------------- ]]
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
	
	--[[ -----------------------------------
	Function: exsto.SaveVarInfo
	Description: Saves the variable's information to FEL.
     ----------------------------------- ]]
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
			Options = {
				Update = true,
				Threaded = true,
			}
		} )
	end
	
	--[[ -----------------------------------
	Function: exsto.GetVar
	Description: Returns a variable's data table.
     ----------------------------------- ]]
	function exsto.GetVar( dirty )
		return exsto.Variables[dirty]
	end
	exsto.FindVar = exsto.GetVar
	
	--[[ -----------------------------------
	Function: exsto.Variable_Load
	Description: Loads all existing exsto variables.
     ----------------------------------- ]]
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

	exsto.Variable_Load()
end
