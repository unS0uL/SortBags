-- VERSION 21.3 MASTER: BLIND BURST ENGINE (ASYNC BANKING)
local _G = getfenv(0)

-- --- [1] PERFORMANCE CACHE ---
local pairs, ipairs, tinsert, tremove, sort = pairs, ipairs, table.insert, table.remove, table.sort
local strfind, format, tonumber, strlower, strsub = string.find, string.format, tonumber, string.lower, string.sub
local GCI, GCL = GetContainerItemInfo, GetContainerItemLink
local PCI, GII, CC = PickupContainerItem, GetItemInfo, ClearCursor
local GNS, CIID = GetContainerNumSlots, ContainerIDToInventoryID
local GIIL, BBID = GetInventoryItemLink, BankButtonIDToInvSlotID
local GFR, GT, DMS =
	GetFramerate, GetTime, function()
		return (_G.debugprofilestop and _G.debugprofilestop() or GetTime() * 1000)
	end

-- --- [2] NAMESPACE & CONSTANTS ---
_G.SortBags = _G.SortBags
	or {
		Queue = {},
		IsSorting = false,
		Stats = { start = 0, moves = 0, p1Total = 0, p2Total = 0, pickup = 0, drop = 0, cleanup = 0, retry = 0 },
		OriginalFuncs = {},
		L = {
			Armor = "Armor",
			Weapon = "Weapon",
			Cons = "Consumable",
			Reag = "Reagent",
			Trade = "Trade Goods",
			Quest = "Quest",
			Ammo = "Projectile",
			SoulBag = "Soul Bag",
			HerbBag = "Herb Bag",
			EnchBag = "Enchanting Bag",
			AmmoBag = "Quiver",
			Finished = "Done. Moves:%d Time:%dms (P1:%.1fms)\nFPS:%.0f Latency:%dms\nPick:%.1fms Drop:%.1fms Clean:%.1fms",
			Waiting = "Waiting for items to unlock...",
			NoMoves = "%s already sorted.",
			Frozen = "Frozen (Alt+Click): %s",
			Unfrozen = "Unfrozen: %s",
		},
		SlotMap = {
			INVTYPE_HEAD = 1,
			INVTYPE_NECK = 2,
			INVTYPE_SHOULDER = 3,
			INVTYPE_BODY = 4,
			INVTYPE_CHEST = 5,
			INVTYPE_ROBE = 5,
			INVTYPE_WAIST = 6,
			INVTYPE_LEGS = 7,
			INVTYPE_FEET = 8,
			INVTYPE_WRIST = 9,
			INVTYPE_HAND = 10,
			INVTYPE_HANDS = 10,
			INVTYPE_FINGER = 11,
			INVTYPE_TRINKET = 12,
			INVTYPE_CLOAK = 13,
			INVTYPE_WEAPON = 14,
			INVTYPE_SHIELD = 15,
			INVTYPE_2HWEAPON = 16,
			INVTYPE_WEAPONMAINHAND = 17,
			INVTYPE_WEAPONOFFHAND = 18,
			INVTYPE_HOLDABLE = 19,
			INVTYPE_RANGED = 20,
			INVTYPE_THROWN = 21,
			INVTYPE_RANGEDRIGHT = 22,
			INVTYPE_RELIC = 23,
			INVTYPE_TABARD = 24,
			INVTYPE_SHIRT = 25,
		},
		Cache = { slots = {}, items = {}, reality = {}, ideal = {}, virtual = {} },
		ItemCache = {},
	}
local SB = _G.SortBags
_G.SortBags_IgnoreList = _G.SortBags_IgnoreList or {}
_G.SortBags_Debug = _G.SortBags_Debug or false

local Teleports = {
	[6948] = true, -- Hearthstone
	[18984] = true, -- Dimensional Ripper - Everlook
	[18986] = true, -- Ultrasafe Transporter - Gadgetzan
	[22589] = true, -- Atiesh
	[17690] = true, -- Frostwolf Insignia Rank 6
	[17909] = true, -- Frostwolf Insignia Rank 6
	[17691] = true, -- Stormpike Insignia Rank 6
	[17904] = true, -- Stormpike Insignia Rank 6
	[13209] = true, -- Seal of the Dawn
	[22631] = true, -- Atiesh
	[51313] = true, -- Portable Wormhole Generator (TWOW)
	[61000] = true, -- Time-Worn Rune (TWOW)
}

