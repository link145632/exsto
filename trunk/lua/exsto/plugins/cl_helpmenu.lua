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
			local capture = string.gmatch( sub, "%[category=([%w%s%p]-)%](.-)%[/category%]" )
			
			for k,v in capture do
				help[k] = {}

				for title, content in string.gmatch( v, "%[title=([%w%s%p]-)%]([%w%s%p]-)%[/title%]" ) do
					table.insert( help[k], { Title = title, Text = content } )
				end
			end

			local list = exsto.CreatePanelList( 5, 0, panel:GetWide() - 10, panel:GetTall() - 50, 10, false, true, panel )
				list.Color = Color( 229, 229, 229, 0 )
				
			for catName, data in pairs( help ) do
					
				local category = exsto.CreateCollapseCategory( 0, 0, list:GetWide(), 40, catName )
					category.Color = Color( 229, 229, 229, 255 )
					category.Header.TextColor = Color( 60, 60, 60, 255 )
					category.Header.Font = "exstoHelpTitle" 
					
				local helplist = exsto.CreatePanelList( 5, 5, category:GetWide(), 200, 10, false, true )
				
				category:SetContents( helplist )
				list:AddItem( category )
					
				local tall = 40
				for _, content in pairs( data ) do
				
					local helpcategory = exsto.CreateCollapseCategory( 0, 0, list:GetWide(), 40, content.Title )
						helpcategory.Color = Color( 229, 229, 229, 255 )
						helpcategory.Header.TextColor = Color( 60, 60, 60, 255 )
						helpcategory.Header.Font = "exstoHelpTitle" 
						helpcategory:SetExpanded( true )
					
					local label = exsto.CreateLabel( 15, 0, content.Text, "default" )
						label:SetWrap( true )
						label:SetTextColor( Color( 60, 60, 60, 255 ) )
						
					helpcategory:SetContents( label )
					helplist:AddItem( helpcategory )
					
					tall = tall + label:GetTall() + 7
				
				end
				
				helplist:SetTall( tall )

			end
			
		end
		http.Get( "http://94.23.154.153/Exsto/helpdb.txt", "", RecieveHelp )
	end
)