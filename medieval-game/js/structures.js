/**
 * Historic structures around Lough Key.
 * - MacDermot Castle on Castle Island (The Rock)
 * - Trinity Island Premonstratensian Monastery
 * - Ring forts, crannogs, clachan village
 */
import * as THREE from 'three';
import { getTerrainHeight } from './world.js';

const stone = new THREE.MeshStandardMaterial({ color: 0x726b62, roughness: 0.85 });
const darkStone = new THREE.MeshStandardMaterial({ color: 0x4d4740, roughness: 0.85 });
const wood = new THREE.MeshStandardMaterial({ color: 0x4d3319, roughness: 0.9 });
const thatch = new THREE.MeshStandardMaterial({ color: 0x665a33, roughness: 0.95 });
const earth = new THREE.MeshStandardMaterial({ color: 0x4d4026, roughness: 0.95 });
const wattle = new THREE.MeshStandardMaterial({ color: 0x736140, roughness: 0.9 });
const darkWood = new THREE.MeshStandardMaterial({ color: 0x140f0a, roughness: 0.95 });

export function buildStructures(scene) {
  const group = new THREE.Group();
  group.name = 'Structures';

  buildMacDermotCastle(group);
  buildTrinityMonastery(group);
  buildRingFort(group, 130, 80, 'Rath_Mor');
  buildRingFort(group, 160, 130, 'Rath_Beag');
  buildCrannog(group, 75, 108);
  buildCrannog(group, 110, 88);
  buildVillage(group, 140, 100);

  scene.add(group);
}

// ─── MacDermot Castle ─────────────────────────────────────
function buildMacDermotCastle(parent) {
  const g = new THREE.Group();
  g.name = 'MacDermotCastle';
  const cx = 95, cz = 105;
  const baseY = getTerrainHeight(cx, cz);
  g.position.set(cx, baseY, cz);

  // Main keep
  addBox(g, 0, 5, 0, 6, 10, 5, stone);
  // Battlements
  for (let i = 0; i < 4; i++) {
    for (let j = 0; j < 3; j++) {
      if ((i + j) % 2 === 0) {
        addBox(g, -2.5 + i * 1.8, 10.6, -1.8 + j * 1.8, 0.8, 1.2, 0.8, darkStone);
      }
    }
  }

  // Curtain wall
  const wallR = 10;
  const segs = 16;
  for (let i = 0; i < segs; i++) {
    const a = (i / segs) * Math.PI * 2;
    const x = Math.cos(a) * wallR;
    const z = Math.sin(a) * wallR;
    const wallMesh = makeBox(5.2, 6, 0.8, stone);
    wallMesh.position.set(x, 3, z);
    wallMesh.rotation.y = -a + Math.PI / 2;
    wallMesh.castShadow = true;
    wallMesh.receiveShadow = true;
    g.add(wallMesh);
  }

  // Corner towers
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * Math.PI * 2 + Math.PI / 4;
    const x = Math.cos(a) * wallR;
    const z = Math.sin(a) * wallR;
    addCylinder(g, x, 4, z, 1.5, 8, darkStone);
    addCone(g, x, 9.5, z, 2, 3, thatch);
  }

  // Gatehouse
  addBox(g, wallR, 3.5, 0, 4, 7, 3, darkStone);
  addBox(g, wallR, 2, 0, 2, 4, 3.2, darkWood); // Gate opening

  // Great hall
  addBox(g, -3, 2, -3, 8, 4, 5, stone);
  addBox(g, -3, 4.5, -3, 9, 0.5, 6, thatch); // Roof

  // Banner (MacDermot red)
  const bannerMat = new THREE.MeshStandardMaterial({ color: 0x991a1a, roughness: 0.8 });
  addCylinder(g, 0, 12, 0, 0.05, 4, wood);
  addBox(g, 0.75, 12.5, 0, 1.5, 1.0, 0.05, bannerMat);

  // Warm light from great hall
  const hallLight = new THREE.PointLight(0xff9944, 1.5, 15);
  hallLight.position.set(-3, 2.5, -3);
  g.add(hallLight);

  parent.add(g);
}

// ─── Trinity Island Monastery ─────────────────────────────
function buildTrinityMonastery(parent) {
  const g = new THREE.Group();
  g.name = 'TrinityMonastery';
  const cx = 88, cz = 92;
  const baseY = getTerrainHeight(cx, cz);
  g.position.set(cx, baseY, cz);

  // Nave
  addBox(g, 0, 2.5, 0, 4, 5, 10, stone);
  // Roof slopes
  addBox(g, -1.2, 5.3, 0, 3, 0.3, 10.5, thatch);
  addBox(g, 1.2, 5.3, 0, 3, 0.3, 10.5, thatch);

  // Bell tower
  addBox(g, 0, 4, -5.5, 2, 8, 2, stone);
  addCone(g, 0, 9.5, -5.5, 1.8, 2.5, thatch);

  // Cloister wings
  for (let side = 0; side < 4; side++) {
    const a = side * Math.PI / 2;
    const cloister = makeBox(6, 2.5, 1.5, stone);
    cloister.position.set(Math.cos(a) * 4, 1.25, Math.sin(a) * 4 + 5);
    cloister.rotation.y = a;
    cloister.castShadow = true;
    g.add(cloister);
  }

  // High cross
  addCylinder(g, 4, 0.25, 0, 0.3, 0.5, stone);   // Base
  addBox(g, 4, 2, 0, 0.3, 3, 0.3, stone);         // Shaft
  addBox(g, 4, 3, 0, 1.5, 0.3, 0.3, stone);       // Cross arm
  // Ring (torus approximated by a thin cylinder)
  const ringGeo = new THREE.TorusGeometry(0.5, 0.06, 8, 16);
  const ring = new THREE.Mesh(ringGeo, stone);
  ring.position.set(4, 3, 0);
  g.add(ring);

  parent.add(g);
}

