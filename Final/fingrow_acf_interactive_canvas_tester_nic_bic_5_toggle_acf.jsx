import React, { useMemo, useState } from "react";

/**
 * Fingrow ACF — Interactive Canvas Tester (NIC/BIC, 5×, Toggle ACF)
 * -----------------------------------------------------------------
 * เวอร์ชันนี้ปรับชื่อฟิลด์ให้ตรงกับตาราง `users`:
 * - id, run_number, parent_id, child_count, max_children, acf_accepting,
 *   inviter_id, invite_code, created_at, level, max_network
 *
 * ยังเป็นระบบจำลองใน frontend (ยังไม่ต่อ DB จริง)
 * แต่โครงสร้างฟิลด์ตรงกับฐานข้อมูลแล้ว พร้อมต่อ API/SQL ภายหลัง
 */

// ---------------- Types ----------------
type User = {
  id: string;                 // e.g. "25AAA0001" (ใช้แทน users.id ในเดโมนี้)
  run_number: number;         // insertion/run order
  parent_id: string | null;
  child_count: number;
  max_children: number;
  acf_accepting: boolean;
  inviter_id?: string | null;
  invite_code?: string | null;
  created_at: number;         // epoch ms
  level: number;              // depth from GLOBAL root
  max_network?: number;       // DEFAULT 19531 (ถ้ามีใน DB)
};

type Mode = "NIC" | "BIC";

const SYSTEM_ROOT_ID = "25AAA0000";      // id ของ root ระบบ
const DEFAULT_ACF_ROOT_ID = "25AAA0001"; // id ของ ACF root ดีฟอลต์ (คนแรกที่สมัคร)
const MAX_NETWORK = 19531;               // (5^7 - 1) / 4 for levels 0..6 inclusive

// ---------------- Utilities ----------------
function getNow() {
  return Date.now();
}

// ID generator: YY + AAA + NNNN (e.g., 25AAA0001)
function twoDigitYear(date = new Date()): string {
  return String(date.getFullYear() % 100).padStart(2, "0");
}

function makeUserId(seq: number, letters = "AAA", date = new Date()): string {
  const yy = twoDigitYear(date);
  const num = String(seq).padStart(4, "0");
  return `${yy}${letters}${num}`;
}

// ใช้ id / parent_id เหมือน DB
function buildIndex(users: User[]) {
  const byId = new Map<string, User>();
  const children = new Map<string, User[]>();
  for (const u of users) byId.set(u.id, u);
  for (const u of users) {
    if (!u.parent_id) continue;
    const list = children.get(u.parent_id) ?? [];
    list.push(u);
    children.set(u.parent_id, list);
  }
  return { byId, children };
}

function bfsSubtree(users: User[], rootId: string): Set<string> {
  const { children } = buildIndex(users);
  const out = new Set<string>();
  const q: string[] = [rootId];
  while (q.length) {
    const id = q.shift()!;
    if (out.has(id)) continue;
    out.add(id);
    const ch = children.get(id) ?? [];
    for (const c of ch) q.push(c.id);
  }
  return out;
}

function relativeDepthMap(users: User[], rootId: string): Map<string, number> {
  const { children } = buildIndex(users);
  const depth = new Map<string, number>();
  const q: Array<{ id: string; d: number }> = [{ id: rootId, d: 0 }];
  while (q.length) {
    const { id, d } = q.shift()!;
    if (depth.has(id)) continue;
    depth.set(id, d);
    const ch = children.get(id) ?? [];
    for (const c of ch) q.push({ id: c.id, d: d + 1 });
  }
  return depth;
}

function computeGlobalLevel(users: User[], userId: string): number {
  const { byId } = buildIndex(users);
  let level = 0;
  let cur = byId.get(userId);
  while (cur && cur.parent_id) {
    level += 1;
    cur = byId.get(cur.parent_id);
  }
  return level;
}

// NIC ordering: depthFromAcfRoot → child_count → created_at → run_number
function cmpNICWithDepth(depth: Map<string, number>) {
  return (a: User, b: User) => {
    const da = depth.get(a.id) ?? Number.POSITIVE_INFINITY;
    const db = depth.get(b.id) ?? Number.POSITIVE_INFINITY;
    if (da !== db) return da - db;
    const aCC = a.child_count ?? 0;
    const bCC = b.child_count ?? 0;
    if (aCC !== bCC) return aCC - bCC;
    if (a.created_at !== b.created_at) return a.created_at - b.created_at;
    return a.run_number - b.run_number;
  };
}

