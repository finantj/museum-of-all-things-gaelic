/**
 * UI management — HUD updates, inventory panel, crafting panel, minimap.
 */
import { playerState } from './player.js';
import { inventory, ITEMS, RECIPES, canCraft, craftItem, getWeight, getMaxWeight } from './systems.js';
import { getTerrainHeight } from './world.js';
import { getPlayerPosition } from './player.js';

let notificationTimer = 0;
let dialogueTimer = 0;
let minimapCtx;
let gameState;

// ─── Initialization ───────────────────────────────────────
export function initUI(state) {
  gameState = state;

  // Minimap
  const canvas = document.getElementById('minimap-canvas');
  minimapCtx = canvas.getContext('2d');
  drawMinimapBase();

  // Crafting categories
  document.querySelectorAll('.craft-cat').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.craft-cat').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      populateCraftingList(btn.dataset.cat);
    });
  });

  // Craft button
  document.getElementById('craft-button').addEventListener('click', () => {
    const selected = document.querySelector('.craft-item.selected');
    if (selected) {
      const id = selected.dataset.recipe;
      if (craftItem(id)) {
        const item = ITEMS[id];
        showNotification(`Crafted: ${item ? item.nameEn : id}`);
        populateCraftingList(document.querySelector('.craft-cat.active')?.dataset.cat || 'all');
        showCraftDetail(id);
        refreshInventoryGrid();
      }
    }
  });
}

// ─── HUD Update (called every frame) ─────────────────────
export function updateUI(state) {
  // Stat bars
  updateBar('health', playerState.health, playerState.maxHealth);
  updateBar('stamina', playerState.stamina, playerState.maxStamina);
  updateBar('hunger', playerState.hunger, playerState.maxHunger);

  // Day/time
  const hour = Math.floor(state.gameTime);
  const min = Math.floor((state.gameTime - hour) * 60);
  let period;
  if (state.gameTime < 5.5) period = 'Night';
  else if (state.gameTime < 7) period = 'Dawn';
  else if (state.gameTime < 18.5) period = 'Day';
  else if (state.gameTime < 20.5) period = 'Dusk';
  else period = 'Night';
  document.getElementById('day-time').textContent =
    `Moylurg — ${String(hour).padStart(2, '0')}:${String(min).padStart(2, '0')} — ${period}`;

  // Notification fade
  if (notificationTimer > 0) {
    notificationTimer -= 0.016;
    if (notificationTimer <= 0) {
      document.getElementById('notification').classList.remove('show');
    }
  }

  // Dialogue fade
  if (dialogueTimer > 0) {
    dialogueTimer -= 0.016;
    if (dialogueTimer <= 0) {
      document.getElementById('dialogue-box').style.display = 'none';
    }
  }

  // Interaction prompt
  updateInteractPrompt();

  // Minimap player marker
  updateMinimap();
}

function updateBar(name, current, max) {
  const bar = document.getElementById(name + '-bar');
  const val = document.getElementById(name + '-value');
  if (bar) bar.style.width = (current / max * 100) + '%';
  if (val) val.textContent = `${Math.ceil(current)}/${Math.ceil(max)}`;
}

// ─── Notifications ────────────────────────────────────────
export function showNotification(text, duration = 3) {
  const el = document.getElementById('notification');
  el.textContent = text;
  el.classList.add('show');
  notificationTimer = duration;
}

// ─── Dialogue ─────────────────────────────────────────────
export function showDialogue(name, title, text) {
  const box = document.getElementById('dialogue-box');
  document.getElementById('dialogue-name').textContent = `${name} — ${title}`;
  document.getElementById('dialogue-text').textContent = text;
  box.style.display = 'block';
  dialogueTimer = 6;
}

export function hideDialogue() {
  document.getElementById('dialogue-box').style.display = 'none';
  dialogueTimer = 0;
}

