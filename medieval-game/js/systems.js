/**
 * Inventory, crafting, and item systems.
 * All item names include Irish (Gaeilge) translations.
 */

// ─── Item Database ────────────────────────────────────────
export const ITEMS = {
  // Resources
  wood:       { name: 'Adhmad', nameEn: 'Wood', weight: 2, stack: 50, type: 'resource', icon: '🪵' },
  stone:      { name: 'Cloch', nameEn: 'Stone', weight: 3, stack: 50, type: 'resource', icon: '🪨' },
  flint:      { name: 'Breochloch', nameEn: 'Flint', weight: 0.5, stack: 20, type: 'resource', icon: '🔶' },
  leather:    { name: 'Leathar', nameEn: 'Leather', weight: 1, stack: 20, type: 'resource', icon: '🟤' },
  iron:       { name: 'Iarann', nameEn: 'Iron Ore', weight: 4, stack: 30, type: 'resource', icon: '⛏️' },
  bronze:     { name: 'Cré-umha', nameEn: 'Bronze', weight: 3.5, stack: 30, type: 'resource', icon: '🟠' },
  wool:       { name: 'Olann', nameEn: 'Wool', weight: 0.5, stack: 30, type: 'resource', icon: '🐑' },
  flax:       { name: 'Líon', nameEn: 'Flax', weight: 0.3, stack: 30, type: 'resource', icon: '🌾' },
  thatch:     { name: 'Tuí', nameEn: 'Thatch', weight: 1, stack: 50, type: 'resource', icon: '🌿' },
  clay:       { name: 'Cré', nameEn: 'Clay', weight: 2, stack: 30, type: 'resource', icon: '🏺' },
  bone:       { name: 'Cnámh', nameEn: 'Bone', weight: 1, stack: 20, type: 'resource', icon: '🦴' },
  feather:    { name: 'Cleite', nameEn: 'Feather', weight: 0.1, stack: 50, type: 'resource', icon: '🪶' },
  resin:      { name: 'Roisín', nameEn: 'Resin', weight: 0.5, stack: 20, type: 'resource', icon: '🫗' },

  // Food
  berries:      { name: 'Sméara', nameEn: 'Berries', weight: 0.2, stack: 50, type: 'food', icon: '🫐', hp: 5, stam: 10, hunger: 10, dur: 180 },
  mushroom:     { name: 'Beacán', nameEn: 'Mushroom', weight: 0.2, stack: 50, type: 'food', icon: '🍄', hp: 8, stam: 5, hunger: 8, dur: 150 },
  honey:        { name: 'Mil', nameEn: 'Honey', weight: 0.5, stack: 10, type: 'food', icon: '🍯', hp: 12, stam: 15, hunger: 15, dur: 300 },
  deer_meat:    { name: 'Feoil Fia', nameEn: 'Venison (raw)', weight: 1.5, stack: 20, type: 'food_raw', icon: '🥩' },
  fish:         { name: 'Iasc', nameEn: 'Fish (raw)', weight: 1, stack: 20, type: 'food_raw', icon: '🐟' },
  cooked_meat:  { name: 'Feoil Bruite', nameEn: 'Cooked Meat', weight: 1, stack: 20, type: 'food', icon: '🍖', hp: 25, stam: 15, hunger: 35, dur: 480 },
  cooked_fish:  { name: 'Iasc Bruite', nameEn: 'Cooked Fish', weight: 0.8, stack: 20, type: 'food', icon: '🍽️', hp: 20, stam: 25, hunger: 30, dur: 420 },
  bread:        { name: 'Arán', nameEn: 'Bread', weight: 0.5, stack: 20, type: 'food', icon: '🍞', hp: 15, stam: 20, hunger: 30, dur: 360 },
  mead:         { name: 'Miodh', nameEn: 'Mead', weight: 1, stack: 10, type: 'food', icon: '🍺', hp: 20, stam: 30, hunger: 10, dur: 600 },

  // Tools
  stone_axe:     { name: 'Tua Chloiche', nameEn: 'Stone Axe', weight: 3, stack: 1, type: 'tool', icon: '🪓', toolType: 'axe', damage: 8 },
  bronze_axe:    { name: 'Tua Chré-umha', nameEn: 'Bronze Axe', weight: 3.5, stack: 1, type: 'tool', icon: '🪓', toolType: 'axe', damage: 15 },
  iron_axe:      { name: 'Tua Iarainn', nameEn: 'Iron Axe', weight: 4, stack: 1, type: 'tool', icon: '🪓', toolType: 'axe', damage: 25 },
  stone_pickaxe: { name: 'Piocóid', nameEn: 'Stone Pickaxe', weight: 3, stack: 1, type: 'tool', icon: '⛏️', toolType: 'pickaxe', damage: 8 },
  fishing_rod:   { name: 'Slat Iascaireachta', nameEn: 'Fishing Rod', weight: 1.5, stack: 1, type: 'tool', icon: '🎣', toolType: 'fishing' },
  hammer:        { name: 'Casúr', nameEn: 'Hammer', weight: 2.5, stack: 1, type: 'tool', icon: '🔨', toolType: 'hammer' },

  // Weapons
  club:          { name: 'Smiste', nameEn: 'Club', weight: 2, stack: 1, type: 'weapon', icon: '🏏', damage: 10 },
  bronze_sword:  { name: 'Claidheamh Cré-umha', nameEn: 'Bronze Sword', weight: 3, stack: 1, type: 'weapon', icon: '⚔️', damage: 20 },
  iron_sword:    { name: 'Claidheamh Iarainn', nameEn: 'Iron Sword', weight: 3.5, stack: 1, type: 'weapon', icon: '⚔️', damage: 35 },
  spear:         { name: 'Sleagh', nameEn: 'Spear', weight: 2.5, stack: 1, type: 'weapon', icon: '🔱', damage: 25 },
  bow:           { name: 'Bogha', nameEn: 'Bow', weight: 2, stack: 1, type: 'weapon', icon: '🏹', damage: 15 },
  arrow:         { name: 'Saighead', nameEn: 'Arrow', weight: 0.1, stack: 100, type: 'ammo', icon: '➡️' },
  wooden_shield: { name: 'Sciath Adhmaid', nameEn: 'Wooden Shield', weight: 4, stack: 1, type: 'shield', icon: '🛡️', block: 20 },

  // Armor
  leather_helm:  { name: 'Clogad Leathair', nameEn: 'Leather Helm', weight: 1.5, stack: 1, type: 'armor', icon: '⛑️', armor: 5 },
  leather_chest: { name: 'Luíreach Leathair', nameEn: 'Leather Armor', weight: 5, stack: 1, type: 'armor', icon: '🦺', armor: 10 },
  wool_cape:     { name: 'Brat Olna', nameEn: 'Wool Cape', weight: 1, stack: 1, type: 'armor', icon: '🧣', armor: 2 },

  // Building
  wattle_wall:  { name: 'Balla Caolach', nameEn: 'Wattle Wall', weight: 5, stack: 10, type: 'building', icon: '🧱' },
  thatch_roof:  { name: 'Díon Tuí', nameEn: 'Thatch Roof', weight: 3, stack: 10, type: 'building', icon: '🏠' },
  wooden_floor: { name: 'Urlár Adhmaid', nameEn: 'Wooden Floor', weight: 4, stack: 10, type: 'building', icon: '🪵' },
  wooden_door:  { name: 'Doras Adhmaid', nameEn: 'Wooden Door', weight: 6, stack: 5, type: 'building', icon: '🚪' },
  fire_pit:     { name: 'Tine', nameEn: 'Fire Pit', weight: 8, stack: 1, type: 'building', icon: '🔥' },
  workbench:    { name: 'Binse Oibre', nameEn: 'Workbench', weight: 10, stack: 1, type: 'building', icon: '🪑' },
  forge:        { name: 'Ceárta', nameEn: 'Forge', weight: 20, stack: 1, type: 'building', icon: '🏭' },
  bed:          { name: 'Leaba', nameEn: 'Bed', weight: 8, stack: 1, type: 'building', icon: '🛏️' },
};

