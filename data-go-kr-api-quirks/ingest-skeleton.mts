/**
 * 재사용 가능한 data.go.kr LOCALDATA ingest 스켈레톤.
 *
 * 새 카테고리(음식점/숙박/카페/약국 등) ingest 작성 시 이 파일을 복사한 뒤
 * ENDPOINT, SCHEMA, MATCHING_KEY 만 교체.
 *
 * 사용:
 *   1) 활용신청 받은 ENC 키를 .env.local 에 DATA_GO_KR_ENC_KEY=... 로 저장
 *   2) ENDPOINT 와 매칭 대상(현재 데이터의 phone/address/name 컬럼) 교체
 *   3) node --env-file=.env.local --experimental-strip-types this-script.mts
 *
 * 핵심 패턴:
 *   - ENC 키 verbatim (URL 인코딩 그대로 박기, 더블 인코딩 X)
 *   - numOfRows=100 cap → 페이지네이션 루프
 *   - 매칭 폴백 체인: phone → cleanedAddr+name → name+district
 *   - 결과는 byId 맵으로 — 시설 ID 기준 조회
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";

const ENC_KEY = process.env.DATA_GO_KR_ENC_KEY;
if (!ENC_KEY) {
  console.error("DATA_GO_KR_ENC_KEY not set — add to .env.local");
  process.exit(1);
}

// === 설정 — 교체 대상 ===
const ENDPOINT = "https://apis.data.go.kr/{ORG_ID}/{CATEGORY}/info";
const CURRENT_PATH = "data/{domain}/main.json"; // 우리 시설 목록 (매칭 대상)
const OUTPUT_PATH = "data/{domain}/localdata.json";

// === 유틸 — 재사용 가능 ===
function saveJson(path: string, data: unknown) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, JSON.stringify(data, null, 2) + "\n", "utf8");
}

function normPhone(raw: unknown): string {
  return String(raw ?? "").replace(/\D/g, "");
}

function normName(raw: unknown): string {
  return String(raw ?? "")
    .replace(/\s+/g, "")
    .replace(/[()]/g, "")
    .toLowerCase();
}

function cleanAddress(raw: unknown): string {
  return String(raw ?? "")
    .replace(/[,]?\s*[BbＢ지하]?\s*\d+(\s*[,.~\-]\s*\d+)*\s*[층호]/g, "")
    .replace(/\s*\([^)]*\)\s*$/, "")
    .replace(/[,]\s*$/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

type Item = Record<string, string | null>;

// 페이지네이션 (numOfRows 100 cap)
async function fetchAll(): Promise<Item[]> {
  const PER_PAGE = 100;
  const all: Item[] = [];
  let total = 0;
  for (let page = 1; page <= 30; page++) {
    const url = `${ENDPOINT}?serviceKey=${ENC_KEY}&numOfRows=${PER_PAGE}&pageNo=${page}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status} page=${page}`);
    const json = (await res.json()) as {
      response?: { body?: { items?: { item?: Item[] }; totalCount?: number } };
    };
    const items = json.response?.body?.items?.item ?? [];
    total = json.response?.body?.totalCount ?? total;
    all.push(...items);
    if (items.length === 0 || all.length >= total) break;
  }
  console.log(`fetched ${all.length}/${total}`);
  return all;
}

// === 매칭 ===
type Current = {
  id: string;
  name: string;
  district: string;
  address: string;
  phone: string;
};
const current = JSON.parse(readFileSync(CURRENT_PATH, "utf8")) as Current[];

const byPhone = new Map<string, Current>();
const byAddrName = new Map<string, Current>();
const byNameDistrict = new Map<string, Current>();
for (const c of current) {
  const ph = normPhone(c.phone);
  if (ph.length >= 9) byPhone.set(ph, c);
  byAddrName.set(`${cleanAddress(c.address)}|${normName(c.name)}`, c);
  byNameDistrict.set(`${normName(c.name)}|${c.district}`, c);
}

// === 정규화 — 도메인별로 교체 ===
type Normalized = Record<string, unknown>; // 도메인별 정의

function toNormalized(it: Item): Normalized {
  return {
    // BPLC_NM, TELNO, ROAD_NM_ADDR 등은 LOCALDATA 공통 필드.
    // 카테고리별 추가 필드는 데이터셋 명세 참조.
    name: it.BPLC_NM,
    phone: it.TELNO,
    address: it.ROAD_NM_ADDR,
    status: it.SALS_STTS_NM,
    statusCode: it.SALS_STTS_CD,
    licenseDate: it.LCPMT_YMD,
    closeDate: it.CLSBIZ_YMD,
    lastUpdate: it.DAT_UPDT_PNT,
    managementNo: it.MNG_NO,
    // 도메인 고유 필드 추가...
  };
}

// === Main ===
const items = await fetchAll();

const byId: Record<string, Normalized> = {};
const counters = {
  matchedPhone: 0,
  matchedAddrName: 0,
  matchedNameDistrict: 0,
  unmatched: 0,
};

for (const it of items) {
  const phone = normPhone(it.TELNO);
  const name = normName(it.BPLC_NM);
  const addrKey = `${cleanAddress(it.ROAD_NM_ADDR ?? "")}|${name}`;

  let target: Current | undefined;
  if (phone.length >= 9) target = byPhone.get(phone);
  if (target) counters.matchedPhone++;
  else {
    target = byAddrName.get(addrKey);
    if (target) counters.matchedAddrName++;
  }
  if (!target) {
    const addrTokens = String(it.ROAD_NM_ADDR ?? "").split(/\s+/);
    const district =
      addrTokens.find((t) => /(시|군|구)$/.test(t) && t !== addrTokens[0]) ?? "";
    target = byNameDistrict.get(`${name}|${district}`);
    if (target) counters.matchedNameDistrict++;
  }

  if (!target) {
    counters.unmatched++;
    continue;
  }

  byId[target.id] = toNormalized(it);
}

console.log(
  `matched: phone=${counters.matchedPhone} addrName=${counters.matchedAddrName} nameDistrict=${counters.matchedNameDistrict} unmatched=${counters.unmatched}`,
);
console.log(`coverage: ${Object.keys(byId).length}/${current.length}`);

saveJson(OUTPUT_PATH, {
  fetchedAt: new Date().toISOString(),
  source: ENDPOINT,
  byId,
});

console.log(`-> ${OUTPUT_PATH}`);
