// Quay cả video "Một chấm thôi" trong MỘT lượt: trang sân khấu (thẻ kể chuyện + 2 điện thoại chạy app thật).
// Nhịp do lời đọc dẫn: mỗi câu hiện phụ đề, chạy thao tác, rồi giữ cho tới khi câu đọc xong.
// Ghi hình bằng CDP screencast (JPEG chất lượng cao) thay vì video của Playwright (VP8 ~1 Mbps, chữ bị nhoè).
//
// Cần: backend :8787, `python3 -m http.server 5181` ở thư mục demo-video, đã chạy prepare.mjs và
// build-narration-audio.py.   Dùng: node scripts/record.mjs [--vertical]
import { chromium } from '@playwright/test';
import fs from 'fs';
import path from 'path';

const VERTICAL = process.argv.includes('--vertical');
const NAME = VERTICAL ? 'vertical' : 'horizontal';
const SIZE = VERTICAL ? { width: 1080, height: 1920 } : { width: 1920, height: 1080 };
const BASE = 'http://localhost:5181';
const KHOA_BASE = 'http://127.0.0.1:5181'; // origin khác => localStorage khác => tài khoản khác
const API = 'http://localhost:8787/api';
const OUT = `demo-out/rec-${NAME}`;
const seed = JSON.parse(fs.readFileSync('demo-out/prep/seed.json', 'utf8'));
const manifest = JSON.parse(fs.readFileSync('demo-out/narration/manifest.json', 'utf8')).lines;
const SPEAKER = { thu: 'Thư', khoa: 'Khoa' };

fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(`${OUT}/frames`, { recursive: true });

const browser = await chromium.launch({
  args: [
    '--use-fake-ui-for-media-stream',
    '--use-fake-device-for-media-stream',
    `--use-file-for-fake-video-capture=${path.resolve('demo-out/prep/qr-camera.y4m')}`,
    '--autoplay-policy=no-user-gesture-required',
  ],
});
const context = await browser.newContext({ viewport: SIZE, deviceScaleFactor: 1 });
await context.grantPermissions(['camera'], { origin: KHOA_BASE });
await context.grantPermissions(['camera'], { origin: BASE });

// Máy của Thư (origin localhost) có sẵn tài khoản + một tuần nhật ký; máy Khoa (127.0.0.1) mới tinh.
await context.addInitScript(({ seed }) => {
  if (location.origin !== 'http://localhost:5181' || !location.pathname.startsWith('/app-build')) return;
  if (localStorage.getItem('flutter.cham_onboarded_v1')) return;
  localStorage.setItem('flutter.cham_account_v1', JSON.stringify(JSON.stringify(seed.account)));
  localStorage.setItem('flutter.cham_activity_logs_v1', JSON.stringify(JSON.stringify(seed.logs)));
  localStorage.setItem('flutter.cham_onboarded_v1', 'true');
}, { seed });

const page = await context.newPage();
page.on('pageerror', (e) => console.log('pageerror:', e.message));
await page.goto(`${BASE}/stage/${VERTICAL ? '?v=1' : ''}`);
await page.evaluate(({ a, b }) => stage.load(a, b), { a: `${BASE}/app-build/`, b: `${KHOA_BASE}/app-build/` });
await page.evaluate((c) => stage.credit(c), process.env.DEMO_CREDIT || '');

// ---------- khung app ----------
async function appFrame(origin) {
  for (let i = 0; i < 200; i++) {
    const f = page.frames().find((fr) => fr.url().startsWith(`${origin}/app-build`));
    if (f) return f;
    await page.waitForTimeout(100);
  }
  throw new Error(`frame ${origin} not found`);
}
const thu = await appFrame(BASE);
const khoa = await appFrame(KHOA_BASE);
async function enableSemantics(frame) {
  await frame.locator('flt-semantics-placeholder').waitFor({ state: 'attached', timeout: 90_000 });
  await frame.evaluate(() => document.querySelector('flt-semantics-placeholder').click());
}
await Promise.all([enableSemantics(thu), enableSemantics(khoa)]);
await thu.getByText('Ăn uống', { exact: true }).first().waitFor({ timeout: 60_000 });
await khoa.getByText('Mỗi việc là một chấm').waitFor({ timeout: 60_000 });

