/**
 * Third-person player controller — Valheim-style.
 * WASD movement, mouse orbit camera, sprint, jump, swim, dodge.
 */
import * as THREE from 'three';
import { getTerrainHeight } from './world.js';

const WALK_SPEED = 4;
const RUN_SPEED = 7;
const SWIM_SPEED = 2.5;
const JUMP_FORCE = 8;
const GRAVITY = 20;
const MOUSE_SENS = 0.002;
const CAM_DISTANCE = 6;
const CAM_MIN = 2;
const CAM_MAX = 14;
const WATER_LEVEL = 0;
const STAMINA_SPRINT = 8; // per second
const STAMINA_JUMP = 10;
const STAMINA_ATTACK = 8;

// Exported state
export const playerState = {
  health: 25, maxHealth: 25,
  stamina: 50, maxStamina: 50,
  hunger: 80, maxHunger: 100,
  dead: false,
  swimming: false,
  running: false,
  attackCooldown: 0,
  facing: new THREE.Vector3(0, 0, -1),
};

// Internal
const keys = {};
let camYaw = 0, camPitch = -0.3;
let camDist = CAM_DISTANCE;
let velocityY = 0;
let onGround = false;
let playerGroup, playerModel, camera;
const tmpVec = new THREE.Vector3();

export function createPlayer(scene, cam) {
  camera = cam;
  playerGroup = new THREE.Group();
  playerGroup.name = 'PlayerGroup';

  // Model
  playerModel = new THREE.Group();
  playerModel.name = 'PlayerModel';

  // Body
  const bodyGeo = new THREE.CapsuleGeometry(0.25, 1.0, 4, 8);
  const bodyMat = new THREE.MeshStandardMaterial({ color: 0x736650, roughness: 0.8 });
  const body = new THREE.Mesh(bodyGeo, bodyMat);
  body.position.y = 0.75;
  body.castShadow = true;
  playerModel.add(body);

  // Head
  const headGeo = new THREE.SphereGeometry(0.16, 8, 6);
  const headMat = new THREE.MeshStandardMaterial({ color: 0xc09a80, roughness: 0.7 });
  const head = new THREE.Mesh(headGeo, headMat);
  head.position.y = 1.55;
  head.castShadow = true;
  playerModel.add(head);

  // Leine (tunic)
  const tunicGeo = new THREE.CylinderGeometry(0.28, 0.4, 0.8, 8);
  const tunicMat = new THREE.MeshStandardMaterial({ color: 0xb3a680 });
  const tunic = new THREE.Mesh(tunicGeo, tunicMat);
  tunic.position.y = 0.5;
  tunic.castShadow = true;
  playerModel.add(tunic);

  // Brat (cloak)
  const cloakGeo = new THREE.BoxGeometry(0.6, 0.7, 0.12);
  const cloakMat = new THREE.MeshStandardMaterial({ color: 0x4d7333 });
  const cloak = new THREE.Mesh(cloakGeo, cloakMat);
  cloak.position.set(0, 1.0, -0.12);
  cloak.castShadow = true;
  playerModel.add(cloak);

  playerGroup.add(playerModel);

  // Spawn on eastern shore
  playerGroup.position.set(80, getTerrainHeight(80, 60) + 1, 60);
  scene.add(playerGroup);

  // Input
  document.addEventListener('keydown', (e) => { keys[e.code] = true; });
  document.addEventListener('keyup', (e) => { keys[e.code] = false; });
  document.addEventListener('mousemove', onMouseMove);
  document.addEventListener('wheel', onWheel);
}

function onMouseMove(e) {
  if (!document.pointerLockElement) return;
  camYaw -= e.movementX * MOUSE_SENS;
  camPitch -= e.movementY * MOUSE_SENS;
  camPitch = Math.max(-1.2, Math.min(0.8, camPitch));
}

function onWheel(e) {
  camDist += e.deltaY * 0.01;
  camDist = Math.max(CAM_MIN, Math.min(CAM_MAX, camDist));
}

