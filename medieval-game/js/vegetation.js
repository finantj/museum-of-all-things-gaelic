/**
 * Trees, bushes, and reeds around Lough Key.
 * Native Irish species: oak, ash, hazel, birch, holly, willow, alder.
 */
import * as THREE from 'three';
import { getTerrainHeight, fbm } from './world.js';

const TERRAIN_SIZE = 256;
const LAKE_CENTER = [100, 100];
const LAKE_RADIUS = 45;

// Reusable materials
const trunkMaterials = {};
const leafMaterials = {};

function getTrunkMat(color) {
  const key = color.toString(16);
  if (!trunkMaterials[key]) {
    trunkMaterials[key] = new THREE.MeshStandardMaterial({ color, roughness: 0.95 });
  }
  return trunkMaterials[key];
}

function getLeafMat(color) {
  const key = color.toString(16);
  if (!leafMaterials[key]) {
    leafMaterials[key] = new THREE.MeshStandardMaterial({ color, roughness: 0.9 });
  }
  return leafMaterials[key];
}

// Shared geometries (instanced where possible)
const trunkGeo = new THREE.CylinderGeometry(0.06, 0.12, 1, 6);
const canopyGeo = new THREE.SphereGeometry(1, 6, 5);
const bushGeo = new THREE.SphereGeometry(1, 5, 4);
const reedGeo = new THREE.CylinderGeometry(0.01, 0.02, 1, 4);

const TREE_DEFS = {
  oak:    { trunkH: [3,5], trunkR: [0.2,0.4], canopy: [2.5,4], leafColor: 0x275a1a, trunkColor: 0x4d3319 },
  ash:    { trunkH: [4,6], trunkR: [0.15,0.3], canopy: [2,3.5], leafColor: 0x336626, trunkColor: 0x594d33 },
  hazel:  { trunkH: [2,3.5], trunkR: [0.08,0.15], canopy: [1.5,2.5], leafColor: 0x33611f, trunkColor: 0x594026 },
  birch:  { trunkH: [4,7], trunkR: [0.1,0.18], canopy: [1.5,2.5], leafColor: 0x407326, trunkColor: 0xc8c7b3 },
  holly:  { trunkH: [2,3], trunkR: [0.08,0.12], canopy: [1,1.8], leafColor: 0x144014, trunkColor: 0x403326 },
  willow: { trunkH: [3,4.5], trunkR: [0.2,0.35], canopy: [2.5,4], leafColor: 0x336619, trunkColor: 0x4d4026 },
  alder:  { trunkH: [3,5], trunkR: [0.12,0.22], canopy: [1.8,3], leafColor: 0x2e591a, trunkColor: 0x47331f },
};

let rng;

function seededRandom(seed) {
  let s = seed;
  return () => {
    s = (s * 16807 + 0) % 2147483647;
    return (s - 1) / 2147483646;
  };
}

function randRange(lo, hi) { return lo + rng() * (hi - lo); }

export function spawnVegetation(scene) {
  rng = seededRandom(1250);

  const vegGroup = new THREE.Group();
  vegGroup.name = 'Vegetation';

  // Trees
  for (let i = 0; i < 500; i++) {
    const [x, z] = randomLandPos();
    if (x === 0 && z === 0) continue;
    const h = getTerrainHeight(x, z);
    if (h < 0.5) continue;

    // Choose species based on height
    let species;
    if (h < 1.5) species = rng() < 0.5 ? 'willow' : 'alder';
    else if (h < 5) species = ['oak', 'ash', 'hazel'][Math.floor(rng() * 3)];
    else if (h < 12) species = ['oak', 'birch', 'holly'][Math.floor(rng() * 3)];
    else species = rng() < 0.5 ? 'birch' : 'hazel';

    const tree = createTree(species);
    tree.position.set(x, h, z);
    tree.rotation.y = rng() * Math.PI * 2;
    const s = randRange(0.7, 1.3);
    tree.scale.set(s, randRange(0.8, 1.2) * s, s);
    vegGroup.add(tree);
  }

  // Bushes
  for (let i = 0; i < 350; i++) {
    const [x, z] = randomLandPos();
    if (x === 0 && z === 0) continue;
    const h = getTerrainHeight(x, z);
    if (h < 0.5 || h > 15) continue;

    const bush = new THREE.Mesh(bushGeo, getLeafMat(
      new THREE.Color(randRange(0.1, 0.2), randRange(0.25, 0.4), randRange(0.08, 0.15)).getHex()
    ));
    const r = randRange(0.3, 0.8);
    bush.scale.set(r, randRange(0.5, 0.8), r);
    bush.position.set(x, h + r * 0.3, z);
    bush.castShadow = true;
    vegGroup.add(bush);
  }

  // Reeds along shore
  const reedMat = new THREE.MeshStandardMaterial({ color: 0x596626, roughness: 0.9 });
  for (let i = 0; i < 200; i++) {
    const angle = rng() * Math.PI * 2;
    const dist = LAKE_RADIUS + randRange(-3, 5);
    const noise = randRange(-8, 8);
    const x = LAKE_CENTER[0] + Math.cos(angle) * (dist + noise);
    const z = LAKE_CENTER[1] + Math.sin(angle) * (dist + noise);
    const h = getTerrainHeight(x, z);
    if (Math.abs(h) > 1.5) continue;

    const reed = new THREE.Mesh(reedGeo, reedMat);
    const rh = randRange(0.8, 1.8);
    reed.scale.set(1, rh, 1);
    reed.position.set(x, h + rh * 0.5, z);
    reed.rotation.x = randRange(-0.1, 0.1);
    reed.rotation.z = randRange(-0.1, 0.1);
    vegGroup.add(reed);
  }

  scene.add(vegGroup);
}

function createTree(species) {
  const def = TREE_DEFS[species];
  const group = new THREE.Group();

  const trunkH = randRange(...def.trunkH);
  const trunkR = randRange(...def.trunkR);

  // Trunk
  const trunk = new THREE.Mesh(trunkGeo, getTrunkMat(def.trunkColor));
  trunk.scale.set(trunkR / 0.12, trunkH, trunkR / 0.12);
  trunk.position.y = trunkH / 2;
  trunk.castShadow = true;
  group.add(trunk);

  // Canopy blobs
  const numBlobs = 2 + Math.floor(rng() * 3);
  const canopyR = randRange(...def.canopy);

  for (let j = 0; j < numBlobs; j++) {
    const cr = canopyR * randRange(0.5, 1.0);
    const canopy = new THREE.Mesh(canopyGeo, getLeafMat(def.leafColor));
    canopy.scale.set(cr, cr * randRange(0.6, 1.0), cr);
    canopy.position.set(
      randRange(-canopyR * 0.3, canopyR * 0.3),
      trunkH + canopyR * 0.3 + j * canopyR * 0.15,
      randRange(-canopyR * 0.3, canopyR * 0.3),
    );
    canopy.castShadow = true;
    group.add(canopy);
  }

  return group;
}

function randomLandPos() {
  for (let attempt = 0; attempt < 10; attempt++) {
    const x = rng() * TERRAIN_SIZE;
    const z = rng() * TERRAIN_SIZE;
    const dx = x - LAKE_CENTER[0], dz = z - LAKE_CENTER[1];
    if (Math.sqrt(dx * dx + dz * dz) < LAKE_RADIUS * 0.85) continue;
    const h = getTerrainHeight(x, z);
    if (h > 0.5) return [x, z];
  }
  return [0, 0];
}
