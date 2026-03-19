#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const DISK_DIR = path.join(__dirname, '..', 'disk');
const OUTPUT_DIR = path.join(__dirname, '..', 'collages');

const CGA_PALETTE = [
  [0, 0, 0],         // 00 = black
  [85, 255, 255],    // 01 = cyan
  [255, 85, 255],    // 10 = magenta
  [255, 255, 255]    // 11 = white
];

function decompressRLE(data, offset, expectedSize) {
  const output = [];
  let pos = offset;

  while (output.length < expectedSize && pos < data.length) {
    const byte = data[pos];

    if (byte === 0x7b && pos + 2 < data.length) {
      const value = data[pos + 1];
      const count = data[pos + 2] + 1;
      const toAdd = Math.min(count, expectedSize - output.length);
      for (let i = 0; i < toAdd; i++) {
        output.push(value);
      }
      pos += 3;
    } else {
      output.push(byte);
      pos++;
    }
  }

  return { data: Buffer.from(output), bytesRead: pos - offset };
}

function parseINDFile(indPath) {
  const data = fs.readFileSync(indPath);
  const sprites = [];
  let offset = 0;

  while (offset + 4 <= data.length) {
    const spriteID = data.readUInt16LE(offset);
    const spriteOffset = data.readUInt16LE(offset + 2);
    if (spriteID === 0xFFFF) break;
    sprites.push({ id: spriteID, offset: spriteOffset });
    offset += 4;
  }

  return sprites;
}

function extractSprite(datData, offset) {
  if (offset + 3 > datData.length) return null;

  const widthBytes = datData[offset];
  const height = datData[offset + 1];
  const flags = datData[offset + 2];

  if (widthBytes === 0 || widthBytes > 100 || height === 0 || height > 200) return null;

  const expectedSize = widthBytes * height;

  const pixelResult = decompressRLE(datData, offset + 3, expectedSize);
  if (pixelResult.data.length !== expectedSize) return null;

  const maskOffset = offset + 3 + pixelResult.bytesRead;
  const maskResult = decompressRLE(datData, maskOffset, expectedSize);

  return {
    widthBytes,
    widthPixels: widthBytes * 4,
    height,
    flags,
    pixels: pixelResult.data,
    mask: maskResult.data.length === expectedSize ? maskResult.data : null
  };
}

function renderSpriteToBuffer(sprite) {
  const { widthBytes, widthPixels, height, pixels } = sprite;
  const buf = Buffer.alloc(widthPixels * height * 3);

  // Column-major: data goes y++, then x+=4
  let x = 0, y = 0;
  for (let i = 0; i < pixels.length; i++) {
    const byte = pixels[i];
    for (let bit = 6; bit >= 0; bit -= 2) {
      const colorIndex = (byte >> bit) & 0x03;
      const color = CGA_PALETTE[colorIndex];
      const px = x + (3 - bit / 2);
      if (y < height && px < widthPixels) {
        const idx = (y * widthPixels + px) * 3;
        buf[idx] = color[0];
        buf[idx + 1] = color[1];
        buf[idx + 2] = color[2];
      }
    }
    y++;
    if (y >= height) {
      y = 0;
      x += 4;
    }
  }

  return buf;
}