// ─── Crafting Recipes ─────────────────────────────────────
export const RECIPES = {
  // No station
  stone_axe:      { ingredients: { wood: 5, stone: 4 }, station: null, count: 1, cat: 'tools', desc: 'A basic stone axe for felling trees.' },
  stone_pickaxe:  { ingredients: { wood: 5, stone: 6 }, station: null, count: 1, cat: 'tools', desc: 'A stone pickaxe for mining.' },
  club:           { ingredients: { wood: 6 }, station: null, count: 1, cat: 'weapons', desc: 'A crude wooden club.' },
  hammer:         { ingredients: { wood: 3, stone: 2 }, station: null, count: 1, cat: 'tools', desc: 'A hammer for building structures.' },
  fire_pit:       { ingredients: { stone: 5, wood: 2 }, station: null, count: 1, cat: 'building', desc: 'A stone fire pit for cooking.' },
  workbench:      { ingredients: { wood: 10 }, station: null, count: 1, cat: 'building', desc: 'A workbench for crafting.' },

  // Fire pit
  cooked_meat:    { ingredients: { deer_meat: 1 }, station: 'fire', count: 1, cat: 'food', desc: 'Roasted venison.' },
  cooked_fish:    { ingredients: { fish: 1 }, station: 'fire', count: 1, cat: 'food', desc: 'Grilled fish.' },
  bread:          { ingredients: { flax: 4 }, station: 'fire', count: 2, cat: 'food', desc: 'Simple flatbread.' },
  mead:           { ingredients: { honey: 3 }, station: 'fire', count: 1, cat: 'food', desc: 'A potent drink of fermented honey.' },

  // Workbench
  wooden_shield:  { ingredients: { wood: 10, leather: 4, resin: 2 }, station: 'workbench', count: 1, cat: 'weapons', desc: 'A round wooden shield.' },
  spear:          { ingredients: { wood: 5, flint: 3 }, station: 'workbench', count: 1, cat: 'weapons', desc: 'A flint-tipped spear.' },
  bow:            { ingredients: { wood: 8, leather: 2 }, station: 'workbench', count: 1, cat: 'weapons', desc: 'A simple hunting bow.' },
  arrow:          { ingredients: { wood: 2, feather: 1, flint: 1 }, station: 'workbench', count: 10, cat: 'weapons', desc: 'Flint-tipped arrows.' },
  fishing_rod:    { ingredients: { wood: 4, leather: 2 }, station: 'workbench', count: 1, cat: 'tools', desc: 'For fishing in Lough Key.' },
  leather_helm:   { ingredients: { leather: 6 }, station: 'workbench', count: 1, cat: 'armor', desc: 'A hardened leather cap.' },
  leather_chest:  { ingredients: { leather: 10, bone: 4 }, station: 'workbench', count: 1, cat: 'armor', desc: 'Leather armor with bone reinforcement.' },
  wool_cape:      { ingredients: { wool: 8 }, station: 'workbench', count: 1, cat: 'armor', desc: 'A warm woolen brat (cloak).' },
  wattle_wall:    { ingredients: { wood: 4 }, station: 'workbench', count: 2, cat: 'building', desc: 'Wattle wall section.' },
  thatch_roof:    { ingredients: { thatch: 4, wood: 2 }, station: 'workbench', count: 2, cat: 'building', desc: 'Thatched roof section.' },
  wooden_floor:   { ingredients: { wood: 6 }, station: 'workbench', count: 2, cat: 'building', desc: 'Wooden floor section.' },
  wooden_door:    { ingredients: { wood: 8 }, station: 'workbench', count: 1, cat: 'building', desc: 'A wooden door.' },
  bed:            { ingredients: { wood: 8, wool: 4, leather: 2 }, station: 'workbench', count: 1, cat: 'building', desc: 'A bed for resting.' },

  // Forge
  bronze_axe:     { ingredients: { bronze: 8, wood: 4 }, station: 'forge', count: 1, cat: 'tools', desc: 'A bronze-headed axe.' },
  bronze_sword:   { ingredients: { bronze: 12, wood: 4, leather: 2 }, station: 'forge', count: 1, cat: 'weapons', desc: 'A bronze sword.' },
  iron_axe:       { ingredients: { iron: 10, wood: 4 }, station: 'forge', count: 1, cat: 'tools', desc: 'A sturdy iron axe.' },
  iron_sword:     { ingredients: { iron: 15, wood: 4, leather: 3 }, station: 'forge', count: 1, cat: 'weapons', desc: 'A fine iron sword.' },
  forge:          { ingredients: { stone: 20, wood: 5, clay: 10 }, station: 'workbench', count: 1, cat: 'building', desc: 'A forge for metalworking.' },
};

