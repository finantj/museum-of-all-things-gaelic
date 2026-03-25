/**
 * Terrain generation for the Lough Key / Moylurg region.
 * Procedural heightmap with lake basin, islands, and rolling drumlins.
 */
import * as THREE from 'three';

export const TERRAIN = {
  SIZE: 256,
  RES: 200,       // vertices per side
  MAX_HEIGHT: 25,
  LAKE_LEVEL: 0,
  LAKE_CENTER: [100, 100],
  LAKE_RADIUS: 45,
  CASTLE_ISLAND: [95, 105],
  TRINITY_ISLAND: [88, 92],
  DRUMMAN_ISLAND: [105, 95],
};

let heightData = null;

export function createTerrain(scene) {
  heightData = generateHeightmap();

  const geo = new THREE.PlaneGeometry(TERRAIN.SIZE, TERRAIN.SIZE, TERRAIN.RES - 1, TERRAIN.RES - 1);
  geo.rotateX(-Math.PI / 2);

  const positions = geo.attributes.position.array;
  const colors = new Float32Array(positions.length);

  for (let i = 0; i < positions.length; i += 3) {
    const x = positions[i] + TERRAIN.SIZE / 2;
    const z = positions[i + 2] + TERRAIN.SIZE / 2;
    const h = sampleHeight(x, z);
    positions[i + 1] = h;

    // Vertex colors for terrain type
    const [r, g, b] = terrainColor(h, x, z);
    colors[i] = r;
    colors[i + 1] = g;
    colors[i + 2] = b;
  }

  geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  geo.computeVertexNormals();

  const mat = new THREE.MeshStandardMaterial({
    vertexColors: true,
    roughness: 0.88,
    metalness: 0.02,
    flatShading: false,
  });

  const mesh = new THREE.Mesh(geo, mat);
  mesh.name = 'Terrain';
  mesh.receiveShadow = true;
  mesh.castShadow = false;
  mesh.position.set(TERRAIN.SIZE / 2, 0, TERRAIN.SIZE / 2);

  scene.add(mesh);
  return mesh;
}

export function getTerrainHeight(worldX, worldZ) {
  return sampleHeight(worldX, worldZ);
}

// ─── Height Generation ────────────────────────────────────
function generateHeightmap() {
  const data = new Float32Array(TERRAIN.RES * TERRAIN.RES);
  for (let z = 0; z < TERRAIN.RES; z++) {
    for (let x = 0; x < TERRAIN.RES; x++) {
      const wx = (x / TERRAIN.RES) * TERRAIN.SIZE;
      const wz = (z / TERRAIN.RES) * TERRAIN.SIZE;
      data[z * TERRAIN.RES + x] = sampleHeight(wx, wz);
    }
  }
  return data;
}

function sampleHeight(x, z) {
  // Rolling hills (drumlins of Roscommon)
  let h = 0;
  h += fbm(x * 0.008, z * 0.008, 4) * TERRAIN.MAX_HEIGHT * 0.6;
  h += fbm(x * 0.02, z * 0.02, 3) * TERRAIN.MAX_HEIGHT * 0.25;
  h += fbm(x * 0.05, z * 0.05, 2) * TERRAIN.MAX_HEIGHT * 0.1;

  // Carve lake basin with irregular shoreline
  const [cx, cz] = TERRAIN.LAKE_CENTER;
  const lakeDist = Math.sqrt((x - cx) ** 2 + (z - cz) ** 2);
  const shoreNoise = fbm(x * 0.03 + 500, z * 0.03 + 500, 3) * 15;
  const lakeFactor = smoothstep(TERRAIN.LAKE_RADIUS * 0.5 + shoreNoise, TERRAIN.LAKE_RADIUS * 1.1 + shoreNoise, lakeDist);
  const lakeDepth = -4 * (1 - lakeFactor);
  h = lerp(lakeDepth, h, lakeFactor);

  // Islands
  h = addIsland(x, z, TERRAIN.CASTLE_ISLAND, 8, 3.5, h);
  h = addIsland(x, z, TERRAIN.TRINITY_ISLAND, 10, 2.5, h);
  h = addIsland(x, z, TERRAIN.DRUMMAN_ISLAND, 6, 2.0, h);

  return h;
}

function addIsland(x, z, [ix, iz], radius, height, current) {
  const d = Math.sqrt((x - ix) ** 2 + (z - iz) ** 2);
  if (d < radius) {
    const t = 1 - d / radius;
    const s = t * t * (3 - 2 * t); // smoothstep
    const ih = height * s + fbm(x * 0.1 + 200, z * 0.1 + 200, 2) * 0.5 * s;
    return Math.max(current, ih);
  }
  return current;
}

// ─── Terrain Color ────────────────────────────────────────
function terrainColor(h, x, z) {
  if (h < -0.5)  return [0.15, 0.12, 0.08]; // Lake bed
  if (h < 0.3)   return [0.30, 0.26, 0.18]; // Muddy shore
  if (h < 1.5)   return [0.22, 0.42, 0.14]; // Lush grass near water

  // Add variation with noise
  const n = fbm(x * 0.05, z * 0.05, 2) * 0.08;

  if (h < TERRAIN.MAX_HEIGHT * 0.4)
    return [0.18 + n, 0.38 + n, 0.11 + n]; // Forest green
  if (h < TERRAIN.MAX_HEIGHT * 0.7)
    return [0.28 + n, 0.33 + n, 0.14 + n]; // Hillside
  return [0.33 + n, 0.30 + n, 0.23 + n];   // Rocky hilltop
}

// ─── Noise Functions ──────────────────────────────────────
function hash2d(x, z) {
  let n = (x | 0) * 374761393 + (z | 0) * 668265263;
  n = (n ^ (n >> 13)) * 1274126177;
  return ((n & 0x7fffffff) / 0x7fffffff);
}

function noise2d(x, z) {
  const ix = Math.floor(x), iz = Math.floor(z);
  let fx = x - ix, fz = z - iz;
  fx = fx * fx * (3 - 2 * fx);
  fz = fz * fz * (3 - 2 * fz);

  const a = hash2d(ix, iz);
  const b = hash2d(ix + 1, iz);
  const c = hash2d(ix, iz + 1);
  const d = hash2d(ix + 1, iz + 1);

  return lerp(lerp(a, b, fx), lerp(c, d, fx), fz);
}

function fbm(x, z, octaves) {
  let value = 0, amp = 1, freq = 1, maxVal = 0;
  for (let i = 0; i < octaves; i++) {
    value += noise2d(x * freq, z * freq) * amp;
    maxVal += amp;
    amp *= 0.5;
    freq *= 2;
  }
  return value / maxVal;
}

function lerp(a, b, t) { return a + (b - a) * t; }
function smoothstep(lo, hi, x) {
  const t = Math.max(0, Math.min(1, (x - lo) / (hi - lo)));
  return t * t * (3 - 2 * t);
}

export { fbm, noise2d, smoothstep, lerp, TERRAIN as TerrainConst };
