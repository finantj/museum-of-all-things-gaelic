/**
 * NPC system — MacDermot clan, monks, villagers, warriors.
 */
import * as THREE from 'three';
import { getTerrainHeight } from './world.js';

const npcs = [];

const NPC_DATA = [
  {
    id: 'macdermot_lord', name: 'Cormac MacDermot', title: 'Rí Mhaigh Luirg — King of Moylurg',
    pos: [95, 105], type: 'noble', color: 0x801a1a,
    dialogue: [
      'Fáilte go Loch Cé! Welcome to Lough Key, traveler.',
      'I am Cormac MacDermot, lord of Moylurg. These lands have been ours since time beyond memory.',
      'The rock upon which we stand has been the seat of the MacDermots for generations.',
      'Serve me well, and you shall have land and cattle. Betray me, and the lake shall be your grave.',
    ]
  },
  {
    id: 'macdermot_wife', name: 'Gráinne Ní Chonchobhair', title: 'Lady of Moylurg',
    pos: [93, 106], type: 'noble', color: 0x801a1a,
    dialogue: [
      'You are welcome in our hall, stranger.',
      'The MacDermots have ruled from this rock since the time of Maelruanaidh.',
      'If you would eat, speak with the cook. We do not let guests go hungry.',
    ]
  },
  {
    id: 'brehon', name: 'Flann mac Lonáin', title: 'Breitheamh — Brehon Judge',
    pos: [92, 104], type: 'scholar', color: 0x594d40,
    dialogue: [
      'I am the Brehon of Moylurg. I keep the law of the Féineachas.',
      'Under Brehon law, every person has an honour price. Even the king must pay his debts.',
      'If you have a dispute, bring it before me. Justice will be done.',
    ]
  },
  {
    id: 'abbot', name: 'Brother Colmán', title: 'Ab Inis na Tríonóide — Abbot',
    pos: [88, 92], type: 'monk', color: 0xc0b8a0,
    dialogue: [
      'Dia dhuit, child. God be with you.',
      'We are the Premonstratensian order. We tend this abbey and preserve the written word.',
      'The Annals record all that passes in these lands. History must not be forgotten.',
      'We keep a garden of herbs for healing. If you are injured, we may help.',
    ]
  },
  {
    id: 'scribe', name: 'Brother Malachy', title: 'Scríbhneoir — Scribe',
    pos: [89, 93], type: 'monk', color: 0xc0b8a0,
    dialogue: [
      'I copy the manuscripts so that knowledge may endure.',
      'The Annals of Loch Cé record the deeds of kings and the sorrows of the people.',
      'Ink and vellum are precious. Each page is a treasure.',
    ]
  },
  {
    id: 'blacksmith', name: 'Gobnait', title: 'Gabha — Smith',
    pos: [142, 101], type: 'craftsman', color: 0x594033,
    dialogue: [
      'Need something forged? Bring me iron and I\'ll make it sing.',
      'A good sword needs good iron. The bogs yield the best ore.',
      'The MacDermot\'s warriors keep me busy. There\'s always need for blades.',
    ]
  },
  {
    id: 'merchant', name: 'Tadhg the Trader', title: 'Ceannaí — Merchant',
    pos: [138, 98], type: 'merchant', color: 0x665980,
    dialogue: [
      'Finest goods from Connacht and beyond! Come, look!',
      'I trade up and down the Shannon. Lough Key is a fine stopping place.',
      'Wool, leather, bronze — I deal in all manner of goods.',
    ]
  },
  {
    id: 'fisherman', name: 'Séamus', title: 'Iascaire — Fisherman',
    pos: [115, 120], type: 'commoner', color: 0x806650,
    dialogue: [
      'The lake is generous if you know where to cast your line.',
      'Pike and trout, mostly. Sometimes an eel if you\'re patient.',
      'See that island? The MacDermot himself lives there. Nobody crosses without his leave.',
    ]
  },
  {
    id: 'farmer', name: 'Pádraig', title: 'Feirmeoir — Farmer',
    pos: [155, 125], type: 'commoner', color: 0x806650,
    dialogue: [
      'Oats and barley are what we grow. The land is good here.',
      'The cattle are the real wealth. A man\'s honour is measured in cows.',
      'We pay our dues to the MacDermot. In return, he protects us.',
    ]
  },
  {
    id: 'warrior', name: 'Donncha mac Aodha', title: 'Gallóglaigh — Gallowglass',
    pos: [97, 108], type: 'warrior', color: 0x403830,
    dialogue: [
      'I serve the MacDermot with my sword arm. That is my oath.',
      'These walls have never been taken. The rock is our fortress.',
      'If you can swing a blade, there\'s always work for a warrior.',
    ]
  },
];