// ---------- ghi hình ----------
const cdp = await context.newCDPSession(page);
const frames = [];
let frameNo = 0;
cdp.on('Page.screencastFrame', async ({ data, metadata, sessionId }) => {
  const file = `${OUT}/frames/${String(frameNo++).padStart(6, '0')}.jpg`;
  frames.push({ file, ts: metadata.timestamp * 1000 });
  fs.writeFile(file, Buffer.from(data, 'base64'), () => {});
  cdp.send('Page.screencastFrameAck', { sessionId }).catch(() => {});
});
await cdp.send('Page.startScreencast', { format: 'jpeg', quality: 92, maxWidth: SIZE.width, maxHeight: SIZE.height, everyNthFrame: 1 });
await page.waitForTimeout(500);
const t0 = Date.now();
const timing = [];

// ---------- công cụ dẫn nhịp ----------
const sleep = (ms) => page.waitForTimeout(ms);
const stage = (fn, ...args) => page.evaluate(({ fn, args }) => window.stage[fn](...args), { fn, args });
const GAP = 450;
async function dump(tag) {
  for (const [n, f] of [['thu', thu], ['khoa', khoa]]) {
    const labels = await f.evaluate(() => [...document.querySelectorAll('flt-semantics')]
      .map((el) => `${el.getAttribute('role') || ''}|${el.getAttribute('aria-label') || ''}|${el.childElementCount ? '' : el.textContent}`)
      .filter((x) => x !== '||')).catch(() => []);
    console.log(`[${n}] ${f.url()}`, JSON.stringify(labels));
  }
  await page.screenshot({ path: `${OUT}/error-${tag}.png` });
}
async function line(id, actions) {
  const entry = manifest[id];
  if (!entry) throw new Error(`no narration ${id}`);
  const offsetMs = Date.now() - t0;
  await stage('caption', entry.text, SPEAKER[entry.speaker]);
  const until = Date.now() + entry.ms;
  if (actions) {
    try {
      await actions();
    } catch (e) {
      // In nhãn trợ năng hiện có của hai máy để sửa selector nhanh.
      for (const [n, f] of [['thu', thu], ['khoa', khoa]]) {
        const labels = await f.evaluate(() => [...document.querySelectorAll('flt-semantics')]
          .map((el) => `${el.getAttribute('role') || ''}|${el.getAttribute('aria-label') || ''}|${el.childElementCount ? '' : el.textContent}`)
          .filter((x) => x !== '||')).catch(() => []);
        console.log(`[${n}]`, JSON.stringify(labels));
      }
      await page.screenshot({ path: `${OUT}/error-${id}.png` });
      throw e;
    }
  }
  const left = until - Date.now();
  if (left > 0) await sleep(left);
  timing.push({ id, offsetMs, ms: entry.ms, text: entry.text, speaker: entry.speaker, end: Date.now() - t0 });
  console.log(`${id}  ${(offsetMs / 1000).toFixed(1)}s  ${entry.text.slice(0, 50)}`);
  await sleep(GAP);
}

// Con trỏ của sân khấu bay tới phần tử (toạ độ trang chính), gợn sóng, rồi bấm thật trong app.
async function center(loc) {
  await loc.waitFor({ state: 'visible', timeout: 20_000 });
  const b = await loc.boundingBox();
  return { x: b.x + b.width / 2, y: b.y + b.height / 2 };
}
async function point(loc, ms = 650) {
  const { x, y } = await center(loc);
  await stage('cursor', x, y, ms);
  await sleep(ms);
}
async function tap(loc, { pause = 180 } = {}) {
  await point(loc);
  const { x, y } = await center(loc);
  await stage('ripple', x, y);
  await loc.click();
  await sleep(pause);
}
async function type(loc, text) {
  await tap(loc);
  await loc.pressSequentially(text, { delay: 110 });
}
async function tapBarrier(frame) {
  // Chạm phần nền phía trên để đóng bottom sheet.
  const el = await frame.frameElement();
  const b = await el.boundingBox();
  await stage('cursor', b.x + b.width / 2, b.y + 120, 500);
  await sleep(500);
  await stage('ripple', b.x + b.width / 2, b.y + 120);
  await page.mouse.click(b.x + b.width / 2, b.y + 120);
  await sleep(500);
}
const btn = (frame, name, exact = true) => frame.getByRole('button', { name, exact }).first();
const txt = (frame, text, exact = true) => frame.getByText(text, { exact }).first();
// Chữ nằm trong nhãn trợ năng gộp (aria-label) hoặc là chữ rời.
const any = (frame, re) => frame.getByLabel(re).or(frame.getByText(re)).first();

// =====================================================================================
// 00 — Mở
await stage('card', 'intro');
await line('sc00.1');
await line('sc00.2');

// 01 — Xa
await stage('card', 'map');
await line('sc01.1');
await stage('card', 'chat');
await line('sc01.2');
await stage('card', 'night');
await line('sc01.3');
await stage('card', 'silence');
await line('sc01.4');

