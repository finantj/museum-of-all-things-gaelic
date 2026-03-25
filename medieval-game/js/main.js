/**
 * Loch Cé — A Valheim-inspired survival game set in 13th century County Roscommon.
 * Centered on Lough Key and the MacDermot lordship of Moylurg.
 */
import * as THREE from 'three';
import { createTerrain, getTerrainHeight } from './world.js';
import { createWater, updateWater } from './water.js';
import { createSky, updateSky } from './sky.js';
import { spawnVegetation } from './vegetation.js';
import { buildStructures } from './structures.js';
import { spawnResources, updateResources, hitResource } from './resources.js';
import { createPlayer, updatePlayer, getPlayerPosition, playerState } from './player.js';
import { spawnNPCs, updateNPCs, getNearbyNPC } from './npcs.js';
import { initUI, updateUI, showNotification, showDialogue, hideDialogue } from './ui.js';
import { inventory, addItem, craftItem, getRecipes, canCraft } from './systems.js';

// ─── Game State ───────────────────────────────────────────
const state = {
  clock: new THREE.Clock(),
  gameTime: 8.0,        // Start at 8 AM
  dayLengthSec: 1200,   // 20 real minutes per game day
  paused: false,
  started: false,
  scene: null,
  camera: null,
  renderer: null,
};

// Expose for other modules
export { state, getTerrainHeight };

// ─── Initialization ───────────────────────────────────────
async function init() {
  updateLoadingBar(5, 'Initializing renderer...');

  // Renderer
  state.renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
  state.renderer.setSize(window.innerWidth, window.innerHeight);
  state.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  state.renderer.shadowMap.enabled = true;
  state.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  state.renderer.toneMapping = THREE.ACESFilmicToneMapping;
  state.renderer.toneMappingExposure = 1.0;
  state.renderer.outputColorSpace = THREE.SRGBColorSpace;
  document.body.prepend(state.renderer.domElement);

  // Scene
  state.scene = new THREE.Scene();
  state.scene.fog = new THREE.FogExp2(0x8a9a8a, 0.004);

  // Camera
  state.camera = new THREE.PerspectiveCamera(65, window.innerWidth / window.innerHeight, 0.1, 600);

  // Resize handling
  window.addEventListener('resize', () => {
    state.camera.aspect = window.innerWidth / window.innerHeight;
    state.camera.updateProjectionMatrix();
    state.renderer.setSize(window.innerWidth, window.innerHeight);
  });

  // Build world
  updateLoadingBar(15, 'Generating terrain...');
  await delay(50);
  createTerrain(state.scene);

  updateLoadingBar(30, 'Filling Lough Key...');
  await delay(50);
  createWater(state.scene);

  updateLoadingBar(40, 'Painting the sky...');
  await delay(50);
  createSky(state.scene);

  updateLoadingBar(50, 'Growing forests of Moylurg...');
  await delay(50);
  spawnVegetation(state.scene);

  updateLoadingBar(60, 'Building castles and monasteries...');
  await delay(50);
  buildStructures(state.scene);

  updateLoadingBar(70, 'Scattering resources...');
  await delay(50);
  spawnResources(state.scene);

  updateLoadingBar(80, 'Summoning the MacDermot clan...');
  await delay(50);
  spawnNPCs(state.scene);

  updateLoadingBar(90, 'Preparing the player...');
  await delay(50);
  createPlayer(state.scene, state.camera);

  // Give the player some starter items
  addItem('wood', 5);
  addItem('stone', 3);
  addItem('berries', 5);

  updateLoadingBar(95, 'Setting up interface...');
  await delay(50);
  initUI(state);

  updateLoadingBar(100, 'Ready.');
  await delay(300);

  // Show start screen
  document.getElementById('loading-screen').style.display = 'none';
  document.getElementById('start-screen').style.display = 'flex';

  // Start button
  document.getElementById('start-button').addEventListener('click', () => {
    document.getElementById('start-screen').style.display = 'none';
    document.getElementById('hud').style.display = 'block';
    document.body.requestPointerLock();
    state.started = true;
    showNotification('Welcome to Moylurg. The MacDermot lords bid you survive.');
  });

  // Input handlers
  setupInput();

  // Start game loop
  animate();
}