function makeCollage(datPath, indPath, outputPath) {
  const baseName = path.basename(datPath, '.DAT');
  const datData = fs.readFileSync(datPath);
  const spriteEntries = parseINDFile(indPath);

  const sprites = [];
  for (const entry of spriteEntries) {
    const sprite = extractSprite(datData, entry.offset);
    if (sprite && sprite.widthPixels <= 180 &&
        !sprite.pixels.every(b => b === 0x00) &&
        !sprite.pixels.every(b => b === 0xFF)) {
      sprite.id = entry.id;
      sprites.push(sprite);
    }
  }

  if (sprites.length === 0) {
    console.log(`  ${baseName}: no sprites found, skipping`);
    return;
  }

  // Layout: arrange sprites in a grid with padding
  const PADDING = 4;
  const LABEL_HEIGHT = 10;
  const SCALE = 2;

  // Calculate grid layout — aim for roughly square collage
  const cols = Math.ceil(Math.sqrt(sprites.length));
  const rows = Math.ceil(sprites.length / cols);

  // Find max sprite dimensions per column and row
  const colWidths = new Array(cols).fill(0);
  const rowHeights = new Array(rows).fill(0);

  for (let i = 0; i < sprites.length; i++) {
    const col = i % cols;
    const row = Math.floor(i / cols);
    colWidths[col] = Math.max(colWidths[col], sprites[i].widthPixels * SCALE);
    rowHeights[row] = Math.max(rowHeights[row], sprites[i].height * SCALE + LABEL_HEIGHT);
  }

  const totalWidth = colWidths.reduce((a, b) => a + b, 0) + PADDING * (cols + 1);
  const totalHeight = rowHeights.reduce((a, b) => a + b, 0) + PADDING * (rows + 1);

  // Create image buffer (dark gray background)
  const imgBuf = Buffer.alloc(totalWidth * totalHeight * 3, 32);

  // Compute column X offsets
  const colX = [PADDING];
  for (let c = 1; c < cols; c++) {
    colX.push(colX[c - 1] + colWidths[c - 1] + PADDING);
  }
  const rowY = [PADDING];
  for (let r = 1; r < rows; r++) {
    rowY.push(rowY[r - 1] + rowHeights[r - 1] + PADDING);
  }

  // Blit each sprite
  for (let i = 0; i < sprites.length; i++) {
    const sprite = sprites[i];
    const col = i % cols;
    const row = Math.floor(i / cols);
    const spriteBuf = renderSpriteToBuffer(sprite);

    const startX = colX[col];
    const startY = rowY[row] + LABEL_HEIGHT;

    // Blit with 2x scale
    for (let sy = 0; sy < sprite.height; sy++) {
      for (let sx = 0; sx < sprite.widthPixels; sx++) {
        const srcIdx = (sy * sprite.widthPixels + sx) * 3;
        for (let dy = 0; dy < SCALE; dy++) {
          for (let dx = 0; dx < SCALE; dx++) {
            const destX = startX + sx * SCALE + dx;
            const destY = startY + sy * SCALE + dy;
            if (destX < totalWidth && destY < totalHeight) {
              const destIdx = (destY * totalWidth + destX) * 3;
              imgBuf[destIdx] = spriteBuf[srcIdx];
              imgBuf[destIdx + 1] = spriteBuf[srcIdx + 1];
              imgBuf[destIdx + 2] = spriteBuf[srcIdx + 2];
            }
          }
        }
      }
    }
  }

  // Write PPM
  const ppmPath = outputPath.replace(/\.png$/, '.ppm');
  const header = `P6\n${totalWidth} ${totalHeight}\n255\n`;
  const fd = fs.openSync(ppmPath, 'w');
  fs.writeSync(fd, header);
  fs.writeSync(fd, imgBuf);
  fs.closeSync(fd);

  // Convert to PNG
  try {
    execSync(`magick ${ppmPath} ${outputPath}`, { stdio: 'ignore' });
    fs.unlinkSync(ppmPath);
  } catch (err) {
    try {
      execSync(`convert ${ppmPath} ${outputPath}`, { stdio: 'ignore' });
      fs.unlinkSync(ppmPath);
    } catch (err2) {
      console.log(`  Warning: PNG conversion failed, keeping ${ppmPath}`);
    }
  }

  console.log(`  ${baseName}: ${sprites.length} sprites -> ${path.basename(outputPath)} (${totalWidth}x${totalHeight})`);
}

// Main
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

const datFiles = fs.readdirSync(DISK_DIR)
  .filter(f => f.endsWith('.DAT'))
  .sort();

console.log(`Karateka Sprite Collage Generator`);
console.log(`Found ${datFiles.length} DAT files in ${DISK_DIR}`);
console.log();

for (const datFile of datFiles) {
  const baseName = datFile.replace(/\.DAT$/, '');
  const indFile = baseName + '.IND';
  const indPath = path.join(DISK_DIR, indFile);

  if (!fs.existsSync(indPath)) {
    console.log(`  ${baseName}: no IND file, skipping`);
    continue;
  }

  makeCollage(
    path.join(DISK_DIR, datFile),
    indPath,
    path.join(OUTPUT_DIR, `${baseName}.png`)
  );
}

console.log('\nDone. Collages saved to:', OUTPUT_DIR);