local PriorityTools = {
	[2901] = true, -- Mining Pick
	[5956] = true, -- Blacksmithing Hammer
	[6218] = true, -- Skinning Knife
	[7005] = true, -- Skinning Knife
	[11130] = true, -- Gnomish Army Knife
	[6365] = true, -- Strong Fishing Pole
	[6367] = true, -- Big Iron Fishing Pole
	[12225] = true, -- Blanched Needle
	[19022] = true, -- Nat Pagle's Extreme Angler
}

local PriorityKeys = {
	[12344] = true, -- Seal of Ascension
	[50545] = true, -- Gemstone of Ysera
	[16309] = true, -- Drakefire Amulet
	[9240] = true, -- Mallet of Zul'Farrak
	[22057] = true, -- Brazier of Invocation
	[61706] = true, -- Corrupt Dream Signet
	[18249] = true, -- Scepter of Celebras
	[7146] = true, -- Skeleton Key
	[10844] = true, -- Key to the City
	[11144] = true, -- Shadowforge Key
	[12324] = true, -- Workshop Key
}

-- --- [3] UTILITIES ---
local function Log(m)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00SB:|r " .. m)
	end
end

local function GetID(link)
	if not link or link == "" then
		return nil
	end
	local _, _, id = strfind(link, "item:(%d+)")
	return tonumber(id or 0)
end

function SB:ToggleEvents(state)
	local evs = {
		"BAG_UPDATE",
		"ITEM_LOCK_CHANGED",
		"BAG_UPDATE_COOLDOWN",
		"SPELLS_CHANGED",
		"UNIT_INVENTORY_CHANGED",
		"UNIT_MODEL_CHANGED",
	}
	local funcs = { "ContainerFrame_Update", "BankFrame_UpdateItems", "CharacterFrame_Update", "GameTooltip_OnEvent" }
	local frames = {
		_G.UIParent,
		_G.BankFrame,
		_G.CharacterFrame,
		_G.ItemRackFrame,
		_G.Bagnon,
		_G.OneBag,
		_G.Combuctor,
		_G.Telo,
	}
	-- Add pfUI specific containers if they exist
	if _G.pfUI then
		if _G.pfUI.container then
			tinsert(frames, _G.pfUI.container)
		end
		if _G.pfUI.bank then
			tinsert(frames, _G.pfUI.bank)
		end
	end

	for i = 1, 13 do
		local f = getglobal("ContainerFrame" .. i)
		if f then
			tinsert(frames, f)
		end
	end

	for _, frame in pairs(frames) do
		if frame and frame.UnregisterEvent then
			for _, ev in ipairs(evs) do
				if state then
					frame:RegisterEvent(ev)
				else
					frame:UnregisterEvent(ev)
				end
			end
		end
	end

	if not state then
		for _, name in ipairs(funcs) do
			if _G[name] and not self.OriginalFuncs[name] then
				self.OriginalFuncs[name] = _G[name]
				_G[name] = function() end
			end
		end
		_G.GameTooltip:Hide()
	else
		for _, name in ipairs(funcs) do
			if self.OriginalFuncs[name] then
				_G[name] = self.OriginalFuncs[name]
				self.OriginalFuncs[name] = nil
			end
		end
		if _G.ContainerFrame_Update then
			for i = 1, 13 do
				local f = getglobal("ContainerFrame" .. i)
				if f and f:IsShown() then
					_G.ContainerFrame_Update(f)
				end
			end
		end
	end
end

function SB:IdentifyBag(bagID)
	if bagID == 0 or bagID == -1 then
		return "Normal"
	end
	local invID = CIID(bagID)
	if not invID then
		return "Normal"
	end
	local ok, link = pcall(GIIL, "player", invID)
	if not ok or not link or link == "" then
		return "Normal"
	end
	local bid = GetID(link)
	-- Specialized Bag IDs (Vanilla)
	local SoulBags = { [21340] = true, [21341] = true, [21342] = true, [22243] = true, [11362] = true, [11363] = true }
	local HerbBags = { [13731] = true, [13732] = true, [22251] = true, [22252] = true }
	local EnchBags = { [14008] = true, [19143] = true, [22244] = true }

	if SoulBags[bid] then
		return "Soul"
	end
	if HerbBags[bid] then
		return "Herb"
	end
	if EnchBags[bid] then
		return "Ench"
	end

	local n, _, _, _, _, _, sub = GII(bid)
	if not n or not sub then
		return nil
	end
	local s = strlower(sub)
	if strfind(s, "soul") or strfind(s, "shard") then
		return "Soul"
	end
	if strfind(s, "herb") then
		return "Herb"
	end
	if strfind(s, "enchant") then
		return "Ench"
	end
	if strfind(s, "quiver") or strfind(s, "ammo") or strfind(s, "pouch") then
		return "Ammo"
	end
	return "Normal"