// ─── Game Loop ────────────────────────────────────────────
function animate() {
  requestAnimationFrame(animate);

  const delta = state.clock.getDelta();
  const clampedDelta = Math.min(delta, 0.05); // Prevent spiral on tab-away

  if (state.started && !state.paused) {
    // Advance game time
    state.gameTime += (24 / state.dayLengthSec) * clampedDelta;
    if (state.gameTime >= 24) state.gameTime -= 24;

    // Update systems
    updateSky(state.scene, state.gameTime, clampedDelta);
    updateWater(clampedDelta);
    updatePlayer(clampedDelta, state);
    updateNPCs(clampedDelta, getPlayerPosition());
    updateResources(clampedDelta);
    updateUI(state);
  }

  state.renderer.render(state.scene, state.camera);
}

// ─── Input ────────────────────────────────────────────────
function setupInput() {
  // Pointer lock
  document.addEventListener('pointerlockchange', () => {
    if (!document.pointerLockElement && state.started && !state.paused) {
      togglePause();
    }
  });

  document.addEventListener('keydown', (e) => {
    if (!state.started) return;

    switch (e.code) {
      case 'Escape':
        togglePause();
        break;
      case 'Tab':
        e.preventDefault();
        togglePanel('inventory-panel');
        break;
      case 'KeyC':
        togglePanel('crafting-panel');
        break;
      case 'KeyE':
        if (!state.paused) handleInteract();
        break;
    }
  });

  // Attack on click
  document.addEventListener('mousedown', (e) => {
    if (!state.started || state.paused) return;
    if (e.button === 0) handleAttack();
  });

  // Resume / quit buttons
  document.getElementById('resume-button').addEventListener('click', togglePause);
  document.getElementById('quit-button').addEventListener('click', () => location.reload());
  document.getElementById('respawn-button').addEventListener('click', handleRespawn);

  // Panel close buttons
  document.querySelectorAll('.panel-close').forEach(btn => {
    btn.addEventListener('click', () => {
      const panelId = btn.dataset.panel;
      document.getElementById(panelId).style.display = 'none';
      document.body.requestPointerLock();
    });
  });
}

function togglePause() {
  state.paused = !state.paused;
  const menu = document.getElementById('pause-menu');

  if (state.paused) {
    menu.style.display = 'flex';
    document.exitPointerLock();
  } else {
    menu.style.display = 'none';
    closePanels();
    document.body.requestPointerLock();
  }
}

function togglePanel(panelId) {
  const panel = document.getElementById(panelId);
  const isOpen = panel.style.display !== 'none';

  closePanels();

  if (isOpen) {
    document.body.requestPointerLock();
  } else {
    panel.style.display = 'block';
    document.exitPointerLock();
    state.paused = true;
    // Don't show pause menu, just pause gameplay
  }
}

function closePanels() {
  document.getElementById('inventory-panel').style.display = 'none';
  document.getElementById('crafting-panel').style.display = 'none';
  state.paused = false;
}

function handleInteract() {
  const pos = getPlayerPosition();
  const npc = getNearbyNPC(pos, 4);

  if (npc) {
    showDialogue(npc.name, npc.title, npc.getNextLine());
    return;
  }

  hideDialogue();
}

function handleAttack() {
  if (playerState.attackCooldown > 0) return;
  playerState.attackCooldown = 0.5;

  const pos = getPlayerPosition();
  const result = hitResource(pos, playerState.facing, 3.0, 10);

  if (result && result.drops) {
    for (const [itemId, count] of Object.entries(result.drops)) {
      addItem(itemId, count);
      showNotification(`+${count} ${itemId}`);
    }
  }
}

function handleRespawn() {
  document.getElementById('death-screen').style.display = 'none';
  playerState.health = 25;
  playerState.stamina = 50;
  playerState.hunger = 80;
  playerState.dead = false;
  // Reset position to spawn
  const player = state.scene.getObjectByName('PlayerGroup');
  if (player) player.position.set(80, getTerrainHeight(80, 60) + 1, 60);
  document.body.requestPointerLock();
}

// ─── Helpers ──────────────────────────────────────────────
function updateLoadingBar(pct, text) {
  const bar = document.getElementById('loading-bar');
  const label = document.getElementById('loading-text');
  if (bar) bar.style.width = pct + '%';
  if (label) label.textContent = text;
}

function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Go!
init().catch(err => {
  console.error('Failed to initialize:', err);
  document.getElementById('loading-text').textContent = 'Error: ' + err.message;
});
