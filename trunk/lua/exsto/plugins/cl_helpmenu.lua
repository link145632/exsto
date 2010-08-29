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
						background-image:url( "]] .. self.DropLink .. "background.png" .. [[" );
						padding:0px 0px 0px 0px;
						margin:0px 0px 0px 0px;
					}
					.image{
						width:565px;
						height:280px;
					}
				</style>
			</head>
			<body>
				<center><img src="]] .. url .. [[" alt="image1" /></center>
			</body>
		</html>
	]]
end

function PLUGIN:CreatePage( panel )
	local tabs = panel:RequestTabs()
	
	-- Sort them.
	local newTable = {}
	for category, pictures in pairs( self.DatabaseConstruct ) do
		table.insert( newTable, { Category = category, Pics = pictures } )
	end
	
	table.sort( newTable, function( a, b ) return a.Category == "Introduction" or a.Category > b.Category end )
	
	local function waitOnFinish( html, url )
		html:SetVisible( true )
		panel:EndLoad()
	end
		
	for _, data in ipairs( newTable ) do
		local page = tabs:CreatePage( panel )
		
		page.CurrentIndex = 1
		
		-- Create the HTML thing.  Thank you WebKit.
		local browser = vgui.Create( "HTML", page )
			browser:SetHTML( self:CreateHTML( self.DropLink .. data.Pics[1] ) )
			browser:SetSize( 595, 305 )
			browser:SetPos( ( panel:GetWide() / 2 ) - ( browser:GetWide() / 2 ), 5 )
			
			browser:SetMouseInputEnabled( false )
			browser.FinishedURL = waitOnFinish
			
		-- Create prev and next buttons.
		if #data.Pics > 1 then
			page.Prev = exsto.CreateButton( 15, page:GetTall() - 40, 84, 27, "Previous", page )
				page.Prev:SetStyle( "negative" )
				page.Prev:SetVisible( false )
				
				page.Prev.OnClick = function()
					if page.CurrentIndex == 1 then return end
					
					page.CurrentIndex = page.CurrentIndex - 1
					browser:SetHTML( self:CreateHTML( self.DropLink .. data.Pics[ page.CurrentIndex ] ) )
					browser:SetVisible( false )
					panel:PushLoad()
					
					page.Next:SetVisible( true )
					if page.CurrentIndex == 1 then page.Prev:SetVisible( false ) end
				end

			page.Next = exsto.CreateButton( page:GetWide() - 74 - 15,page:GetTall() - 40, 74, 27, "Next", page )
				page.Next:SetStyle( "positive" )
				
				page.Next.OnClick = function()
					if page.CurrentIndex == #data.Pics then return end
					
					page.CurrentIndex = page.CurrentIndex + 1
					browser:SetHTML( self:CreateHTML( self.DropLink .. data.Pics[ page.CurrentIndex ] ) )
					browser:SetVisible( false )
					panel:PushLoad()
					
					page.Prev:SetVisible( true )
					if page.CurrentIndex == #data.Pics then page.Next:SetVisible( false ) end
				end
		end
			
		tabs:AddItem( data.Category, page )
	end
	
end	
	
Menu:CreatePage({
		Title = "Exsto Help",
		Short = "helppage",
	}, function( panel )
		PLUGIN:CreatePage( panel )
	end )
	
PLUGIN:Register()
