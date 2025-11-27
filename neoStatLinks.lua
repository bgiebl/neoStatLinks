-- Locale System (similar to TaboreaDreaming)
local ROOT_PATH = "Interface/Addons/neoStatLinks"
local LOCALE_PATH = ROOT_PATH.."/locales/"
local DEFAULT_LANGUAGE = "EN"

local function SafeLoadLocaleFile(path)
	local chunk, err = loadfile(path)
	if not chunk then
		print(string.format("|cffff0000[neoStatLinks]|r Failed to load locale file: %s (%s)", tostring(path), tostring(err)))
		return nil
	end
	local ok, data = pcall(chunk)
	if not ok then
		print(string.format("|cffff0000[neoStatLinks]|r Error executing locale file: %s (%s)", tostring(path), tostring(data)))
		return nil
	end
	if type(data) ~= "table" then
		return nil
	end
	return data
end

local function DetectLanguage()
	if type(GetLanguage) == "function" then
		local gameLang = GetLanguage()
		if gameLang and gameLang ~= "" then
			return string.upper(string.sub(gameLang, 1, 2))
		end
	end
	return DEFAULT_LANGUAGE
end

local function MergeLocales(base, overlay)
	if type(base) ~= "table" then
		base = {}
	end
	if type(overlay) == "table" then
		for key, value in pairs(overlay) do
			base[key] = value
		end
	end
	return base
end

local function LoadLocale(languageOverride)
	local requested = languageOverride
	if not requested or requested == "" or requested == "auto" then
		requested = DetectLanguage()
	else
		requested = string.upper(string.sub(requested, 1, 2))
	end

	local base = SafeLoadLocaleFile(LOCALE_PATH.."BASE.lua") or {}
	local overlay = SafeLoadLocaleFile(string.format("%s%s.lua", LOCALE_PATH, requested))

	if not overlay and requested ~= DEFAULT_LANGUAGE then
		overlay = SafeLoadLocaleFile(string.format("%s%s.lua", LOCALE_PATH, DEFAULT_LANGUAGE))
	end

	local merged = MergeLocales(base, overlay)

	return requested, merged
end

local Locale = {}
local LocaleTable = {}

function Locale.Get(key)
	return LocaleTable[key] or key
end

function Locale.Format(key, ...)
	local text = Locale.Get(key)
	if select("#", ...) > 0 then
		return string.format(text, ...)
	end
	return text
end

local L = Locale

neoStatLinks = {
	Version = "0.2",
	Author = "Xcalmx",
	Original_ChatEdit_AddItemLink = nil,
	UsePyHook = false,
	py_hook = nil,
	py_lib = nil,
	Debug = false,
	Frame = nil,
        ManaStoneTier1ID = 202840,
        ManaStoneTier20ID = 202859,
        ManaStoneTier4ID = 202843,
	
	NameAndStat = {
		-- Balanced accessories
		[229698] = true,
		[229699] = true,
		[229700] = true,
		-- Blue crap from KBN
		[227700] = true,
		[227701] = true,
		[227702] = true,
		[227703] = true,
		[227704] = true,
		[227705] = true,
		[227706] = true,
		[227707] = true,
		[227708] = true,
		[227709] = true,
		[227710] = true,
		[227711] = true,
	},
	
	-- Locale system
	L = nil,
	Locale = Locale,
};

-- Initialize locale system
local function InitializeLocale()
	local _, initialLocales = LoadLocale()
	LocaleTable = initialLocales
	neoStatLinks.L = initialLocales
	neoStatLinks.Language = DetectLanguage()
end

function neoStatLinks.ReloadLocale(languageOverride)
	local language, locales = LoadLocale(languageOverride)
	LocaleTable = locales
	neoStatLinks.L = locales
	neoStatLinks.Language = language
	if type(neoStatLinks.ApplyLocaleTexts) == "function" then
		neoStatLinks.ApplyLocaleTexts()
	end
	return locales
end

function neoStatLinks.SetLanguage(language)
	if language == nil or language == "" then
		language = "auto"
	end
	local normalized
	if language == "auto" or language == "AUTO" then
		normalized = "auto"
	else
		normalized = string.upper(string.sub(language, 1, 2))
	end
	
	if not neoStatLinksSettings then
		neoStatLinksSettings = {}
	end
	neoStatLinksSettings.Language = normalized
	SaveVariables("neoStatLinksSettings")
	neoStatLinks.ReloadLocale(normalized)
end

-- Initialize locale system
InitializeLocale()

