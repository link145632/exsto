-- Chat Messings!
-- chat.AddText() Override to work with this chat engine :(

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Custom Chat",
	ID = "cl-chat",
	Desc = "A cool custom chat with supporting animations.",
	Owner = "Prefanatic",
} )

require( "datastream" )
require( "glon" )

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
	
		--timer.Simple( 2, function()
	
			local Send = {}
			for k,v in pairs( exsto.Commands ) do
				
				Send[v.ID] = {
					ID = v.ID,
					Desc = v.Desc,
					Args = v.Args,
					Chat = v.Chat,
					ReturnOrder = v.ReturnOrder,
					Optional = v.Optional,
				}
				
			end
			
			--Send = glon.encode( Send )
		
			datastream.StreamToClients( ply, "exsto_RecieveCommands", Send )
		--end)
		
		PLUGIN.SetExstoColors( ply, exsto.GetVar( "native_exsto_colors" ).Value )
		
	end)
	
	local Anims = true
	
	function PLUGIN.ToggleAnims( owner )
	
		exsto.UMStart( "pchat_toggleanims", owner )
		
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
		exsto.UMStart( "pchat_setcolors", person, value )
	end
	
elseif CLIENT then

	surface.CreateFont( "coolvetica", 20, 400, true, false, "ChatText" )

	local Commands = nil

	local function IncommingHook( ply, handler, id, encoded, decoded )

		Commands = encoded
		
	end
	datastream.Hook( "exsto_RecieveCommands", IncommingHook )

	local pchat = {}
		pchat.Lines = {}
		pchat.Open = false
		
		pchat.Entry = nil
		pchat.Panel = nil
		pchat.CurrentText = ""
		
		pchat.W = ScrW()
		pchat.H = ScrH()
		pchat.X = 35
		pchat.Y = pchat.H - 210
		
		pchat.G_W = 0
		pchat.G_Text = "Chat"
		
		pchat.Font = "ChatText"
		pchat.StayTime = 10
		
		pchat.NextInterval = 0
		pchat.CursorInterval = 1
		pchat.Blink = false
		
		pchat.OutlineCol = Color( 0, 0, 0, 100 )
		pchat.Box_Alpha = 0
		
		pchat.UseAnims = true
		
		pchat.LastSound = 0
		
	function pchat.ToggleChatAnims()
	
		pchat.UseAnims = !pchat.UseAnims
		
		local Status = "ENABLED"
		if !pchat.UseAnims then
			Status = "DISABLED"
		end
		
		chat.AddText( COLOR.PAC, "Chat animations have been ", COLOR.RED, Status )
		
	end
	exsto.UMHook( "pchat_toggleanims", pchat.ToggleChatAnims )
	
	function pchat.SetColors( val )
		pchat.UseExstoColors = val
	end
	exsto.UMHook( "pchat_setcolors", pchat.SetColors )
		
	function pchat.Init()

		pchat.Entry = vgui.Create( "DTextEntry" )
		pchat.Entry:SetPos( 35, pchat.H - 310 )
		pchat.Entry:SetSize( 0, 0 )
		pchat.Entry:SetVisible( false )
		pchat.Entry:SetEditable( false )
		
		pchat.Open = false
		
	end

	function pchat.Open( )

		pchat.Open = true
		pchat.Entry:SetVisible( true )
		gui.EnableScreenClicker( true )
		
		pchat.G_Text = "Chat"
		pchat.UpdateGlobalW( pchat.G_Text )
		
		return true
		
	end
	hook.Add( "StartChat", "exsto_OpenChat", pchat.Open )

	function pchat.Close()

		pchat.Open = false
		pchat.Entry:SetVisible( false )
		gui.EnableScreenClicker( false )
		
		return true
		
	end
	hook.Add( "FinishChat", "exsto_CloseChat", pchat.Close )

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

	function pchat.Think( text )
	
		surface.SetFont( pchat.Font )

		-- TODO: Arguments inside the find table
		
		-- CPU Intensive? test.
		local first = string.Explode( " ", text )
		if Commands and first[1] != "" and first[1]:First() == "!" then
		
			Find_List = {}
			
			pchat.G_Text = "Exsto"
			pchat.UpdateGlobalW( "Exsto" )
			
			local look = string.sub( first[1], 1 )
		
			for k, data in pairs( Commands ) do
			
				if data.Chat then
			
					for k,v in pairs( data.Chat ) do
					
						local command = string.sub( v, 1 )
					
						if string.FindStart( command:lower():Trim(), look:lower():Trim() ) then
						
							local width, height = surface.GetTextSize( v )
							
							if width == 0 then print( "Ugh, width == 0" ) end
							if height == 0 then print( "Ugh, height == 0" ) end
						
							table.insert( Find_List, { Name = v, Width = width, Height = height, ReturnOrder = data.ReturnOrder, Args = data.Args, Optional = data.Optional } )
							
						end
						
					end
					
				end
				
			end
			
		elseif first[1]:First() != "!" and Find_List then
			pchat.G_Text = "Chat"
			pchat.UpdateGlobalW( "Chat" )
			Find_List = {}
		end

		pchat.CurrentText = text
		
	end
	hook.Add( "ChatTextChanged", "exsto_ThinkChat", pchat.Think )

	function pchat.PlyMsg( ply, msg, team, dead )
	end
	hook.Add( "OnPlayerChat", "exsto_PlayerChat", pchat.PlyMsg )

	function pchat.EventMsg( ply, nick, msg, type )
		chat.AddText( COLOR.NORM, msg )	
		return true
	end
	hook.Add( "ChatText", "exsto_EventChat", pchat.EventMsg )
	
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

		--[[for k,v in pairs( split ) do
		
			local found = string.find( find, v )
			if found and StringDist( find, v ) < 9 then return found end
			
		end]]
		
		return false
		
	end

	function pchat.ParseLine( ply, line )

		surface.SetFont( pchat.Font )

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
							
							if pchat.LastSound < CurTime() and sound then
								LocalPlayer():EmitSound( sound, 100, math.random( 70, 130 ) )
								pchat.LastSound = CurTime() + 1
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
		data.Time = CurTime() + pchat.StayTime
		data.Alpha = 255
		data.Last_Y = pchat.Y + 10
		data.Last_X = 70
		data.Total_W = total_w
		data.Text_Full = fulltext
		table.insert( pchat.Lines, data )			
		
	end
	
	local oldChat = chat.AddText
	function chat.AddText( ... )
		//oldChat( unpack( {...} ) )  -- For console + stuff.  It wont print to the custom chat for some reason.
		
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
				if pchat.UseExstoColors then	
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
		pchat.ParseLine( ply, data )
		
	end
		
	function pchat.UpdateGlobalW( text )

		surface.SetFont( pchat.Font )

		local w, h = surface.GetTextSize( text ) 
		
		pchat.G_W = w + 10
		
	end

	function pchat.DrawLine( x, y, line )
		
		surface.SetFont( pchat.Font ) 
		
		local outline = Color( pchat.OutlineCol.r, pchat.OutlineCol.g, pchat.OutlineCol.b, line.Alpha / 2 )

		local pw = 0

		local curX = x
		local curY = y																																						
		local num = line.Length
		local blink = line.Blink

		for I = 1, line.Length do
		
			local t = line.Type[I]
			local w = line.Width[I]
			local val = line.Value[I]
			local text = line.Text[I]
			
			if t == 1 then
			
				draw.SimpleTextOutlined( text, pchat.Font, curX, curY, Color( 255, 255, 255, line.Alpha ), 0, 0, 1, outline )
				
			elseif t == 2 then
			
				if blink then
					val = Color( math.Clamp( val.r + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 ),
								math.Clamp( val.g + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 ),
								math.Clamp( val.b + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 ),
								val.a )
				end
			
				draw.SimpleTextOutlined( text, pchat.Font, curX, curY, Color( val.r, val.g, val.b, line.Alpha ), 0, 0, 1, outline )
				
			end
			
			if w then curX = curX + w or curX end
			
		end

	end

	function pchat.DrawKeyBlinker( x, alpha )

		local col
		
		if pchat.NextInterval < CurTime() then

			pchat.Blink = !pchat.Blink
		
			pchat.NextInterval = CurTime() + pchat.CursorInterval
			
		end
		
		if pchat.Blink then
		
			col = Color( 0, 0, 0, 0 )
			
		else
		
			col = Color( 200, 200, 200, alpha )

		end
		
		surface.SetDrawColor( col.r, col.g, col.b, col.a )
		surface.DrawRect( x, pchat.Y + 2, 1, 16 )
		
	end

	function pchat.AnimateInputBox( olda, newa, mul )

		if !pchat.UseAnims then
			return newa
		end

		if olda != newa then
		
			local dist = newa - olda
			local speed = dist / mul
			
			olda = math.Approach( olda, newa, speed )
			
		end
		
		return olda
		
	end

	function pchat.DrawCautionChars( w )

		surface.SetFont( pchat.Font )
		
		local outlinecol = Color( pchat.OutlineCol.r, pchat.OutlineCol.g, pchat.OutlineCol.b, pchat.Box_Alpha )
		
		draw.SimpleTextOutlined( "You are getting close to the max char limit!", pchat.Font, pchat.X + pchat.G_W - 20 + w, pchat.Y + 30, Color( 255, 255, 255, pchat.Box_Alpha ), 0, 0, 1, outlinecol )
		draw.SimpleTextOutlined( "You currently have " .. string.len( pchat.CurrentText ) .. " characters!", pchat.Font, pchat.X + pchat.G_W - 20 + w, pchat.Y + 50, Color( 255, 255, 255, pchat.Box_Alpha ), 0, 0, 1, outlinecol )
		draw.SimpleTextOutlined( "The limit is 127!", pchat.Font, pchat.X + pchat.G_W - 20 + w, pchat.Y + 70, Color( 255, 255, 255, pchat.Box_Alpha ), 0, 0, 1, outlinecol )

	end

	function pchat.DrawInputBox()

		surface.SetFont( pchat.Font )

		local w, h = surface.GetTextSize( pchat.CurrentText )
		
		local alpha = 255
		local mul = 10
		local add_w = 510
		
		if not pchat.Open then
		
			alpha = 0
			mul = 40
			
		end
		
		if w > add_w then
			add_w = w + 10
		end
		
		if string.len( pchat.CurrentText ) >= 110 then
		
			pchat.DrawCautionChars( w )
			
		end
		
		pchat.Box_Alpha = pchat.AnimateInputBox( pchat.Box_Alpha, alpha, mul )
		
		local outlinecol = Color( pchat.OutlineCol.r, pchat.OutlineCol.g, pchat.OutlineCol.b, pchat.Box_Alpha )

		draw.SimpleTextOutlined( pchat.CurrentText, pchat.Font, pchat.X + pchat.G_W + 5, pchat.Y, Color( 255, 255, 255, pchat.Box_Alpha ), 0, 0, 1, outlinecol )
		
		surface.SetDrawColor( 50, 50, 50, pchat.Box_Alpha / 2 )
		surface.DrawRect( pchat.X + pchat.G_W, pchat.Y, add_w, 20 )
		
		surface.SetDrawColor( 119, 255, 91, pchat.Box_Alpha / 2 )
		surface.DrawRect( pchat.X, pchat.Y, pchat.G_W, 20 )
		
		surface.SetDrawColor( 255, 255, 255, pchat.Box_Alpha / 2 )
		surface.DrawOutlinedRect( pchat.X + pchat.G_W, pchat.Y, add_w, 20 )
		surface.DrawOutlinedRect( pchat.X, pchat.Y, pchat.G_W, 20 )
		
		draw.SimpleTextOutlined( pchat.G_Text, pchat.Font, pchat.X + 5, pchat.Y, Color( 255, 255, 255, pchat.Box_Alpha ), 0, 0, 1, outlinecol )
		
		pchat.DrawKeyBlinker( w + 6 + pchat.X + pchat.G_W, pchat.Box_Alpha )
		
		-- Find Commands
		if #Find_List >= 1 then
			local height = 20
			local width = 50
			local place = pchat.Y + 25
			local ToDraw = {}

			for I = 1, 4 do -- Processing lines ONLY!
			
				local command = Find_List[I]
				
				if command then
				
					local w = command.Width
					local h = command.Height - 4
					local name = command.Name
					local returnOrder = command.ReturnOrder
					local args = command.Args
					local optional = command.Optional
					
					if w >= width then width = w + 20 end
					
					-- We need to increase width depending on the list of argumentals.
					local comInfo = ""
					for I = 1, #returnOrder do
						
						-- We need to build the argument text for this command
						local argument = returnOrder[I]
						local dataType = args[argument]
						local optional = optional[argument]
						
						if argument then
							argument = argument:Trim():lower()
							
							local format = argument
							if optional then format = "[" .. argument .. "]" end
							
							comInfo = comInfo .. format .. " "
						end
						
					end
					
					local w, h = surface.GetTextSize( comInfo )
					
					if w >= width then width = w + 50 end
					
					table.insert( ToDraw, { Name = name, Place = place, Args = comInfo } )
					
					place = place + h
					height = height + h
					
				end
				
			end
			
			surface.SetDrawColor( 119, 255, 91, pchat.Box_Alpha / 2 )
			surface.DrawRect( pchat.X, pchat.Y + 20, width, height )
			
			surface.SetDrawColor( 255, 255, 255, pchat.Box_Alpha / 2 )
			surface.DrawOutlinedRect( pchat.X, pchat.Y + 20, width, height )
			
			for k,v in pairs( ToDraw ) do
			
				local commandColor = Color( COLOR.NAME.r, COLOR.NAME.g, COLOR.NAME.b, pchat.Box_Alpha )
				local w, h = surface.GetTextSize( v.Name )
				
				draw.SimpleTextOutlined( v.Name, pchat.Font, pchat.X + 5, v.Place, commandColor, 0, 0, 1, outlinecol )
				draw.SimpleTextOutlined( v.Args, pchat.Font, pchat.X + 10 + w, v.Place, COLOR.NORM, 0, 0, 1, outlinecol )
				
			end
			
		end
	end
	
	function pchat.OnChatTab( text )
	
		if Find_List then
		
			local split = string.Explode( " ", text )
			local command = Find_List[1]
			
			if command and #split == 1 then
				return command.Name
			end
			
		end
		
	end
	hook.Add( "OnChatTab", "exsto_ComCompletion", pchat.OnChatTab )
	
	function pchat.Animate( line, curX, curY, mulX, mulY )

		if !pchat.UseAnims then
			line.Last_X = curX
			line.Last_Y = curY
			return
		end
		
		mulX = math.floor( 1 / FrameTime() ) / 3
		mulY = math.floor( 1 / FrameTime() ) / 3

		if line.Last_X != curX then
				
			local dist = curX - line.Last_X
			local speed = dist / mulX
			
			line.Last_X = math.Approach( line.Last_X, curX, speed )
			
		end
		
		if line.Last_Y != curY then
				
			local dist = curY - line.Last_Y
			local speed = dist / mulY
			
			line.Last_Y = math.Approach( line.Last_Y, curY, speed )
			
		end
		
	end

	local Init_FPSMonitor = false
	local FPSTime = 0
	local StartTime = CurTime() + 10
	
	function pchat.Draw()

		surface.SetFont( pchat.Font ) -- Set the font
		
		-- Set variables used.
		local _, lineHeight = surface.GetTextSize( "H" )
		local curX = 70
		local curY = pchat.H - 248
		
		local mulX = 40
		local mulY = 40
		
		--Draw input panenl
		pchat.DrawInputBox()

		for I = 0, 7 do -- For the last 7 lines in the table
		
			local k = #pchat.Lines - I
			
			local line = pchat.Lines[ k ]
			
			if line then -- If the line exists
			
				if line and ( line.Time < CurTime() ) then  -- His time is up, remove and slide.				 																			
				
					curX = ( line.Total_W * -2 )
					
					if line.Last_X - 5 <= line.Total_W * -2 then
						
						--table.remove( pchat.Lines, k )
						
					end
					
				end
				
				if pchat.Open then -- If the chat is open, make the lines come back and give a new time.
				
					curX = 70
					mulX = 6
					
					if line.Time < CurTime() then -- If he should be gone, give him some more time to live.
					
						line.Time = CurTime() + 2 + I
						
					end
					
				end
				
				pchat.Animate( line, curX, curY, mulX, mulY ) -- Animate smoothing
					
				pchat.DrawLine( line.Last_X, line.Last_Y, line ) -- Draw it
				
				curY = curY - lineHeight - 2 -- Incremental 
				
			end

		end
		
	end
	hook.Add( "HUDPaint", "exsto_DrawChat", pchat.Draw )

	hook.Add( "Think", "exsto_ChatInit", function()

		if LocalPlayer():IsValid() then
		
			pchat.Init()
			hook.Remove( "Think", "exsto_ChatInit" )
			
		end
		
	end) -- Stupid VGUI wont create when player isn't valid :(

end

PLUGIN:Register()