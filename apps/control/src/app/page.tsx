import Link from "next/link";

/** Legacy mini-site — Mission Control owns the real control room now. */
export default function HomePage() {
  return (
    <main className="relative mx-auto flex min-h-screen max-w-3xl flex-col px-6 py-16">
      <p className="font-[family-name:var(--font-mono)] text-sm tracking-[0.2em] text-[var(--accent)]">
        MACTECH CONTROL (LEGACY)
      </p>
      <h1 className="mt-4 text-4xl font-semibold tracking-tight">Moved to Mission Control</h1>
      <p className="mt-4 text-lg text-[var(--muted)]">
        Addon errors, downloads, and donate links now live under your real owner dashboard.
      </p>
      <div className="mt-10 flex flex-col gap-3 sm:flex-row">
        <a
          className="rounded-full bg-[var(--accent)] px-6 py-3 text-center text-white"
          href="https://control.mactech.app/wow"
        >
          Open control.mactech.app/wow
        </a>
        <a
          className="rounded-full border border-[var(--line)] bg-[var(--panel)] px-6 py-3 text-center"
          href="https://control.mactech.app/wow/submit"
        >
          Public debug submit
        </a>
        <Link
          className="rounded-full border border-[var(--line)] bg-[var(--panel)] px-6 py-3 text-center"
          href="https://github.com/jmacz12/addmods-wowaddons/releases/latest"
        >
          Download release
        </Link>
      </div>
    </main>
  );
}
