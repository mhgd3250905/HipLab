// Optional real Chromium probe; run with `node --test <this file>` when
// Playwright and Chrome are installed. Flutter tests do not cover WebView CSS.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { test } = require('node:test');
const { chromium } = require(process.env.HIPLAB_PLAYWRIGHT_MODULE || 'playwright');

test('opaque video reaches first-frame before the host retires its poster', {
  timeout: 30000,
}, async (t) => {
  const mediaRoot = path.resolve(__dirname, '../../assets/drill_media');
  const id = 'hip-n-slider-lateral';
  const server = http.createServer((request, response) => {
    const name = new URL(request.url, 'http://localhost').pathname.slice(1);
    if (!['player.html', 'player.css', 'player.js', `${id}.mp4`].includes(name)) {
      response.writeHead(404).end();
      return;
    }
    const file = name === 'player.css' && process.env.HIPLAB_MEDIA_CSS_PATH
      ? process.env.HIPLAB_MEDIA_CSS_PATH : path.join(mediaRoot, name);
    const size = fs.statSync(file).size;
    const types = { html: 'text/html', css: 'text/css', js: 'text/javascript', mp4: 'video/mp4' };
    const headers = { 'Content-Type': types[name.split('.').pop()], 'Accept-Ranges': 'bytes' };
    const range = /^bytes=(\d+)-(\d*)$/.exec(request.headers.range || '');
    const start = range ? Number(range[1]) : 0;
    const end = range && range[2] ? Math.min(Number(range[2]), size - 1) : size - 1;
    if (range) headers['Content-Range'] = `bytes ${start}-${end}/${size}`;
    headers['Content-Length'] = end - start + 1;
    response.writeHead(range ? 206 : 200, headers);
    fs.createReadStream(file, { start, end }).pipe(response);
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  let browser;
  try {
    browser = await chromium.launch({ channel: 'chrome', headless: true });
    const page = await browser.newPage();
    await page.addInitScript(() => {
      window.__hostFrames = [];
      window.DrillMediaHost = { postMessage(raw) {
        const event = JSON.parse(raw);
        if (event.type === 'first-frame') {
          const video = document.querySelector('video');
          const css = getComputedStyle(video);
          window.__hostFrames.push({ opacity: Number(css.opacity), transition: css.transitionDuration,
            ready: video.readyState, time: video.currentTime });
        }
      } };
    });
    await page.goto(`http://127.0.0.1:${server.address().port}/player.html?id=${id}`);
    await page.waitForFunction(() => window.__drillMediaSnapshot?.().mediaReady);
    // The decoder must render underneath the host's poster, even before
    // first-frame. A CSS fade started inside that callback is too late.
    const before = await page.$eval('video', video => ({
      opacity: Number(getComputedStyle(video).opacity),
      transition: getComputedStyle(video).transitionDuration,
    }));
    assert.equal(before.opacity, 1, 'video must already be opaque behind the poster');
    assert.equal(before.transition, '0s', 'only Flutter animates the handoff');
    await page.evaluate(() => window.drillMediaCommand({ type: 'play' }));
    await page.waitForFunction(() => window.__hostFrames.length === 1);
    const first = await page.evaluate(() => window.__hostFrames[0]);
    assert.equal(first.opacity, 1, 'first-frame must refer to an opaque video frame');
    assert.ok(first.ready >= 2);
    await page.evaluate(() => {
      window.__previousTime = document.querySelector('video').currentTime;
      window.__crossedLoop = false;
      document.querySelector('video').addEventListener('timeupdate', (event) => {
        const time = event.target.currentTime;
        if (time < window.__previousTime) window.__crossedLoop = true;
        window.__previousTime = time;
      });
    });
    await page.waitForFunction(() => window.__crossedLoop, null, { timeout: 12000 });
    await page.evaluate(() => window.drillMediaCommand({ type: 'pause' }));
    const paused = await page.$eval('video', video => video.currentTime);
    await page.waitForTimeout(250);
    const still = await page.$eval('video', video => ({ paused: video.paused, time: video.currentTime }));
    assert.equal(still.paused, true);
    assert.ok(Math.abs(still.time - paused) < 0.03);
    await page.evaluate(() => window.drillMediaCommand({ type: 'play' }));
    await page.waitForFunction(time => {
      const video = document.querySelector('video');
      return !video.paused && video.currentTime > time + 0.1;
    }, paused);
    const final = await page.evaluate(() => ({
      ...window.__drillMediaSnapshot(),
      firstFrameEvents: window.__hostFrames.length,
      opacity: Number(getComputedStyle(document.querySelector('video')).opacity),
      crossedLoop: window.__crossedLoop,
      decodedFrames: document.querySelector('video').getVideoPlaybackQuality().totalVideoFrames,
    }));
    assert.equal(final.firstFrameEvents, 1);
    assert.equal(final.opacity, 1);
    assert.ok(final.decodedFrames > 100);
    t.diagnostic(JSON.stringify({ before, first, final }));
  } finally {
    await browser?.close();
    await new Promise(resolve => server.close(resolve));
  }
});