end

function SB:GetItemMeta(link, id, bag, slot)
	-- 1. Cache Check
	local cached = self.ItemCache[id]

	if not cached then
		local d1, d2, d3, d4, d5, d6, d7, d8, d9 = GII(id)
		if not d1 or not d6 or not d7 then
			return nil
		end
		local name, qual, iLvl, class, sub = d1, d3, d4, d6, d7
		local iSlot = ""
		-- d9 is itemEquipLoc token (e.g. "INVTYPE_HEAD")
		if d9 and strfind(d9, "INVTYPE_") then
			iSlot = d9
		elseif d8 and strfind(d8, "INVTYPE_") then
			iSlot = d8
		end

		local specID = 0
		if id == 6265 or strfind(strlower(name), "soul shard") then
			specID = 1
		elseif strfind(strlower(sub or ""), "herb") then
			specID = 2
		elseif strfind(strlower(sub or ""), "enchant") then
			specID = 3
		elseif class == self.L.Ammo or strfind(strlower(sub or ""), "ammo") then
			specID = 4
		end

		local cat = 7 -- Default: Misc
		if iSlot ~= "" and iSlot ~= "INVTYPE_NON_EQUIP" then
			cat = 3 -- Gear
		elseif
			class == self.L.Cons
			or class == self.L.Reag
			or strfind(strlower(sub or ""), "potion")
			or strfind(strlower(sub or ""), "scroll")
		then
			cat = 5 -- Consumables
		elseif class == self.L.Trade or qual > 0 then
			cat = 6 -- Trade Goods
		end

		-- Fallback: Force Armor/Weapon/Staves/etc to Gear category.
		local isArmor = (class == self.L.Armor or sub == self.L.Armor)
		local isWeapon = (class == self.L.Weapon or sub == self.L.Weapon)
		if (isArmor or isWeapon) and cat == 7 then
			cat = 3
		end

		-- Specialized Items (Mounts, Tools, Keys)
		if PriorityKeys[id] then
			cat = 2
			slotWeight = 0 -- Top of Cat 2
		elseif class == "Mount" or strfind(strlower(sub or ""), "mount") or PriorityTools[id] then
			cat = 2
		end

		if specID > 0 then
			cat = 8
		end

		if Teleports[id] then
			cat = 1
		end

		cached = {
			name = name,
			qual = qual,
			lvl = iLvl,
			class = class,
			sub = sub,
			slot = (self.SlotMap[iSlot] or 99),
			spec = specID,
			cat = cat,
			iSlot = iSlot,
			skip = false,
		}
		self.ItemCache[id] = cached
	end

	if cached.skip then
		return nil
	end

	-- 2. Dynamic Tooltip Scan (Soulbound/Quest state)
	local isSB, isQuest = false, (cached.class == self.L.Quest)

	self.Scanner:ClearLines()
	if bag == -1 then
		self.Scanner:SetInventoryItem("player", BBID(slot))
	else
		self.Scanner:SetBagItem(bag, slot)
	end

	if not self.ScannerLines then
		self.ScannerLines = {}
		for i = 1, 5 do
			self.ScannerLines[i] = getglobal("SortBagsScannerTextLeft" .. i)
		end
	end

	for i = 1, 5 do
		local t = self.ScannerLines[i]
		local txt = t and t:GetText()
		if txt then
			if txt == ITEM_SOULBOUND or txt == ITEM_BIND_ON_PICKUP then
				isSB = true
			elseif txt == ITEM_BIND_QUEST or (strfind(strlower(txt), "quest item")) then
				isQuest = true
			end
		end
	end

	local finalSlot = cached.slot
	local finalCat = cached.cat

	-- Tooltip Slot Detection Fallback (for items with missing equipLoc)
	if cached.iSlot == "" then
		for i = 2, 3 do
			local t = self.ScannerLines[i]
			local txt = t and t:GetText() or ""
			if self.SlotMap[txt] then
				finalSlot = self.SlotMap[txt]
				finalCat = 3 -- If it has a slot, it's Gear
				break
			end
		end
	end

	-- Final Prioritization & Protection
	if id == 6948 then -- Hearthstone ALWAYS first
		finalCat = 1
		finalSlot = -1
	elseif Teleports[id] then
		finalCat = 1
		finalSlot = 0
	elseif PriorityKeys[id] then
		finalCat = 2
		finalSlot = 1
	elseif isQuest then
		finalCat = 4
	elseif isSB and finalCat > 4 then
		-- Keep gear as Cat 3, but upgrade soulbound Misc to Cat 4
		if finalCat == 7 then
			finalCat = 4
		end
	end

	return {
		cat = finalCat,
		spec = cached.spec,
		slot = finalSlot,
		gearStatus = isSB and 0 or 1,
		qual = cached.qual,
		lvl = cached.lvl,
		id = id,
		name = cached.name,
		class = cached.class,
		sub = cached.sub,
	}
