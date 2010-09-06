local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "MOTD",
	ID = "motd",
	Desc = "Message of the Day.",
	Owner = "Vigilante"
})

if SERVER then

	function PLUGIN:Send( mode, target )
		if mode == "off" then return true end
		
		if mode == "url" then
			local url = exsto.GetVar( "motd_url" ).Value
			
			if url == "" then
				return false, "MOTD URL is empty."
			end
			
			local sender = exsto.CreateSender( "ExMOTD", target )
				sender:AddBool( true )
				if url:find( "://" ) then
					sender:AddString( url )
				else
					sender:AddString( "http://" .. url )
				end
			sender:Send()
		else
			if !file.Exists( "exsto_motd.txt" ) then
				return false, "'data\\exsto_motd.txt' not exists."
			end
			
			local sender = exsto.CreateSender( "ExMOTD", target )
				sender:AddBool( false )
				sender:AddString( file.Read( "exsto_motd.txt" ) )
			sender:Send()
		end
		
		return true
	end

	function PLUGIN.OnModeChange( mode )
		return PLUGIN:Send( mode, "all" )
	end

	PLUGIN:AddVariable({
		Pretty = "MOTD Mode",
		Dirty = "motd_mode",
		Default = "off",
		Description = "MOTD Mode. 'off' - disable MOTD. 'file' - load MOTD from 'data\\exsto_motd.txt'. 'url' - load MOTD from URL.",
		Possible = { "off", "file", "url" },
		//OnChange = PLUGIN.OnModeChange
	})
	
	function PLUGIN.OnURLChange( url )
		if exsto.GetVar( "motd_mode" ).Value == "url" then
			if url == "" then
				return false, "You can't remove MOTD URL when MOTD Mode is 'url'."
			else
				local sender = exsto.CreateSender( "ExMOTD", "all" )
					sender:AddBool( true )
					if url:find( "://" ) then
						sender:AddString( url )
					else
						sender:AddString( "http://" .. url )
					end
				sender:Send()
			end
		end
		return true
	end
	PLUGIN:AddVariable({
		Pretty = "MOTD URL",
		Dirty = "motd_url",
		Default = "",
		Description = "MOTD URL.",
		//OnChange = PLUGIN.OnURLChange
	})
	
	function PLUGIN:Init()
		local mode = exsto.GetVar( "motd_mode" ).Value
		if mode == "url" and exsto.GetVar( "motd_url" ) == "" then
			exsto.ErrorNoHalt( "MOTD URL is empty. Switching MOTD Mode to 'off'." )
			exsto.SetVar( "motd_mode", "off" )
		elseif mode == "file" and !file.Exists( "exsto_motd.txt" ) then
			exsto.ErrorNoHalt( "'data\\exsto_motd.txt' not exists. Switching MOTD Mode to 'off'." )
			exsto.SetVar( "motd_mode", "off" )
		end
	end
	
	function PLUGIN:ExInitSpawn( ply )
		ply:ExShowMOTD()
	end
	
	function _R.Player:ExShowMOTD()
		if exsto.GetVar( "motd_mode" ).Value == "off" then return end
		
		local sender = exsto.CreateSender( "ExMOTD", self )
			if exsto.GetVar( "motd_mode" ).Value == "url" then
				sender:AddChar( 1 )
				sender:AddString( exsto.GetVar( "motd_url" ).Value )
			else
				sender:AddChar( 2 )
				sender:AddString( file.Read( "exsto_motd.txt" ) )
			end
			sender:Send()
	end

	function PLUGIN:MOTD( ply )
		if exsto.GetVar( "motd_mode" ).Value == "off" then
			exsto.Print( exsto_CHAT, ply, COLOR.NORM, "MOTD is disabled." )
		else
			ply:ExShowMOTD()
		end
	end
	PLUGIN:AddCommand( "motd", {
		Call = PLUGIN.MOTD,
		Desc = "Shows MOTD.",
		Console = { "motd" },
		Chat = { "!motd" }
	})

elseif CLIENT then

	local motd = vgui.Create( "DFrame" )
	motd:SetVisible( false )
	motd:SetTitle( "MOTD" )
	motd:SetSize( ScrW() * 0.95, ScrH() * 0.95 )
	motd:Center()
	//motd:SetSkin( "ExstoTheme" )
	
	local html = vgui.Create( "HTML", motd )
	html:SetPos( 5, 25 )
	html:SetSize( motd:GetWide() - 10, motd:GetTall() - motd:GetTall() / 25 - 2.5 - html.y )
	
	local button = vgui.Create( "DButton", motd )
	button:SetText( "Close" )
	button.DoClick = function() motd:SetVisible( false ) end
	button:SetPos( 5, motd:GetTall() - motd:GetTall() / 25 + 2.5 )
	button:SetSize( motd:GetWide() - 10, motd:GetTall() - 5 - button.y )
	
	exsto.CreateReader( "ExMOTD", function( reader )
		local t = reader:ReadChar()
		if t == 1 then -- URL
			html:OpenURL( reader:ReadString() )
		elseif t == 2 then -- HTML
			html:SetHTML( reader:ReadString() )
		end
		
		motd:SetVisible( true )
		motd:MakePopup()
	end )

end	

PLUGIN:Register()