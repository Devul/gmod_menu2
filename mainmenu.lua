local R=function(x) return function() return RawConsoleCommand(x) end end
local M=function(x) return function() return RunGameUICommand(x) end end
local NOT=function(f) return function(...) return not f(...) end end

local mainmenu = {
	{""},
	{"resume_game",					gui.HideGameUI,                      "icon16/joystick.png"				,show=IsInGame},
	{"disconnect",					M"disconnect",                      "icon16/disconnect.png"				,show=IsInGame},
	{"reconnect",					R"retry",                      		"icon16/connect.png"				,show=WasInGame},
	{"GameUI_GameMenu_PlayerList",	M"openplayerlistdialog",        	"icon16/group_delete.png"			,show=IsInGame},
	
	{"",show=WasInGame},
	{"new_game",					M"opencreatemultiplayergamedialog", "icon16/server.png"					},
	{"server_list",					M"openserverbrowser",               "icon16/world.png"					},
	
	{""},
	{"options",						M"openoptionsdialog",               "icon16/wrench.png"					},
	{"GameUI_Console",				R"showconsole",                   	"icon16/application_xp_terminal.png",
		show=function() return DEVELOPER and not gui.IsConsoleVisible() end},
	
	{""},
	{"GameUI_Quit",					M"quitnoconfirm",                   "icon16/door.png"					},
	{""},
}
-- addons
-- games
-- language
-- settings
-- lua cache?
-- workshop search
-- con filter out
-- console open
-- devmode quicktoggle
-- favorites and their status on main menu?
-- browser? / overlay?
-- client.vdf browser/editor
-- 

local menulist_wrapper = vgui.Create('DPanelList',nil,'menulist_wrapper')
local isours
if pnlMainMenu and pnlMainMenu:IsValid() then pnlMainMenu:Remove() end
	
_G.pnlMainMenu = menulist_wrapper
menulist_wrapper:EnableVerticalScrollbar(true)
menulist_wrapper:SetWide(350)
menulist_wrapper:Dock(LEFT)
menulist_wrapper:DockMargin(32,32,32,32)


local div_hack = vgui.Create'EditablePanel'
div_hack:SetTall(52)
div_hack:SetZPos(-20000)
menulist_wrapper:AddItem(div_hack)

local lastscroll = menulist_wrapper.VBar:GetScroll()



local addonslist
function CreateAddons()
	
	if addonslist and addonslist:IsValid() then addonslist:Remove() addonslist=nil end
	
	addonslist = vgui.Create('DForm',menulist_wrapper,'addonslist')
	addonslist:Dock(TOP)
	addonslist:SetName"Installed Addons"
	addonslist:SetExpanded(false)
	
	addonslist:SetCookieName"addonslist"
	addonslist:LoadCookies()
	
	menulist_wrapper:AddItem(addonslist)
	menulist_wrapper:InvalidateLayout(true)
	addonslist:InvalidateLayout(true)
	addonslist.Header:SetIcon 'icon16/plugin.png'
	

	local btn = vgui.Create("DButton",addonslist,'addonslist_button')
		addonslist:AddItem(btn)
		btn:SetText("Enable All")
		function btn.DoClick(btn)
			for k,v in next,engine.GetAddons() do
				steamworks.SetShouldMountAddon(v.file,true)
			end
			isours = true
			steamworks.ApplyAddons()
			isours = true
		end
	local btn = vgui.Create("DButton",addonslist,'addonslist_button')
		addonslist:AddItem(btn)
		btn:SetText("Disable All")
		function btn.DoClick(btn)
			for k,v in next,engine.GetAddons() do
				steamworks.SetShouldMountAddon(v.file,false)
			end
			isours = true
			steamworks.ApplyAddons()
			isours = true

		end
	local btn = vgui.Create("DButton",addonslist,'addonslist_button')
		addonslist:AddItem(btn)
		btn:SetText("Unsubscribe All")
		function btn.DoClick(btn)
			for k,v in next,engine.GetAddons() do
				if v.wsid then
					steamworks.Unsubscribe(v.wsid)
				end
			end
			isours = true steamworks.ApplyAddons() isours = true
		
		end

	local function AddButton(data,title,mounted,downloaded,wsid,filepath)
		
		local btn = vgui.Create("DCheckBoxLabel",addonslist,'addonslist_button')
			addonslist:AddItem(btn)
			btn:SetText(title or filepath)
			btn:SetChecked(mounted)
			btn:SetBright(true)
			btn:SetDisabled(not downloaded)
			btn:SizeToContents()
			function btn:OnChange(val)
				print("mount",filepath,val)
				steamworks.SetShouldMountAddon(wsid,val)
				isours = true steamworks.ApplyAddons() isours = true
				btn:SetChecked(steamworks.ShouldMountAddon(wsid))
			end
	
		btn:InvalidateLayout(true)
		--btn:Dock(TOP)
	end

	local t=engine.GetAddons()
	table.sort(t,function(a,b)
		if a.mounted==b.mounted then
			if a.wsid and b.wsid then
				return a.wsid<b.wsid
			elseif a.title and b.title then
				return a.title<b.title
			else
				return a.file<b.file
			end
		else
			return  (a.mounted and 0 or 1)<(b.mounted and 0 or 1)
		end
	end)
	for _,data in next,t do
		AddButton(data,data.title,data.mounted,data.downloaded,data.wsid,data.file)
	end
	
	
	
	menulist_wrapper.VBar:SetScroll(lastscroll)
	