end

-- --- [4] CORE LOGIC ---
function SB:InitLocale()
	-- Probe IDs for localized class strings to ensure perfect matching
	local _, _, _, _, _, cCons = GII(117) -- Consumable (Tough Jerky)
	local _, _, _, _, _, cTrade = GII(2447) -- Trade Goods (Peacebloom)
	local _, _, _, _, _, cReag = GII(1708) -- Reagent (Sweet Nectar)
	local _, _, _, _, _, _, sMount = GII(13327) -- Subclass: Mount
	local _, _, _, _, _, cArmor = GII(52) -- Armor (Worn Vest)
	local _, _, _, _, _, cWeapon = GII(25) -- Weapon (Worn Shortsword)

	if cCons then
		self.L.Cons = cCons
	end
	if cTrade then
		self.L.Trade = cTrade
	end
	if cReag then
		self.L.Reag = cReag
	end
	if sMount then
		self.L.Mount = sMount
	end
	if cArmor then
		self.L.Armor = cArmor
	end
	if cWeapon then
		self.L.Weapon = cWeapon
	end

	-- Update SlotMap with localized strings from globals
	for token, weight in pairs(self.SlotMap) do
		local loc = _G[token]
		if loc and type(loc) == "string" then
			self.SlotMap[loc] = weight
		end
	end

	-- Check for Turtle WoW or standard localization overrides
	if _G.SortBags_Locale then
		for k, v in pairs(_G.SortBags_Locale) do
			self.L[k] = v
		end
	end
end