export function updatePlayer(delta, state) {
  if (!playerGroup || playerState.dead) return;

  // Attack cooldown
  if (playerState.attackCooldown > 0) playerState.attackCooldown -= delta;

  // Survival drains
  playerState.hunger = Math.max(0, playerState.hunger - 0.5 / 60 * delta);
  if (playerState.hunger <= 0) playerState.health -= 1 * delta; // Starving

  // Regen
  if (playerState.hunger > 0 && playerState.health < playerState.maxHealth) {
    playerState.health = Math.min(playerState.maxHealth, playerState.health + 1 * delta);
  }
  if (playerState.stamina < playerState.maxStamina) {
    playerState.stamina = Math.min(playerState.maxStamina, playerState.stamina + 6 * delta);
  }

  // Death check
  if (playerState.health <= 0) {
    playerState.dead = true;
    document.getElementById('death-screen').style.display = 'flex';
    document.exitPointerLock();
    return;
  }

  // Movement input
  let inputX = 0, inputZ = 0;
  if (keys['KeyW'] || keys['ArrowUp']) inputZ -= 1;
  if (keys['KeyS'] || keys['ArrowDown']) inputZ += 1;
  if (keys['KeyA'] || keys['ArrowLeft']) inputX -= 1;
  if (keys['KeyD'] || keys['ArrowRight']) inputX += 1;

  const hasInput = inputX !== 0 || inputZ !== 0;

  // Direction relative to camera yaw
  const sinYaw = Math.sin(camYaw);
  const cosYaw = Math.cos(camYaw);
  const moveX = inputX * cosYaw + inputZ * sinYaw;
  const moveZ = -inputX * sinYaw + inputZ * cosYaw;
  const moveLen = Math.sqrt(moveX * moveX + moveZ * moveZ) || 1;
  const dirX = moveX / moveLen;
  const dirZ = moveZ / moveLen;

  // Sprint
  playerState.running = keys['ShiftLeft'] && hasInput && playerState.stamina > STAMINA_SPRINT * delta;
  if (playerState.running) {
    playerState.stamina -= STAMINA_SPRINT * delta;
  }

  // Swimming
  playerState.swimming = playerGroup.position.y < WATER_LEVEL;

  // Speed
  let speed;
  if (playerState.swimming) speed = SWIM_SPEED;
  else if (playerState.running) speed = RUN_SPEED;
  else speed = WALK_SPEED;

  // Apply horizontal movement
  if (hasInput) {
    playerGroup.position.x += dirX * speed * delta;
    playerGroup.position.z += dirZ * speed * delta;

    // Rotate model to face movement direction
    const targetAngle = Math.atan2(dirX, dirZ);
    let angleDiff = targetAngle - playerModel.rotation.y;
    while (angleDiff > Math.PI) angleDiff -= Math.PI * 2;
    while (angleDiff < -Math.PI) angleDiff += Math.PI * 2;
    playerModel.rotation.y += angleDiff * Math.min(1, 10 * delta);

    playerState.facing.set(dirX, 0, dirZ);
  }

  // Vertical: gravity / jump / swim
  const terrainH = getTerrainHeight(playerGroup.position.x, playerGroup.position.z);

  if (playerState.swimming) {
    if (playerGroup.position.y < WATER_LEVEL - 0.5) {
      velocityY += 6 * delta; // Buoyancy
    } else {
      velocityY *= 0.9;
    }
    if (keys['Space']) {
      velocityY = 3; // Swim up
    }
  } else {
    // Ground check
    onGround = playerGroup.position.y <= terrainH + 0.05;

    if (onGround) {
      velocityY = 0;
      playerGroup.position.y = terrainH;

      // Jump
      if (keys['Space'] && playerState.stamina >= STAMINA_JUMP) {
        velocityY = JUMP_FORCE;
        playerState.stamina -= STAMINA_JUMP;
      }
    } else {
      velocityY -= GRAVITY * delta;
    }
  }

  playerGroup.position.y += velocityY * delta;

  // Clamp to terrain
  if (!playerState.swimming && playerGroup.position.y < terrainH) {
    playerGroup.position.y = terrainH;
    velocityY = 0;
  }

  // Keep in bounds
  playerGroup.position.x = Math.max(1, Math.min(255, playerGroup.position.x));
  playerGroup.position.z = Math.max(1, Math.min(255, playerGroup.position.z));

  // Camera
  updateCamera();
}

function updateCamera() {
  if (!camera || !playerGroup) return;

  const playerPos = playerGroup.position;

  // Camera orbit position
  const offsetX = Math.sin(camYaw) * Math.cos(camPitch) * camDist;
  const offsetY = Math.sin(-camPitch) * camDist;
  const offsetZ = Math.cos(camYaw) * Math.cos(camPitch) * camDist;

  const camTarget = new THREE.Vector3(playerPos.x, playerPos.y + 1.5, playerPos.z);

  camera.position.set(
    camTarget.x + offsetX,
    camTarget.y + offsetY + 1,
    camTarget.z + offsetZ,
  );

  // Prevent camera from going underground
  const camTerrainH = getTerrainHeight(camera.position.x, camera.position.z);
  if (camera.position.y < camTerrainH + 0.5) {
    camera.position.y = camTerrainH + 0.5;
  }

  camera.lookAt(camTarget);
}

export function getPlayerPosition() {
  return playerGroup ? playerGroup.position.clone() : new THREE.Vector3();
}
