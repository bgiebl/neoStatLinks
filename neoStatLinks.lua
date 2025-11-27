
neoStatLinks = {
	Version = "0.1",
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
};


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
	DEFAULT_CHAT_FRAME:AddMessage("neoStatLinks has been enabled.");
end

function neoStatLinks.Disable()
	neoStatLinksSettings.enabled = false;
	DEFAULT_CHAT_FRAME:AddMessage("neoStatLinks has been disabled.");
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
				-- Create the replacement text with tier: "[TX | Stat Name]"
				replacementText = string.format("[T%d | %s]", tier, statName);
				neoStatLinks.DebugPrint(string.format("  -> Manastone tier: %d (itemID: %d)", tier, item.itemID));
			else
				neoStatLinks.DebugPrint("  -> Failed to get stat name, link not rewritten");
			end
		elseif statsCount == 0 then
			-- Clean manastone (no stats)
			neoStatLinks.DebugPrint("  -> Clean manastone detected (no stats)");
			replacementText = string.format("[T%d | Clean]", tier);
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
	
	-- Not sure I actually want this...
	--if(item and neoStatLinks.NameAndStat[item.itemID]) then
	--	if(item.stats and #item.stats == 1) then
	--		-- We have a stone with only one stat
	--		local statName = neoStatLinks:_getStatName(item.stats[1]);
	--		link = string.gsub(link, "%["..item.name.."%]", "["..item.name..": "..statName.."]");
	--	end
	--end
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
	
	if(neoStatLinksSettings.enabled) then
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
	
	if(neoStatLinksSettings.enabled) then
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
					DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r Debug mode disabled.");
				else
					neoStatLinksSettings.debug = true;
					neoStatLinks.Debug = true;
					DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[neoStatLinks]|r Debug mode enabled.");
				end
				SaveVariables("neoStatLinksSettings");
			else
				neoStatLinks:Toggle();
			end
		end
		
		if(not neoStatLinksSettings) then
			neoStatLinksSettings = {
				enabled = true,
				debug = false
				};
		end
		SaveVariables("neoStatLinksSettings");
		
		-- Set debug mode from settings
		if neoStatLinksSettings.debug ~= nil then
			neoStatLinks.Debug = neoStatLinksSettings.debug;
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
			configFrame = false, 
			slashCommand = "/neoStatLinks",
			miniButton = false,
			onClickScript = false,
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