// BIC ordering: inviter-relative depth → child_count → created_at → run_number
function cmpBIC(depth: Map<string, number>) {
  return (a: User, b: User) => {
    const da = depth.get(a.id) ?? Number.POSITIVE_INFINITY;
    const db = depth.get(b.id) ?? Number.POSITIVE_INFINITY;
    if (da !== db) return da - db;
    const aCC = a.child_count ?? 0;
    const bCC = b.child_count ?? 0;
    if (aCC !== bCC) return aCC - bCC;
    if (a.created_at !== b.created_at) return a.created_at - b.created_at;
    return a.run_number - b.run_number;
  };
}

// ใช้ id แสดงเป็น "User ID" (ตอนต่อ DB จริง จะตรงกับ users.id เลย)
function displayUserCode(u: User): string {
  return u.id;
}

// ---------------- UI atoms ----------------
function Badge({
  label,
  tone = "default",
}: {
  label: React.ReactNode;
  tone?: "default" | "ok" | "warn" | "crit";
}) {
  const t =
    tone === "ok"
      ? "bg-green-600 text-white"
      : tone === "warn"
      ? "bg-amber-500 text-white"
      : tone === "crit"
      ? "bg-rose-600 text-white"
      : "bg-gray-100 text-gray-800 border";
  return <span className={`text-xs px-2 py-0.5 rounded-full ${t}`}>{label}</span>;
}

function SlotBar({ count = 0, max = 0 }: { count?: number; max?: number }) {
  const safeMax = Math.max(0, max | 0);
  const safeCount = Math.max(0, Math.min(count | 0, safeMax));
  const slots = Array.from({ length: safeMax });
  return (
    <div className="flex gap-1">
      {slots.map((_, i) => {
        const filled = i < safeCount;
        return (
          <div
            key={i}
            className={`w-3 h-3 rounded-sm ${filled ? "bg-blue-600" : "bg-gray-200"}`}
            title={`${i + 1}/${safeMax}`}
          />
        );
      })}
    </div>
  );
}

function UserCard({
  u,
  onSelect,
  selected,
}: {
  u: User;
  onSelect: (id: string) => void;
  selected: boolean;
}) {
  const cc = u.child_count ?? 0;
  const mx = u.max_children ?? 0;
  const full = cc >= mx && mx > 0;
  return (
    <button
      onClick={() => onSelect(u.id)}
      className={`text-left w-full border rounded-2xl p-4 transition shadow-sm hover:shadow-md ${
        selected ? "border-blue-500 ring-2 ring-blue-200" : "border-gray-200"
      }`}
    >
      <div className="flex items-center gap-4">
        <div className="w-12 h-12 rounded-full bg-gray-900 text-white flex items-center justify-center text-sm font-semibold">
          {u.id === SYSTEM_ROOT_ID ? "R" : u.run_number}
        </div>
        <div className="flex-1 min-w-0">
          <div className="font-semibold text-base truncate">{displayUserCode(u)}</div>
          <div className="text-xs text-gray-500">run #{u.run_number} • level {u.level ?? 0}</div>
          <div className="mt-2 flex items-center gap-2">
            <SlotBar count={cc} max={mx} />
            <Badge label={`child ${cc}/${mx}`} tone={full ? "warn" : "default"} />
            <Badge label={u.acf_accepting ? "ACF: ON" : "ACF: OFF"} tone={u.acf_accepting ? "ok" : "crit"} />
          </div>
        </div>
      </div>
    </button>
  );
}

