-- Exsto
-- Head Titles

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Head Title",
	ID = "headtitles",
	Desc = "A plugin that allows tags above the head.",
	Owner = "Prefanatic",
	Experimental = false,
} )

if SERVER then
	exsto.CreateFlag( "displayheadtags", "Allows users to see tags above players heads." )
	
	-- Create the table.
	exsto.HeadDB = FEL.CreateDatabase( "exsto_headtitle" )
		exsto.HeadDB:ConstructColumns( {
			SteamID = "VARCHAR(50):primary:not_null";
			Title = "TEXT";
		} )
	
	PLUGIN:AddVariable({
		Pretty = "Title Limit",
		Dirty = "title_limit",
		Default = 50,
		Description = "The limit to the number of letters in a player head title.",
	})

	function PLUGIN:ExInitSpawn( ply, sid )
		-- Load their data.
		local title = exsto.HeadDB:GetData( sid, "Title" )
		
		-- If their title doesn't exist, don't continue.
		if !title then return end
		
		-- If we have it, store it.
		ply:SetNWString( "title", title )
		
	end
	
	function PLUGIN:SetPlayerTitle( caller, ply, title )
		if title:len() > exsto.GetVar( "title_limit" ).Value then
			return { caller, COLOR.NORM, "You cannot set your title to contain more than ", COLOR.NAME, tostring( exsto.GetVar( "title_limit" ).Value ), COLOR.NORM, " characters!" }
		end
		
		ply:SetNWString( "title", title )
		
		-- Save the data.
		exsto.HeadDB:AddRow( {
			Title = ply:GetNWString( "title" );
			SteamID = ply:SteamID();
		} )
		
		return { COLOR.NAME, caller:Nick(), COLOR.NORM, " has set ", COLOR.NAME, ply:Nick(), COLOR.NORM, "'s title to ", COLOR.NORM, title, COLOR.NORM, "!" }
	end
	PLUGIN:AddCommand( "playertitle", {
		Call = PLUGIN.SetPlayerTitle,
		Desc = "Allows users to set other players titles.",
		Console = { "plytitle" },
		Chat = { "!plytitle" },
		ReturnOrder = "Player-Title",
		Args = { Player = "PLAYER", Title = "STRING" },
		Optional = { Title = "I have no title." },
		Category = "Fun",
	})

	function PLUGIN:SetTitle( caller, title )
		if title:len() > exsto.GetVar( "title_limit" ).Value then
			return { caller, COLOR.NORM, "You cannot set your title to contain more than ", COLOR.NAME, exsto.GetVar( "title_limit" ).Value, COLOR.NORM, "characters!" }
		end
		
		caller:SetNWString( "title", title )
		
		-- Save the data.
		exsto.HeadDB:AddRow( {
			Title = caller:GetNWString( "title" );
			SteamID = caller:SteamID();
		} )

		return {
			Activator = caller,
			Wording = " has set his title to ",
			Player = title,
		}
	end
	PLUGIN:AddCommand( "title", {
		Call = PLUGIN.SetTitle,
		Desc = "Allows users to set their own titles.",
		Console = { "title" },
		Chat = { "!title" },
		ReturnOrder = "Title",
		Args = { Title = "STRING" },
		Optional = { Title = "I have no title." },
		Category = "Fun",
	})
	
	function PLUGIN:MyTitle( caller )
		return { caller, COLOR.NORM, "Your title is set to: ", COLOR.NAME, caller:GetNWString( "title" ) or "nothing",  COLOR.NORM, "!" }
	end
	PLUGIN:AddCommand( "mytitle", {
		Call = PLUGIN.MyTitle,
		Desc = "Allows users to see their titles.",
		Console = { "mytitle" },
		Chat = { "!mytitle" },
		Args = { },
		Category = "Fun",
	})
	
	function PLUGIN.ChatState( ply, _, args )
		ply:SetNWBool( "ExChatState", tobool( args[1] ) )
	end
	concommand.Add( "_ChatState", PLUGIN.ChatState )
	
elseif CLIENT then

	surface.CreateFont( "coolvetica", 20, 400, true, false, "PlayerTagText" )
	
	function PLUGIN:StartChat()
		RunConsoleCommand( "_ChatState", true )
	end
	
	function PLUGIN:FinishChat()
		RunConsoleCommand( "_ChatState", false )
	end
	
	local newCol
	function PLUGIN:BlinkColor( col )
		newCol = {}
		newCol.r = math.Clamp( col.r + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 )
		newCol.g = math.Clamp( col.g + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 )
		newCol.b = math.Clamp( col.b + ( math.sin( CurTime() * 7 ) * 90  ), 0, 255 )
		newCol.a = col.a
		
		return newCol
	end
	
	local traceData = {}
	local textColor = Color( 232, 232, 232, 255 )
	local outlineCol = Color( 0, 0, 0, 255 )
	local id = surface.GetTextureID( "gui/center_gradient" ) 
	local id2 = surface.GetTextureID( "glow2" )
	function PLUGIN:HUDPaint()
		if !LocalPlayer():IsAllowed( "displayheadtags" ) then return end
		
		for _, ply in ipairs( player.GetAll() ) do
			if ply != LocalPlayer() and ply:Health() > 0 then 
			
				traceData = {
					start = LocalPlayer():GetShootPos(),
					endpos = ply:GetShootPos(),
				}
				
				local trace = util.TraceLine( traceData )
				local dist = LocalPlayer():GetShootPos():Distance( ply:GetShootPos() )
				
				-- If we arnt hitting world, continue
				if !trace.HitWorld and dist <= 1000 then
					
					surface.SetFont( "PlayerTagText" )
					local w = math.max( surface.GetTextSize( ply:Nick() ) + 20, surface.GetTextSize( ply:GetNWString( "title" ) ) + 20 )
					local h = 40
					
					if !ply:GetNWString( "title" ) or ply:GetNWString( "title" ) == "" then h = 21 end
					
					local drawPos = ( ply:GetBonePosition( ply:LookupBone( "ValveBiped.Bip01_Head1" ) ) + Vector( 0, 0, 15 ) ):ToScreen()
					drawPos.x = drawPos.x - w / 2
					drawPos.y = drawPos.y - 20
					
					local col = exsto.GetRankColor( ply:GetRank() ) or team.GetColor( ply:Team() )
					local alpha = math.Clamp( 255 - ( dist / 4 ), 0, 255 )
					
					if ply:GetNWBool( "ExChatState" ) then col = self:BlinkColor( col ) end
					
					surface.SetTexture( id2 )
					surface.SetDrawColor( col.r, col.g, col.b, alpha )
					surface.DrawTexturedRect( drawPos.x - 25, drawPos.y - 25, w + 50, h + 50 )
					
					textColor.a = alpha
					outlineCol.a = alpha
					
					draw.SimpleTextOutlined( ply:Nick(), "PlayerTagText", drawPos.x + w / 2, drawPos.y + 2, textColor, 1, 0, 1, outlineCol )
					
					-- if h is not 21, we have a title.  draw cool stuff.
					if h != 21 then
						//surface.DrawLine( drawPos.x + 5, drawPos.y + 18, drawPos.x + w - 5, drawPos.y + 18 )
						draw.SimpleTextOutlined( ply:GetNWString( "title" ), "PlayerTagText", drawPos.x + w / 2, drawPos.y + 18, textColor, 1, 0, 1, outlineCol )
					end
				end
			end
		end
	end
	
end

PLUGIN:Register()

	