// ─── Inventory ────────────────────────────────────────────
export const inventory = {};   // { itemId: count }
const MAX_WEIGHT = 300;

export function addItem(itemId, count = 1) {
  if (!ITEMS[itemId]) return false;
  inventory[itemId] = (inventory[itemId] || 0) + count;
  return true;
}

export function removeItem(itemId, count = 1) {
  if (!inventory[itemId] || inventory[itemId] < count) return false;
  inventory[itemId] -= count;
  if (inventory[itemId] <= 0) delete inventory[itemId];
  return true;
}

export function hasItem(itemId, count = 1) {
  return (inventory[itemId] || 0) >= count;
}

export function getItemCount(itemId) {
  return inventory[itemId] || 0;
}

export function getWeight() {
  let w = 0;
  for (const [id, count] of Object.entries(inventory)) {
    if (ITEMS[id]) w += ITEMS[id].weight * count;
  }
  return w;
}

export function getMaxWeight() { return MAX_WEIGHT; }

// ─── Crafting ─────────────────────────────────────────────
export function canCraft(recipeId) {
  const recipe = RECIPES[recipeId];
  if (!recipe) return false;
  for (const [itemId, needed] of Object.entries(recipe.ingredients)) {
    if (!hasItem(itemId, needed)) return false;
  }
  return true;
}

export function craftItem(recipeId) {
  if (!canCraft(recipeId)) return false;
  const recipe = RECIPES[recipeId];
  for (const [itemId, needed] of Object.entries(recipe.ingredients)) {
    removeItem(itemId, needed);
  }
  addItem(recipeId, recipe.count);
  return true;
}

export function getRecipes() { return RECIPES; }
export function getItems() { return ITEMS; }