function neoStatLinks:parse_item_link(link)
	if(not link) then
		neoStatLinks.DebugPrint("parse_item_link: link is nil");
		return nil;
	end
	
	neoStatLinks.DebugPrint("parse_item_link: Parsing link format");
	
	local itemID, bindType, runes_plus_tier_max_dur, stat12, stat34, stat56, rune1, rune2, rune3, rune4, dur, hash, color, name = 
		string.match(link, "|Hitem:([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+)|h|c([0-9a-f]+)%[(.+)%]|[hr]");
	if(not name) then
		neoStatLinks.DebugPrint("parse_item_link: First pattern failed, trying without color");
		--try without color
		color = "ffffff";
		itemID, bindType, runes_plus_tier_max_dur, stat12, stat34, stat56, rune1, rune2, rune3, rune4, dur, hash, name = 
			string.match(link, "|Hitem:([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+) ([0-9a-f]+)|h%[(.+)%]|[hr]");
		if(not name) then
			neoStatLinks.DebugPrint("parse_item_link: Second pattern failed, trying simple vendor link");
			--try it without any modifiers OR color (vendor link)
			bindType, runes_plus_tier_max_dur, stat12, stat34, stat56, rune1, rune2, rune3, rune4, dur, hash = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
			itemID, name = string.match(link, "|Hitem:([0-9a-f]+)|h%[(.+)%]|[hr]");
			if(not name) then
				neoStatLinks.DebugPrint("parse_item_link: Third pattern failed, trying with color only");
				--try it without any modifiers (vendor link)
				itemID, color, name = string.match(link, "|Hitem:([0-9a-f]+)|h|c([0-9a-f]+)%[(.+)%]|[hr]");
				if(not name) then
					neoStatLinks.DebugPrint("parse_item_link: All patterns failed, returning nil");
					return nil;
				end
			end
		end
	end
	
	neoStatLinks.DebugPrint(string.format("parse_item_link: Parsed - itemID=%s, name=%s, stat12=%s, stat34=%s, stat56=%s", 
		tostring(itemID), tostring(name), tostring(stat12), tostring(stat34), tostring(stat56)));
	if(string.len(color) == 8) then
		color = string.sub(color, 3);
	end
	
	local stats = {};
	for n,v in pairs({stat12, stat34, stat56}) do
		local statName = (n == 1 and "stat12") or (n == 2 and "stat34") or "stat56";
		neoStatLinks.DebugPrint(string.format("parse_item_link: Processing %s = '%s'", statName, tostring(v)));
		if(v and v ~= "0" and v ~= nil) then
			-- we have at least one stat.
			if(string.len(v) < 5) then
				--single stat
				local statValue = tonumber(v, 16);
				neoStatLinks.DebugPrint(string.format("parse_item_link: %s is single stat: %d (0x%x)", statName, statValue, statValue));
				table.insert(stats, statValue);
			else
				local s1 = string.sub(v, 1, 4);
				local s2 = string.sub(v, 5);
				local statValue1 = tonumber(s1, 16);
				local statValue2 = tonumber(s2, 16);
				neoStatLinks.DebugPrint(string.format("parse_item_link: %s contains two stats: %d (0x%x) and %d (0x%x)", 
					statName, statValue1, statValue1, statValue2, statValue2));
				table.insert(stats, statValue1);
				table.insert(stats, statValue2);
			end
		else
			neoStatLinks.DebugPrint(string.format("parse_item_link: %s is empty or zero, skipping", statName));
		end
	end
	
	neoStatLinks.DebugPrint(string.format("parse_item_link: Final stats array has %d entries", #stats));
	
	
	local unknown, rune_plus, rarity_tier, max_dur = string.match("0000000"..runes_plus_tier_max_dur, "([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])$");
	rune_plus = tonumber(rune_plus, 16);
	rarity_tier = tonumber(rarity_tier, 16);
	local plus = rune_plus % 32;
	local emptyRuneSlots = math.floor(rune_plus/32);
	local rarity = math.floor(rarity_tier/32);
	local tier = rarity_tier % 32;
	
	-- bindType contains the following information:
	-- 0x001 - item unbound
	-- 0x002 - has been previously unbound
	-- 0x100 - prevent hijack - whatever that means
	-- 0x200 - hide durability
	-- 0x400 - Skill Set Extracted
	-- 0x10000 - unknown, but seen on real items.
	local bindType = tonumber(bindType, 16);
	local unbound = ((bindType%2) == 1);
	local bindOnEquip = ((math.floor(bindType/2)%2) == 1);
	local skillExtracted = ((math.floor(bindType/0x400)%2) == 1);

	local result = {
		itemID=tonumber(itemID, 16),
		bindType=bindType,
		unbound=unbound,
		bindOnEquip=bindOnEquip,
		skillExtracted=skillExtracted,
		stats=stats,
		runes = {
				tonumber(rune1, 16),
				tonumber(rune2, 16),
				tonumber(rune3, 16),
				tonumber(rune4, 16),
			},
		emptyRuneSlots=emptyRuneSlots,
		plus=plus,
		tier_add=tier-10,
		rarity_add=rarity,
		max_dur=tonumber(max_dur, 16),
		dur=tonumber(dur, 16)/100,
		hash=tonumber(hash, 16),
		color=color,
		misc=tonumber(unknown, 16),
		name=name
		};
	
	return result;
end
function neoStatLinks:_getStatName(id)
	local sns, name;
	if(id > 500000) then
		--try it directly.
		sns = 'Sys' .. id .. '_name';
		name = TEXT(sns);
		if(name ~= sns) then
			return name;
		end
	end
	
	-- Off by 0x70000 is the most common.
	sns = 'Sys' .. (id + 0x70000) .. '_name';
	name = TEXT(sns);
	if(name ~= sns) then
		return name;
	end
	
	-- Last ditch effort, try 500000
	sns = 'Sys' .. (id + 500000) .. '_name';
	return(TEXT(sns));
end

function neoStatLinks:EscapePattern(str)
	if not str then return str end
	-- Escape special pattern characters in Lua: ( ) . + - * ? [ ] ^ $ %
	return (string.gsub(str, "([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1"))
end


function neoStatLinks:OnLoad(this)
	self.Frame = this;
	this:RegisterEvent("VARIABLES_LOADED");
end

function neoStatLinks:Toggle()
	if(neoStatLinksSettings.enabled) then
		neoStatLinks.Disable();
	else
		neoStatLinks.Enable();
	end
end

function neoStatLinks.Enable()
	neoStatLinksSettings.enabled = true;
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r " .. L.Get("PRINT_ENABLED"));
end

function neoStatLinks.Disable()
	neoStatLinksSettings.enabled = false;
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r " .. L.Get("PRINT_DISABLED"));
end

function neoStatLinks.OpenCurseForgePage()
	if GC_OpenWebRadio then
		GC_OpenWebRadio(L.Get("CURSEFORGE_URL"))
	end
end

function neoStatLinks.LanguageDropdownInit()
	local currentValue = (neoStatLinksSettings and neoStatLinksSettings.Language) or "auto"
	local current
	if type(currentValue) == "string" then
		local upper = string.upper(currentValue)
		if upper == "AUTO" then
			current = "auto"
		else
			current = string.upper(string.sub(upper, 1, 2))
		end
	else
		current = "auto"
	end

	local function addOption(value, labelKey)
		local info = {}
		info.text = L.Get(labelKey)
		info.func = function()
			neoStatLinks.SetLanguage(value)
		end
		if value == "auto" then
			info.checked = (current == "auto")
		else
			info.checked = (current == string.upper(value))
		end
		UIDropDownMenu_AddButton(info)
	end

	addOption("auto", "OPTION_LANGUAGE_DROPDOWN_AUTO")
	addOption("EN", "OPTION_LANGUAGE_DROPDOWN_EN")
	addOption("DE", "OPTION_LANGUAGE_DROPDOWN_DE")
end

function neoStatLinks.ApplyLocaleTexts()
	if neoStatLinks_SettingsTitle then
		neoStatLinks_SettingsTitle:SetText(L.Get("SETTINGS_TITLE_LABEL"))
	end
	if neoStatLinks_SettingsMoreInfoLabel then
		neoStatLinks_SettingsMoreInfoLabel:SetText(L.Get("SETTINGS_MORE_INFO_LABEL"))
	end
	if neoStatLinks_SettingsLanguageLabel then
		neoStatLinks_SettingsLanguageLabel:SetText(L.Get("SETTINGS_LANGUAGE_LABEL"))
	end
	if neoStatLinks_SettingsCleanTextLabel then
		neoStatLinks_SettingsCleanTextLabel:SetText(L.Get("SETTINGS_CLEAN_TEXT_LABEL"))
	end
	if neoStatLinks_ShowTierCheckbox_Text then
		neoStatLinks_ShowTierCheckbox_Text:SetText(L.Get("SETTINGS_SHOW_TIER"))
	end
	if neoStatLinks_EnableAAHCheckbox_Text then
		neoStatLinks_EnableAAHCheckbox_Text:SetText(L.Get("SETTINGS_ENABLE_AAH"))
	end
	if neoStatLinks_DebugCheckbox_Text then
		neoStatLinks_DebugCheckbox_Text:SetText(L.Get("SETTINGS_ENABLE_DEBUG"))
	end
	if neoStatLinks_SettingsDialog_CurseForgeButton then
		neoStatLinks_SettingsDialog_CurseForgeButton:SetText(L.Get("CURSEFORGE_BUTTON"))
	end
	if neoStatLinks_LanguageDropdown then
		local language = (neoStatLinksSettings and neoStatLinksSettings.Language) or "auto"
		local labelKey
		if language == "auto" or language == "AUTO" then
			labelKey = "OPTION_LANGUAGE_DROPDOWN_AUTO"
		elseif language == "DE" then
			labelKey = "OPTION_LANGUAGE_DROPDOWN_DE"
		elseif language == "EN" then
			labelKey = "OPTION_LANGUAGE_DROPDOWN_EN"
		else
			labelKey = "OPTION_LANGUAGE_DROPDOWN_AUTO"
		end
		UIDropDownMenu_SetText(neoStatLinks_LanguageDropdown, L.Get(labelKey))
	end
end

function neoStatLinks.ShowSettings()
	if neoStatLinks_SettingsDialog and neoStatLinks_SettingsDialog:IsVisible() then
		neoStatLinks_SettingsDialog:Hide()
	elseif neoStatLinks_SettingsDialog then
		-- Apply locale texts
		if type(neoStatLinks.ApplyLocaleTexts) == "function" then
			neoStatLinks.ApplyLocaleTexts()
		end
		
		-- Refresh language dropdown text
		if neoStatLinks_LanguageDropdown then
			local language = (neoStatLinksSettings and neoStatLinksSettings.Language) or "auto"
			local labelKey
			if language == "auto" or language == "AUTO" then
				labelKey = "OPTION_LANGUAGE_DROPDOWN_AUTO"
			elseif language == "DE" then
				labelKey = "OPTION_LANGUAGE_DROPDOWN_DE"
			elseif language == "EN" then
				labelKey = "OPTION_LANGUAGE_DROPDOWN_EN"
			else
				labelKey = "OPTION_LANGUAGE_DROPDOWN_AUTO"
			end
			UIDropDownMenu_SetText(neoStatLinks_LanguageDropdown, L.Get(labelKey))
		end
		
		-- Set checkbox states
		if neoStatLinks_ShowTierCheckbox then
			if neoStatLinksSettings.showTier ~= false then
				neoStatLinks_ShowTierCheckbox:SetChecked(true)
			else
				neoStatLinks_ShowTierCheckbox:SetChecked(false)
			end
		end
		
		if neoStatLinks_EnableAAHCheckbox then
			if neoStatLinksSettings.enableAAH ~= false then
				neoStatLinks_EnableAAHCheckbox:SetChecked(true)
			else
				neoStatLinks_EnableAAHCheckbox:SetChecked(false)
			end
		end
		
		if neoStatLinks_DebugCheckbox then
			if neoStatLinksSettings.debug then
				neoStatLinks_DebugCheckbox:SetChecked(true)
			else
				neoStatLinks_DebugCheckbox:SetChecked(false)
			end
		end
		
		-- Set clean text input value
		if neoStatLinks_SettingsDialog_CleanTextInput then
			local cleanText = (neoStatLinksSettings and neoStatLinksSettings.cleanText) or "Clean"
			neoStatLinks_SettingsDialog_CleanTextInput:SetText(cleanText)
		end
		
		neoStatLinks_SettingsDialog:Show()
	end
end

function neoStatLinks.OnShowTierCheckboxClick(checked)
	neoStatLinksSettings.showTier = (checked == true or checked == 1)
	SaveVariables("neoStatLinksSettings")
	if neoStatLinksSettings.showTier then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r " .. L.Get("PRINT_TIER_ENABLED"));
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r " .. L.Get("PRINT_TIER_DISABLED"));
	end
end

function neoStatLinks.OnEnableAAHCheckboxClick(checked)
	neoStatLinksSettings.enableAAH = (checked == true or checked == 1)
	SaveVariables("neoStatLinksSettings")
	if neoStatLinksSettings.enableAAH then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r " .. L.Get("PRINT_AAH_ENABLED"));
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r " .. L.Get("PRINT_AAH_DISABLED"));
	end
end

function neoStatLinks.OnDebugCheckboxClick(checked)
	neoStatLinksSettings.debug = (checked == true or checked == 1)
	neoStatLinks.Debug = (checked == true or checked == 1)
	SaveVariables("neoStatLinksSettings")
	if neoStatLinksSettings.debug then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r " .. L.Get("PRINT_DEBUG_ENABLED"));
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r " .. L.Get("PRINT_DEBUG_DISABLED"));
	end
end

function neoStatLinks.OnCleanTextChanged()
	local input = neoStatLinks_SettingsDialog_CleanTextInput
	if not input then return end
	
	local cleanText = input:GetText()
	if cleanText and cleanText ~= "" then
		neoStatLinksSettings.cleanText = cleanText
		SaveVariables("neoStatLinksSettings")
	end
end

function neoStatLinks.DebugPrint(msg)
	if neoStatLinks.Debug or (neoStatLinksSettings and neoStatLinksSettings.debug) then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks Debug]|r " .. tostring(msg));
	end
end

function neoStatLinks.SetHook()
	if neoStatLinks.UsePyHook and neoStatLinks.py_hook then
		neoStatLinks.py_hook.AddHook("ChatEdit_AddItemLink", "NEOSTATLINKS", neoStatLinks.ChatEdit_AddItemLink_PyHook)
		neoStatLinks.DebugPrint("Hook registered using py_hook");
		return true;
	else
		neoStatLinks.DebugPrint("SetHook called but py_hook not available");
		return false;
	end
end

function neoStatLinks.RemoveHook()
	if neoStatLinks.UsePyHook and neoStatLinks.py_hook then
		neoStatLinks.py_hook.RemoveHook("ChatEdit_AddItemLink", "NEOSTATLINKS")
	end
end

function neoStatLinks.RewriteLink(link)
	if not link then
		neoStatLinks.DebugPrint("RewriteLink called with nil link");
		return link;
	end
	
	neoStatLinks.DebugPrint("RewriteLink called for: " .. tostring(link:sub(1, 100)) .. (link:len() > 100 and "..." or ""));
	
	-- Looking specifically for mana stones.
	local item = neoStatLinks:parse_item_link(link);
	
	if not item then
		neoStatLinks.DebugPrint("  -> Failed to parse item link");
		return link;
	end
	
	neoStatLinks.DebugPrint(string.format("  -> Parsed item: ID=%d, Name=%s, Stats count=%d", 
		item.itemID or 0, item.name or "nil", item.stats and #item.stats or 0));
	
	if item.stats and #item.stats > 0 then
		for i, statId in ipairs(item.stats) do
			neoStatLinks.DebugPrint(string.format("    Stat[%d] = %d (0x%x)", i, statId, statId));
		end
	end
	
	if(item and item.itemID >= neoStatLinks.ManaStoneTier1ID and item.itemID <= neoStatLinks.ManaStoneTier20ID) then
		neoStatLinks.DebugPrint(string.format("  -> Item is a manastone (ID %d is in range %d-%d)", 
			item.itemID, neoStatLinks.ManaStoneTier1ID, neoStatLinks.ManaStoneTier20ID));
		
		--we have a mana stone.
		local statsCount = item.stats and #item.stats or 0;
		local tier = item.itemID - neoStatLinks.ManaStoneTier1ID + 1;
		local replacementText = nil;
		
		if statsCount == 1 then
			-- We have a stone with only one stat
			local statName = neoStatLinks:_getStatName(item.stats[1]);
			neoStatLinks.DebugPrint(string.format("  -> Single stat found: ID=%d, Name=%s", item.stats[1], statName or "nil"));
			if statName then
				-- Create the replacement text with or without tier based on settings
				local showTier = neoStatLinksSettings.showTier ~= false; -- default to true
				if showTier then
					replacementText = string.format("[T%d | %s]", tier, statName);
				else
					replacementText = string.format("[%s]", statName);
				end
				neoStatLinks.DebugPrint(string.format("  -> Manastone tier: %d (itemID: %d)", tier, item.itemID));
			else
				neoStatLinks.DebugPrint("  -> Failed to get stat name, link not rewritten");
			end
		elseif statsCount == 0 then
			-- Clean manastone (no stats)
			neoStatLinks.DebugPrint("  -> Clean manastone detected (no stats)");
			local cleanText = (neoStatLinksSettings and neoStatLinksSettings.cleanText) or "Clean"
			local showTier = neoStatLinksSettings.showTier ~= false; -- default to true
			if showTier then
				replacementText = string.format("[T%d | %s]", tier, cleanText);
			else
				replacementText = string.format("[%s]", cleanText);
			end
			neoStatLinks.DebugPrint(string.format("  -> Manastone tier: %d (itemID: %d)", tier, item.itemID));
		else
			neoStatLinks.DebugPrint(string.format("  -> Stats count is %d, not 0 or 1, skipping rewrite", statsCount));
		end
		
		-- If we have a replacement text, perform the replacement
		if replacementText then
			-- Escape special characters in item.name before using in pattern
			local escapedName = neoStatLinks:EscapePattern(item.name);
			local newLink, numReplacements = string.gsub(link, "%["..escapedName.."%]", replacementText);
			
			neoStatLinks.DebugPrint(string.format("  -> Attempting to replace [%s] with %s", item.name, replacementText));
			neoStatLinks.DebugPrint(string.format("  -> Escaped pattern: [%s]", escapedName));
			neoStatLinks.DebugPrint(string.format("  -> Replacement text: %s", replacementText));
			neoStatLinks.DebugPrint(string.format("  -> gsub made %d replacement(s)", numReplacements));
			
			if numReplacements > 0 then
				link = newLink;
				neoStatLinks.DebugPrint("  -> Link rewritten successfully");
				neoStatLinks.DebugPrint("  -> New link: " .. tostring(link:sub(1, 100)) .. (link:len() > 100 and "..." or ""));
			else
				neoStatLinks.DebugPrint("  -> WARNING: gsub found no matches! Original item name might not match link format");
				neoStatLinks.DebugPrint("  -> Original item name: [" .. tostring(item.name) .. "]");
				-- Try alternative approach: find the name in the link and replace it
				local linkNameStart, linkNameEnd = string.find(link, "%[" .. escapedName .. "%]");
				if linkNameStart then
					neoStatLinks.DebugPrint(string.format("  -> Found item name at position %d-%d, attempting direct replacement", linkNameStart, linkNameEnd));
					link = string.sub(link, 1, linkNameStart-1) .. replacementText .. string.sub(link, linkNameEnd+1);
					neoStatLinks.DebugPrint("  -> Link rewritten using direct replacement");
				else
					-- Try without escaping to see if it matches differently
					local plainStart, plainEnd = string.find(link, "%[" .. item.name .. "%]");
					if plainStart then
						neoStatLinks.DebugPrint(string.format("  -> Found item name (unescaped) at position %d-%d, attempting direct replacement", plainStart, plainEnd));
						link = string.sub(link, 1, plainStart-1) .. replacementText .. string.sub(link, plainEnd+1);
						neoStatLinks.DebugPrint("  -> Link rewritten using direct replacement (unescaped)");
					else
						neoStatLinks.DebugPrint("  -> Could not find item name in link - pattern mismatch");
						neoStatLinks.DebugPrint("  -> Link sample around name: " .. tostring(link:match("|h.([%[].[%]])") or "not found"));
					end
				end
			end
		end
	elseif item.itemID then
		neoStatLinks.DebugPrint(string.format("  -> Item ID %d is not a manastone (not in range %d-%d)", 
			item.itemID, neoStatLinks.ManaStoneTier1ID, neoStatLinks.ManaStoneTier20ID));
	end
	
	return(link);
end

-- Hook function using py_hook (receives nextfn as first parameter)
function neoStatLinks.ChatEdit_AddItemLink_PyHook(nextfn, link, ...)
	neoStatLinks.DebugPrint("ChatEdit_AddItemLink_PyHook called");
	if(neoStatLinksSettings and neoStatLinksSettings.enabled and link) then
		link = neoStatLinks.RewriteLink(link);
	else
		neoStatLinks.DebugPrint("  -> Hook called but addon disabled or link is nil");
	end
	return nextfn(link, ...);
end

-- Fallback hook function using direct replacement
function neoStatLinks.ChatEdit_AddItemLink(link)
	neoStatLinks.DebugPrint("ChatEdit_AddItemLink (direct hook) called");
	if(neoStatLinksSettings and neoStatLinksSettings.enabled) then
		local newLink = neoStatLinks.RewriteLink(link);
		link = newLink; -- Use the returned link
		neoStatLinks.DebugPrint("  -> Link after rewrite: " .. tostring(link and link:sub(1, 100) or "nil") .. (link and link:len() > 100 and "..." or ""));
	else
		neoStatLinks.DebugPrint("  -> Hook called but addon disabled");
	end
	if neoStatLinks.Original_ChatEdit_AddItemLink then
		local result = neoStatLinks.Original_ChatEdit_AddItemLink(link);
		return result; -- Return the result of the original function
	else
		neoStatLinks.DebugPrint("  -> ERROR: Original_ChatEdit_AddItemLink is nil!");
		return false;
	end
end

--- This is a patch for AAH which displays stat names in the list ---
function neoStatLinks.BrowseAddItemToList(pageNumber, itemIndex)
	neoStatLinks.Original_BrowseAddItemToList(pageNumber, itemIndex);
	
	if(neoStatLinksSettings.enabled and neoStatLinksSettings.enableAAH ~= false) then
		local list = AuctionBrowseList.list
		local index = #(AuctionBrowseList.list)
		--Look specifically for Mana Stone items.
		local itemid = AAHVar.AuctionBrowseCache.CACHEDDATA[pageNumber][itemIndex].itemid;
		if(list[index] and itemid >= neoStatLinks.ManaStoneTier1ID and itemid <= neoStatLinks.ManaStoneTier20ID) then
			local link = GetAuctionBrowseItemLink(list[index].auctionid);
                        local item = neoStatLinks:parse_item_link(link);
			
			if(item and item.stats and #item.stats == 1) then
				-- We have a stone with only one stat
				list[index].name = neoStatLinks:_getStatName(item.stats[1]);
			end
		end
		if(list[index] and neoStatLinks.NameAndStat[itemid]) then
			local link = GetAuctionBrowseItemLink(list[index].auctionid);
                        local item = neoStatLinks:parse_item_link(link);
			if(item.stats and #item.stats == 1) then
				-- We have an item with only one stat
				local statName = neoStatLinks:_getStatName(item.stats[1]);
				list[index].name = item.name..": "..statName;
			end
		end
	end
end
function neoStatLinks.AAH3_BrowseAddItemToList(pageNumber, itemIndex)
	neoStatLinks.Original_AAH3_BrowseAddItemToList(pageNumber, itemIndex);
	
	if(neoStatLinksSettings.enabled and neoStatLinksSettings.enableAAH ~= false) then
		local list = AAH.Browse.Results.list
		local index = #(AAH.Browse.Results.list)
		--Look specifically for Mana Stone items.
		local listing = AAH.Browse.Cache.CACHEDDATA[pageNumber][itemIndex];
		local itemid = listing.itemid;
		
		if(list[index] and itemid >= neoStatLinks.ManaStoneTier1ID and itemid <= neoStatLinks.ManaStoneTier20ID) then
			local link = GetAuctionBrowseItemLink(list[index].auctionid);
                        local item = neoStatLinks:parse_item_link(link);
			
			if(item and item.stats and #item.stats == 1) then
				-- We have a stone with only one stat
				list[index].name = neoStatLinks:_getStatName(item.stats[1]);
			end
		end
		if(list[index] and neoStatLinks.NameAndStat[itemid]) then
			local link = GetAuctionBrowseItemLink(list[index].auctionid);
                        local item = neoStatLinks:parse_item_link(link);
			if(item.stats and #item.stats == 1) then
				-- We have an item with only one stat
				local statName = neoStatLinks:_getStatName(item.stats[1]);
				list[index].name = item.name..": "..statName;
			end
		end
	end
end

function neoStatLinks:OnEvent(event)
	if (event == "VARIABLES_LOADED") then
                SLASH_neoStatLinks1 = "/neoStatLinks";
                SLASH_neoStatLinks2 = "/nsl";
		SlashCmdList["neoStatLinks"] = function (editbox, msg) 
			local command = string.lower(string.match(msg, "^(%S+)") or "");
			local param = string.match(msg, "^%S+%s+(.+)$") or "";
			
			if command == "debug" or command == "d" then
				if neoStatLinksSettings.debug then
					neoStatLinksSettings.debug = false;
					neoStatLinks.Debug = false;
					DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r " .. L.Get("PRINT_DEBUG_DISABLED"));
				else
					neoStatLinksSettings.debug = true;
					neoStatLinks.Debug = true;
					DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r " .. L.Get("PRINT_DEBUG_ENABLED"));
				end
				SaveVariables("neoStatLinksSettings");
			elseif command == "config" or command == "settings" then
				neoStatLinks.ShowSettings();
			else
				neoStatLinks:Toggle();
			end
		end
		
		if(not neoStatLinksSettings) then
			neoStatLinksSettings = {
				enabled = true,
				debug = false,
				showTier = true,
				enableAAH = true,
				cleanText = "Clean"
				};
		end
		-- Ensure new settings exist with defaults if missing
		if neoStatLinksSettings.showTier == nil then
			neoStatLinksSettings.showTier = true;
		end
		if neoStatLinksSettings.enableAAH == nil then
			neoStatLinksSettings.enableAAH = true;
		end
		if neoStatLinksSettings.cleanText == nil then
			neoStatLinksSettings.cleanText = "Clean";
		end
		
		-- Load saved language preference or use auto
		local savedLanguage = neoStatLinksSettings.Language or "auto"
		neoStatLinks.ReloadLocale(savedLanguage)
		
		SaveVariables("neoStatLinksSettings");
		
		-- Set debug mode from settings
		if neoStatLinksSettings.debug ~= nil then
			neoStatLinks.Debug = neoStatLinksSettings.debug;
		end
		
		-- Apply locale texts after UI is loaded
		if type(neoStatLinks.ApplyLocaleTexts) == "function" then
			neoStatLinks.ApplyLocaleTexts()
		end
		
		neoStatLinks.DebugPrint("Initializing neoStatLinks - Hook setup starting");
		
		-- Try to use py_hook if pylib is available
		if pylib and pylib.GetLibraries then
			neoStatLinks.DebugPrint("pylib detected, attempting to get libraries");
			local py_lib, py_timer, py_string, py_table, py_num, py_hash, py_color, py_hook, py_callback, py_item, py_helper = pylib.GetLibraries()
			if py_hook then
				neoStatLinks.DebugPrint("py_hook library found, using py_hook system");
				self.py_hook = py_hook
				self.py_lib = py_lib
				self.UsePyHook = true
				
				-- Try to hook immediately first
				local hooked = self:SetHook()
				
				-- Also register for REGISTER_HOOKS event in case it fires later or pylib isn't ready yet
				if py_lib.RegisterEventHandler then
					neoStatLinks.DebugPrint("Registering for REGISTER_HOOKS and UNREGISTER_HOOKS events");
					py_lib.RegisterEventHandler("REGISTER_HOOKS", "NEOSTATLINKS", function()
						neoStatLinks.DebugPrint("REGISTER_HOOKS event received, setting hook");
						self:SetHook()
					end)
					py_lib.RegisterEventHandler("UNREGISTER_HOOKS", "NEOSTATLINKS", self.RemoveHook)
					
					-- Try to manually trigger if pylib is already ready
					if py_lib.SendEvent then
						-- This will trigger the hook setup if REGISTER_HOOKS already fired
						neoStatLinks.DebugPrint("Checking if pylib is ready by trying to send REGISTER_HOOKS event");
					end
				else
					neoStatLinks.DebugPrint("RegisterEventHandler not available");
				end
				
				if not hooked then
					neoStatLinks.DebugPrint("WARNING: Immediate hook registration failed, will wait for REGISTER_HOOKS event");
				end
			else
				neoStatLinks.DebugPrint("pylib found but py_hook is nil, falling back to direct hook");
			end
		else
			neoStatLinks.DebugPrint("pylib not found, using direct hook method");
		end
		
		-- Fallback to direct hooking if py_hook not available or not hooked yet
		if not self.UsePyHook then
			if(not self.Original_ChatEdit_AddItemLink) then
				neoStatLinks.DebugPrint("Setting up direct hook replacement");
				self.Original_ChatEdit_AddItemLink = _G.ChatEdit_AddItemLink;
				_G.ChatEdit_AddItemLink = self.ChatEdit_AddItemLink;
				neoStatLinks.DebugPrint("Direct hook installed successfully");
			else
				neoStatLinks.DebugPrint("Direct hook already installed");
			end
		else
			-- Even with py_hook, ensure we have a backup if py_hook fails
			if not self.Original_ChatEdit_AddItemLink then
				self.Original_ChatEdit_AddItemLink = _G.ChatEdit_AddItemLink;
			end
		end
		
		neoStatLinks.DebugPrint(string.format("Hook setup complete. Using %s hook method.", 
			self.UsePyHook and "py_hook" or "direct"));
		
		-- Register for PLAYER_ENTERING_WORLD as a backup to ensure hook is set
		if self.UsePyHook and self.Frame then
			self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD");
		end
		
		--Hook AAH if installed.
		if(AAHFunc and not self.Original_BrowseAddItemToList) then
			self.Original_BrowseAddItemToList = AAHFunc.BrowseAddItemToList;
			AAHFunc.BrowseAddItemToList = self.BrowseAddItemToList;
		end
		--Newer versions of AAH
		if(AAH and AAH.Browse and not self.Original_AAH3_BrowseAddItemToList) then
			self.Original_AAH3_BrowseAddItemToList = AAH.Browse.AddItemToList;
			AAH.Browse.AddItemToList = self.AAH3_BrowseAddItemToList;
		end
		
		if AddonManager then
		    local addon = {
			name = "neoStatLinks",
			version = neoStatLinks.Version,
			author = neoStatLinks.Author,
			description = "More readable stat item links",
			icon = "interface/addons/neoStatLinks/icons/icon.png",
			category = "Other",
			configFrame = neoStatLinks_SettingsDialog, 
			slashCommand = "/neoStatLinks",
			miniButton = false,
			onClickScript = function()
				neoStatLinks.ShowSettings()
			end,
			disableScript = neoStatLinks.Disable,
			enableScript = neoStatLinks.Enable,
		    }
		    if AddonManager.RegisterAddonTable then
			AddonManager.RegisterAddonTable(addon)
		    else
			AddonManager.RegisterAddon(addon.name, addon.description, addon.icon, addon.category, 
			    addon.configFrame, addon.slashCommand, addon.miniButton, addon.onClickScript, addon.version, addon.author)
		    end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Try to hook again in case pylib wasn't ready during VARIABLES_LOADED
		if self.UsePyHook and self.py_hook then
			neoStatLinks.DebugPrint("PLAYER_ENTERING_WORLD: Attempting to ensure hook is registered");
			self:SetHook()
		end
		if self.Frame then
			self.Frame:UnregisterEvent("PLAYER_ENTERING_WORLD");
		end
	end
end