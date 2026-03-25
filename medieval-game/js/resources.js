/**
 * Harvestable resource nodes — trees, rocks, flint, berries, mushrooms, ore.
 * Resources respawn after a delay.
 */
import * as THREE from 'three';
import { getTerrainHeight } from './world.js';

const TERRAIN_SIZE = 256;
const LAKE_CENTER = [100, 100];
const LAKE_RADIUS = 45;
const RESPAWN_TIME = 120; // seconds

const resourceNodes = [];
const respawnQueue = [];

let rng;
function seededRandom(seed) {
  let s = seed;
  return () => { s = (s * 16807 + 0) % 2147483647; return (s - 1) / 2147483646; };
}
function randRange(lo, hi) { return lo + rng() * (hi - lo); }

const RESOURCE_DEFS = {
  tree: {
    health: 50, drops: { wood: 4 }, tool: 'axe',
    color: 0x4d3319, geo: () => new THREE.CylinderGeometry(0.15, 0.25, 4, 6),
    yOff: 2, canopy: true,
  },
  stone_deposit: {
    health: 80, drops: { stone: 5 }, tool: 'pickaxe',
    color: 0x737066, geo: () => new THREE.SphereGeometry(0.8, 6, 5),
    yOff: 0.4,
  },
  flint_node: {
    health: 20, drops: { flint: 3 }, tool: null,
    color: 0x404047, geo: () => new THREE.BoxGeometry(0.3, 0.15, 0.25),
    yOff: 0.08,
  },
  berry_bush: {
    health: 10, drops: { berries: 3 }, tool: null,
    color: 0x264d1a, geo: () => new THREE.SphereGeometry(0.5, 5, 4),
    yOff: 0.35,
  },
  mushroom: {
    health: 5, drops: { mushroom: 2 }, tool: null,
    color: 0x998066, geo: () => new THREE.CylinderGeometry(0.15, 0.05, 0.2, 6),
    yOff: 0.1,
  },
  iron_deposit: {
    health: 120, drops: { iron: 3 }, tool: 'pickaxe',
    color: 0x594033, geo: () => new THREE.SphereGeometry(0.7, 6, 5),
    yOff: 0.35, metallic: true,
  },
  clay_deposit: {
    health: 40, drops: { clay: 5 }, tool: 'pickaxe',
    color: 0x805933, geo: () => new THREE.SphereGeometry(0.6, 5, 4),
    yOff: 0.15,
  },
  resin_tree: {
    health: 15, drops: { resin: 2, wood: 1 }, tool: null,
    color: 0x40261a, geo: () => new THREE.CylinderGeometry(0.12, 0.2, 3, 6),
    yOff: 1.5,
  },
};

export function spawnResources(scene) {
  rng = seededRandom(1251);
  const group = new THREE.Group();
  group.name = 'Resources';

  const spawn = (type, count, filter) => {
    for (let i = 0; i < count; i++) {
      const [x, z] = filter();
      if (x === 0 && z === 0) continue;
      const h = getTerrainHeight(x, z);
      createResourceNode(group, type, x, h, z);
    }
  };

  spawn('tree', 120, randomLandPos);
  spawn('stone_deposit', 60, () => { const p = randomLandPos(); return getTerrainHeight(p[0], p[1]) > 2 ? p : [0, 0]; });
  spawn('flint_node', 40, randomShorePos);
  spawn('berry_bush', 50, () => { const p = randomLandPos(); const h = getTerrainHeight(p[0], p[1]); return h > 0.5 && h < 8 ? p : [0, 0]; });
  spawn('mushroom', 40, () => { const p = randomLandPos(); const h = getTerrainHeight(p[0], p[1]); return h > 1 && h < 6 ? p : [0, 0]; });
  spawn('iron_deposit', 15, () => { const p = randomLandPos(); return getTerrainHeight(p[0], p[1]) > 8 ? p : [0, 0]; });
  spawn('clay_deposit', 20, randomShorePos);
  spawn('resin_tree', 30, () => { const p = randomLandPos(); return getTerrainHeight(p[0], p[1]) > 2 ? p : [0, 0]; });

  scene.add(group);
}