// 02 — Tự giữ mình
await stage('hideCards');
await stage('layout', 'thu');
await stage('side', 'L', '<div class="chip">Nhật ký một chạm</div><h2>Mỗi việc<br>là một chấm.</h2><p>Chạm một biểu tượng trên vòng tròn. Không cần viết, không cần chụp.</p>');
await line('sc02.1', async () => {
  await sleep(700);
  for (const name of ['Cà phê', 'Chạy bộ', 'Ngủ', 'Đọc sách']) await point(txt(thu, name), 520);
});
await line('sc02.2', async () => {
  await tap(txt(thu, 'Ăn uống'), { pause: 1600 });
  await tap(txt(thu, 'Tập trung'), { pause: 900 });
});
await line('sc02.3', async () => {
  await tap(thu.getByRole('button', { name: /HÔM NAY/ }).first(), { pause: 900 });
  await tap(btn(thu, 'Viết ghi chú'), { pause: 900 });
  await type(thu.getByRole('textbox').first(), 'Bánh mì cô Ba, ngon đúng như lời đồn.');
});
await line('sc02.4', async () => {
  await tap(btn(thu, 'Lưu'), { pause: 900 });
  await stage('side', 'L', '<div class="chip">Riêng tư là mặc định</div><h2>Chỉ nằm<br>trên máy bạn.</h2><p>Không ai thấy, trừ khi bạn bật Công khai.</p>');
  await point(thu.getByRole('button', { name: 'Riêng tư', exact: true }).first());
});
await line('sc02.5', async () => {
  await tapBarrier(thu);
  await tap(btn(thu, 'Lịch sử & thống kê'), { pause: 900 });
  await tap(txt(thu, 'Tuần'), { pause: 700 });
  await tap(btn(thu, 'Tạo ảnh tóm tắt'), { pause: 400 });
  await stage('side', 'L', '<div class="chip">Thống kê tuần</div><h2>Nhìn lại<br>một tuần.</h2><p>Lưu thành ảnh để giữ, hoặc gửi cho người thân.</p>');
});
await sleep(2600); // để người xem kịp đọc thẻ "Tuần của tôi"


// 03 — Gặp lại
await stage('chapter', 'Tháng sáu', 'Gặp lại');
await stage('side', 'L', '');
await sleep(900);
await tapBarrier(thu);
await btn(thu, 'Back').click();
await stage('cursorOff');
await stage('tags', 'Thư <small>🌸 đã dùng Chấm 3 tháng</small>', 'Khoa <small>🐻 vừa cài app</small>');
await stage('layout', 'two');
await line('sc03.1', async () => {
  await sleep(1800);
  await stage('chapterOff');
});
await line('sc03.2', async () => {
  for (let i = 0; i < 3; i++) await tap(btn(khoa, 'Tiếp tục'), { pause: 450 });
  await type(khoa.getByRole('textbox').first(), 'Khoa');
  await tap(txt(khoa, '🐻'), { pause: 300 });
  await tap(btn(khoa, 'Bắt đầu chấm'), { pause: 900 });
});
await line('sc03.3', async () => {
  await tap(thu.getByRole('button', { name: /^Hồ sơ/ }).first(), { pause: 500 });
  await tap(txt(thu, 'Mở Mã QR & Quét Bạn Bè'), { pause: 600 });
  await tap(khoa.getByRole('button', { name: /^Hồ sơ/ }).first(), { pause: 500 });
  await tap(txt(khoa, 'Mở Mã QR & Quét Bạn Bè'), { pause: 500 });
  await tap(txt(khoa, 'Quét mã QR'), { pause: 300 });
  await tap(btn(khoa, 'Kết bạn'), { pause: 900 });
});
// Mở danh sách bạn bè; chạm lại nếu lần đầu rơi đúng lúc màn đang dựng lại.
async function openFriends(f) {
  await tap(btn(f, 'Danh sách bạn bè'), { pause: 300 });
  for (let i = 0; i < 3; i++) {
    if (await btn(f, 'Thêm bạn').waitFor({ timeout: 1500 }).then(() => true).catch(() => false)) return;
    // Cú bấm chuột không tới được app (xem ghi chú ở press): kích hoạt thẳng nút trợ năng.
    await btn(f, 'Danh sách bạn bè').dispatchEvent('click').catch(() => {});
  }
}
await line('sc03.4', async () => {
  await openFriends(thu);
  await openFriends(khoa);
});
await sleep(600);