function SB:Plan(bags)
	-- Properly clear cache tables to prevent pollution from previous runs.
	-- In Lua 5.0, we must clear values AND reset the size counter (n).
	self.ItemCache = {} -- Force refresh of item meta to apply new categorization logic
	for _, v in pairs(self.Cache) do
		for k in pairs(v) do
			v[k] = nil
		end
		table.setn(v, 0)
	end
	local slots, items = self.Cache.slots, self.Cache.items
	local reality, ideal = self.Cache.reality, self.Cache.ideal

	local cacheReady = true
	for _, b in ipairs(bags) do
		local num = GNS(b)
		if num and num > 0 then
			local bType = self:IdentifyBag(b)
			if bType == nil then
				cacheReady = false
			end
			for s = 1, num do
				local slotAddr = b * 100 + s
				tinsert(slots, { b = b, s = s, type = bType or "Normal", addr = slotAddr })
				local slotIdx = table.getn(slots)

				local link = GCL(b, s)
				if link then
					local id = GetID(link)
					local meta = self:GetItemMeta(link, id, b, s)
					local isFrozen = _G.SortBags_IgnoreList[id]

					if isFrozen or not meta then
						-- Lock this slot: item stays here, and no one else can take it.
						local dummy = {
							meta = { name = "Frozen", cat = 999 },
							done = true,
							addr = slotAddr,
							cnt = 0,
						}
						ideal[slotIdx] = dummy
						reality[slotIdx] = dummy
					else
						local _, cnt = GCI(b, s)
						local it = {
							meta = meta,
							cnt = cnt,
							curr = slotIdx,
							addr = slotAddr,
						}
						tinsert(items, it)
						reality[slotIdx] = it
						if _G.SortBags_Debug then
							Log(
								format(
									"[Debug] %s | ID:%d | Class:%s | Slot:%d | Cat:%d",
									strsub(meta.name, 1, 15),
									id,
									meta.class,
									meta.slot,
									meta.cat
								)
							)
						end
					end
				end
			end
		end
	end
	if not cacheReady then
		return "RETRY"
	end

	sort(items, function(v1, v2)
		local ma, mb = v1.meta, v2.meta
		if ma.cat ~= mb.cat then
			return ma.cat < mb.cat
		end
		if ma.slot ~= mb.slot then
			return ma.slot < mb.slot
		end
		if ma.class ~= mb.class then
			return ma.class < mb.class
		end
		if ma.sub ~= mb.sub then
			return ma.sub < mb.sub
		end
		if ma.spec ~= mb.spec then
			return ma.spec < mb.spec
		end
		if ma.gearStatus ~= mb.gearStatus then
			return ma.gearStatus < mb.gearStatus
		end
		if ma.qual ~= mb.qual then
			return ma.qual > mb.qual
		end
		if ma.lvl ~= mb.lvl then
			return ma.lvl > mb.lvl
		end
		if ma.name ~= mb.name then
			return ma.name < mb.name
		end
		if v1.cnt ~= v2.cnt then
			return v1.cnt > v2.cnt
		end
		-- Ultimate Tie-breaker: original address
		if v1.addr ~= v2.addr then
			return v1.addr < v2.addr
		end
		return ma.id < mb.id
	end)

	-- Fill specialized bags first
	for i, s in ipairs(slots) do
		if not ideal[i] and s.type ~= "Normal" then
			for _, it in ipairs(items) do
				if not it.done then
					local specMap = { Soul = 1, Herb = 2, Ench = 3, Ammo = 4 }
					if it.meta.spec == specMap[s.type] then
						ideal[i], it.done = it, true
						break
					end
				end
			end
		end
	end

	-- Fill normal bags: 1. Overflow Special Items (Shards/Ammo that didn't fit)
	-- Fill BACKWARDS (from last slot to first) to keep them close to special bags
	for i = table.getn(slots), 1, -1 do
		local s = slots[i]
		if not ideal[i] and s.type == "Normal" then
			for _, it in ipairs(items) do
				if not it.done and it.meta.spec > 0 then
					ideal[i], it.done = it, true
					break
				end
			end
		end
	end

	-- Fill normal bags: 2. Regular Items
	for i, s in ipairs(slots) do
		if not ideal[i] and s.type == "Normal" then
			for _, it in ipairs(items) do
				if not it.done and it.meta.cat < 8 then
					ideal[i], it.done = it, true
					break
				end
			end
		end
	end

	-- Fill remaining (Misc/Junk)
	for i = table.getn(slots), 1, -1 do
		if not ideal[i] and slots[i].type == "Normal" then
			for _, it in ipairs(items) do
				if not it.done then -- Fill anything left
					ideal[i], it.done = it, true
					break
				end
			end
		end
	end

	local queue = {}
	local virtual = self.Cache.virtual
	for i = 1, table.getn(slots) do
		virtual[i] = reality[i]
	end

	-- 1. SMART SWAP (2-Cycle)
	for i = 1, table.getn(slots) do
		local targetI = ideal[i]
		local actualI = virtual[i]
		-- Skip if slot is empty or already correct
		local sameI = (targetI and actualI and targetI.meta.id == actualI.meta.id and targetI.cnt == actualI.cnt)
		if targetI and not sameI then
			for j = i + 1, table.getn(slots) do
				local actualJ = virtual[j]
				if actualJ and actualJ.meta.id == targetI.meta.id and actualJ.cnt == targetI.cnt then
					local targetJ = ideal[j]
					if targetJ and actualI and targetJ.meta.id == actualI.meta.id and targetJ.cnt == actualI.cnt then
						tinsert(queue, {
							src = slots[j],
							dst = slots[i],
							name = targetI.meta.name,
							id = targetI.meta.id,
							type = "SmartSwap",
							attempts = 0,
						})
						virtual[j], virtual[i] = virtual[i], virtual[j]
						break
					end
				end
			end
		end
	end

	-- 2. ENHANCED FILL (Cycle Following)
	-- Instead of shifting everything, try to find where the item in the current slot BELONGS.
	for i = 1, table.getn(slots) do
		local target, actual = ideal[i], virtual[i]
		local same = (target and actual and target.meta.id == actual.meta.id and target.cnt == actual.cnt)

		if target and not same then
			-- Slot i needs 'target'. Look for it.
			local found = false
			for j = i + 1, table.getn(slots) do
				local cand = virtual[j]
				if cand and cand.meta.id == target.meta.id and cand.cnt == target.cnt then
					-- Found the item we need at slot j.
					-- Check if slot j is already happy?
					local candIsHappy = (ideal[j] and ideal[j].meta.id == cand.meta.id and ideal[j].cnt == cand.cnt)
					if not candIsHappy then
						tinsert(queue, {
							src = slots[j],
							dst = slots[i],
							name = target.meta.name,
							id = target.meta.id,
							attempts = 0,
						})
						virtual[j], virtual[i] = virtual[i], virtual[j]
						found = true
						break
					end
				end
			end

			-- If not found in unhappy slots, we might need to take it from a happy one (rare)
			if not found then
				for j = 1, table.getn(slots) do
					local cand = virtual[j]
					if cand and cand.meta.id == target.meta.id and cand.cnt == target.cnt then
						tinsert(queue, {
							src = slots[j],
							dst = slots[i],
							name = target.meta.name,
							id = target.meta.id,
							attempts = 0,
						})
						virtual[j], virtual[i] = virtual[i], virtual[j]
						break
					end
				end
			end
		end
	end

	if _G.SortBags_Debug then
		Log(format("Plan: %d slots, %d items, %d moves.", table.getn(slots), table.getn(items), table.getn(queue)))
	end
	return queue
end

-- --- [5] EXECUTION ENGINE ---
local f = CreateFrame("Frame", "SortBags_Engine")
f:Hide()
f:RegisterEvent("BANKFRAME_CLOSED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:SetScript("OnEvent", function()
	SB:Stop()
	Log("Sort stopped (Safety Reset).")
end)

local waitTimer = 0
f:SetScript("OnUpdate", function()
	if waitTimer > GT() then
		return
	end
	if _G.CursorHasItem() then
		if SB.lastSrc then
		else
			local t = DMS()
			CC()
			SB.Stats.cleanup = SB.Stats.cleanup + (DMS() - t)
		end
		return
	end
	local step = SB.Queue[1]
	if not step then
		-- Settling phase: Wait for BAG_UPDATE to reflect reality
		local delay = (SB.TargetName == "Bank") and 0.6 or 0.3
		if not SB.Settling then
			SB.Settling = GT() + delay
			return
		elseif SB.Settling > GT() then
			return
		end
		SB.Settling = nil
		SB:FinalAudit()
		return
	end

	local moved, batchStart = 0, DMS()
	local isBank = (SB.TargetName == "Bank")
	-- Strict Burst: Bags 20 moves, Bank 1 move per cycle for stability.
	local limit = isBank and 1 or 20
	local frameBudget = 10 -- ms

	while table.getn(SB.Queue) > 0 and moved < limit do
		if _G.CursorHasItem() then
			if _G.SortBags_Debug then
				Log("Burst break: Cursor blocked.")
			end
			break
		end
		local s = SB.Queue[1]
		local _, _, l1 = GCI(s.src.b, s.src.s)
		local _, _, l2 = GCI(s.dst.b, s.dst.s)

		-- REQUEUE LOGIC: Smart Lookahead
		if l1 or l2 then
			local found = false
			local maxK = math.min(table.getn(SB.Queue), 20)
			for k = 2, maxK do
				local ns = SB.Queue[k]
				-- Check if candidate is unlocked
				local _, _, nl1 = GCI(ns.src.b, ns.src.s)
				local _, _, nl2 = GCI(ns.dst.b, ns.dst.s)
				-- Check for dependency conflict (ensure candidate doesn't touch current blocked slots)
				local conflict = (ns.src.addr == s.src.addr)
					or (ns.src.addr == s.dst.addr)
					or (ns.dst.addr == s.src.addr)
					or (ns.dst.addr == s.dst.addr)

				if not nl1 and not nl2 and not conflict then
					SB.Queue[1], SB.Queue[k] = SB.Queue[k], SB.Queue[1]
					s = SB.Queue[1] -- Update current step pointer
					found = true
					if _G.SortBags_Debug then
						Log("Lookahead: Swapped blocked #" .. 1 .. " with #" .. k)
					end
					break
				end
			end

			if not found then
				s.attempts = (s.attempts or 0) + 1
				if s.attempts > 10 then -- Hard limit for stuck slots
					tremove(SB.Queue, 1)
					Log("Skip Locked (Timeout): " .. s.name)
				else
					waitTimer = GT() + 0.1 -- Wait for lock to clear
				end
				break
			end
		end

		-- Sync Verify: Check ID match
		local link = GCL(s.src.b, s.src.s)
		if not link or GetID(link) ~= s.id then
			-- Logic Mismatch: The item is not where we thought it was.
			-- We cannot push to end, as that breaks chains. We must discard or fail.
			SB.Stats.retry = SB.Stats.retry + 1
			tremove(SB.Queue, 1) -- Discard this specific step to prevent chain corruption
			if _G.SortBags_Debug then
				Log("Sync Fail: Discarding " .. s.name .. " (Exp:" .. s.id .. ")")
			end
			-- Don't break, try next immediately
		else
			SB.lastSrc = s.src
			local t1 = DMS()
			PCI(s.src.b, s.src.s)
			local tPickup = DMS() - t1
			SB.Stats.pickup = SB.Stats.pickup + tPickup

			-- Pickup Success Check
			if _G.CursorHasItem() then
				local t2 = DMS()
				PCI(s.dst.b, s.dst.s)
				-- Swap completion check (Item swapped back to cursor?)
				if _G.CursorHasItem() then
					PCI(s.src.b, s.src.s) -- Put it back
				end
				local tDrop = DMS() - t2
				SB.Stats.drop = SB.Stats.drop + tDrop

				-- Move successful
				local tTotal = DMS() - t1
				SB.Stats.p1Total = SB.Stats.p1Total + tTotal
				tremove(SB.Queue, 1)
				SB.Stats.moves = SB.Stats.moves + 1
				moved = moved + 1

				if _G.SortBags_Debug then
					Log(format("[#%d] %s -> %d", SB.Stats.moves, strsub(s.name, 1, 10), s.dst.addr))
				end
			else
				-- Pickup Failed (Server lag/Busy)
				SB.lastSrc = nil
				s.attempts = (s.attempts or 0) + 1
				-- Retry in place
				if s.attempts >= 3 then
					tremove(SB.Queue, 1)
					Log("Skip Pickup Fail: " .. s.name)
				else
					SB.Stats.retry = SB.Stats.retry + 1
				end
				waitTimer = GT() + 0.2 -- Longer wait for server lag
				break
			end
		end

		if isBank then
			waitTimer = GT() + 0.05
			break
		end

		-- Check frame budget
		if (DMS() - batchStart) > frameBudget then
			break
		end
	end
end)

function SB:FinalAudit()
	local moves = SB.Stats.moves
	local p1Avg = moves > 0 and SB.Stats.p1Total / moves or 0
	local pickAvg = moves > 0 and SB.Stats.pickup / moves or 0
	local dropAvg = moves > 0 and SB.Stats.drop / moves or 0
	local cleanAvg = moves > 0 and SB.Stats.cleanup / moves or 0

	local _, _, lat = GetNetStats()
	local fps = GFR()

	if _G.SortBags_Debug then
		Log(
			format(
				SB.L.Finished .. " Retries:%d",
				moves,
				floor(DMS() - SB.Stats.start),
				p1Avg,
				fps,
				lat,
				pickAvg,
				dropAvg,
				cleanAvg,
				SB.Stats.retry or 0
			)
		)
	else
		Log(format("Done. Moves: %d", moves))
	end

	if _G.CursorHasItem() then
		if _G.SortBags_Debug then
			Log("|cffff0000Audit Blocked:|r Item on cursor. Clearing.")
		end
		local t = DMS()
		CC()
		SB.Stats.cleanup = SB.Stats.cleanup + (DMS() - t)
		waitTimer = GT() + 0.5
		return
	end

	local q = self:Plan(SB.Stats.lastBags)
	if q and type(q) == "table" and table.getn(q) > 0 then
		self.AuditRetry = (self.AuditRetry or 0) + 1

		-- Log first mismatch
		local m = q[1]
		if _G.SortBags_Debug then
			Log(format("Audit Mismatch: %s should be at %d, but found at %d", m.name, m.dst.addr, m.src.addr))
		end

		if self.AuditRetry <= 3 then
			local delay = (SB.TargetName == "Bank") and 1.2 or 0.6
			if _G.SortBags_Debug then
				Log("|cffff0000Audit Failed:|r Retrying #" .. self.AuditRetry)
			end
			waitTimer = GT() + delay
			if not self.AuditFrame then
				self.AuditFrame = CreateFrame("Frame")
			end
			self.AuditFrame:SetScript("OnUpdate", function()
				if waitTimer < GT() then
					this:SetScript("OnUpdate", nil)
					SB:Action(SB.Stats.lastBags, SB.TargetName, true)
				end
			end)
		else
			Log("|cffff0000Audit Aborted.|r Logic mismatch.")
			self:Stop()
		end
	else
		if _G.SortBags_Debug then
			Log("|cff00ff00Audit Passed.|r")
		end
		self:Stop()
	end
end

function SB:Action(bags, name, isRetry)
	if self.IsSorting and not isRetry then
		return
	end
	if not isRetry then
		self.AuditRetry = 0
	end
	self:InitLocale()
	if not isRetry and _G.SortBags_Debug then
		Log("Sorting " .. name .. "...")
	end
	self.Stats.start, self.Stats.moves, self.Stats.p1Total, self.Stats.p2Total = DMS(), 0, 0, 0
	self.Stats.pickup, self.Stats.drop, self.Stats.cleanup, self.Stats.retry = 0, 0, 0, 0
	self.Stats.lastBags = bags
	self.TargetName = name
	local q = self:Plan(bags)
	if q == "RETRY" then
		if not self.RetryFrame then
			self.RetryFrame = CreateFrame("Frame")
		end
		if _G.SortBags_Debug then
			Log("Warming cache...")
		end
		waitTimer = GT() + 0.5
		self.RetryFrame:SetScript("OnUpdate", function()
			if waitTimer < GT() then
				this:SetScript("OnUpdate", nil)
				SB:Action(bags, name, isRetry)
			end
		end)
		return
	end
	if q and table.getn(q) > 0 then
		self.Queue = q
		self.IsSorting = true
		self:ToggleEvents(false)
		f:Show()
	else
		Log(format(self.L.NoMoves, name))
		self:Stop()
	end
end

function SB:Dump()
	self:InitLocale()
	local bags = { 0, 1, 2, 3, 4 }
	local isBank = false
	if BankFrame and BankFrame:IsShown() then
		isBank = true
		tinsert(bags, -1)
		for i = 5, 10 do
			tinsert(bags, i)
		end
	end

	Log("--- SortBags Dump (" .. (isBank and "Bank Open" or "Bags Only") .. ") ---")
	for _, b in ipairs(bags) do
		local num = GNS(b)
		local bType = self:IdentifyBag(b) or "Unknown"
		if num then
			Log(format("Bag %d (%s, %d slots):", b, bType, num))
			for s = 1, num do
				local link = GCL(b, s)
				if link then
					local id = GetID(link)
					local meta = self:GetItemMeta(link, id, b, s)
					if meta then
						Log(
							format(
								"  [%d] %s | ID:%d C:%d | %s",
								s,
								strsub(meta.name, 1, 15),
								id,
								meta.cat,
								meta.class or "Misc"
							)
						)
					else
						Log(format("  [%d] %s (Meta Nil)", s, link))
					end
				end
			end
		end
	end
	Log("--- End Dump ---")
end

function SB:Stop()
	self:ToggleEvents(true)
	f:Hide()
	self.Queue, self.IsSorting, self.AuditRetry = {}, false, 0
end

function SortBags()
	SB:Action({ 0, 1, 2, 3, 4 }, "Bags")
end
function SortBankBags()
	SB:Action({ -1, 5, 6, 7, 8, 9, 10 }, "Bank")
end
_G.SortBags, _G.SortBankBags = SortBags, SortBankBags
SB.Scanner = _G.SortBagsScanner or CreateFrame("GameTooltip", "SortBagsScanner", nil, "GameTooltipTemplate")
SB.Scanner:SetOwner(UIParent, "ANCHOR_NONE")
local orig = ContainerFrameItemButton_OnClick
_G.ContainerFrameItemButton_OnClick = function(button, ignore)
	if IsAltKeyDown() then
		local bag, slot = this:GetParent():GetID(), this:GetID()
		local link = GCL(bag, slot)
		if link then
			local id = GetID(link)
			if SortBags_IgnoreList[id] then
				SortBags_IgnoreList[id] = nil
				Log(format(SB.L.Unfrozen, link))
			else
				SortBags_IgnoreList[id] = true
				Log(format(SB.L.Frozen, link))
			end
		end
	else
		orig(button, ignore)
	end
end
SLASH_SB1, SLASH_SB2 = "/sortbags", "/sb"
SlashCmdList["SB"] = function(msg)
	if msg == "bank" then
		SortBankBags()
	elseif msg == "stop" then
		SB:Stop()
		Log("Manual Stop.")
	elseif msg == "dump" then
		SB:Dump()
	elseif msg == "debug" then
		_G.SortBags_Debug = not _G.SortBags_Debug
		Log("Debug: " .. (_G.SortBags_Debug and "ON" or "OFF"))
	else
		SortBags()
	end
end
if _G.SortBags_Debug then
	Log("v21.3 MASTER Loaded.")
end
