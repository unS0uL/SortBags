-- SortBags: Localization Data (v21.3)
local _G = getfenv(0)

local Locales = {
	enUS = {
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
	deDE = {
		Armor = "Rüstung",
		Weapon = "Waffe",
		Cons = "Verbrauchbar",
		Reag = "Reagenz",
		Trade = "Handwerkswaren",
		Quest = "Quest",
		Ammo = "Projektil",
		SoulBag = "Seelentasche",
		HerbBag = "Kräutertasche",
		EnchBag = "Verzauberertasche",
		AmmoBag = "Köcher",
		Finished = "Fertig. Züge:%d Zeit:%dms (P1:%.1fms)\nFPS:%.0f Latenz:%dms",
		Waiting = "Warte auf Freigabe...",
		NoMoves = "%s bereits sortiert.",
		Frozen = "Eingefroren (Alt+Click): %s",
		Unfrozen = "Aufgetaut: %s",
	},
	esES = {
		Armor = "Armadura",
		Weapon = "Arma",
		Cons = "Consumible",
		Reag = "Componente",
		Trade = "Comercio",
		Quest = "Misión",
		Ammo = "Proyectil",
		SoulBag = "Bolsa de Almas",
		HerbBag = "Bolsa de Hierbas",
		EnchBag = "Bolsa de Encantamiento",
		AmmoBag = "Carcaj",
		Finished = "Listo. Movimientos:%d Tiempo:%dms (P1:%.1fms)\nFPS:%.0f Latencia:%dms",
		Waiting = "Esperando desbloqueo...",
		NoMoves = "%s ya ordenado.",
		Frozen = "Congelado (Alt+Click): %s",
		Unfrozen = "Descongelado: %s",
	},
	zhCN = {
		Armor = "护甲",
		Weapon = "武器",
		Cons = "消耗品",
		Reag = "材料",
		Trade = "商品",
		Quest = "任务",
		Ammo = "弹药",
		SoulBag = "灵魂袋",
		HerbBag = "草药袋",
		EnchBag = "附魔袋",
		AmmoBag = "箭袋",
		Finished = "完成。移动:%d 时间:%dms (P1:%.1fms)\nFPS:%.0f 延迟:%dms",
		Waiting = "等待物品解锁...",
		NoMoves = "%s 已整理。",
		Frozen = "锁定 (Alt+Click): %s",
		Unfrozen = "解锁: %s",
	},
	ukUA = {
		Armor = "Обладунки",
		Weapon = "Зброя",
		Cons = "Витратні",
		Reag = "Реагенти",
		Trade = "Товари",
		Quest = "Квест",
		Ammo = "Боєприпаси",
		SoulBag = "Сумка душ",
		HerbBag = "Сумка трав",
		EnchBag = "Сумка зачарування",
		AmmoBag = "Сагайдак",
		Finished = "Готово. Рухів:%d Час:%dмс (P1:%.1fмс)\nFPS:%.0f Пінг:%dмс",
		Waiting = "Очікування розблокування...",
		NoMoves = "%s вже відсортовано.",
		Frozen = "Заморожено (Alt+Click): %s",
		Unfrozen = "Розморожено: %s",
	},
}

-- Turtle WoW Logic: Uses standard GetLocale() but allows manual override if needed
local L = Locales[GetLocale()] or Locales.enUS

-- If on Turtle WoW with Cyrillic patch, we might detect ukUA/ruRU specifically
if GetLocale() == "ruRU" then 
	-- Fallback for RU client if not specifically translated (using UA as closest Cyrillic or EN)
	-- Ideally add ruRU block above. For now, let's assume default EN or partial RU if available.
end

_G.SortBags_Locale = L
