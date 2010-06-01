-- Exsto
-- Help Menu

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Help Menu",
	ID = "helpmenu",
	Desc = "A menu page that shows Exsto help",
	Owner = "Prefanatic",
	Experimental = false,
} )

Menu.CreatePage( {
	Title = "Exsto Help",
	Short = "exstohelp",
	Flag = "helppage",
	},
	function( panel )
	
		surface.SetFont( "default" )
		
		local function RecieveHelp( contents, size )
			local verStart, verEnd, verTag, version = string.find( contents, "(%[helpver=(%d+%.%d+)%])" )
			
			if !version then
				
				return
			end
			
			-- Create table on the info we have.
			local help = {}
			
			local sub = string.sub( contents, verEnd + 1 ):Trim()
			local capture = string.gmatch( sub, "%[title=([%w%s%p]-)%]([%w%s%p]-)%[/title%]" )
			
			for k,v in capture do
				help[k] = v
			end

			local list = exsto.CreatePanelList( 5, 0, panel:GetWide() - 10, panel:GetTall() - 50, 10, false, true, panel )
				list.Color = Color( 229, 229, 229, 0 )
				
			for k,v in pairs( help ) do
				local w, h = surface.GetTextSize( k )

				local label = exsto.CreateLabel( 15, 0, v, "default" )
					label:SetWrap( true )
					label:SetTextColor( Color( 60, 60, 60, 255 ) )
					
				local category = exsto.CreateCollapseCategory( 0, 0, w + 10, label:GetTall() + 30, k )
					category.Color = Color( 229, 229, 229, 255 )
					category.Header.TextColor = Color( 60, 60, 60, 255 )
					category.Header.Font = "exstoHelpTitle" 
					
				category:SetContents( label )
				list:AddItem( category )
			end
			
		end
		http.Get( "http://94.23.154.153/Exsto/helpdb.txt", "", RecieveHelp )
	end
)