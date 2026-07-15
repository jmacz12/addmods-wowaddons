"use client";

import { useState } from "react";
import Link from "next/link";

export default function DebugPage() {
  const [raw, setRaw] = useState("");
  const [status, setStatus] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function submit() {
    setLoading(true);
    setStatus(null);
    try {
      const res = await fetch("/api/debug", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ raw, source: "paste" }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Submit failed");
      setStatus("Report saved to Mission Control.");
      setRaw("");
    } catch (err) {
      setStatus(err instanceof Error ? err.message : "Submit failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="relative mx-auto min-h-screen max-w-3xl px-6 py-16">
      <Link href="/" className="text-sm text-[var(--accent)]">
        ← MacTech Control
      </Link>
      <h1 className="mt-6 text-4xl font-semibold">Submit debug export</h1>
      <p className="mt-3 text-[var(--muted)]">
        In Ascension: <code className="font-[family-name:var(--font-mono)]">/mtdb export</code>, then paste the JSON here.
      </p>
      <textarea
        value={raw}
        onChange={(e) => setRaw(e.target.value)}
        placeholder='{"addon":"AutoSeller & Repair","errors":[...]}'
        className="mt-8 h-72 w-full rounded-2xl border border-[var(--line)] bg-white/80 p-4 font-[family-name:var(--font-mono)] text-sm outline-none focus:border-[var(--accent)]"
      />
      <button
        type="button"
        disabled={loading || !raw.trim()}
        onClick={submit}
        className="mt-4 rounded-full bg-[var(--accent)] px-6 py-3 text-white transition hover:bg-[var(--accent-bright)] disabled:opacity-50"
      >
        {loading ? "Sending…" : "Send to control"}
      </button>
      {status && <p className="mt-4 text-[var(--muted)]">{status}</p>}
    </main>
  );
}