function createResourceNode(parent, type, x, y, z) {
  const def = RESOURCE_DEFS[type];
  const mat = new THREE.MeshStandardMaterial({
    color: def.color,
    roughness: def.metallic ? 0.6 : 0.9,
    metalness: def.metallic ? 0.3 : 0,
  });

  const mesh = new THREE.Mesh(def.geo(), mat);
  mesh.position.set(x, y + def.yOff, z);
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  parent.add(mesh);

  // Add canopy for trees
  if (def.canopy) {
    const canopyMat = new THREE.MeshStandardMaterial({ color: 0x275a1a, roughness: 0.9 });
    const canopy = new THREE.Mesh(new THREE.SphereGeometry(2, 6, 5), canopyMat);
    canopy.position.set(x, y + 5, z);
    canopy.castShadow = true;
    parent.add(canopy);

    resourceNodes.push({
      type, mesh, canopy, health: def.health, maxHealth: def.health,
      drops: def.drops, tool: def.tool, active: true, x, y, z,
    });
  } else {
    resourceNodes.push({
      type, mesh, canopy: null, health: def.health, maxHealth: def.health,
      drops: def.drops, tool: def.tool, active: true, x, y, z,
    });
  }
}

export function hitResource(playerPos, facing, range, damage) {
  let closest = null;
  let closestDist = range;

  for (const node of resourceNodes) {
    if (!node.active) continue;

    const dx = node.x - playerPos.x;
    const dz = node.z - playerPos.z;
    const dist = Math.sqrt(dx * dx + dz * dz);

    if (dist > range) continue;

    // Check facing direction (dot product)
    const dirX = dx / dist, dirZ = dz / dist;
    const dot = dirX * facing.x + dirZ * facing.z;
    if (dot < 0.3) continue; // Must be roughly facing it

    if (dist < closestDist) {
      closest = node;
      closestDist = dist;
    }
  }

  if (!closest) return null;

  closest.health -= damage;

  // Visual feedback — flash the mesh
  const origColor = closest.mesh.material.color.getHex();
  closest.mesh.material.color.setHex(0xffffff);
  setTimeout(() => {
    if (closest.mesh.material) closest.mesh.material.color.setHex(origColor);
  }, 80);

  if (closest.health <= 0) {
    // Destroyed
    closest.active = false;
    closest.mesh.visible = false;
    if (closest.canopy) closest.canopy.visible = false;

    respawnQueue.push({ node: closest, timer: RESPAWN_TIME });
    return { drops: { ...closest.drops } };
  }

  return { partial: true, remaining: closest.health };
}

export function updateResources(delta) {
  for (let i = respawnQueue.length - 1; i >= 0; i--) {
    respawnQueue[i].timer -= delta;
    if (respawnQueue[i].timer <= 0) {
      const node = respawnQueue[i].node;
      node.active = true;
      node.health = node.maxHealth;
      node.mesh.visible = true;
      if (node.canopy) node.canopy.visible = true;
      respawnQueue.splice(i, 1);
    }
  }
}

function randomLandPos() {
  for (let attempt = 0; attempt < 10; attempt++) {
    const x = rng() * TERRAIN_SIZE;
    const z = rng() * TERRAIN_SIZE;
    const dx = x - LAKE_CENTER[0], dz = z - LAKE_CENTER[1];
    if (Math.sqrt(dx * dx + dz * dz) < LAKE_RADIUS * 0.9) continue;
    if (getTerrainHeight(x, z) > 0.5) return [x, z];
  }
  return [0, 0];
}

function randomShorePos() {
  const angle = rng() * Math.PI * 2;
  const dist = LAKE_RADIUS + randRange(-2, 5);
  const x = LAKE_CENTER[0] + Math.cos(angle) * dist;
  const z = LAKE_CENTER[1] + Math.sin(angle) * dist;
  const h = getTerrainHeight(x, z);
  return (h > -0.5 && h < 2) ? [x, z] : [0, 0];
}
