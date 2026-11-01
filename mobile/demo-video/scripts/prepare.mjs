// Dựng dữ liệu cho lượt quay: tài khoản "Thư" (🌸) trên backend local kèm một tuần nhật ký trên máy,
// và video camera giả chứa mã QR thật của Thư để máy "Khoa" quét bằng camera của app.
// Dùng: node scripts/prepare.mjs   (backend local phải đang chạy ở :8787)
import fs from 'fs';
import { execFileSync } from 'child_process';
import QRCode from 'qrcode';

const API = process.env.DEMO_API_URL || 'http://localhost:8787/api';
const OUT = 'demo-out/prep';
fs.mkdirSync(OUT, { recursive: true });

async function call(method, path, body, token) {
  const res = await fetch(API + path, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => null);
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${JSON.stringify(json)}`);
  return json.data;
}

const reg = await call('POST', '/auth/register', { displayName: 'Thư' });
await call('PATCH', '/me', { displayName: 'Thư', avatarEmoji: '🌸' }, reg.token);
const account = { id: reg.user.id, displayName: 'Thư', avatarEmoji: '🌸', inviteCode: reg.user.inviteCode, token: reg.token };

// --- Một tuần (Thứ Hai -> hôm nay) theo giờ VN: 5 ngày Tập trung, ngủ muộn, 15 ly cà phê ---
const VN = 7 * 3600e3;
const now = Date.now();
const vnNow = new Date(now + VN);
const vnMidnight = Date.UTC(vnNow.getUTCFullYear(), vnNow.getUTCMonth(), vnNow.getUTCDate()) - VN; // 00:00 VN hôm nay (UTC ms)
const weekday = (vnNow.getUTCDay() + 6) % 7; // 0 = Thứ Hai
const at = (dayOffset, h, m) => vnMidnight + dayOffset * 86400e3 + (h * 60 + m) * 60e3;
const T = {
  coffee: ['Cà phê', '☕'], focus: ['Tập trung', '💻'], sleep: ['Ngủ', '🌙'], eating: ['Ăn uống', '🍽️'],
  water: ['Nước', '💧'], running: ['Chạy bộ', '🏃'], reading: ['Đọc sách', '📖'], music: ['Nghe nhạc', '🎧'],
};
const logs = [];
const add = (type, t) => { if (t < now - 60e3) logs.push({ type, t }); };
let coffees = 0;
for (let d = -weekday; d <= 0; d++) {
  const dow = weekday + d; // 0..6
  const workday = dow < 5;
  add('eating', at(d, 7, 40));
  if (workday) { add('focus', at(d, 8, 50)); add('eating', at(d, 12, 15)); }
  // cà phê: 3 ly ngày thường, 1 ly cuối tuần — tổng 15 với 5 ngày làm việc
  const cups = workday ? [[8, 20], [10, 30], [15, 0]] : [[9, 30]];
  for (const [h, m] of cups) if (coffees < 15) { add('coffee', at(d, h, m)); coffees++; }
  add('water', at(d, 11, 0));
  if (d < 0) add('sleep', at(d + 1, 0, 40)); // ngủ muộn: 00:40 sáng hôm sau
  if (dow === 2 || dow === 5) add('running', at(d, 6, 30));
  if (dow === 3) add('reading', at(d, 21, 15));
  if (dow === 4) add('music', at(d, 22, 0));
}
const uuid = () => crypto.randomUUID();
const activityLogs = logs
  .sort((a, b) => b.t - a.t)
  .map(({ type, t }) => ({
    id: uuid(), eventTypeId: type, name: T[type][0], emoji: T[type][1],
    occurredAt: new Date(t).toISOString(), visibility: 'private', syncStatus: 'synced',
  }));

const seed = { account, logs: activityLogs };
fs.writeFileSync(`${OUT}/seed.json`, JSON.stringify(seed, null, 2));

// --- QR + camera giả ---
const qrPng = `${OUT}/thu-qr.png`;
await QRCode.toFile(qrPng, `CHAM:${account.inviteCode}`, { width: 360, margin: 2, errorCorrectionLevel: 'H' });
// Khung 640x480: QR trên nền giấy, lắc nhẹ như tay cầm điện thoại.
execFileSync('ffmpeg', ['-y', '-v', 'error', '-loop', '1', '-i', qrPng, '-f', 'lavfi', '-i', 'color=c=0xEDE6DC:s=760x600:d=20',
  '-filter_complex', "[1][0]overlay=x='200+14*sin(t*1.7)':y='120+10*cos(t*1.3)':shortest=1,crop=640:480:60:60,format=yuv420p",
  '-r', '30', '-t', '20', `${OUT}/qr-camera.y4m`]);

console.log(`Thư: ${account.inviteCode} · ${activityLogs.length} bản ghi (${coffees} cà phê) -> ${OUT}`);