// ─── Interaction Prompt ───────────────────────────────────
function updateInteractPrompt() {
  const el = document.getElementById('interact-prompt');
  // Simple distance-based check could go here
  // For now, just clear it
}

// ─── Inventory Grid ───────────────────────────────────────
export function refreshInventoryGrid() {
  const grid = document.getElementById('inventory-grid');
  grid.innerHTML = '';

  // Fill with items
  const entries = Object.entries(inventory);
  for (const [itemId, count] of entries) {
    const item = ITEMS[itemId];
    if (!item || count <= 0) continue;

    const slot = document.createElement('div');
    slot.className = 'inv-slot';
    slot.title = `${item.nameEn} (${item.name})`;
    slot.innerHTML = `
      <span class="item-icon">${item.icon}</span>
      <span class="item-count">${count > 1 ? count : ''}</span>
    `;

    // Click to use food
    if (item.type === 'food') {
      slot.style.cursor = 'pointer';
      slot.addEventListener('click', () => {
        eatFood(itemId);
        refreshInventoryGrid();
      });
    }

    grid.appendChild(slot);
  }

  // Fill remaining slots to 32
  const remaining = 32 - entries.filter(([id, c]) => c > 0 && ITEMS[id]).length;
  for (let i = 0; i < remaining; i++) {
    const slot = document.createElement('div');
    slot.className = 'inv-slot';
    grid.appendChild(slot);
  }

  // Weight
  document.getElementById('inventory-weight').textContent =
    `Weight: ${Math.round(getWeight())} / ${getMaxWeight()}`;
}

function eatFood(itemId) {
  const item = ITEMS[itemId];
  if (!item || item.type !== 'food') return;
  if (!inventory[itemId] || inventory[itemId] <= 0) return;

  inventory[itemId]--;
  if (inventory[itemId] <= 0) delete inventory[itemId];

  playerState.maxHealth = Math.min(150, playerState.maxHealth + (item.hp || 0));
  playerState.health = Math.min(playerState.maxHealth, playerState.health + (item.hp || 0) * 0.5);
  playerState.maxStamina = Math.min(200, playerState.maxStamina + (item.stam || 0));
  playerState.stamina = Math.min(playerState.maxStamina, playerState.stamina + (item.stam || 0) * 0.5);
  playerState.hunger = Math.min(playerState.maxHunger, playerState.hunger + (item.hunger || 0));

  showNotification(`Ate ${item.nameEn}`);
}

// ─── Crafting Panel ───────────────────────────────────────
export function populateCraftingList(category) {
  const list = document.getElementById('crafting-list');
  list.innerHTML = '';

  for (const [id, recipe] of Object.entries(RECIPES)) {
    if (category !== 'all' && recipe.cat !== category) continue;

    const item = ITEMS[id];
    if (!item) continue;

    const el = document.createElement('div');
    el.className = 'craft-item' + (canCraft(id) ? '' : ' unavailable');
    el.dataset.recipe = id;
    el.innerHTML = `
      <div>${item.icon} ${item.nameEn}</div>
      <div class="craft-item-irish">${item.name}</div>
    `;
    el.addEventListener('click', () => {
      document.querySelectorAll('.craft-item').forEach(e => e.classList.remove('selected'));
      el.classList.add('selected');
      showCraftDetail(id);
    });
    list.appendChild(el);
  }
}

function showCraftDetail(recipeId) {
  const recipe = RECIPES[recipeId];
  const item = ITEMS[recipeId];
  if (!recipe || !item) return;

  document.getElementById('craft-name').textContent = `${item.icon} ${item.nameEn} — ${item.name}`;
  document.getElementById('craft-desc').textContent = recipe.desc;

  // Ingredients
  const ingEl = document.getElementById('craft-ingredients');
  ingEl.innerHTML = '';
  for (const [ingId, needed] of Object.entries(recipe.ingredients)) {
    const ing = ITEMS[ingId];
    const have = inventory[ingId] || 0;
    const cls = have >= needed ? 'has-item' : 'missing-item';
    const span = document.createElement('span');
    span.className = cls;
    span.textContent = `${ing ? ing.nameEn : ingId}: ${have}/${needed}  `;
    ingEl.appendChild(span);
  }

  if (recipe.station) {
    const stationNote = document.createElement('div');
    stationNote.style.color = '#6a5530';
    stationNote.style.marginTop = '4px';
    stationNote.textContent = `Requires: ${recipe.station}`;
    ingEl.appendChild(stationNote);
  }

  document.getElementById('craft-button').disabled = !canCraft(recipeId);
}