// ─── Ring Fort ────────────────────────────────────────────
function buildRingFort(parent, fx, fz, name) {
  const g = new THREE.Group();
  g.name = name;
  const baseY = getTerrainHeight(fx, fz);
  g.position.set(fx, baseY, fz);

  // Earthen bank
  const bankSegs = 24;
  const bankR = 8;
  for (let i = 0; i < bankSegs; i++) {
    const a = (i / bankSegs) * Math.PI * 2;
    const bank = makeBox(2.5, 1.5, 1.2, earth);
    bank.position.set(Math.cos(a) * bankR, 0.75, Math.sin(a) * bankR);
    bank.rotation.y = -a;
    g.add(bank);
  }

  // Central dwelling
  addCylinder(g, 0, 1.5, 0, 3, 3, wattle);
  addCone(g, 0, 4, 0, 3.5, 2.5, thatch);

  parent.add(g);
}

// ─── Crannog ──────────────────────────────────────────────
function buildCrannog(parent, cx, cz) {
  const g = new THREE.Group();
  g.name = 'Crannog';
  g.position.set(cx, 0.3, cz);

  // Wooden platform
  addCylinder(g, 0, 0.15, 0, 5, 0.3, wood);

  // Support posts
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * Math.PI * 2;
    addCylinder(g, Math.cos(a) * 4, -1, Math.sin(a) * 4, 0.15, 3, wood);
  }

  // Roundhouse
  addCylinder(g, 0, 1.55, 0, 2, 2.5, wattle);
  addCone(g, 0, 4, 0, 2.5, 2, thatch);

  // Palisade
  for (let i = 0; i < 16; i++) {
    const a = (i / 16) * Math.PI * 2;
    addCylinder(g, Math.cos(a) * 4.5, 1.3, Math.sin(a) * 4.5, 0.08, 2, wood);
  }

  parent.add(g);
}

// ─── Village (Clachan) ───────────────────────────────────
function buildVillage(parent, vx, vz) {
  const g = new THREE.Group();
  g.name = 'ClachanVillage';
  const baseY = getTerrainHeight(vx, vz);
  g.position.set(vx, baseY, vz);

  const positions = [
    [0,0,0], [5,0,2], [-3,0,5], [7,0,-3],
    [-5,0,-2], [2,0,-5], [10,0,1], [-1,0,8]
  ];

  let rngLocal = 1250;
  const lr = () => { rngLocal = (rngLocal * 16807) % 2147483647; return rngLocal / 2147483647; };

  for (const [ox, oy, oz] of positions) {
    const r = 1.5 + lr() * 1.0;
    const wh = 2.0 + lr() * 0.8;
    addCylinder(g, ox, wh / 2, oz, r, wh, wattle);
    addCone(g, ox, wh + wh * 0.35, oz, r + 0.5, wh * 0.7, thatch);
    // Door
    addBox(g, ox + r - 0.1, 0.75, oz, 0.7, 1.5, 0.3, darkWood);
  }

  // Central fire
  addCylinder(g, 2, 0.1, 1, 1, 0.2, earth);
  const fireLight = new THREE.PointLight(0xff6622, 2.5, 12);
  fireLight.position.set(2, 1, 1);
  g.add(fireLight);

  // Fire glow mesh
  const fireGeo = new THREE.SphereGeometry(0.2, 6, 4);
  const fireMat = new THREE.MeshBasicMaterial({ color: 0xff6611 });
  const fireMesh = new THREE.Mesh(fireGeo, fireMat);
  fireMesh.position.set(2, 0.4, 1);
  g.add(fireMesh);

  parent.add(g);
}

// ─── Helpers ──────────────────────────────────────────────
function makeBox(w, h, d, mat) {
  const geo = new THREE.BoxGeometry(w, h, d);
  const mesh = new THREE.Mesh(geo, mat);
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  return mesh;
}

function addBox(group, x, y, z, w, h, d, mat) {
  const mesh = makeBox(w, h, d, mat);
  mesh.position.set(x, y, z);
  group.add(mesh);
}

function addCylinder(group, x, y, z, radius, height, mat) {
  const geo = new THREE.CylinderGeometry(radius * 0.7, radius, height, 8);
  const mesh = new THREE.Mesh(geo, mat);
  mesh.position.set(x, y, z);
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  group.add(mesh);
}

function addCone(group, x, y, z, radius, height, mat) {
  const geo = new THREE.ConeGeometry(radius, height, 8);
  const mesh = new THREE.Mesh(geo, mat);
  mesh.position.set(x, y, z);
  mesh.castShadow = true;
  group.add(mesh);
}