// Generic villagers
const VILLAGER_NAMES = ['Niamh', 'Ciarán', 'Aoife', 'Ruairí', 'Siobhán', 'Cathal'];
const VILLAGER_LINES = [
  'Dia dhuit! A fine day, is it not?',
  'The MacDermot keeps us safe.',
  'Have you seen the monastery on the island? Beautiful place.',
  'The harvest was good this year, praise God.',
];

export function spawnNPCs(scene) {
  const group = new THREE.Group();
  group.name = 'NPCs';

  for (const data of NPC_DATA) {
    createNPC(group, data);
  }

  // Villagers
  const vPositions = [[135,95], [145,105], [150,98], [138,108], [143,95], [148,102]];
  for (let i = 0; i < vPositions.length; i++) {
    createNPC(group, {
      id: 'villager_' + i, name: VILLAGER_NAMES[i], title: 'Tuathánach — Commoner',
      pos: vPositions[i], type: 'commoner', color: 0x807360,
      dialogue: VILLAGER_LINES,
    });
  }

  scene.add(group);
}

function createNPC(parent, data) {
  const [px, pz] = data.pos;
  const py = getTerrainHeight(px, pz);
  const npcGroup = new THREE.Group();
  npcGroup.name = 'NPC_' + data.id;
  npcGroup.position.set(px, py, pz);

  // Body
  const bodyGeo = new THREE.CapsuleGeometry(0.22, 1.0, 4, 8);
  const bodyMat = new THREE.MeshStandardMaterial({ color: data.color, roughness: 0.8 });
  const body = new THREE.Mesh(bodyGeo, bodyMat);
  body.position.y = 0.72;
  body.castShadow = true;
  npcGroup.add(body);

  // Head
  const headGeo = new THREE.SphereGeometry(0.14, 8, 6);
  const headMat = new THREE.MeshStandardMaterial({ color: 0xc09a80, roughness: 0.7 });
  const head = new THREE.Mesh(headGeo, headMat);
  head.position.y = 1.45;
  head.castShadow = true;
  npcGroup.add(head);

  // Name label (HTML-style using sprite)
  const canvas = document.createElement('canvas');
  canvas.width = 256;
  canvas.height = 64;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#c9a84c';
  ctx.font = 'bold 18px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText(data.name, 128, 22);
  ctx.fillStyle = '#8a7d65';
  ctx.font = '13px sans-serif';
  ctx.fillText(data.title, 128, 44);

  const texture = new THREE.CanvasTexture(canvas);
  const spriteMat = new THREE.SpriteMaterial({ map: texture, transparent: true, depthTest: false });
  const sprite = new THREE.Sprite(spriteMat);
  sprite.scale.set(3, 0.75, 1);
  sprite.position.y = 2.1;
  npcGroup.add(sprite);

  parent.add(npcGroup);

  let dialogueIdx = 0;
  npcs.push({
    id: data.id,
    name: data.name,
    title: data.title,
    pos: npcGroup.position,
    group: npcGroup,
    dialogue: data.dialogue,
    getNextLine() {
      const line = this.dialogue[dialogueIdx];
      dialogueIdx = (dialogueIdx + 1) % this.dialogue.length;
      return line;
    }
  });
}

export function updateNPCs(delta, playerPos) {
  // Simple: NPCs face the player when nearby
  for (const npc of npcs) {
    const dx = playerPos.x - npc.pos.x;
    const dz = playerPos.z - npc.pos.z;
    const dist = Math.sqrt(dx * dx + dz * dz);

    if (dist < 8) {
      const angle = Math.atan2(dx, dz);
      npc.group.rotation.y = angle;
    }
  }
}

export function getNearbyNPC(playerPos, range) {
  let closest = null;
  let closestDist = range;

  for (const npc of npcs) {
    const dx = playerPos.x - npc.pos.x;
    const dz = playerPos.z - npc.pos.z;
    const dist = Math.sqrt(dx * dx + dz * dz);
    if (dist < closestDist) {
      closest = npc;
      closestDist = dist;
    }
  }
  return closest;
}
