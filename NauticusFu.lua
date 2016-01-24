-- declard color codes for console messages
local RED     = "|cffff0000"
local GREEN   = "|cff00ff00"
local BLUE    = "|cff0000ff"
local MAGENTA = "|cffff00ff"
local YELLOW  = "|cffffff00"
local CYAN    = "|cff00ffff"
local WHITE   = "|cffffffff"
local ORANGE  = "|cffffba00"

local Nauticus = Nauticus
local transitData = Nauticus.transitData
local L = Naut_localise

local Naut_ARTWORKPATH = "Interface\\AddOns\\Nauticus\\Artwork\\"

Nauticus.activeTransitName = ""
Nauticus.activeSelect = -1
Nauticus.activeTransit = -1

-- local variables
local dropdownvalues = {}
local dropdownindexes = {}

NauticusFu = AceLibrary("AceAddon-2.0"):new("FuBarPlugin-2.0", "AceEvent-2.0", "AceDB-2.0")

NauticusFu:RegisterDB("NauticusDB", "NauticusDBPC")
NauticusFu:RegisterDefaults("profile", {
	factionSpecific = true,
	zoneSpecific = false,
	cityAlias = true;
} )

function NauticusFu:OnInitialize()
	self.hasIcon = true
	self.title = "Nauticus"
	self:SetIcon(Naut_ARTWORKPATH.."NauticusLogo")
end

function NauticusFu:IsFactionSpecific()
    return self.db.profile.factionSpecific
end

function NauticusFu:ToggleFaction()
    self.db.profile.factionSpecific = not self.db.profile.factionSpecific
    self:Update()
end

function NauticusFu:IsZoneSpecific()
    return self.db.profile.zoneSpecific
end

function NauticusFu:ToggleZone()
    self.db.profile.zoneSpecific = not self.db.profile.zoneSpecific
    self:Update()
end

function NauticusFu:IsAlias()
    return self.db.profile.cityAlias
end

function NauticusFu:ToggleAlias()
    self.db.profile.cityAlias = not self.db.profile.cityAlias
    self:Update()
end

local tablet = AceLibrary("Tablet-2.0")
function NauticusFu:OnTooltipUpdate()
	local cat = tablet:AddCategory(
		'columns', 2,
		'child_textR', 1,
		'child_textG', 1,
		'child_textB', 0
	)

	if ((Nauticus.activeTransit ~= -1) and (nautSavedVars.knownTimes[Nauticus.activeTransit] ~= nil)) then
		local transit = Nauticus.activeTransit

		cat:AddLine('text', Nauticus.activeTransitName)

		for index, data in pairs(transitData[transit..'_plats']) do
			local platname

			if ( self:IsAlias() ) then
				platname = data.alias
			else
				platname = data.name
			end

			local cat = tablet:AddCategory(
				'text', platname,
				'columns', 2,
				'child_textR', 1,
				'child_textG', 1,
				'child_textB', 0
			)

			local the_time = Nauticus.activeData[index]
			local depOrArr
			local r,g,b

			if (the_time < 0) then
				the_time = -the_time

				if (the_time > 30) then
					r,g,b = 1,1,0
				else
					r,g,b = 1,0,0
				end

				depOrArr = "Departure"
			else
				r,g,b = 0,1,0
				depOrArr = "Arrival"
			end

			local formatted_time
			if (the_time > 59) then
				formatted_time = format("%0.0f", math.floor(the_time/60)).."m "
					..format("%0.0f", the_time-(math.floor(the_time/60)*60)).."s"
			else
				formatted_time = format("%0.0f", the_time).."s"
			end

			cat:AddLine('text', depOrArr..":",
				'text2', formatted_time,
				'text2R', r, 'text2G', g, 'text2B', b)

		end
		local seconds_elapsed = tonumber(time()-nautSavedVars.timestamps[Nauticus.activeTransit]) or 0
		local days = math.floor(seconds_elapsed/86400)
		local hours = math.floor((seconds_elapsed-(days*86400))/3600)
		local minutes = math.floor((seconds_elapsed-(days*86400)-(hours*3600))/60)
		local seconds = seconds_elapsed - (days*86400) - (hours*3600) - (minutes*60)
		local formatted_time
		if days > 1 then
			formatted_time = string.format("%0.0fd %0.0fh %0.0fm %0.0fs",days,hours,minutes,seconds)
		elseif hours > 1 then
			formatted_time = string.format("%0.0fh %0.0fm %0.0fs",hours,minutes,seconds)
		elseif minutes > 1 then
			formatted_time = string.format("%0.0fm %0.0fs",minutes,seconds)
		elseif seconds > 1 then
			formatted_time = string.format("%0.0fs",seconds)
		else
			formatted_time = "0 s"
		end
		cat:AddLine('text', "Age:",
			'text2', formatted_time)

	elseif ((Nauticus.activeTransit ~= -1) and (nautSavedVars.knownTimes[Nauticus.activeTransit] == nil)) then
		local transit = Nauticus.activeTransit

		cat:AddLine('text', Nauticus.activeTransitName)

		for index, data in pairs(transitData[transit..'_plats']) do
			local platname

			if ( self:IsAlias() ) then
				platname = data.alias
			else
				platname = data.name
			end

			local cat = tablet:AddCategory(
				'text', platname,
				'columns', 2,
				'child_textR', 1,
				'child_textG', 1,
				'child_textB', 0
			)

			cat:AddLine('text', "Not Available")
		end
	elseif (Nauticus.activeTransit == -1) then
		cat:AddLine('text', "No Transit Selected")
	end

    tablet:SetHint(L["HINT"])