function TreeBranch({
  users,
  rootId,
  onSelect,
}: {
  users: User[];
  rootId: string;
  onSelect: (id: string) => void;
}) {
  const { children, byId } = useMemo(() => buildIndex(users), [users]);

  function renderNode(id: string): React.ReactNode {
    const u = byId.get(id);
    if (!u) return null;
    const ch = (children.get(id) ?? []).sort((a, b) => a.run_number - b.run_number);
    const cc = u.child_count ?? 0;
    const mx = u.max_children ?? 0;
    const full = cc >= mx && mx > 0;
    return (
      <div key={id} className="ml-4">
        <div className="flex items-center gap-3 py-1">
          <button
            onClick={() => onSelect(id)}
            className={`text-sm font-medium underline-offset-2 hover:underline ${
              id === rootId ? "text-blue-700" : ""
            }`}
          >
            {displayUserCode(u)}
          </button>
          <SlotBar count={cc} max={mx} />
          <Badge label={u.acf_accepting ? "ON" : "OFF"} tone={u.acf_accepting ? "ok" : "crit"} />
          <Badge label={`${cc}/${mx}`} tone={full ? "warn" : "default"} />
        </div>
        {ch.length > 0 && (
          <div className="border-l-2 border-gray-200 pl-4 mt-1 space-y-2">
            {ch.map((c) => renderNode(c.id))}
          </div>
        )}
      </div>
    );
  }

  return <div className="text-sm leading-6">{renderNode(rootId)}</div>;
}