// 04 — Gần
await stage('chapter', 'Về lại', 'Hai đầu đất nước');
await sleep(800);
// Về trang chủ (sau thẻ chương nên không lọt vào hình): lùi lịch sử trình duyệt hai bước.
// Có lúc khung app cùng origin với sân khấu bỏ qua cú bấm chuột thật (khi khung kia đang mở camera);
// kích hoạt nút trợ năng bằng sự kiện click thì luôn ăn.
async function press(loc) {
  for (let i = 0; i < 5; i++) {
    try {
      await loc.dispatchEvent('click', {}, { timeout: 3000 });
      return;
    } catch {
      await sleep(400); // nút bị dựng lại trong lúc chuyển trang: thử lại
    }
  }
  await dump('press');
  throw new Error('press failed');
}
// Lùi tới trang chủ bằng nút quay lại có trên màn (Back của AppBar, hoặc "Quay lại" ở màn QR).
async function goHome(f) {
  for (let i = 0; i < 6; i++) {
    if (await btn(f, 'Lịch sử & thống kê').isVisible().catch(() => false)) return;
    for (const name of ['Back', 'Quay lại']) {
      if (await btn(f, name).isVisible().catch(() => false)) {
        await press(btn(f, name));
        break;
      }
    }
    await sleep(800);
  }
  await dump('go-home');
  throw new Error('not home');
}
await goHome(thu);
await goHome(khoa);
await khoa.getByRole('button', { name: 'Bảng tin bạn bè (Vuốt sang trái)' }).waitFor({ timeout: 10_000 }).catch(async (e) => {
  await dump('to-home');
  throw e;
});
await btn(khoa, 'Bảng tin bạn bè (Vuốt sang trái)').click();
await stage('tags', 'Sài Gòn <small>Thư 🌸</small>', 'Hà Nội <small>Khoa 🐻</small>');
await stage('layout', 'apart');
await stage('cursorOff');
await sleep(900);
await stage('chapterOff');
await line('sc04.1', async () => {
  await sleep(500);
  await tap(txt(thu, 'Chạy bộ'), { pause: 1200 });
  await tap(thu.getByRole('button', { name: /HÔM NAY/ }).first(), { pause: 800 });
  await tap(thu.getByRole('button', { name: 'Riêng tư', exact: true }).first(), { pause: 900 });
});
await line('sc04.2', async () => {
  await tapBarrier(thu);
  await any(khoa, /Thư đã chấm/).waitFor({ timeout: 15_000 });
  await point(any(khoa, /Thư đã chấm/));
  await tap(khoa.getByRole('button', { name: /Yêu thích/ }).first(), { pause: 300 });
});
// Trong lúc đó, Khoa cũng đã chấm vài việc Công khai hôm nay (để thấy "Ngày của Khoa" ở cảnh kết).
const khoaAccount = await khoa.evaluate(() => JSON.parse(JSON.parse(localStorage.getItem('flutter.cham_account_v1'))));
const vnToday = (h, m) => {
  const d = new Date(Date.now() + 7 * 3600e3);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), h - 7, m)).toISOString();
};
for (const [emoji, name, h, m] of [['☕', 'Cà phê', 7, 30], ['🍜', 'Ăn uống', 12, 5], ['📖', 'Đọc sách', 13, 20]]) {
  if (Date.parse(vnToday(h, m)) > Date.now()) continue;
  await fetch(`${API}/shares/${crypto.randomUUID()}`, {
    method: 'PUT',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${khoaAccount.token}` },
    body: JSON.stringify({ emoji, name, occurredAt: vnToday(h, m) }),
  });
}
await line('sc04.3', async () => {
  await sleep(1600); // thông báo realtime trượt xuống trên máy Thư
  await tap(btn(thu, 'Bảng tin bạn bè (Vuốt sang trái)'), { pause: 900 });
  await tap(any(thu, /người đã thả cảm xúc/), { pause: 600 });
});

// 05 — Kết
await line('sc05.1', async () => {
  await tapBarrier(thu);
  await tap(btn(thu, 'Khoa'), { pause: 500 });
  await khoa.getByRole('button', { name: 'Tất cả', exact: true }).first().waitFor();
  await tap(btn(khoa, 'Thư'), { pause: 500 });
  await stage('cursorOff');
});
await sleep(600);
await stage('caption', '');
await stage('layout', 'none');
await stage('card', 'outro');
await line('sc05.2');
await sleep(2500);
await stage('caption', '');
await sleep(1200);

const end = Date.now();
await cdp.send('Page.stopScreencast');
await sleep(500);
fs.writeFileSync(`${OUT}/timing.json`, JSON.stringify({ t0, end, lines: timing }, null, 2));
fs.writeFileSync(`${OUT}/frames.json`, JSON.stringify(frames));
await browser.close();
console.log(`done: ${((end - t0) / 1000).toFixed(1)}s, ${frames.length} frames -> ${OUT}`);
