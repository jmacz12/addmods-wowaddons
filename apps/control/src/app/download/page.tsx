import Link from "next/link";

export default function DownloadPage() {
  return (
    <main className="relative mx-auto min-h-screen max-w-3xl px-6 py-16">
      <Link href="/" className="text-sm text-[var(--accent)]">
        ← MacTech Control
      </Link>
      <h1 className="mt-6 text-4xl font-semibold">Install AutoSeller & Repair</h1>
      <ol className="mt-8 list-decimal space-y-4 pl-5 text-[var(--muted)]">
        <li>
          Copy the folder{" "}
          <code className="font-[family-name:var(--font-mono)] text-[var(--ink)]">
            AutoSeller
          </code>{" "}
          into your Ascension{" "}
          <code className="font-[family-name:var(--font-mono)] text-[var(--ink)]">
            Interface\AddOns\
          </code>
        </li>
        <li>Restart Ascension (or reload UI if available).</li>
        <li>
          Open{" "}
          <code className="font-[family-name:var(--font-mono)] text-[var(--ink)]">
            Interface → AddOns → AutoSeller & Repair
          </code>{" "}
          or type{" "}
          <code className="font-[family-name:var(--font-mono)] text-[var(--ink)]">/autoseller</code>.
        </li>
        <li>
          On errors: <code className="font-[family-name:var(--font-mono)] text-[var(--ink)]">/mtdb export</code>{" "}
          then paste at <Link href="/debug" className="text-[var(--accent)] underline">/debug</Link>.
        </li>
      </ol>
      <p className="mt-8">
        <a
          className="inline-flex rounded-full bg-[var(--accent)] px-5 py-3 text-white"
          href="https://github.com/jmacz12/mactech-wowaddons/releases/latest"
          target="_blank"
          rel="noreferrer"
        >
          Download latest release zip
        </a>
      </p>
      <p className="mt-6 text-sm text-[var(--muted)]">
        Retail CurseForge/Wago packaging comes after the Ascension flavor is stable.
      </p>
    </main>
  );
}