end




local gameslist
function CreateGames()
	
	if gameslist and gameslist:IsValid() then gameslist:Remove() gameslist=nil end
	
	gameslist = vgui.Create('DForm',menulist_wrapper,'gameslist')
	gameslist:Dock(TOP)
	gameslist:SetName"Mounted games"
	gameslist:SetExpanded(false)
	gameslist.Header:SetIcon 'icon16/joystick.png'
	gameslist:SetCookieName"gameslist"
	gameslist:LoadCookies()
	
	menulist_wrapper:AddItem(gameslist)
	menulist_wrapper:InvalidateLayout(true)
	gameslist:InvalidateLayout(true)
	
	local function AddButton(data,title,mounted,owned,installed,depot)
		
		local btn = vgui.Create("DCheckBoxLabel",gameslist,'gameslist_button')
			gameslist:AddItem(btn)
			btn:SetText(title)
			btn:SetChecked(mounted)
			btn:SetBright(true)
			btn:SetDisabled(not owned or not installed)
			btn:SizeToContents()
			function btn:OnChange(val)
				engine.SetMounted(depot,val)
				btn:SetChecked(IsMounted(depot))
			end
	
		btn:InvalidateLayout(true)
		--btn:Dock(TOP)
	end

	local t=engine.GetGames()
	table.sort(t,function(a,b)
		if a.mounted==b.mounted then
			if a.mounted then
				return a.depot<b.depot
			else
				return ((a.installed and a.owned) and 0 or 1)<((b.installed and b.owned) and 0 or 1)
			end
		else
			return  (a.mounted and 0 or 1)<(b.mounted and 0 or 1)
		end
	end)
	for _,data in next,t do
		AddButton(data,data.title,data.mounted,data.owned,data.installed,data.depot)
	end
	
	CreateAddons()
	
end



local menulist
function CreateMenu()
	
	lastscroll = menulist_wrapper.VBar:GetScroll()
	
	if menulist and menulist:IsValid() then menulist:Remove() menulist=nil end
	
	menulist = vgui.Create('DForm',menulist_wrapper,'menulist')
	menulist:Dock(TOP)
	menulist:SetName""
	menulist.Header:SetIcon 'icon16/house.png'
	menulist:SetCookieName"menulist"
	menulist:LoadCookies()
	
	
	menulist_wrapper:AddItem(menulist)
	menulist_wrapper:InvalidateLayout(true)
	menulist:InvalidateLayout(true)
	
	local function AddButton(data,text,menucmd,icon)
		
		if data.show and not data:show() then return end
		
		if text=="" and not menucmd then
			local div = vgui.Create'EditablePanel'
			div:SetTall(1)
			menulist:AddItem(div)
			return
		end
		
		local btn = vgui.Create("DButton",menulist,'menulist_button')
			menulist:AddItem(btn)
			btn:SetText("#"..text)
			btn:SetFont"closecaption_normal"
			btn:SizeToContents()
		btn.DoClick=function()
			menucmd()
			btn:SetSelected(false)
		end
		if icon and #icon>0 then
			btn:SetImage(icon)
		end
		btn:InvalidateLayout(true)
		
		btn:SetTextInset( 16+ 16, 0 )
		btn:SetContentAlignment(4)
		
		local tall = btn:GetTall()+4
		tall=tall<32 and 32 or tall
		btn:SetTall(tall)
		--btn:Dock(TOP)
	end

	for _,data in next,mainmenu do
		AddButton(data,data[1],data[2],data[3])
	end
	
	CreateGames()
end
CreateMenu()

hook.Add( "GameContentsChanged", "CreateMenu", function(mount,addon)
	if isours then isours = false return end

	CreateMenu()
	
end )

hook.Add( "InGame", "CreateMenu", function(is)
	CreateMenu()
end )

hook.Add( "ConsoleVisible", "CreateMenu", function(is)
	--CreateMenu()
	--print"ConsoleVisible"
end )

hook.Add( "LoadingStatus", "CreateMenu", function(status)
	--CreateMenu()
end )