/**
 * Day/night cycle with sun, moon, ambient light, and fog.
 * Irish overcast atmosphere.
 */
import * as THREE from 'three';

let sunLight, moonLight, ambientLight, hemisphere;
const sunTarget = new THREE.Object3D();

export function createSky(scene) {
  // Hemisphere light — sky / ground
  hemisphere = new THREE.HemisphereLight(0x8899aa, 0x223320, 0.5);
  scene.add(hemisphere);

  // Ambient fill
  ambientLight = new THREE.AmbientLight(0x404840, 0.3);
  scene.add(ambientLight);

  // Sun
  sunLight = new THREE.DirectionalLight(0xfff0dd, 1.2);
  sunLight.castShadow = true;
  sunLight.shadow.mapSize.set(2048, 2048);
  sunLight.shadow.camera.left = -80;
  sunLight.shadow.camera.right = 80;
  sunLight.shadow.camera.top = 80;
  sunLight.shadow.camera.bottom = -80;
  sunLight.shadow.camera.near = 0.5;
  sunLight.shadow.camera.far = 200;
  sunLight.shadow.bias = -0.001;
  scene.add(sunLight);
  scene.add(sunTarget);
  sunLight.target = sunTarget;

  // Moon
  moonLight = new THREE.DirectionalLight(0x6670aa, 0);
  scene.add(moonLight);
}

export function updateSky(scene, gameTime, delta) {
  if (!sunLight) return;

  const sunAngle = ((gameTime - 6) / 12) * Math.PI; // rises at 6, peaks at 12, sets at 18
  const sunY = Math.sin(sunAngle);
  const sunX = Math.cos(sunAngle);

  // Position sun relative to center of terrain
  sunLight.position.set(128 + sunX * 100, sunY * 80, 128 + 30);
  sunTarget.position.set(128, 0, 128);

  moonLight.position.set(128 - sunX * 100, -sunY * 80, 128 - 30);

  // Determine period
  let period;
  if (gameTime < 5.5) period = 'night';
  else if (gameTime < 7) period = 'dawn';
  else if (gameTime < 18.5) period = 'day';
  else if (gameTime < 20.5) period = 'dusk';
  else period = 'night';

  const fogColor = new THREE.Color();

  switch (period) {
    case 'night':
      sunLight.intensity = 0;
      moonLight.intensity = 0.15;
      ambientLight.intensity = 0.06;
      hemisphere.intensity = 0.1;
      fogColor.setRGB(0.06, 0.07, 0.1);
      scene.fog.density = 0.006;
      break;

    case 'dawn': {
      const t = (gameTime - 5.5) / 1.5;
      sunLight.intensity = t * 0.9;
      sunLight.color.setRGB(1, 0.7 + t * 0.25, 0.4 + t * 0.45);
      moonLight.intensity = 0.15 * (1 - t);
      ambientLight.intensity = 0.06 + t * 0.25;
      hemisphere.intensity = 0.1 + t * 0.4;
      fogColor.setRGB(0.3 + t * 0.3, 0.28 + t * 0.32, 0.2 + t * 0.4);
      scene.fog.density = 0.006 - t * 0.002;
      break;
    }
    case 'day':
      sunLight.intensity = 1.2;
      sunLight.color.setRGB(1, 0.96, 0.88);
      moonLight.intensity = 0;
      ambientLight.intensity = 0.35;
      hemisphere.intensity = 0.5;
      fogColor.setRGB(0.55, 0.6, 0.55);
      scene.fog.density = 0.004;
      break;

    case 'dusk': {
      const t = (gameTime - 18.5) / 2;
      sunLight.intensity = 0.9 * (1 - t);
      sunLight.color.setRGB(1, 0.95 - t * 0.45, 0.88 - t * 0.68);
      moonLight.intensity = t * 0.15;
      ambientLight.intensity = 0.35 - t * 0.29;
      hemisphere.intensity = 0.5 - t * 0.4;
      fogColor.setRGB(0.4 - t * 0.34, 0.35 - t * 0.28, 0.3 - t * 0.2);
      scene.fog.density = 0.004 + t * 0.002;
      break;
    }
  }

  scene.fog.color.copy(fogColor);
  scene.background = fogColor.clone();
}