end

-- NOT using an AceOptions data table
local dewdrop = AceLibrary("Dewdrop-2.0")
function NauticusFu:OnMenuRequest(level, value, inTooltip)

	if inTooltip then return end

	dropdownvalues = {}
	dropdownindexes = {}

	dewdrop:AddLine(
		'text', L["OPT_FACTION"],
		'arg1', self,
		'func', "ToggleFaction",
		'checked', self:IsFactionSpecific(),
		'tooltipTitle', L["OPT_FACTION"],
		'tooltipText', L["OPT_FACTION_DESC"]
	)
	dewdrop:AddLine(
		'text', L["OPT_ZONE"],
		'arg1', self,
		'func', "ToggleZone",
		'checked', self:IsZoneSpecific(),
		'tooltipTitle', L["OPT_ZONE"],
		'tooltipText', L["OPT_ZONE_DESC"]
	)
	dewdrop:AddLine(
		'text', L["OPT_ALIAS"],
		'arg1', self,
		'func', "ToggleAlias",
		'checked', self:IsAlias(),
		'tooltipTitle', L["OPT_ALIAS"],
		'tooltipText', L["OPT_ALIAS_DESC"]
	)
	dewdrop:AddLine(
		'text', ""
	)
	dewdrop:AddLine(
		'text', YELLOW.."Select None",
		'func', function() self:SetTransport(-1) end
	)

	local count = 1
	for index, data in pairs(transitData.transports) do

		local tmplabel = data.label
		dropdownindexes[tmplabel] = index

		local textdesc
		if ( self:IsAlias() ) then
			textdesc = transitData.transports[index].namealias
		else
			textdesc = transitData.transports[index].name
		end

		local addtrans = false
		if ( self:IsFactionSpecific() ) then
			local faction = UnitFactionGroup("player")
			if ((transitData.transports[index].faction == faction) or (transitData.transports[index].faction == "Neutral")) then
				addtrans = true
			end
		else
			addtrans = true
		end

		if ( self:IsZoneSpecific() and (addtrans)) then
			local zonestr = string.lower(transitData.transports[index].name)
			local czonestr = string.lower(GetRealZoneText())
			if (not string.find(zonestr, czonestr)) then
				addtrans = false
			end
		end

		if ((addtrans) and (transitData.transports[index].faction ~= -1)) then
			table.insert(dropdownvalues, transitData.transports[index].label)

			label = transitData.transports[index].label

			if (nautSavedVars.knownTimes[label] ~= nil) then
				textdesc = GREEN..textdesc
			end

			dewdrop:AddLine(
				'text', textdesc,
				'arg1', count,
				'func', function(count) self:SetTransport(count) end
			)

			count = count + 1
		end
	end

	dewdrop:AddLine(
		'text', ""
	)

end

function NauticusFu:OnEnable()
	self:ScheduleRepeatingEvent(self.OnUpdate, 1, self)
end

function NauticusFu:OnUpdate()
	self:Update()
end

