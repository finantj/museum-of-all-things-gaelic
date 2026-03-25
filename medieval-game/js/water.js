/**
 * Lough Key water surface — animated dark Irish lake water.
 */
import * as THREE from 'three';

let waterMesh = null;
let waterTime = 0;
const LAKE_SIZE = 150;

export function createWater(scene) {
  const geo = new THREE.PlaneGeometry(LAKE_SIZE, LAKE_SIZE, 80, 80);
  geo.rotateX(-Math.PI / 2);

  const mat = new THREE.MeshPhysicalMaterial({
    color: 0x0a2018,
    transparent: true,
    opacity: 0.78,
    roughness: 0.05,
    metalness: 0.1,
    transmission: 0.15,
    thickness: 2.0,
    ior: 1.33,
    envMapIntensity: 0.4,
    clearcoat: 0.3,
    side: THREE.DoubleSide,
  });

  waterMesh = new THREE.Mesh(geo, mat);
  waterMesh.name = 'Water';
  waterMesh.position.set(100, 0, 100);
  waterMesh.receiveShadow = true;

  scene.add(waterMesh);

  // Underwater dark volume
  const underGeo = new THREE.BoxGeometry(LAKE_SIZE, 8, LAKE_SIZE);
  const underMat = new THREE.MeshBasicMaterial({ color: 0x020605 });
  const under = new THREE.Mesh(underGeo, underMat);
  under.position.set(100, -4.5, 100);
  scene.add(under);
}

export function updateWater(delta) {
  if (!waterMesh) return;

  waterTime += delta;
  const positions = waterMesh.geometry.attributes.position.array;
  const count = positions.length / 3;

  for (let i = 0; i < count; i++) {
    const x = positions[i * 3];
    const z = positions[i * 3 + 2];
    const wx = x + 100;
    const wz = z + 100;

    // Multi-layer wave animation
    let h = 0;
    h += Math.sin(wx * 0.08 + waterTime * 0.5) * 0.1;
    h += Math.sin(wz * 0.12 + waterTime * 0.3) * 0.08;
    h += Math.sin((wx + wz) * 0.05 + waterTime * 0.7) * 0.06;
    h += Math.sin(wx * 0.2 - waterTime * 0.4) * 0.03;

    positions[i * 3 + 1] = h;
  }

  waterMesh.geometry.attributes.position.needsUpdate = true;
  waterMesh.geometry.computeVertexNormals();
}