// ---------------- UsersTable ----------------
function UsersTable({
  users,
  selectedUser,
  onSelect,
  onToggleAccept,
  onSetMax,
}: {
  users: User[];
  selectedUser: string;
  onSelect: (id: string) => void;
  onToggleAccept: (id: string) => void;
  onSetMax: (id: string, max: number) => void;
}) {
  const { children } = useMemo(() => buildIndex(users), [users]);
  const rows = useMemo(() => [...users].sort((a, b) => a.run_number - b.run_number), [users]);

  // subtree size (including self)
  const subtreeSize = useMemo(() => {
    const memo = new Map<string, number>();
    const dfs = (id: string): number => {
      if (memo.has(id)) return memo.get(id)!;
      const ch = children.get(id) ?? [];
      let sum = 1;
      for (const c of ch) sum += dfs(c.id);
      memo.set(id, sum);
      return sum;
    };
    for (const u of users) dfs(u.id);
    return memo;
  }, [users, children]);

  const getChildren = (pid: string) =>
    (children.get(pid) ?? [])
      .sort((a, b) => a.run_number - b.run_number)
      .slice(0, 5);

  return (
    <div className="overflow-auto">
      <table className="min-w-full text-sm">
        <thead className="bg-slate-800/80 sticky top-0 z-10">
          <tr className="text-left">
            <th className="px-3 py-2">#</th>
            <th className="px-3 py-2">User ID</th>
            <th className="px-3 py-2">User</th>
            <th className="px-3 py-2">Parent</th>
            <th className="px-3 py-2">Level</th>
            <th className="px-3 py-2">Network</th>
            <th className="px-3 py-2">Max</th>
            <th className="px-3 py-2">Count</th>
            <th className="px-3 py-2">ACF</th>
            <th className="px-3 py-2" colSpan={5}>
              Child #1–#5
            </th>
          </tr>
        </thead>
        <tbody>
          {rows.map((u) => {
            const ch = getChildren(u.id);
            const cc = u.child_count ?? 0;
            const mx = u.max_children ?? 0;
            const full = cc >= mx && mx > 0;
            const networkSize = subtreeSize.get(u.id) ?? 1;
            return (
              <tr
                key={u.id}
                className={`border-t border-slate-700/50 ${selectedUser === u.id ? "bg-slate-800/40" : ""}`}
              >
                <td className="px-3 py-2 font-mono">{u.run_number}</td>
                <td className="px-3 py-2 font-mono">{displayUserCode(u)}</td>
                <td className="px-3 py-2">
                  <button
                    onClick={() => onSelect(u.id)}
                    className="underline underline-offset-2 hover:opacity-80"
                  >
                    {displayUserCode(u)}
                  </button>
                </td>
                <td className="px-3 py-2 font-mono opacity-80">{u.parent_id ?? "—"}</td>
                <td className="px-3 py-2">{u.level ?? 0}</td>
                <td className="px-3 py-2 font-mono">
                  <span title="รวมสมาชิกในเครือข่ายรวมตัวเอง">
                    {networkSize}/{u.max_network ?? MAX_NETWORK}
                  </span>
                </td>
                <td className="px-3 py-2">
                  <select
                    value={mx}
                    onChange={(e) => onSetMax(u.id, parseInt(e.target.value, 10))}
                    className="rounded px-2 py-1 bg-transparent border border-slate-600"
                  >
                    {[1, 2, 3, 4, 5].map((m) => (
                      <option key={m} value={m}>
                        {m}
                      </option>
                    ))}
                  </select>
                </td>
                <td className="px-3 py-2">
                  <Badge label={`${cc}/${mx}`} tone={full ? "warn" : "default"} />
                </td>
                <td className="px-3 py-2">
                  <button
                    onClick={() => onToggleAccept(u.id)}
                    className={`px-2 py-1 rounded-lg border ${
                      u.acf_accepting
                        ? "border-emerald-500 text-emerald-400"
                        : "border-rose-500 text-rose-400"
                    }`}
                  >
                    {u.acf_accepting ? "ON" : "OFF"}
                  </button>
                </td>
                {[0, 1, 2, 3, 4].map((i) => (
                  <td key={i} className="px-2 py-2">
                    {ch[i] ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-slate-700/60">
                        <span className="font-mono text-xs">{ch[i].run_number}</span>
                        <span className="opacity-80">{displayUserCode(ch[i])}</span>
                      </span>
                    ) : (
                      <span className="opacity-40">—</span>
                    )}
                  </td>
                ))}
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

// ---------------- Main Component ----------------
export default function ACFCanvasTester() {
  // nextSeq: 0 reserved for SYSTEM_ROOT_ID; start from 1 for first signup
  const [nextSeq, setNextSeq] = useState<number>(1);

  const [users, setUsers] = useState<User[]>(() => {
    const root: User = {
      id: SYSTEM_ROOT_ID,
      run_number: 0,
      parent_id: null,
      child_count: 0,
      max_children: 1,
      acf_accepting: true,
      inviter_id: null,
      invite_code: null,
      created_at: getNow(),
      level: 0,
      max_network: MAX_NETWORK,
    };
    return [root];
  });

  const [lastRun, setLastRun] = useState(0);
  const [selectedUser, setSelectedUser] = useState<string>(SYSTEM_ROOT_ID);

  // ACF root (ใช้สำหรับ NIC)
  const [acfRootId, setAcfRootId] = useState<string>(DEFAULT_ACF_ROOT_ID);

  const [bicInviter, setBicInviter] = useState<string>(SYSTEM_ROOT_ID);
  const [batch, setBatch] = useState<number>(5);

  // Settings
  const [respectACF, setRespectACF] = useState(true);
  const [defaultAcceptACF, setDefaultAcceptACF] = useState(true);
  const [autoCloseWhenFull, setAutoCloseWhenFull] = useState(true);

  const sortedUsers = useMemo(() => [...users].sort((a, b) => a.run_number - b.run_number), [users]);

  // refresh level ทุกครั้งที่โครงสร้างเปลี่ยน
  function recomputeGlobalLevels(list: User[]) {
    for (const u of list) u.level = computeGlobalLevel(list, u.id);
  }

  // ถ้า ACF root ยังไม่มีใน list ให้ fallback เป็น root ระบบ
  const actualAcfRoot = useMemo(() => {
    const exists = users.some((u) => u.id === acfRootId);
    return exists ? acfRootId : SYSTEM_ROOT_ID;
  }, [acfRootId, users]);

  // NIC candidates
  const nicTop = useMemo(() => {
    const subtree = bfsSubtree(users, actualAcfRoot);
    const depth = relativeDepthMap(users, actualAcfRoot);
    const pool = users.filter(
      (u) =>
        subtree.has(u.id) &&
        u.id !== SYSTEM_ROOT_ID &&
        (u.child_count ?? 0) < (u.max_children ?? 0) &&
        (!respectACF || u.acf_accepting)
    );
    return pool.sort(cmpNICWithDepth(depth)).slice(0, 5);
  }, [users, respectACF, actualAcfRoot]);

  // BIC candidates
  const bicTop = useMemo(() => {
    const subtree = bfsSubtree(users, bicInviter);
    const depth = relativeDepthMap(users, bicInviter);
    const pool = users.filter(
      (u) =>
        subtree.has(u.id) &&
        (u.child_count ?? 0) < (u.max_children ?? 0) &&
        (!respectACF || u.acf_accepting)
    );
    return pool.sort(cmpBIC(depth)).slice(0, 5);
  }, [users, bicInviter, respectACF]);

  function pickParent(mode: Mode, list: User[]): User | null {
    if (mode === "NIC") {
      const subtree = bfsSubtree(list, actualAcfRoot);
      const depth = relativeDepthMap(list, actualAcfRoot);
      const pool = list.filter(
        (u) =>
          subtree.has(u.id) &&
          u.id !== SYSTEM_ROOT_ID &&
          (u.child_count ?? 0) < (u.max_children ?? 0) &&
          (!respectACF || u.acf_accepting)
      );
      return pool.sort(cmpNICWithDepth(depth))[0] ?? null;
    } else {
      const subtree = bfsSubtree(list, bicInviter);
      const depth = relativeDepthMap(list, bicInviter);
      const pool = list.filter(
        (u) =>
          subtree.has(u.id) &&
          (u.child_count ?? 0) < (u.max_children ?? 0) &&
          (!respectACF || u.acf_accepting)
      );
      return pool.sort(cmpBIC(depth))[0] ?? null;
    }
  }

  function addOne(mode: Mode) {
    setUsers((prev) => {
      const copy = structuredClone(prev) as User[];
      const parent = pickParent(mode, copy);
      if (!parent) {
        alert(
          mode === "NIC"
            ? "NIC: ไม่มีผู้เปิดรับ/ที่ว่างในเลเยอร์ปัจจุบันภายใต้ ACF Root"
            : "BIC: เครือข่ายผู้เชิญไม่มีที่ว่าง/ไม่เปิดรับ"
        );
        return prev;
      }
      const newRun = lastRun + 1;
      const newId = makeUserId(nextSeq); // id = 25AAA0001, 25AAA0002, ...
      const newUser: User = {
        id: newId,
        run_number: newRun,
        parent_id: parent.id,
        child_count: 0,
        max_children: 5,
        acf_accepting: defaultAcceptACF,
        inviter_id: mode === "BIC" ? bicInviter : null,
        invite_code: mode === "BIC" ? `INV-${bicInviter}` : null,
        created_at: getNow(),
        level: 0,
        max_network: MAX_NETWORK,
      };
      copy.push(newUser);

      const p = copy.find((u) => u.id === parent.id)!;
      p.child_count = (p.child_count ?? 0) + 1;
      if (autoCloseWhenFull && (p.child_count ?? 0) >= (p.max_children ?? 0)) {
        p.acf_accepting = false;
      }

      recomputeGlobalLevels(copy);
      setLastRun(newRun);
      setNextSeq(nextSeq + 1);
      setSelectedUser(parent.id);
      return copy;
    });
  }

  function addBatchNIC(n: number) {
    for (let i = 0; i < n; i += 1) addOne("NIC");
  }

  function toggleAccept(uid: string) {
    setUsers((prev) =>
      prev.map((u) => {
        if (u.id !== uid) return u;
        if (!u.acf_accepting) {
          const canOpen = (u.child_count ?? 0) < (u.max_children ?? 0);
          return { ...u, acf_accepting: canOpen };
        }
        return { ...u, acf_accepting: false };
      })
    );
  }

  function setMax(uid: string, max: number) {
    const newMax = Math.max(1, Math.min(5, max | 0));
    setUsers((prev) =>
      prev.map((u) =>
        u.id === uid
          ? {
              ...u,
              max_children: newMax,
              acf_accepting:
                (u.child_count ?? 0) < newMax ? u.acf_accepting : false,
            }
          : u
      )
    );
  }

  function setSubtreeAccept(rootId: string, accept: boolean) {
    setUsers((prev) => {
      const ids = bfsSubtree(prev, rootId);
      return prev.map((u) =>
        ids.has(u.id)
          ? {
              ...u,
              acf_accepting: accept
                ? (u.child_count ?? 0) < (u.max_children ?? 0)
                : false,
            }
          : u
      );
    });
  }

  function CandidateList({ title, list }: { title: string; list: User[] }) {
    return (
      <div className="border rounded-2xl p-3 bg-slate-800/40 border-slate-600">
        <div className="flex items-center justify-between mb-2">
          <h3 className="font-semibold">{title}</h3>
          <span className="text-xs opacity-70">ลำดับ (layer-first)</span>
        </div>
        {list.length === 0 ? (
          <div className="text-sm text-rose-400">ไม่มีผู้เปิดรับ/ที่ว่าง</div>
        ) : (
          <ol className="space-y-1">
            {list.map((u, idx) => {
              const cc = u.child_count ?? 0;
              const mx = u.max_children ?? 0;
              const full = cc >= mx && mx > 0;
              return (
                <li key={u.id} className="flex items-center gap-3 text-sm">
                  <div className="w-6 h-6 rounded-full bg-gray-900 text-white flex items-center justify-center text-xs">
                    {idx + 1}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="truncate font-medium">
                      {displayUserCode(u)}{" "}
                      <span className="text-xs opacity-70">(run {u.run_number})</span>
                    </div>
                    <div className="flex items-center gap-2 mt-0.5">
                      <Badge label={`level ${u.level ?? 0}`} />
                      <SlotBar count={cc} max={mx} />
                      <Badge label={`${cc}/${mx}`} tone={full ? "warn" : "default"} />
                      <Badge label={u.acf_accepting ? "ON" : "OFF"} tone={u.acf_accepting ? "ok" : "crit"} />
                    </div>
                  </div>
                </li>
              );
            })}
          </ol>
        )}
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-900 via-slate-900 to-slate-950 text-slate-100 p-6 max-w-7xl mx-auto space-y-6">
      <header className="flex flex-col md:flex-row md:items-end md:justify-between gap-2">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight">Fingrow ACF — Interactive Canvas Tester</h1>
          <p className="text-sm opacity-70 mt-1">
            System Root:{" "}
            <span className="font-mono bg-slate-100 text-slate-900 px-2 py-0.5 rounded">
              {SYSTEM_ROOT_ID}
            </span>
          </p>
        </div>
        <div className="text-xs opacity-70">
          ACF: Layer-first (BFS) • Respect ACF: {respectACF ? "ON" : "OFF"}
        </div>
      </header>

      {/* Settings */}
      <section className="bg-slate-800/60 backdrop-blur rounded-2xl p-5 border border-slate-700/50 shadow">
        <h2 className="text-xl font-semibold mb-3">ACF Settings</h2>
        <div className="grid md:grid-cols-2 gap-4 text-sm">
          <div className="space-y-2">
            <div className="text-xs opacity-80">
              ACF Root (ใช้คัด NIC layer-first ภายใต้เครือข่ายนี้)
            </div>
            <div className="flex gap-2 items-center flex-wrap">
              <select
                value={acfRootId}
                onChange={(e) => setAcfRootId(e.target.value)}
                className="border rounded-lg px-3 py-2 bg-slate-900 text-slate-100 border-slate-600 focus:outline-none focus:ring-2 focus:ring-sky-600 appearance-none"
              >
                {sortedUsers.map((u) => (
                  <option key={u.id} value={u.id} className="bg-slate-900 text-slate-100">
                    {displayUserCode(u)} (run {u.run_number})
                  </option>
                ))}
              </select>
              <Badge
                label={
                  <span>
                    ใช้จริง:{" "}
                    <span className="font-mono">{actualAcfRoot}</span>
                  </span>
                }
              />
            </div>
            <div className="text-xs opacity-70">
              ค่าเริ่มต้น: {DEFAULT_ACF_ROOT_ID} (ถ้ายังไม่มี จะ fallback เป็น {SYSTEM_ROOT_ID})
            </div>
          </div>

          <div className="space-y-2">
            <div className="text-xs opacity-80">พารามิเตอร์</div>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                className="scale-110"
                checked={respectACF}
                onChange={(e) => setRespectACF(e.target.checked)}
              />{" "}
              พิจารณาเฉพาะผู้ที่เปิดรับ ACF
            </label>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                className="scale-110"
                checked={defaultAcceptACF}
                onChange={(e) => setDefaultAcceptACF(e.target.checked)}
              />{" "}
              สมาชิกใหม่เปิดรับ ACF อัตโนมัติ
            </label>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                className="scale-110"
                checked={autoCloseWhenFull}
                onChange={(e) => setAutoCloseWhenFull(e.target.checked)}
              />{" "}
              ปิดรับอัตโนมัติเมื่อเต็ม
            </label>
          </div>
        </div>
      </section>

      {/* Controls + Live Candidates */}
      <section className="grid lg:grid-cols-3 gap-4">
        <div className="rounded-2xl p-4 space-y-3 bg-slate-800/60 border border-slate-700/50">
          <h2 className="font-semibold text-lg">Add via NIC</h2>
          <div className="flex flex-wrap items-center gap-2">
            <button
              onClick={() => addOne("NIC")}
              className="px-3 py-2 rounded-xl bg-sky-600 hover:bg-sky-700 text-white"
            >
              Add 1 via NIC
            </button>
            <input
              type="number"
              min={1}
              value={batch}
              onChange={(e) => setBatch(parseInt(e.target.value || "1", 10))}
              className="w-24 rounded-lg px-3 py-2 border border-slate-600 bg-slate-900 text-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-600"
            />
            <button
              onClick={() => addBatchNIC(Math.max(1, batch))}
              className="px-3 py-2 rounded-xl border border-slate-600"
            >
              Add N via NIC
            </button>
          </div>
          <p className="text-xs opacity-70">
            คัด parent ภายใต้ ACF Root:{" "}
            <span className="font-mono">{actualAcfRoot}</span> • ชั้นตื้นก่อน → child → เวลา
          </p>
          <CandidateList title="NIC Candidate (Top 5)" list={nicTop} />
        </div>

        <div className="rounded-2xl p-4 space-y-3 bg-slate-800/60 border border-slate-700/50">
          <h2 className="font-semibold text-lg">Add via BIC</h2>
          <div className="flex items-center gap-2">
            <select
              aria-label="Select inviter"
              value={bicInviter}
              onChange={(e) => setBicInviter(e.target.value)}
              className="rounded-lg px-3 py-2 border border-slate-600 bg-slate-900 text-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-600 appearance-none"
            >
              {sortedUsers.map((u) => (
                <option key={u.id} value={u.id} className="bg-slate-900 text-slate-100">
                  {displayUserCode(u)} (run {u.run_number})
                </option>
              ))}
            </select>
            <button
              onClick={() => addOne("BIC")}
              className="px-3 py-2 rounded-xl bg-sky-600 hover:bg-sky-700 text-white"
            >
              Add via BIC
            </button>
          </div>
          <p className="text-xs opacity-70">
            จำกัดใต้เครือข่ายผู้เชิญ: ชั้นใกล้ผู้เชิญก่อน → child → เวลา
          </p>
          <CandidateList title="BIC Candidate (Top 5)" list={bicTop} />
        </div>

        <div className="rounded-2xl p-4 space-y-3 bg-slate-800/60 border border-slate-700/50">
          <h2 className="font-semibold text-lg">Tree Focus</h2>
          <div className="flex items-center gap-2">
            <select
              value={selectedUser}
              onChange={(e) => setSelectedUser(e.target.value)}
              className="rounded-lg px-3 py-2 border border-slate-600 bg-slate-900 text-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-600 appearance-none"
            >
              {sortedUsers.map((u) => (
                <option key={u.id} value={u.id} className="bg-slate-900 text-slate-100">
                  {displayUserCode(u)} (run {u.run_number})
                </option>
              ))}
            </select>
            <span className="text-xs opacity-70">แสดงเครือข่ายย่อย</span>
          </div>
          <div className="text-xs opacity-70">
            รวม {bfsSubtree(users, selectedUser).size} คนในเครือข่ายนี้
          </div>
          <div className="text-xs opacity-70">Tip: คลิกชื่อใน Tree เพื่อ focus</div>
        </div>
      </section>

      {/* Tree View */}
      <section className="rounded-2xl p-4 bg-slate-800/60 border border-slate-700/50">
        <h2 className="font-semibold mb-3 text-lg">Subtree Viewer</h2>
        <TreeBranch users={users} rootId={selectedUser} onSelect={setSelectedUser} />
      </section>

      {/* Users Table */}
      <section className="rounded-2xl p-4 bg-slate-800/60 border border-slate-700/50">
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-semibold text-lg">Users Table (Child 1–#5)</h2>
          <div className="text-xs opacity-70">คลิก User เพื่อโฟกัส / ปรับ Max / สลับ ACF</div>
        </div>
        <UsersTable
          users={users}
          selectedUser={selectedUser}
          onSelect={setSelectedUser}
          onToggleAccept={toggleAccept}
          onSetMax={setMax}
        />
      </section>

      <footer className="text-xs opacity-70 text-center pb-6">
        SystemRoot={SYSTEM_ROOT_ID} • Default ACF Root={DEFAULT_ACF_ROOT_ID} • NIC scoped to ACF Root • BIC scoped to inviter • Order: depth→child→time→run • Max network={MAX_NETWORK}.
      </footer>
    </div>
  );
}

// ---------------- Dev sanity tests (console only) ----------------
(function runDevTests() {
  try {
    const t0 = getNow();
    const id1 = makeUserId(1);
    const id2 = makeUserId(12);
    console.assert(/^[0-9]{2}[A-Z]{3}[0-9]{4}$/.test(id1) && /^[0-9]{2}[A-Z]{3}[0-9]{4}$/.test(id2), "UserId format must be YYAAA####");

    const calcMax = (Math.pow(5, 7) - 1) / 4;
    console.assert(calcMax === MAX_NETWORK, "MAX_NETWORK should equal (5^7-1)/4 for 7 levels");

    const ROOT: User = {
      id: SYSTEM_ROOT_ID,
      run_number: 0,
      parent_id: null,
      child_count: 0,
      max_children: 1,
      acf_accepting: true,
      inviter_id: null,
      invite_code: null,
      created_at: t0 - 1000,
      level: 0,
      max_network: MAX_NETWORK,
    };
    const A: User = {
      id: makeUserId(1),
      run_number: 1,
      parent_id: SYSTEM_ROOT_ID,
      child_count: 0,
      max_children: 5,
      acf_accepting: true,
      inviter_id: null,
      invite_code: null,
      created_at: t0 - 900,
      level: 1,
      max_network: MAX_NETWORK,
    };
    const B: User = {
      id: makeUserId(2),
      run_number: 2,
      parent_id: SYSTEM_ROOT_ID,
      child_count: 0,
      max_children: 5,
      acf_accepting: true,
      inviter_id: null,
      invite_code: null,
      created_at: t0 - 800,
      level: 1,
      max_network: MAX_NETWORK,
    };
    const A1: User = {
      id: makeUserId(3),
      run_number: 3,
      parent_id: A.id,
      child_count: 0,
      max_children: 5,
      acf_accepting: true,
      inviter_id: null,
      invite_code: null,
      created_at: t0 - 700,
      level: 2,
      max_network: MAX_NETWORK,
    };

    const usersBase: User[] = [ROOT, A, B, A1];
    const acfRootWanted = DEFAULT_ACF_ROOT_ID;
    const acfRootActual = usersBase.some((u) => u.id === acfRootWanted) ? acfRootWanted : SYSTEM_ROOT_ID;
    console.assert(acfRootActual === SYSTEM_ROOT_ID, "Fallback to system root if default ACF root not present");

    const depthMap = relativeDepthMap(usersBase, acfRootActual);
    const nicScoped = usersBase.filter((u) => bfsSubtree(usersBase, acfRootActual).has(u.id) && u.id !== SYSTEM_ROOT_ID);
    const nicSorted = nicScoped.sort(cmpNICWithDepth(depthMap)).map((u) => u.id);
    console.assert(nicSorted[0] === A.id || nicSorted[0] === B.id, "[NIC BFS] shallower under ACF root first");

    const depthB = relativeDepthMap(usersBase, B.id);
    const bicScoped = usersBase.filter((u) => bfsSubtree(usersBase, B.id).has(u.id));
    const bicSorted = bicScoped
      .filter((u) => (u.child_count ?? 0) < (u.max_children ?? 0))
      .sort(cmpBIC(depthB))
      .map((u) => u.id);
    console.assert(bicSorted[0] === B.id, "[BIC BFS] inviter at depth 0 first if not full");
  } catch (e) {
    // eslint-disable-next-line no-console
    console.warn("[ACF DevTests] Warning:", e);
  }
})();
