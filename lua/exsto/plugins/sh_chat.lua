-- Chat Messings!
-- chat.AddText() Override to work with this chat engine :(

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Custom Chat",
	ID = "cl-chat",
	Desc = "A cool custom chat with supporting animations.",
	Owner = "Prefanatic",
} )

if SERVER then

	-- Can we do this a different way? :(
	local function OnVarChange( val )
		for k,v in pairs( player.GetAll() ) do
			PLUGIN.SetExstoColors( v, val )
		end
		return true
	end
	PLUGIN:AddVariable({
		Pretty = "Override Team Colors with Exsto Colors",
		Dirty = "native_exsto_colors",
		Default = false,
		Description = "Enable to have Exsto over-ride team colors with rank colors.",
		OnChange = OnVarChange,
		Possible = { true, false }
	})

	resource.AddFile( "sound/name_said.wav" )

	local meta = FindMetaTable( "Player" )
	
	hook.Add( "exsto_InitSpawn", "exsto_SendComTable", function( ply )
		PLUGIN.SetExstoColors( ply, exsto.GetVar( "native_exsto_colors" ).Value )
	end)
	
	local Anims = true
	
	function PLUGIN:ToggleAnims( owner )
		exsto.UMStart( "PLUGIN_toggleanims", owner )
	end	
	PLUGIN:AddCommand( "togglechatanim", {
		Call = PLUGIN.ToggleAnims,
		Desc = "Toggles chat animations",
		FlagDesc = "Allows users to toggle chat animations on or off.",
		Console = { "togglechatanims" },
		Chat = { "!chatanim" },
		Args = {},
	})
	
	function PLUGIN.SetExstoColors( person, value )
		exsto.UMStart( "PLUGIN_setcolors", person, value )
	end
	
elseif CLIENT then

	surface.CreateFont( "coolvetica", 20, 400, true, false, "ChatText" )

	PLUGIN.Lines = {}
	PLUGIN.Open = false
	
	PLUGIN.Entry = nil
	PLUGIN.Panel = nil
	PLUGIN.CurrentText = ""
	
	PLUGIN.W = ScrW()
	PLUGIN.H = ScrH()
	PLUGIN.X = 35
	PLUGIN.Y = PLUGIN.H - 210
	
	PLUGIN.G_W = 0
	PLUGIN.G_Text = "Chat"
	
	PLUGIN.Font = "ChatText"
	PLUGIN.StayTime = 10
	
	PLUGIN.NextInterval = 0
	PLUGIN.CursorInterval = 1
	PLUGIN.Blink = false
	
	PLUGIN.OutlineCol = Color( 0, 0, 0, 100 )
	PLUGIN.Box_Alpha = 0
	
	PLUGIN.UseAnims = true
	
	PLUGIN.LastSound = 0
		
	function PLUGIN.ToggleChatAnims()
	
		PLUGIN.UseAnims = !PLUGIN.UseAnims
		
		local Status = "ENABLED"
		if !PLUGIN.UseAnims then
			Status = "DISABLED"
		end
		
		chat.AddText( COLOR.NORM, "Chat animations have been ", COLOR.NAME, Status )
		
	end
	exsto.UMHook( "PLUGIN_toggleanims", PLUGIN.ToggleChatAnims )
	
	function PLUGIN.SetColors( val )
		PLUGIN.UseExstoColors = val
	end
	exsto.UMHook( "PLUGIN_setcolors", PLUGIN.SetColors )
		
	function PLUGIN.Init()

		PLUGIN.Entry = vgui.Create( "DTextEntry" )
		PLUGIN.Entry:SetPos( 35, PLUGIN.H - 310 )
		PLUGIN.Entry:SetSize( 0, 0 )
		PLUGIN.Entry:SetVisible( false )
		PLUGIN.Entry:SetEditable( false )
		
		PLUGIN.Open = false
		
	end

	function PLUGIN:OnStartChat( )

		PLUGIN.Open = true
		PLUGIN.Entry:SetVisible( true )
		gui.EnableScreenClicker( true )
		
		PLUGIN.G_Text = "Chat"
		PLUGIN.UpdateGlobalW( PLUGIN.G_Text )
		
		return true
		
	end

	function PLUGIN:OnFinishChat()

		PLUGIN.Open = false
		PLUGIN.Entry:SetVisible( false )
		gui.EnableScreenClicker( false )
		
		return true
		
	end

	function string.FindStart( norm, find )

		local find_len = string.len( find )
		local look = string.sub( norm, 1, find_len )
		
		if look:find( find, 1, true ) then return true end
		return false
		
	end
	
	function string.First( txt )
		return string.sub( txt, 0, 1 )
	end
	
	local Find_List = {}
	
	hook.Add( "ExRecCommands", "exstoWaitForCommands", function()
		PLUGIN.CommandsRecieved = true
	end )

	function PLUGIN:OnChatTextChanged( text )
	
		surface.SetFont( PLUGIN.Font )

		-- TODO: Arguments inside the find table
		
		-- CPU Intensive? test.
		local first = string.Explode( " ", text )
		if self.CommandsRecieved and first[1] != "" and first[1]:First() == "!" then
		
			Find_List = {}
			
			PLUGIN.G_Text = "Exsto"
			PLUGIN.UpdateGlobalW( "Exsto" )
			
			local look = string.sub( first[1], 1 )
		
			for k, data in pairs( exsto.Commands ) do
			
				if data.Chat then
			
					for k,v in pairs( data.Chat ) do
					
						local command = string.sub( v, 1 )
					
						if string.FindStart( command:lower():Trim(), look:lower():Trim() ) then
						
							local width, height = surface.GetTextSize( v )
						
							table.insert( Find_List, { Name = v, Width = width, Height = height, ReturnOrder = data.ReturnOrder, Args = data.Args, Optional = data.Optional } )
							
						end
						
					end
					
				end
				
			end
			
		elseif first[1]:First() != "!" and Find_List then
			PLUGIN.G_Text = "Chat"
			PLUGIN.UpdateGlobalW( "Chat" )
			Find_List = {}
		end

		PLUGIN.CurrentText = text
		
	end

	function PLUGIN:OnOnPlayerChat( ply, msg, team, dead )
	end

	function PLUGIN:OnChatText( ply, nick, msg, type )
		chat.AddText( COLOR.NORM, msg )	
		return true
	end
	
	// Stolen from lua-users.org
	local function StringDist( s, t )
		local d, sn, tn = {}, #s, #t
		local byte, min = string.byte, math.min
			for i = 0, sn do d[i * tn] = i end
			for j = 0, tn do d[j] = j end
			for i = 1, sn do
				local si = byte(s, i)
				for j = 1, tn do
					d[i*tn+j] = min(d[(i-1)*tn+j]+1, d[i*tn+j-1]+1, d[(i-1)*tn+j-1]+(si == byte(t,j) and 0 or 1))
				end
			end
		return d[#d]
	end
	
	function string.smartFind( text, find )
	
		local text = text:lower()
		local find = find:lower()
		local split = string.Explode( " ", text )

		if string.find( text, find, 1, true ) then return true end
		
		for k,v in pairs( split ) do
			
			local found = string.find( v, find, 1, true )
			if found then return found end
			
		end
		
		return false
		
	end

	function PLUGIN.ParseLine( ply, line )

		surface.SetFont( PLUGIN.Font )

		local data = {}
			data.Type = {}
			data.Value = {}
			data.Text = {}
			data.Width = {}
			data.Length = {}
			
		local toParse = line
		local id = 1
		local total_w = 0
		local fulltext = toParse
		
		while toParse != "" do
		
			local clStart, clEnd, clTag, clR, clG, clB, clA = string.find( toParse, "(%[c=(%d+),(%d+),(%d+),(%d+)%])" )

			if clStart then
				
				if clStart == 1 then
				
					local colEndStart, colEndEnd, colEnd = string.find( toParse, "(%[/c%])" )
					if colEndStart then colEndStart = colEndStart - 1 else colEndStart = string.len( toParse ) end
					colEndEnd = colEndEnd or string.len( toParse )
					
					local text = string.sub( toParse, clEnd + 1, colEndStart )
					local w, h = surface.GetTextSize( text )
					
					table.insert( data.Type, id, 2 )
					table.insert( data.Text, id, text )
					table.insert( data.Width, id, w )
					
					if ply then -- If its player said

						if text == ply:Nick() then -- if we are parsing his name.
							table.insert( data.Value, id, Color( clR, clG, clB, clA ) )
						else -- if we are parsing someone else.
						
							local sound = ""
							if string.sub( text, 3, 3 ) == "@" and string.smartFind( LocalPlayer():Nick(), string.Explode( " ", text )[2]:Replace( "@", "" ) ) then -- If we are doing a twitter style
		
								table.insert( data.Value, id, Color( 103, 207, 255, 200 ) )
								data.Blink = true
								sound = "name_said.wav"
		
							elseif ply:GetFriendStatus() == "friend" then -- If hes a friend
								
								table.insert( data.Value, id, Color( 255, 203, 124, 200 ) )
								
							else -- Hes just some guy.
								table.insert( data.Value, id, Color( clR, clG, clB, clA ) )
							end
							
							-- Check for his name
							if string.smartFind( text, LocalPlayer():Nick() ) then -- If they said our name (IRC)
							
								data.Blink = true
								sound = "name_said.wav"
								
							end
							
							if PLUGIN.LastSound < CurTime() and sound then
								LocalPlayer():EmitSound( sound, 100, math.random( 70, 130 ) )
								PLUGIN.LastSound = CurTime() + 1
							end
							
						end
						
					else
						table.insert( data.Value, id, Color( clR, clG, clB, clA ) )
					end

					total_w = total_w + w
					
					if colEndEnd then toParse = string.sub( toParse, colEndEnd + 1 ) else toParse = "" end
					
				elseif clStart > 1 then
				
					local text = string.sub( toParse, 1, clStart - 1 )
					local w, h = surface.GetTextSize( text )
					
					table.insert( data.Width, id, w )
					table.insert( data.Text, id, text )
					table.insert( data.Type, id, 1 )
					
					total_w = total_w + w
					
					toParse = string.sub( toParse, clStart, string.len( toParse ) )
					
				end
				
				id = id + 1
				
			else
			
				local w, h = surface.GetTextSize( toParse )
				
				table.insert( data.Type, id, 1 )
				table.insert( data.Text, id, toParse )
				table.insert( data.Width, id, w )
				
				toParse = ""
				id = id + 1
				
				total_w = total_w + w
				
			end
			
		end
		
		data.Length = id
		data.Time = CurTime() + PLUGIN.StayTime
		data.Alpha = 255
		data.Last_Y = PLUGIN.Y + 10
		data.Last_X = 70
		data.Total_W = total_w
		data.Text_Full = fulltext
		table.insert( PLUGIN.Lines, data )			
		
	end
	
	function PLUGIN.AddText( ... )
		local data = ""
		local cprint = ""
		local numColors = 0
		local ply = nil
		local arg = {...}
		
		if type( arg[1] ) == "Player" then ply = arg[1] end
		
		for k,v in pairs( arg ) do

			if type( v ) == "table" then
				
				if numColors == 1 then
					data = data .. "[/c]"
					numColors = 0
				end
			
				data = data .. "[c=" .. v.r .. "," .. v.g .. "," .. v.b .. "," .. v.a .. "]"
				
				numColors = numColors + 1
				
			elseif type( v ) == "Player" then
			
				local rank = v:GetRank()
				local col = team.GetColor( v:Team() )
				if PLUGIN.UseExstoColors then	
					col = exsto.GetRankColor( rank )
				end
				
				if numColors == 1 then
					data = data .. "[/c]"
					numColors = 0
				end
				
				data = data .."[c=" .. col.r .. "," .. col.g .. "," .. col.b .. "," .. col.a .. "]"
				data = data .. v:Nick()
				data = data .. "[/c]"
				
				cprint = cprint .. v:Nick()
				
			elseif type( v ) == "string" then
			
				data = data .. v
				
				cprint = cprint .. v
				
			end
			
		end
		
		print( cprint )
		PLUGIN.ParseLine( ply, data )	
	end
	PLUGIN:AddOverride( "AddText", "AddText", chat )
	
	function PLUGIN.UpdateGlobalW( text )

		surface.SetFont( PLUGIN.Font )

		local w, h = surface.GetTextSize( text ) 
		
		PLUGIN.G_W = w + 10
		
	end

	local pw, curX, curY, num, blink, t, w, val, text
	function PLUGIN.DrawLine( x, y, line )
		
		surface.SetFont( PLUGIN.Font ) 
		
		local outline = Color( PLUGIN.OutlineCol.r, PLUGIN.OutlineCol.g, PLUGIN.OutlineCol.b, line.Alpha / 2 )

		pw = 0

		curX = x
		curY = y																																						
		num = line.Length
		blink = line.Blink

		for I = 1, line.Length do
		
			t = line.Type[I]
			w = line.Width[I]
			val = line.Value[I]
			text = line.Text[I]
			
			if t == 1 then
			
				draw.SimpleTextOutlined( text, PLUGIN.Font, curX, curY, Color( 255, 255, 255, line.Alpha ), 0, 0, 1, outline )
				
			elseif t == 2 then
			
				if blink then
					val = Color( math.Clamp( val.r + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 ),
								math.Clamp( val.g + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 ),
								math.Clamp( val.b + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 ),
								val.a )
				end
			
				draw.SimpleTextOutlined( text, PLUGIN.Font, curX, curY, Color( val.r, val.g, val.b, line.Alpha ), 0, 0, 1, outline )
				
			end
			
			if w then curX = curX + w or curX end
			
		end

	end

	function PLUGIN.DrawKeyBlinker( x, alpha )

		local col
		
		if PLUGIN.NextInterval < CurTime() then

			PLUGIN.Blink = !PLUGIN.Blink
		
			PLUGIN.NextInterval = CurTime() + PLUGIN.CursorInterval
			
		end
		
		if PLUGIN.Blink then
		
			col = Color( 0, 0, 0, 0 )
			
		else
		
			col = Color( 200, 200, 200, alpha )

		end
		
		surface.SetDrawColor( col.r, col.g, col.b, col.a )
		surface.DrawRect( x, PLUGIN.Y + 2, 1, 16 )
		
	end

	local dist, speed
	function PLUGIN.AnimateInputBox( olda, newa, mul )

		if !PLUGIN.UseAnims then
			return newa
		end

		if olda != newa then
		
			dist = newa - olda
			speed = dist / mul
			
			olda = math.Approach( olda, newa, speed )
			
		end
		
		return olda
		
	end

	function PLUGIN.DrawCautionChars( w )

		surface.SetFont( PLUGIN.Font )
		
		local outlinecol = Color( PLUGIN.OutlineCol.r, PLUGIN.OutlineCol.g, PLUGIN.OutlineCol.b, PLUGIN.Box_Alpha )
		
		draw.SimpleTextOutlined( "You are getting close to the max char limit!", PLUGIN.Font, PLUGIN.X + PLUGIN.G_W - 20 + w, PLUGIN.Y + 30, Color( 255, 255, 255, PLUGIN.Box_Alpha ), 0, 0, 1, outlinecol )
		draw.SimpleTextOutlined( "You currently have " .. string.len( PLUGIN.CurrentText ) .. " characters!", PLUGIN.Font, PLUGIN.X + PLUGIN.G_W - 20 + w, PLUGIN.Y + 50, Color( 255, 255, 255, PLUGIN.Box_Alpha ), 0, 0, 1, outlinecol )
		draw.SimpleTextOutlined( "The limit is 127!", PLUGIN.Font, PLUGIN.X + PLUGIN.G_W - 20 + w, PLUGIN.Y + 70, Color( 255, 255, 255, PLUGIN.Box_Alpha ), 0, 0, 1, outlinecol )

	end

	local w, h, alpha, mul, add_w, comWidth, height, width, place, ToDraw, name, returnOrder, args, optional, argument, dataType, newOptional, format, commandColor
	function PLUGIN.DrawInputBox()

		surface.SetFont( PLUGIN.Font )

		w, h = surface.GetTextSize( PLUGIN.CurrentText )
		
		alpha = 255
		mul = 10
		add_w = 510
		
		if not PLUGIN.Open then
		
			alpha = 0
			mul = 40
			
		end
		
		if w > add_w then
			add_w = w + 10
		end
		
		if string.len( PLUGIN.CurrentText ) >= 110 then
		
			PLUGIN.DrawCautionChars( w )
			
		end
		
		PLUGIN.Box_Alpha = PLUGIN.AnimateInputBox( PLUGIN.Box_Alpha, alpha, mul )
		
		local outlinecol = Color( PLUGIN.OutlineCol.r, PLUGIN.OutlineCol.g, PLUGIN.OutlineCol.b, PLUGIN.Box_Alpha )

		draw.SimpleTextOutlined( PLUGIN.CurrentText, PLUGIN.Font, PLUGIN.X + PLUGIN.G_W + 5, PLUGIN.Y, Color( 255, 255, 255, PLUGIN.Box_Alpha ), 0, 0, 1, outlinecol )
		
		surface.SetDrawColor( 50, 50, 50, PLUGIN.Box_Alpha / 2 )
		surface.DrawRect( PLUGIN.X + PLUGIN.G_W, PLUGIN.Y, add_w, 20 )
		
		surface.SetDrawColor( 119, 255, 91, PLUGIN.Box_Alpha / 2 )
		surface.DrawRect( PLUGIN.X, PLUGIN.Y, PLUGIN.G_W, 20 )
		
		surface.SetDrawColor( 255, 255, 255, PLUGIN.Box_Alpha / 2 )
		surface.DrawOutlinedRect( PLUGIN.X + PLUGIN.G_W, PLUGIN.Y, add_w, 20 )
		surface.DrawOutlinedRect( PLUGIN.X, PLUGIN.Y, PLUGIN.G_W, 20 )
		
		draw.SimpleTextOutlined( PLUGIN.G_Text, PLUGIN.Font, PLUGIN.X + 5, PLUGIN.Y, Color( 255, 255, 255, PLUGIN.Box_Alpha ), 0, 0, 1, outlinecol )
		
		PLUGIN.DrawKeyBlinker( w + 6 + PLUGIN.X + PLUGIN.G_W, PLUGIN.Box_Alpha )
		
		-- Find Commands
		if #Find_List >= 1 then
			height = 20
			width = 50
			place = PLUGIN.Y + 25
			ToDraw = {}

			for I = 1, 4 do -- Processing lines ONLY!
			
				local command = Find_List[I]
				
				if command then
				
					w = command.Width
					h = command.Height - 4
					name = command.Name
					returnOrder = command.ReturnOrder
					args = command.Args
					optional = command.Optional
					
					-- We need to increase width depending on the list of argumentals.
					local comInfo = ""
					if type( returnOrder ) == "table" then
						for I = 1, #returnOrder do
							
							-- We need to build the argument text for this command
							argument = returnOrder[I]
							dataType = args[argument]
							
							if optional then newOptional = optional[argument] end
							
							if argument then
								argument = argument:Trim():lower()
								
								format = argument
								if newOptional then format = "[" .. argument .. "]" end
								
								comInfo = comInfo .. format .. " "
							end
							
						end
						
						comWidth, h = surface.GetTextSize( comInfo )
						
						if ( w + comWidth + 10 ) >= width then width = w + comWidth + 10 end
						
						table.insert( ToDraw, { Name = name, Place = place, Args = comInfo } )
						
						place = place + h
						height = height + h
						
					end
					
				end
				
			end
			
			surface.SetDrawColor( 119, 255, 91, PLUGIN.Box_Alpha / 2 )
			surface.DrawRect( PLUGIN.X, PLUGIN.Y + 20, width, height )
			
			surface.SetDrawColor( 255, 255, 255, PLUGIN.Box_Alpha / 2 )
			surface.DrawOutlinedRect( PLUGIN.X, PLUGIN.Y + 20, width, height )
			
			for k,v in ipairs( ToDraw ) do
			
				commandColor = Color( COLOR.NAME.r, COLOR.NAME.g, COLOR.NAME.b, PLUGIN.Box_Alpha )
				w, h = surface.GetTextSize( v.Name )
				
				draw.SimpleTextOutlined( v.Name, PLUGIN.Font, PLUGIN.X + 5, v.Place, commandColor, 0, 0, 1, outlinecol )
				draw.SimpleTextOutlined( v.Args, PLUGIN.Font, PLUGIN.X + 10 + w, v.Place, COLOR.NORM, 0, 0, 1, outlinecol )
				
			end
			
		end
	end
	
	local split, command
	function PLUGIN:OnOnChatTab( text )
	
		if Find_List then
		
			split = string.Explode( " ", text )
			command = Find_List[1]
			
			if command and #split == 1 then
				return command.Name .. " "
			end
			
		end
		
	end
	
	function PLUGIN.Animate( line, curX, curY, mulX, mulY )

		if !PLUGIN.UseAnims then
			line.Last_X = curX
			line.Last_Y = curY
			return
		end
		
		mulX = math.floor( 1 / FrameTime() ) / 3
		mulY = math.floor( 1 / FrameTime() ) / 3

		if line.Last_X != curX then
				
			dist = curX - line.Last_X
			speed = dist / mulX
			
			line.Last_X = math.Approach( line.Last_X, curX, speed )
			
		end
		
		if line.Last_Y != curY then
				
			dist = curY - line.Last_Y
			speed = dist / mulY
			
			line.Last_Y = math.Approach( line.Last_Y, curY, speed )
			
		end
		
	end
	
	local lineHeight, curX, curY, mulX, mulY, k, line, _
	function PLUGIN:OnHUDPaint()

		surface.SetFont( PLUGIN.Font ) -- Set the font
		
		-- Set variables used.
		_, lineHeight = surface.GetTextSize( "H" )
		curX = 70
		curY = PLUGIN.H - 248
		
		mulX = 40
		mulY = 40
		
		--Draw input panenl
		PLUGIN.DrawInputBox()

		for I = 0, 7 do -- For the last 7 lines in the table
		
			k = #PLUGIN.Lines - I
			
			line = PLUGIN.Lines[ k ]
			
			if line then -- If the line exists
			
				if line and ( line.Time < CurTime() ) then  -- His time is up, remove and slide.				 																			
				
					curX = ( line.Total_W * -2 )
					
					if line.Last_X - 5 <= line.Total_W * -2 then
						
						--table.remove( PLUGIN.Lines, k )
						
					end
					
				end
				
				if PLUGIN.Open then -- If the chat is open, make the lines come back and give a new time.
				
					curX = 70
					mulX = 6
					
					if line.Time < CurTime() then -- If he should be gone, give him some more time to live.
					
						line.Time = CurTime() + 2 + I
						
					end
					
				end
				
				PLUGIN.Animate( line, curX, curY, mulX, mulY ) -- Animate smoothing
					
				PLUGIN.DrawLine( line.Last_X, line.Last_Y, line ) -- Draw it
				
				curY = curY - lineHeight - 2 -- Incremental 
				
			end

		end
		
	end

	hook.Add( "Think", "exsto_ChatInit", function()

		if LocalPlayer():IsValid() then
		
			PLUGIN.Init()
			hook.Remove( "Think", "exsto_ChatInit" )
			
		end
		
	end) -- Stupid VGUI wont create when player isn't valid :(

end

PLUGIN:Register()