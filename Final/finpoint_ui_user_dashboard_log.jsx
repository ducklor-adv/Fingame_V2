import React from "react";

// ---------- Types ----------

type LedgerEntry = {
  id: number;
  datetime: string;
  category: string;
  detail: string;
  drCr: "DR" | "CR";
  amount: number;
  balanceAfter: number;
};

type ExpProgress = {
  code: "EXP_PRB" | "EXP_CAR" | "EXP_HEALTH";
  label: string;
  target: number;
  current: number;
};

type NetworkSnapshot = {
  networkSize: number;
  fpFromYou: number;
  uplinePath: string[];
};

type UserDashboardProps = {
  userName: string;
  currentFpBalance: number;
  lastUpdated: string;
  todayEarned: number;
  todayFromSecondhand: number;
  todayFromUpline: number;
  expProgressList: ExpProgress[];
  recentLedger: LedgerEntry[];
  networkSnapshot: NetworkSnapshot;
};

// ---------- User Dashboard ----------

export const UserDashboard: React.FC<UserDashboardProps> = ({
  userName,
  currentFpBalance,
  lastUpdated,
  todayEarned,
  todayFromSecondhand,
  todayFromUpline,
  expProgressList,
  recentLedger,
  networkSnapshot,
}) => {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      {/* HEADER */}
      <header className="border-b border-slate-800 bg-slate-900/70 backdrop-blur">
        <div className="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-emerald-400/20 border border-emerald-400/50 flex items-center justify-center text-xs font-bold text-emerald-300">
              FG
            </div>
            <span className="font-semibold text-slate-50">
              Fingrow Finpoint
            </span>
          </div>
          <div className="flex items-center gap-3 text-sm">
            <span className="text-slate-400">สวัสดี,</span>
            <span className="font-medium">{userName}</span>
            <div className="w-8 h-8 rounded-full bg-slate-800 flex items-center justify-center text-xs">
              👤
            </div>
          </div>
        </div>
      </header>

      {/* MAIN CONTENT */}
      <main className="max-w-6xl mx-auto px-4 py-6 space-y-6">
        {/* แถวบน: FP Summary + Today Breakdown */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Card: FP Balance */}
          <div className="md:col-span-2 bg-slate-900/60 border border-slate-800 rounded-2xl p-4 shadow-lg shadow-emerald-500/5">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-sm uppercase tracking-wide text-slate-400">
                  ยอด Finpoint คงเหลือ
                </h2>
                <p className="mt-1 text-3xl md:text-4xl font-semibold text-emerald-300">
                  {currentFpBalance.toLocaleString()} FP
                </p>
              </div>
              <div className="text-right text-xs text-slate-400">
                <div>อัปเดตล่าสุด</div>
                <div className="font-mono text-slate-300">{lastUpdated}</div>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-3 text-xs mt-4">
              <div className="bg-slate-900/80 border border-slate-800 rounded-xl px-3 py-2">
                <div className="text-slate-400">FP เพิ่มวันนี้</div>
                <div className="mt-1 text-emerald-300 font-semibold">
                  +{todayEarned.toLocaleString()} FP
                </div>
              </div>
              <div className="bg-slate-900/80 border border-slate-800 rounded-xl px-3 py-2">
                <div className="text-slate-400">จากขายของมือสอง</div>
                <div className="mt-1 text-emerald-200 font-medium">
                  +{todayFromSecondhand.toLocaleString()} FP
                </div>
              </div>
              <div className="bg-slate-900/80 border border-slate-800 rounded-xl px-3 py-2">
                <div className="text-slate-400">จากเครือข่าย (upline)</div>
                <div className="mt-1 text-emerald-200 font-medium">
                  +{todayFromUpline.toLocaleString()} FP
                </div>
              </div>
            </div>
          </div>

          {/* Card: Network Snapshot */}
          <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4 space-y-3">
            <h3 className="text-sm font-medium text-slate-100">
              ภาพรวมเครือข่ายของคุณ
            </h3>
            <div className="text-xs space-y-2">
              <div className="flex justify-between">
                <span className="text-slate-400">
                  จำนวนสมาชิกในสายงานของคุณ
                </span>
                <span className="font-semibold text-slate-100">
                  {networkSnapshot.networkSize.toLocaleString()} คน
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">
                  คนที่ได้รับ FP จากคุณแล้ว
                </span>
                <span className="font-semibold text-slate-100">
                  {networkSnapshot.fpFromYou.toLocaleString()} คน
                </span>
              </div>
              <div className="mt-3">
                <div className="text-slate-400 mb-1">สาย upline</div>
                <div className="flex flex-wrap gap-1 text-[11px]">
                  {networkSnapshot.uplinePath.map((id, idx) => (
                    <React.Fragment key={id}>
                      {idx > 0 && <span className="text-slate-500">→</span>}
                      <span className="px-2 py-0.5 rounded-full bg-slate-800 border border-slate-700 font-mono">
                        {id}
                      </span>
                    </React.Fragment>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* แถวกลาง: EXP Progress 3 การ์ด */}
        <section className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-medium text-slate-100">
              เป้าหมาย EXP (พรบ. / ประกันรถ / ประกันสุขภาพ)
            </h2>
            <span className="text-xs text-slate-400">
              ใช้ FP ที่สะสมเพื่อซื้อความคุ้มครอง
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {expProgressList.map((exp) => {
              const percent =
                exp.target > 0
                  ? Math.min(100, Math.round((exp.current / exp.target) * 100))
                  : 0;

              const canSimulate = exp.current >= exp.target;

              return (
                <div
                  key={exp.code}
                  className="bg-slate-950/60 border border-slate-800 rounded-xl p-3 flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <h3 className="text-xs font-semibold text-slate-100">
                        {exp.label}
                      </h3>
                      <span className="text-[11px] text-slate-400">
                        เป้า {exp.target.toLocaleString()} FP
                      </span>
                    </div>
                    {/* progress bar */}
                    <div className="w-full h-2 rounded-full bg-slate-800 overflow-hidden">
                      <div
                        className="h-full bg-emerald-400"
                        style={{ width: `${percent}%` }}
                      />
                    </div>
                    <div className="mt-2 flex justify-between text-[11px] text-slate-400">
                      <span>
                        สะสมแล้ว {" "}
                        <span className="text-emerald-300 font-medium">
                          {exp.current.toLocaleString()} FP
                        </span>
                      </span>
                      <span>{percent}%</span>
                    </div>
                  </div>

                  <button
                    className={`mt-3 w-full rounded-lg text-xs py-1.5 border transition ${
                      canSimulate
                        ? "border-emerald-400 text-emerald-300 hover:bg-emerald-400/10"
                        : "border-slate-700 text-slate-500 cursor-not-allowed"
                    }`}
                    disabled={!canSimulate}
                  >
                    {canSimulate
                      ? "จำลองใช้ FP ซื้อความคุ้มครอง"
                      : "สะสมให้ถึงเป้าก่อน"}
                  </button>
                </div>
              );
            })}
          </div>
        </section>

        {/* แถวล่าง: Ledger ล่าสุด */}
        <section className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-sm font-medium text-slate-100">
              ประวัติการเคลื่อนไหว Finpoint ล่าสุด
            </h2>
            <div className="flex gap-2 text-xs">
              <select className="bg-slate-950 border border-slate-800 rounded-md px-2 py-1 text-slate-300">
                <option>ช่วงเวลา: 7 วันล่าสุด</option>
                <option>ช่วงเวลา: 30 วันล่าสุด</option>
                <option>ทั้งหมด</option>
              </select>
              <select className="bg-slate-950 border border-slate-800 rounded-md px-2 py-1 text-slate-300">
                <option>ทุกประเภท</option>
                <option>ขายของมือสอง</option>
                <option>พรบ.</option>
                <option>ประกันรถ</option>
                <option>ประกันสุขภาพ</option>
              </select>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-full text-xs">
              <thead>
                <tr className="text-slate-400 border-b border-slate-800">
                  <th className="text-left py-2 pr-4">วันที่-เวลา</th>
                  <th className="text-left py-2 pr-4">ประเภท</th>
                  <th className="text-left py-2 pr-4">รายละเอียด</th>
                  <th className="text-right py-2 pr-4">DR / CR</th>
                  <th className="text-right py-2 pr-4">จำนวน (FP)</th>
                  <th className="text-right py-2">ยอดคงเหลือ</th>
                </tr>
              </thead>
              <tbody>
                {recentLedger.map((row) => (
                  <tr
                    key={row.id}
                    className="border-b border-slate-900 hover:bg-slate-900/80"
                  >
                    <td className="py-1.5 pr-4 font-mono text-[11px] text-slate-300">
                      {row.datetime}
                    </td>
                    <td className="py-1.5 pr-4 text-[11px]">
                      <span className="px-2 py-0.5 rounded-full bg-slate-950 border border-slate-800 text-slate-200">
                        {row.category}
                      </span>
                    </td>
                    <td className="py-1.5 pr-4 text-[11px] text-slate-200">
                      {row.detail}
                    </td>
                    <td className="py-1.5 pr-4 text-right">
                      <span
                        className={
                          row.drCr === "DR"
                            ? "text-emerald-300 font-medium"
                            : "text-rose-300 font-medium"
                        }
                      >
                        {row.drCr}
                      </span>
                    </td>
                    <td className="py-1.5 pr-4 text-right text-slate-100">
                      {row.drCr === "DR" ? "+" : "-"}
                      {row.amount.toLocaleString()}
                    </td>
                    <td className="py-1.5 text-right font-mono text-slate-300">
                      {row.balanceAfter.toLocaleString()}
                    </td>
                  </tr>
                ))}

                {recentLedger.length === 0 && (
                  <tr>
                    <td
                      colSpan={6}
                      className="py-4 text-center text-slate-500 text-xs"
                    >
                      ยังไม่มีรายการเคลื่อนไหว
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      </main>
    </div>
  );
};

// Demo Dashboard
export const UserDashboardDemo: React.FC = () => {
  return (
    <UserDashboard
      userName="User Demo"
      currentFpBalance={3250}
      lastUpdated="23/11/2025 10:32"
      todayEarned={120}
      todayFromSecondhand={80}
      todayFromUpline={40}
      expProgressList={[
        {
          code: "EXP_PRB",
          label: "EXP_1 – พรบ. รถยนต์",
          target: 600,
          current: 420,
        },
        {
          code: "EXP_CAR",
          label: "EXP_2 – ประกันรถยนต์",
          target: 5000,
          current: 1350,
        },
        {
          code: "EXP_HEALTH",
          label: "EXP_3 – ประกันสุขภาพ",
          target: 20000,
          current: 2500,
        },
      ]}
      recentLedger={[
        {
          id: 1,
          datetime: "23/11/2025 10:10",
          category: "SECONDHAND_SALE",
          detail: "ขายของมือสอง #S-1021",
          drCr: "DR",
          amount: 70,
          balanceAfter: 3250,
        },
        {
          id: 2,
          datetime: "23/11/2025 09:00",
          category: "EXP_PRB",
          detail: "ได้รับเงินคืน พรบ. (self 45%)",
          drCr: "DR",
          amount: 30,
          balanceAfter: 3180,
        },
      ]}
      networkSnapshot={{
        networkSize: 1235,
        fpFromYou: 120,
        uplinePath: ["YOU", "U1", "U2", "U3", "U4", "U5", "ROOT"],
      }}
    />
  );
};

// ---------- Log Page ----------

type PostLogItem = {
  id: number;
  datetime: string;
  txCategory: string;
  sourceType: string;
  sourceId: string | number;
  totalFp: number;
  affectedCount: number;
  status: "PENDING" | "SUCCESS" | "FAILED";
};

type LogDetailAffectedUser = {
  level: number;
  userId: string;
  fpAmount: number;
  relation: string;
  ledgerId: number;
};

type LogDetailData = {
  id: number;
  datetime: string;
  txCategory: string;
  sourceType: string;
  sourceId: string | number;
  totalFp: number;
  affectedUsers: LogDetailAffectedUser[];
  status: "PENDING" | "SUCCESS" | "FAILED";
  errorMessage?: string;
};

type FinpointLogPageProps = {
  logs: PostLogItem[];
  selectedLog?: LogDetailData | null;
  onSelectLog?: (logId: number) => void;
};

export const FinpointLogPage: React.FC<FinpointLogPageProps> = ({
  logs,
  selectedLog,
  onSelectLog,
}) => {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col">
      {/* HEADER */}
      <header className="border-b border-slate-800 bg-slate-900/80 backdrop-blur">
        <div className="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <button className="text-xs text-slate-400 hover:text-slate-200">
              ⬅ กลับ Dashboard
            </button>
            <span className="text-slate-500">/</span>
            <span className="font-semibold text-slate-100">
              Finpoint Posting Log
            </span>
          </div>
          <div className="text-xs text-slate-400">
            สำหรับตรวจสอบการวิ่งโพสต์ FP ของระบบ
          </div>
        </div>
      </header>

      {/* MAIN */}
      <main className="flex-1 max-w-6xl mx-auto px-4 py-6 flex gap-4">
        {/* Left: Log list */}
        <section className="flex-1 bg-slate-900/60 border border-slate-800 rounded-2xl p-4 flex flex-col">
          {/* Filters */}
          <div className="mb-4 space-y-2">
            <div className="flex flex-wrap gap-2 text-xs">
              <input
                type="text"
                placeholder="ค้นหาจาก Source ID (เช่น S-xxxx / E-xxxx)"
                className="flex-1 min-w-[160px] bg-slate-950 border border-slate-800 rounded-md px-2 py-1 text-slate-200 text-xs placeholder:text-slate-500"
              />
              <input
                type="text"
                placeholder="ค้นหาจาก User ID"
                className="w-40 bg-slate-950 border border-slate-800 rounded-md px-2 py-1 text-slate-200 text-xs placeholder:text-slate-500"
              />
              <select className="bg-slate-950 border border-slate-800 rounded-md px-2 py-1 text-slate-200 text-xs">
                <option>ทุกประเภท</option>
                <option>SECONDHAND_SALE</option>
                <option>EXP_PRB</option>
                <option>EXP_CAR</option>
                <option>EXP_HEALTH</option>
              </select>
              <select className="bg-slate-950 border border-slate-800 rounded-md px-2 py-1 text-slate-200 text-xs">
                <option>ทุกสถานะ</option>
                <option>SUCCESS</option>
                <option>FAILED</option>
                <option>PENDING</option>
              </select>
              <button className="px-3 py-1 rounded-md bg-emerald-500/90 text-slate-900 text-xs font-semibold hover:bg-emerald-400">
                ค้นหา
              </button>
            </div>
          </div>

          {/* Log Table */}
          <div className="flex-1 overflow-auto">
            <table className="min-w-full text-xs">
              <thead>
                <tr className="text-slate-400 border-b border-slate-800">
                  <th className="text-left py-2 pr-3">เวลา</th>
                  <th className="text-left py-2 pr-3">ประเภท</th>
                  <th className="text-left py-2 pr-3">Source</th>
                  <th className="text-right py-2 pr-3">FP ทั้งก้อน</th>
                  <th className="text-right py-2 pr-3">จำนวน user</th>
                  <th className="text-center py-2 pr-3">สถานะ</th>
                  <th className="text-center py-2">Action</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log) => (
                  <tr
                    key={log.id}
                    className="border-b border-slate-900 hover:bg-slate-900/80"
                  >
                    <td className="py-1.5 pr-3 font-mono text-[11px] text-slate-300">
                      {log.datetime}
                    </td>
                    <td className="py-1.5 pr-3 text-[11px]">
                      <span className="px-2 py-0.5 rounded-full bg-slate-950 border border-slate-800">
                        {log.txCategory}
                      </span>
                    </td>
                    <td className="py-1.5 pr-3 text-[11px] text-slate-300">
                      {log.sourceType} #{log.sourceId}
                    </td>
                    <td className="py-1.5 pr-3 text-right text-slate-100">
                      {log.totalFp.toLocaleString()}
                    </td>
                    <td className="py-1.5 pr-3 text-right text-slate-200">
                      {log.affectedCount}
                    </td>
                    <td className="py-1.5 pr-3 text-center">
                      <StatusBadge status={log.status} />
                    </td>
                    <td className="py-1.5 text-center">
                      <button
                        className="text-[11px] px-2 py-1 rounded-md border border-slate-700 hover:border-emerald-400 hover:text-emerald-300"
                        onClick={() => onSelectLog && onSelectLog(log.id)}
                      >
                        ดู
                      </button>
                    </td>
                  </tr>
                ))}

                {logs.length === 0 && (
                  <tr>
                    <td
                      colSpan={7}
                      className="py-4 text-center text-slate-500 text-xs"
                    >
                      ยังไม่มี log การโพสต์
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>

        {/* Right: Detail panel */}
        <section className="w-full md:w-80 bg-slate-900/60 border border-slate-800 rounded-2xl p-4 hidden md:flex flex-col">
          <h2 className="text-sm font-medium text-slate-100 mb-2">
            รายละเอียด Log
          </h2>

          {!selectedLog && (
            <div className="text-xs text-slate-500 mt-4">
              เลือก log ทางซ้ายเพื่อดูรายละเอียด
            </div>
          )}

          {selectedLog && (
            <div className="flex-1 flex flex-col gap-3 text-xs">
              {/* Summary */}
              <div className="bg-slate-950/60 border border-slate-800 rounded-xl p-3 space-y-1.5">
                <div className="flex justify-between">
                  <span className="text-slate-400">Log ID</span>
                  <span className="font-mono text-slate-100">
                    #{selectedLog.id}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">เวลา</span>
                  <span className="font-mono text-slate-200">
                    {selectedLog.datetime}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">ประเภท</span>
                  <span className="text-slate-100">
                    {selectedLog.txCategory}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Source</span>
                  <span className="text-slate-100">
                    {selectedLog.sourceType} #{selectedLog.sourceId}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">FP ทั้งก้อน</span>
                  <span className="text-emerald-300 font-semibold">
                    {selectedLog.totalFp.toLocaleString()} FP
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-400">สถานะ</span>
                  <StatusBadge status={selectedLog.status} />
                </div>
                {selectedLog.status === "FAILED" && selectedLog.errorMessage && (
                  <div className="mt-2 text-[11px] text-rose-300">
                    Error: {selectedLog.errorMessage}
                  </div>
                )}
              </div>

              {/* Affected users */}
              <div className="flex-1 bg-slate-950/40 border border-slate-800 rounded-xl p-3 flex flex-col">
                <div className="flex justify-between items-center mb-2">
                  <span className="text-slate-400">
                    ผู้ที่ได้รับ FP ({selectedLog.affectedUsers.length})
                  </span>
                </div>
                <div className="flex-1 overflow-auto">
                  <table className="w-full text-[11px]">
                    <thead>
                      <tr className="text-slate-400 border-b border-slate-800">
                        <th className="text-left py-1 pr-2">Lv</th>
                        <th className="text-left py-1 pr-2">User</th>
                        <th className="text-right py-1 pr-2">FP</th>
                        <th className="text-center py-1">Ledger</th>
                      </tr>
                    </thead>
                    <tbody>
                      {selectedLog.affectedUsers.map((u) => (
                        <tr
                          key={u.ledgerId}
                          className="border-b border-slate-900"
                        >
                          <td className="py-1 pr-2 text-slate-400">
                            {u.level}
                          </td>
                          <td className="py-1 pr-2">
                            <div className="flex flex-col">
                              <span className="font-mono text-slate-100">
                                {u.userId}
                              </span>
                              <span className="text-[10px] text-slate-500">
                                {u.relation}
                              </span>
                            </div>
                          </td>
                          <td className="py-1 pr-2 text-right text-emerald-300">
                            {u.fpAmount.toLocaleString()}
                          </td>
                          <td className="py-1 text-center">
                            <button className="text-[10px] px-2 py-0.5 rounded border border-slate-700 hover:border-emerald-400 hover:text-emerald-300">
                              #{u.ledgerId}
                            </button>
                          </td>
                        </tr>
                      ))}

                      {selectedLog.affectedUsers.length === 0 && (
                        <tr>
                          <td
                            colSpan={4}
                            className="py-2 text-center text-slate-500"
                          >
                            ไม่มีข้อมูลการกระจาย FP
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* ปุ่มสำหรับอนาคต */}
              <div className="flex gap-2 mt-1">
                <button className="flex-1 border border-slate-700 rounded-md px-2 py-1 text-[11px] text-slate-300 hover:border-emerald-400 hover:text-emerald-300">
                  ทำเครื่องหมายว่า ตรวจสอบแล้ว
                </button>
                <button className="flex-1 border border-slate-700 rounded-md px-2 py-1 text-[11px] text-slate-300 hover:border-amber-400 hover:text-amber-300">
                  Re-run Posting (จำลอง)
                </button>
              </div>
            </div>
          )}
        </section>
      </main>
    </div>
  );
};

const StatusBadge: React.FC<{ status: "PENDING" | "SUCCESS" | "FAILED" }> = ({
  status,
}) => {
  let text = "";
  let cls = "";
  switch (status) {
    case "SUCCESS":
      text = "SUCCESS";
      cls = "bg-emerald-500/10 text-emerald-300 border-emerald-500/40";
      break;
    case "FAILED":
      text = "FAILED";
      cls = "bg-rose-500/10 text-rose-300 border-rose-500/40";
      break;
    case "PENDING":
      text = "PENDING";
      cls = "bg-amber-500/10 text-amber-300 border-amber-500/40";
      break;
  }
  return (
    <span
      className={`inline-flex items-center px-2 py-0.5 rounded-full border text-[10px] font-medium ${cls}`}
    >
      {text}
    </span>
  );
};

// Demo Log Page
export const FinpointLogPageDemo: React.FC = () => {
  const [selectedId, setSelectedId] = React.useState<number | null>(1);

  const logs: PostLogItem[] = [
    {
      id: 1,
      datetime: "23/11/2025 10:10",
      txCategory: "SECONDHAND_SALE",
      sourceType: "SIM_SECONDHAND_SALE",
      sourceId: "S-1021",
      totalFp: 70,
      affectedCount: 7,
      status: "SUCCESS",
    },
    {
      id: 2,
      datetime: "23/11/2025 09:00",
      txCategory: "EXP_PRB",
      sourceType: "SIM_EXP_TRANSACTION",
      sourceId: "E-550",
      totalFp: 100,
      affectedCount: 8,
      status: "SUCCESS",
    },
    {
      id: 3,
      datetime: "22/11/2025 21:30",
      txCategory: "EXP_CAR",
      sourceType: "SIM_EXP_TRANSACTION",
      sourceId: "E-531",
      totalFp: 230,
      affectedCount: 8,
      status: "FAILED",
    },
  ];

  const selectedLog: LogDetailData | null =
    selectedId === 1
      ? {
          id: 1,
          datetime: "23/11/2025 10:10",
          txCategory: "SECONDHAND_SALE",
          sourceType: "SIM_SECONDHAND_SALE",
          sourceId: "S-1021",
          totalFp: 70,
          status: "SUCCESS",
          affectedUsers: [
            {
              level: 0,
              userId: "U123",
              fpAmount: 10,
              relation: "ต้นทาง",
              ledgerId: 101,
            },
            {
              level: 1,
              userId: "U120",
              fpAmount: 10,
              relation: "upline ชั้น 1",
              ledgerId: 102,
            },
          ],
        }
      : selectedId === 3
      ? {
          id: 3,
          datetime: "22/11/2025 21:30",
          txCategory: "EXP_CAR",
          sourceType: "SIM_EXP_TRANSACTION",
          sourceId: "E-531",
          totalFp: 230,
          status: "FAILED",
          errorMessage: "Database timeout while posting upline level 4",
          affectedUsers: [],
        }
      : null;

  return (
    <FinpointLogPage
      logs={logs}
      selectedLog={selectedLog}
      onSelectLog={(id) => setSelectedId(id)}
    />
  );
};

// ---------- Default export for Canvas ----------

const App: React.FC = () => {
  // ถ้าอยากลองหน้า Log ให้เปลี่ยนเป็น <FinpointLogPageDemo />
  return <UserDashboardDemo />;
};

export default App;
