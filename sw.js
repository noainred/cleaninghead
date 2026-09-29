/* BrainBloom Service Worker — 런타임 캐싱 전용 (precache 목록 없음, 릴리스마다 수정 불필요)
 *
 * 전략 (2026-08-10 성능 감사 설계, 검증자 교정 반영):
 *  - 내비게이션(HTML): network-first — fetch(req, {cache:'no-cache'})로 HTTP 캐시를 재검증해
 *    새 배포가 10분 캐시에 가려지지 않게 하고, 오프라인일 때만 캐시 폴백(오프라인 기동 지원).
 *    (navigation preload는 no-cache 재검증과 양립하지 않아 의도적으로 쓰지 않음)
 *  - unpkg CDN·fonts.gstatic(버전 고정/불변 URL): cache-first — HTTP 캐시에서 축출돼도 재다운로드 방지
 *  - fonts.googleapis CSS·같은 origin 정적 자산: stale-while-revalidate
 *  - 그 외(구글 드라이브 API·GIS·GA 등): 개입하지 않음(respondWith 미호출 → 브라우저 기본 동작)
 *
 * 업데이트: 새 sw.js는 skipWaiting + clients.claim으로 즉시 활성화.
 * 캐시 구조를 바꿀 땐 CACHE 버전을 올리면 activate에서 옛 캐시가 삭제된다.
 */
const CACHE = 'bb-rt-v1';

self.addEventListener('install', () => { self.skipWaiting(); });

self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

const CDN_HOSTS = ['unpkg.com', 'fonts.gstatic.com'];
const SWR_HOSTS = ['fonts.googleapis.com'];

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  let url;
  try { url = new URL(req.url); } catch (_) { return; }
  if (url.protocol !== 'https:' && url.protocol !== 'http:') return;

  // ── 내비게이션(HTML): 네트워크 우선(재검증 강제) → 실패 시 캐시 폴백 ──
  if (req.mode === 'navigate') {
    e.respondWith((async () => {
      const cache = await caches.open(CACHE);
      try {
        const res = await fetch(req, { cache: 'no-cache' });
        if (res && res.ok) cache.put(req, res.clone());
        return res;
      } catch (err) {
        // 오프라인 폴백 — 기본 match는 쿼리까지 정확 일치라 '/index.html?app'으로 캐시된 것을
        // '/'로 진입하면 miss가 났다(v3.104.2 수정): 쿼리 무시 → 루트 → index.html 순으로 넓혀 찾는다.
        const hit = await cache.match(req, { ignoreSearch: true })
          || await cache.match('/')
          || await cache.match('/index.html', { ignoreSearch: true });
        if (hit) return hit;
        throw err;
      }
    })());
    return;
  }

  // ── 버전 고정 CDN·폰트 파일: cache-first ──
  if (CDN_HOSTS.includes(url.hostname)) {
    e.respondWith((async () => {
      const cache = await caches.open(CACHE);
      const hit = await cache.match(req);
      if (hit) return hit;
      const res = await fetch(req);
      // script/link에 crossorigin이 붙어 있어 정상 응답은 CORS(비-opaque)로 온다.
      // 만약의 opaque도 CDN은 URL이 버전 고정이라 캐시해도 안전.
      if (res && (res.ok || res.type === 'opaque')) cache.put(req, res.clone());
      return res;
    })());
    return;
  }

  // ── 폰트 CSS·같은 origin 정적 자산: stale-while-revalidate ──
  if (SWR_HOSTS.includes(url.hostname) || url.origin === self.location.origin) {
    e.respondWith((async () => {
      const cache = await caches.open(CACHE);
      const hit = await cache.match(req);
      const refetch = fetch(req).then((res) => {
        if (res && res.ok) cache.put(req, res.clone()); // 오류·opaque 응답은 캐시하지 않음
        return res;
      }).catch(() => hit);
      return hit || refetch;
    })());
    return;
  }
  // 그 외 호스트(구글 API 등)는 개입하지 않는다.
});