// Listen for inventory/crafting panel visibility to refresh
const observer = new MutationObserver((mutations) => {
  for (const m of mutations) {
    if (m.attributeName === 'style') {
      const el = m.target;
      if (el.id === 'inventory-panel' && el.style.display !== 'none') {
        refreshInventoryGrid();
      }
      if (el.id === 'crafting-panel' && el.style.display !== 'none') {
        populateCraftingList('all');
        document.querySelectorAll('.craft-cat').forEach(b => b.classList.remove('active'));
        document.querySelector('.craft-cat[data-cat="all"]')?.classList.add('active');
      }
    }
  }
});

// Start observing after DOM is ready
setTimeout(() => {
  const invPanel = document.getElementById('inventory-panel');
  const craftPanel = document.getElementById('crafting-panel');
  if (invPanel) observer.observe(invPanel, { attributes: true });
  if (craftPanel) observer.observe(craftPanel, { attributes: true });
}, 100);

// ─── Minimap ──────────────────────────────────────────────
function drawMinimapBase() {
  if (!minimapCtx) return;
  const size = 160;
  const scale = size / 256;

  // Draw terrain colors
  for (let z = 0; z < size; z++) {
    for (let x = 0; x < size; x++) {
      const wx = x / scale;
      const wz = z / scale;
      const h = getTerrainHeight(wx, wz);

      let r, g, b;
      if (h < -0.5) { r = 15; g = 40; b = 30; }       // Deep water
      else if (h < 0.3) { r = 25; g = 60; b = 50; }    // Shallow water
      else if (h < 2) { r = 50; g = 100; b = 40; }     // Grass
      else if (h < 8) { r = 40; g = 80; b = 30; }      // Forest
      else { r = 70; g = 65; b = 55; }                   // Hills

      minimapCtx.fillStyle = `rgb(${r},${g},${b})`;
      minimapCtx.fillRect(x, z, 1, 1);
    }
  }

  // Mark key locations
  const markSize = 3;
  const marks = [
    { x: 95, z: 105, color: '#c42020', label: 'Castle' },
    { x: 88, z: 92, color: '#c9a84c', label: 'Monastery' },
    { x: 140, z: 100, color: '#80a060', label: 'Village' },
  ];

  for (const m of marks) {
    minimapCtx.fillStyle = m.color;
    minimapCtx.fillRect(m.x * scale - markSize/2, m.z * scale - markSize/2, markSize, markSize);
  }
}

function updateMinimap() {
  if (!minimapCtx) return;

  // Redraw base (could be optimized with caching)
  drawMinimapBase();

  // Player position
  const pos = getPlayerPosition();
  const scale = 160 / 256;
  const px = pos.x * scale;
  const pz = pos.z * scale;

  minimapCtx.fillStyle = '#ffffff';
  minimapCtx.beginPath();
  minimapCtx.arc(px, pz, 3, 0, Math.PI * 2);
  minimapCtx.fill();

  // Facing direction
  minimapCtx.strokeStyle = '#ffffff';
  minimapCtx.lineWidth = 1.5;
  minimapCtx.beginPath();
  minimapCtx.moveTo(px, pz);
  minimapCtx.lineTo(px + playerState.facing.x * 6, pz + playerState.facing.z * 6);
  minimapCtx.stroke();
}
