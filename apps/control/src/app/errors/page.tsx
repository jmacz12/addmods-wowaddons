"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import type { DebugReport } from "@/lib/store";

export default function ErrorsPage() {
  const [password, setPassword] = useState("");
  const [authed, setAuthed] = useState(false);
  const [reports, setReports] = useState<DebugReport[]>([]);
  const [error, setError] = useState<string | null>(null);

  async function load() {
    const res = await fetch("/api/debug");
    if (res.status === 401) {
      setAuthed(false);
      return;
    }
    const data = await res.json();
    if (!res.ok) {
      setError(data.error || "Failed to load");
      return;
    }
    setAuthed(true);
    setReports(data.reports || []);
  }

  useEffect(() => {
    void load();
  }, []);

  async function login() {
    setError(null);
    const res = await fetch("/api/auth", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ password }),
    });
    if (!res.ok) {
      setError("Invalid password");
      return;
    }
    await load();
  }

  return (
    <main className="relative mx-auto min-h-screen max-w-4xl px-6 py-16">
      <Link href="/" className="text-sm text-[var(--accent)]">
        ← MacTech Control
      </Link>
      <h1 className="mt-6 text-4xl font-semibold">Error control</h1>
      <p className="mt-3 text-[var(--muted)]">
        Inbox backed by Mission Control Supabase — same place you asked for on control.mactech.
      </p>

      {!authed ? (
        <div className="mt-10 max-w-md rounded-2xl border border-[var(--line)] bg-[var(--panel)] p-6">
          <label className="text-sm text-[var(--muted)]">Admin password</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="mt-2 w-full rounded-xl border border-[var(--line)] bg-white px-3 py-2 outline-none focus:border-[var(--accent)]"
          />
          <button
            type="button"
            onClick={login}
            className="mt-4 rounded-full bg-[var(--accent)] px-5 py-2 text-white"
          >
            Unlock
          </button>
          {error && <p className="mt-3 text-[var(--danger)]">{error}</p>}
        </div>
      ) : (
        <div className="mt-10 space-y-4">
          {reports.length === 0 && (
            <p className="text-[var(--muted)]">No reports yet. Submit one from /debug.</p>
          )}
          {reports.map((r) => (
            <article
              key={r.id}
              className="rounded-2xl border border-[var(--line)] bg-[var(--panel)] p-5 backdrop-blur"
            >
              <div className="flex flex-wrap items-baseline justify-between gap-2">
                <h2 className="text-lg font-medium">
                  {r.addon || "Unknown addon"} · {r.version || "?"}
                </h2>
                <span className="font-[family-name:var(--font-mono)] text-xs text-[var(--muted)]">
                  {new Date(r.receivedAt).toLocaleString()}
                </span>
              </div>
              <p className="mt-1 font-[family-name:var(--font-mono)] text-sm text-[var(--muted)]">
                client {r.client || "n/a"} · {r.errors?.length || 0} error(s)
              </p>
              <ul className="mt-3 space-y-2">
                {(r.errors || []).slice(0, 5).map((e, i) => (
                  <li key={i} className="rounded-xl bg-black/5 p-3 text-sm">
                    <div className="text-[var(--danger)]">{e.message || "Error"}</div>
                    {e.stack && (
                      <pre className="mt-2 overflow-x-auto whitespace-pre-wrap font-[family-name:var(--font-mono)] text-xs text-[var(--muted)]">
                        {e.stack}
                      </pre>
                    )}
                  </li>
                ))}
              </ul>
            </article>
          ))}
        </div>
      )}
    </main>
  );
}
