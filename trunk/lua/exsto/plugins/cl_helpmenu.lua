-- Exsto
-- Help Menu

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Help Menu",
	ID = "helpmenu",
	Desc = "A menu page that shows Exsto help",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()
	-- Variables.
	self.DropLink = "http://dl.dropbox.com/u/717734/Exsto/DO%20NOT%20DELETE/Help/"
	self.DatabaseLink = self.DropLink .. "helpdb.txt"
	
	self.DatabaseConstruct = {}
	self.DatabaseLoading = true
	self.DatabaseRecieved = false
	self.DatabaseVersion = 1.0
	
	-- Grab the database list.
	http.Get( self.DatabaseLink, "", function( contents, size )
		if size == 0 or contents:Trim() == "" then
			self:Print( "Unable to retrieve database." )
			self.DatabaseRecieved = false
			self.DatabaseLoading = false
			return
		end
		
		local verStart, verEnd, version = string.find( contents, "%[helpver=(%d%.%d)%]" )
		if !verStart or !verEnd or !version then
			self:Print( "Unable to read version header." )
			self.DatabaseRecieved = false
			self.DatabaseLoading = false
			return
		end
		
		self.DatabaseVersion = tonumber( version )
		self:Print( "Recieved help list.  Constructing menu data.  Version: " .. self.DatabaseVersion  )
		
		-- Loop through our categories.
		local capture = string.gmatch( contents, "%[cat=\"(%a+)\"%](.-)%[/cat%]" )
		for category, data in capture do
			local files = string.match( data, "Files = {(.-)}" )
			self.DatabaseConstruct[ category:Trim() ] = string.Explode( ",", files:gsub( "\"", "" ) )
		end

		self.DatabaseLoading = false
		self.DatabaseRecieved = true
	end )
	
end

function PLUGIN:CreateHTML( url )
	return [[
		<html>
			<head>
				<style type="text/css">
					body{
						padding:0px 0px 0px 0px;
						margin:0px 0px 0px 0px;
					}
				</style>
			</head>
			<body scroll="no">
			   <iframe src="]] .. url .. [["
				height="100%" width="100%" frameborder="0"/>
			</body>
		</html>
	]]
end

function PLUGIN:CreatePage( panel )
	local tabs = panel:RequestTabs()
		
	for category, pictures in pairs( self.DatabaseConstruct ) do
		local page = tabs:CreatePage( panel )
		
		page.CurrentIndex = 1
		
		-- Create the HTML thing.  Thank you WebKit.
		local browser = vgui.Create( "HTML", page )
			browser:SetHTML( self:CreateHTML( self.DropLink .. pictures[1] ) )
			browser:SetSize( 565, 280 )
			browser:SetPos( ( panel:GetWide() / 2 ) - ( browser:GetWide() / 2 ), 5 )
			
			browser:SetMouseInputEnabled( false )
			
		-- Create prev and next buttons.
		if #pictures > 1 then
			page.Prev = exsto.CreateButton( 15, page:GetTall() - 40, 84, 27, "Previous", page )
				page.Prev:SetStyle( "negative" )
				page.Prev:SetVisible( false )
				
				page.Prev.OnClick = function()
					if page.CurrentIndex == 1 then return end
					
					page.CurrentIndex = page.CurrentIndex - 1
					browser:SetHTML( self:CreateHTML( self.DropLink .. pictures[ page.CurrentIndex ] ) )
					
					page.Next:SetVisible( true )
					if page.CurrentIndex == 1 then page.Prev:SetVisible( false ) end
				end

			page.Next = exsto.CreateButton( page:GetWide() - 74 - 15,page:GetTall() - 40, 74, 27, "Next", page )
				page.Next:SetStyle( "positive" )
				
				page.Next.OnClick = function()
					if page.CurrentIndex == #pictures then return end
					
					page.CurrentIndex = page.CurrentIndex + 1
					browser:SetHTML( self:CreateHTML( self.DropLink .. pictures[ page.CurrentIndex ] ) )
					
					page.Prev:SetVisible( true )
					if page.CurrentIndex == #pictures then page.Next:SetVisible( false ) end
				end
		end
			
		tabs:AddItem( category, page )
	end
	
end	
	
Menu:CreatePage({
		Title = "Exsto Help",
		Short = "helppage",
	}, function( panel )
		PLUGIN:CreatePage( panel )
	end )
	
PLUGIN:Register()
