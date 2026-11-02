// Chạy thử 5 tính năng mới trên app web thật (2 "điện thoại" = 2 browser context), chụp màn hình.
// Dùng: DEMO_APP_URL=http://localhost:5180 node scripts/smoke-features.mjs
import { chromium } from '@playwright/test';
import fs from 'fs';

const APP = process.env.DEMO_APP_URL || 'http://localhost:5180';
const API = process.env.DEMO_API_URL || 'http://localhost:8787/api';
const OUT = 'demo-out/smoke';
fs.mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch();
const phone = { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 };

async function open(name) {
  const ctx = await browser.newContext(phone);
  const page = await ctx.newPage();
  page.on('console', (m) => m.type() === 'error' && console.log(`[${name}] console:`, m.text()));
  await page.goto(APP, { waitUntil: 'domcontentloaded' });
  // Flutter vẽ lên canvas; bật cây trợ năng để Playwright thấy chữ và nút.
  await page.locator('flt-semantics-placeholder').waitFor({ state: 'attached', timeout: 60_000 });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder').click());
  return page;
}
const shot = (page, n) => page.screenshot({ path: `${OUT}/${n}.png` });
const tap = async (page, text, opts = {}) => {
  await page.getByText(text, { exact: true, ...opts }).first().click();
  await page.waitForTimeout(600);
};
async function account(page) {
  const raw = await page.evaluate(() => localStorage.getItem('flutter.cham_account_v1'));
  return JSON.parse(JSON.parse(raw));
}
async function onboard(page, name, emoji, prefix) {
  await page.getByText('Mỗi việc là một chấm').waitFor({ timeout: 60_000 });
  await shot(page, `${prefix}-1-welcome`);
  for (let i = 0; i < 3; i++) await tap(page, 'Tiếp tục');
  await page.getByRole('textbox').nth(0).fill(`${prefix}_${Date.now().toString(36)}`); // tên người dùng, duy nhất
  await page.getByRole('textbox').nth(1).fill(name);
  await tap(page, emoji);
  await shot(page, `${prefix}-2-profile`);
  await tap(page, 'Bắt đầu chấm');
  await page.waitForTimeout(1500);
}

const thu = await open('thu');
await onboard(thu, 'Thư', '🌸', 'thu');
await shot(thu, 'thu-3-dial');
await thu.getByText('Chạy bộ', { exact: true }).first().click();
await thu.waitForTimeout(250);
await shot(thu, 'thu-4-tap-effect');

const khoa = await open('khoa');
await onboard(khoa, 'Khoa', '🐻', 'khoa');

const a = await account(thu), b = await account(khoa);
const H = (t) => ({ 'content-type': 'application/json', authorization: `Bearer ${t}` });
let r = await fetch(`${API}/friends`, { method: 'POST', headers: H(b.token), body: JSON.stringify({ username: a.username }) });
console.log('friend', r.status);
r = await fetch(`${API}/shares/${crypto.randomUUID()}`, {
  method: 'PUT', headers: H(a.token),
  body: JSON.stringify({ emoji: '🏃', name: 'Chạy bộ', occurredAt: new Date().toISOString() }),
});
console.log('share', r.status);

// Khoa mở bảng tin, chọn Thư trên thanh Stories -> "Ngày của Thư"
await khoa.getByRole('button', { name: /Bảng tin bạn bè/ }).click();
await khoa.waitForTimeout(2000);
await shot(khoa, 'khoa-5-feed');
await khoa.getByRole('button', { name: 'Thư', exact: true }).click();
await khoa.waitForTimeout(1200);
await shot(khoa, 'khoa-6-day-of-thu');
await khoa.getByRole('button', { name: 'Tất cả', exact: true }).click();
await khoa.waitForTimeout(600);

// Khoa thả tim -> Thư nhận thông báo realtime
await khoa.getByRole('button', { name: /Yêu thích/ }).first().click();
await khoa.waitForTimeout(250);
await shot(khoa, 'khoa-7-burst');
await thu.waitForTimeout(2500);
await shot(thu, 'thu-8-realtime-banner');

// Thư: thống kê -> ảnh tóm tắt
await thu.getByRole('button', { name: 'Lịch sử & thống kê' }).click();
await thu.waitForTimeout(1200);
await tap(thu, 'Tuần');
await thu.getByRole('button', { name: 'Tạo ảnh tóm tắt' }).click();
await thu.waitForTimeout(1200);
await shot(thu, 'thu-9-recap');

await browser.close();
console.log('ok ->', OUT);