function NauticusFu:OnTextUpdate()
	if Naut_IsAlarmSet() then
		self:SetIcon("Interface\\Icons\\INV_Misc_PocketWatch_02")
	else
		self:SetIcon(Naut_ARTWORKPATH..Nauticus.icon)
	end

	if (Nauticus.tempTextCount > 0) then
		Nauticus.tempTextCount = Nauticus.tempTextCount -1
		return
	end

	self:SetText(Nauticus.lowestNameTime)
end

function NauticusFu:OnClick()

	if IsAltKeyDown() then
		if (Nauticus.activeTransit ~= -1) then
			Naut_ToggleAlarm()
	
			-- set tempory button text so you know which one is currently selected
			if Naut_IsAlarmSet() then
				Nauticus.tempText = "Alarm "..RED.."ON"
			else
				Nauticus.tempText = "Alarm OFF"
			end
	
			Nauticus.tempTextCount = 2
			self:SetText(Nauticus.tempText)
			Nauticus.updateNow = true
		end

		return
	end

	if ( table.getn(dropdownvalues) == 0 ) then
		dropdownvalues = {}
		dropdownindexes = {}
	
		local count = 1
		for index, data in pairs(transitData.transports) do
	
			local tmplabel = data.label
			dropdownindexes[tmplabel] = index
	
			local addtrans = false
			if ( self:IsFactionSpecific() ) then
				local faction = UnitFactionGroup("player")
				if ((transitData.transports[index].faction == faction)
					or (transitData.transports[index].faction == "Neutral")) then
	
					addtrans = true
				end
			else
				addtrans = true
			end
	
			if ( self:IsZoneSpecific() and (addtrans)) then
				local zonestr = string.lower(transitData.transports[index].name)
				local czonestr = string.lower(GetRealZoneText())
				if (not string.find(zonestr, czonestr)) then
					addtrans = false
				end
			end
	
			if ((addtrans) and (transitData.transports[index].faction ~= -1)) then
				table.insert(dropdownvalues, transitData.transports[index].label)
				label = transitData.transports[index].label
				count = count + 1
			end
		end
	end

	if ( table.getn(dropdownvalues) == 0 ) then
		Nauticus.activeSelect = -1
		Nauticus.activeTransit = -1
		return
	elseif (Nauticus.activeSelect == -1) then
		Nauticus.activeSelect = 1
	else
		Nauticus.activeSelect = Nauticus.activeSelect + 1
	end

	if (Nauticus.activeSelect > table.getn(dropdownvalues)) then
		Nauticus.activeSelect = 1
		Nauticus.activeTransit = dropdownvalues[Nauticus.activeSelect]
	else
		Nauticus.activeTransit = dropdownvalues[Nauticus.activeSelect]
	end

	if ( self:IsAlias() ) then
		Nauticus.activeTransitName = transitData.transports[dropdownindexes[Nauticus.activeTransit] ].namealias
	else
		Nauticus.activeTransitName = transitData.transports[dropdownindexes[Nauticus.activeTransit] ].name
	end

	local color

	if (nautSavedVars.knownTimes[Nauticus.activeTransit] ~= nil) then
		color = GREEN
	else
		color = RED
	end

	-- set tempory button text so you know which one is currently selected
	Nauticus.tempText = color..Nauticus.activeTransitName
	Nauticus.tempTextCount = 2
	self:SetText(Nauticus.tempText)
	Nauticus.updateNow = true

	if (nautSavedVars.knownTimes[Nauticus.activeTransit] == nil) then
		Naut_TransportRequestData(Nauticus.activeTransit)
	end

	Naut_TransportSelect_SetNone()

end

function NauticusFu:SetTransport(id)

	if (id == -1) then
		Nauticus.activeSelect = -1
		Nauticus.activeTransit = -1
		Nauticus.activeTransitName = L["NONESELECT"]
	else
		Nauticus.activeSelect = id
		Nauticus.activeTransit = dropdownvalues[id]

		if ( self:IsAlias() ) then
			Nauticus.activeTransitName = transitData.transports[dropdownindexes[Nauticus.activeTransit] ].namealias
		else
			Nauticus.activeTransitName = transitData.transports[dropdownindexes[Nauticus.activeTransit] ].name
		end

		if (nautSavedVars.knownTimes[Nauticus.activeTransit] == nil) then
			Naut_TransportRequestData(Nauticus.activeTransit)
		end

		Nauticus.tempText = Nauticus.activeTransitName
		Nauticus.tempTextCount = 2
		self:SetText(Nauticus.tempText)
		Nauticus.updateNow = true
	end

	Naut_TransportSelect_SetNone()

end
