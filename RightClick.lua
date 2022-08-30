local addonName, addon = ...
-------------------------------
-- Right Click Functionality --
-------------------------------
local function SendPlayerInfo(targetName)
	addon.UpdateSpecOptions()
	--Calculate average itemlevel
	local iLevelSum = 0
	for slotNum = 1, 19 do
		--Exclude shirt and tabard slots from itemlevel calculation
		if slotNum ~= 4 and slotNum ~= 19 then
			local tempItemLink = GetInventoryItemLink("player", slotNum)

			if tempItemLink then
				local name, _, _, iLevel, _, _, _, _, itemType = GetItemInfo(tempItemLink)
				if slotNum == 16 and itemType == "INVTYPE_2HWEAPON" then
					--If the weapon is 2 handed, and the offhand slot is empty, we sum the weapon's itemlevel twice
					if GetInventoryItemLink("player", 17) == nil then
						iLevelSum = iLevelSum + iLevel
					end
				end

				iLevelSum = iLevelSum + iLevel
			end
		end
	end
	local averageiLevel = floor(iLevelSum / 17)

	local myclass = UnitClass("player")
	local mylevel = UnitLevel("player")

	--Find out which spec group is active
	local specGroup = addon.GetActiveSpecGroup()
	--1+2=3 :)
	local inactiveSpecGroup = 3 - specGroup
	--Find out which talent spec has the most points spent in it
	local activeTalentSpec = addon.GetSpecByGroupNum(specGroup)
	local inactiveTalentSpec = addon.GetSpecByGroupNum(inactiveSpecGroup)
	local mylocale = GetLocale()
	local activeRole = nil
	local inactiveRole = nil
	if specGroup == 1 then
		activeRole = addon.groupieRoleTable[addon.db.char.groupieSpec1Role]
		inactiveRole = addon.groupieRoleTable[addon.db.char.groupieSpec2Role]
	else
		activeRole = addon.groupieRoleTable[addon.db.char.groupieSpec2Role]
		inactiveRole = addon.groupieRoleTable[addon.db.char.groupieSpec1Role]
	end

	local groupieMsg = format("{rt3} %s : %s LFG! Level %s %s %s wearing %s item-level gear. Other spec is %s %s. %s-speaking Player."
		,
		addonName,
		activeRole,
		mylevel,
		activeTalentSpec,
		myclass,
		tostring(averageiLevel),
		inactiveTalentSpec,
		inactiveRole,
		addon.groupieLocaleTable[mylocale]
	)
	--Sending Current Spec Info
	SendChatMessage(groupieMsg, "WHISPER", "COMMON", targetName)
	return true
end

---------------
-- Menu Hook --
---------------
local function GroupieUnitMenu(dropdownMenu, which, unit, name, userData, ...)
	if (UIDROPDOWNMENU_MENU_LEVEL > 1) then
		return
	end

	--Some context menus dont natively give us a name parameter
	if name == nil then
		name = UnitName(unit)
	end

	--Return if the unit is not a player
	if unit ~= nil and not UnitIsPlayer(unit) then
		return
	end

	--Dont show the menu on the player's own frame if not in debug mode
	if unit == "player" and not addon.debugMenus then
		return
	end

	--Check that we have a non nil name, and that the target is a player
	if name ~= nil then
		UIDropDownMenu_AddSeparator(UIDROPDOWNMENU_MENU_LEVEL)
		local info = UIDropDownMenu_CreateInfo()
		info.notClickable = true
		info.notCheckable = true
		info.isTitle = true
		info.text = addonName
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		info = UIDropDownMenu_CreateInfo()
		info.notClickable = true
		info.notCheckable = true
		info.text = "Send my info..."
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		info = UIDropDownMenu_CreateInfo()
		info.dist = 0
		info.notCheckable = true
		info.func = function() SendPlayerInfo(name) end
		local maxTalentSpec, maxTalentsSpent = addon.GetSpecByGroupNum(addon.GetActiveSpecGroup())
		info.text = "Current Spec : " .. maxTalentSpec
		info.leftPadding = 8
		if maxTalentsSpent > 0 then
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end

		--[[
		info = UIDropDownMenu_CreateInfo()
		info.dist = 0
		info.notCheckable = true
		info.func = function() SendPlayerInfo(2, name) end
		maxTalentSpec, maxTalentsSpent = addon.GetSpecByGroupNum(2)
		info.text = "Spec 2 : " .. maxTalentSpec
		info.leftPadding = 8
		if maxTalentsSpent > 0 then
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
		--]]

		--Only US region supported for now
		if GetLocale() == "enUS" then
			info = UIDropDownMenu_CreateInfo()
			info.dist = 0
			info.notCheckable = true
			info.func = function()
				local myname = UnitName("player")
				local myserver = GetRealmName()
				local link = format("https://classic.warcraftlogs.com/character/us/%s/%s", myserver, myname)
				SendChatMessage("{rt3} " .. addonName .. " : Warcraft Logs Link " .. link, "WHISPER", "COMMON", name)
			end
			info.text = "Warcraft Logs Link"
			info.leftPadding = 8
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end

hooksecurefunc("UnitPopup_ShowMenu", GroupieUnitMenu)
