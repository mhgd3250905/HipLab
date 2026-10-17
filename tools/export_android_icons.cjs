// Deterministic Android resource export from the approved ImageGen foreground.
// Requires Node.js and sharp; no generative or retouching operations are done here.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');

const root = path.resolve(__dirname, '..');
const source = path.join(root, 'design/app-icon/launcher-20261017/foreground-source.png');
const design = path.dirname(source);
const res = path.join(root, 'android/app/src/main/res');
const background = '#101316';
const masterSize = 432; // 108dp at xxxhdpi.
const safeRadius = 128; // 32dp, inside the guaranteed central 66dp diameter.
const layoutAlphaThreshold = 8; // Ignore nearly invisible export speckles for layout only.
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const files = [];
async function write(relative, bytes) {
  const destination = path.join(root, relative);
  fs.mkdirSync(path.dirname(destination), {recursive: true});
  fs.writeFileSync(destination, bytes);
  files.push({file: relative.replaceAll('\\', '/'), bytes: bytes.length, sha256: hash(bytes)});
}
function svg(body, size) {
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">${body}</svg>`);
}
async function clipped(image, body, size) {
  return sharp(image).resize(size, size).composite([{input: svg(body, size), blend: 'dest-in'}]).png().toBuffer();
}
async function main() {
  const original = fs.readFileSync(source);
  const {data, info} = await sharp(original).ensureAlpha().raw().toBuffer({resolveWithObject: true});
  let minX = info.width, minY = info.height, maxX = -1, maxY = -1, transparent = 0;
  for (let y = 0; y < info.height; y++) for (let x = 0; x < info.width; x++) {
    const alpha = data[(y * info.width + x) * 4 + 3];
    if (!alpha) transparent++;
    if (alpha >= layoutAlphaThreshold) {minX = Math.min(minX, x); minY = Math.min(minY, y); maxX = Math.max(maxX, x); maxY = Math.max(maxY, y);}
  }
  if (transparent < info.width * info.height * 0.4 || maxX < 0) throw Error('Source must be an isolated transparent foreground');
  const cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
  let radius = 0;
  for (let y = minY; y <= maxY; y++) for (let x = minX; x <= maxX; x++) {
    if (data[(y * info.width + x) * 4 + 3] >= layoutAlphaThreshold) radius = Math.max(radius, Math.hypot(x - cx, y - cy));
  }
  const scale = safeRadius / radius;
  const width = Math.round(info.width * scale), height = Math.round(info.height * scale);
  const left = Math.round(masterSize / 2 - cx * scale), top = Math.round(masterSize / 2 - cy * scale);
  const resized = await sharp(original).resize(width, height, {kernel: 'lanczos3'}).png().toBuffer();
  const master = await sharp({create: {width: masterSize, height: masterSize, channels: 4, background: '#00000000'}})
    .composite([{input: resized, left, top}]).png().toBuffer();
  const {data: pixels} = await sharp(master).raw().toBuffer({resolveWithObject: true});
  let maxRadius = 0, outsideSafeCircle = 0;
  const monoPixels = Buffer.from(pixels);
  for (let y = 0; y < masterSize; y++) for (let x = 0; x < masterSize; x++) {
    const i = (y * masterSize + x) * 4;
    monoPixels[i] = monoPixels[i + 1] = monoPixels[i + 2] = 255;
    if (pixels[i + 3] >= 8) {
      const r = Math.hypot(x - masterSize / 2, y - masterSize / 2);
      maxRadius = Math.max(maxRadius, r);
      if (r > 132) outsideSafeCircle++;
    }
  }
  if (outsideSafeCircle) throw Error('Foreground exceeds guaranteed 66dp safe circle');
  const mono = await sharp(monoPixels, {raw: {width: masterSize, height: masterSize, channels: 4}}).png().toBuffer();
  const foreground = path.relative(root, path.join(design, 'foreground-108dp.png'));
  await write(foreground, master);
  await write(path.relative(root, path.join(design, 'monochrome-108dp.png')), mono);
  const viewport = {left: 72, top: 72, width: 288, height: 288}; // visible 72dp viewport.
  const visible = await sharp(master).extract(viewport).png().toBuffer();
  const visibleMono = await sharp(mono).extract(viewport).png().toBuffer();
  const colorSquare = await sharp({create: {width: 288, height: 288, channels: 4, background}})
    .composite([{input: visible}]).png().toBuffer();
  for (const [density, factor] of [['mdpi', 1], ['hdpi', 1.5], ['xhdpi', 2], ['xxhdpi', 3], ['xxxhdpi', 4]]) {
    const folder = `android/app/src/main/res/mipmap-${density}`;
    const legacySize = 48 * factor, layerSize = 108 * factor;
    await write(`${folder}/ic_launcher.png`, await sharp(colorSquare).resize(legacySize).png().toBuffer());
    await write(`${folder}/ic_launcher_round.png`, await clipped(colorSquare, `<circle cx="${legacySize / 2}" cy="${legacySize / 2}" r="${legacySize / 2}" fill="white"/>`, legacySize));
    await write(`${folder}/ic_launcher_foreground.png`, await sharp(master).resize(layerSize).png().toBuffer());
    await write(`${folder}/ic_launcher_monochrome.png`, await sharp(mono).resize(layerSize).png().toBuffer());
  }
  for (const version of [26, 33]) for (const name of ['ic_launcher', 'ic_launcher_round']) {
    const xml = `<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n    <background android:drawable="@color/ic_launcher_background" />\n    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n${version === 33 ? '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n' : ''}</adaptive-icon>\n`;
    await write(`android/app/src/main/res/mipmap-anydpi-v${version}/${name}.xml`, Buffer.from(xml));
  }
  await write('android/app/src/main/res/values/ic_launcher_colors.xml', Buffer.from(`<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">${background}</color>\n</resources>\n`));
  await write(path.relative(root, path.join(design, 'store-icon-512.png')), await sharp(colorSquare).resize(512).removeAlpha().png().toBuffer());
  // Packaging previews: circle, rounded square, and wallpaper-tinted monochrome.
  const lightMono = await sharp({create: {width: 288, height: 288, channels: 4, background: '#3CCFA4'}})
    .composite([{input: visibleMono, blend: 'dest-in'}]).png().toBuffer();
  const themed = await sharp({create: {width: 288, height: 288, channels: 4, background: '#D9F6E9'}})
    .composite([{input: lightMono}]).png().toBuffer();
  const size = 256;
  const previews = [
    await clipped(colorSquare, '<circle cx="128" cy="128" r="128" fill="white"/>', size),
    await clipped(colorSquare, '<rect width="256" height="256" rx="58" fill="white"/>', size),
    await clipped(themed, '<circle cx="128" cy="128" r="128" fill="white"/>', size)
  ];
  const layers = previews.map((input, i) => ({input, left: 38 + i * 294, top: 52}));
  for (let i = 0; i < 3; i++) for (const [j, n] of [32, 48, 64].entries()) {
    layers.push({input: await sharp(previews[i]).resize(n).png().toBuffer(), left: 62 + i * 294 + j * 70, top: 362});
  }
  const preview = await sharp({create: {width: 920, height: 456, channels: 4, background: '#E8ECEB'}})
    .composite(layers).png().toBuffer();
  await write(path.relative(root, path.join(design, 'android-preview.png')), preview);
  const manifest = {selected: 'B-standing-hip-mobility',source: path.relative(root, source).replaceAll('\\', '/'), sourceSha256: hash(original), sharpVersion: sharp.versions.sharp, sourceDimensions: [info.width, info.height], sourceTransparentRatio: transparent / (info.width * info.height), background, layoutAlphaThreshold, sourceBounds: [minX, minY, maxX, maxY], safeCircleDiameterDp: 66, measuredRadiusDp: maxRadius / 4, outsideSafeCirclePixels: outsideSafeCircle, legacySizes: [48, 72, 96, 144, 192], layerSizes: [108, 162, 216, 324, 432], files};
  fs.writeFileSync(path.join(design, 'export-manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
  console.log(JSON.stringify({files: files.length, measuredRadiusDp: manifest.measuredRadiusDp, outsideSafeCirclePixels: outsideSafeCircle, sourceTransparentRatio: manifest.sourceTransparentRatio}, null, 2));
}
main().catch(error => {console.error(error); process.exitCode = 1;});
