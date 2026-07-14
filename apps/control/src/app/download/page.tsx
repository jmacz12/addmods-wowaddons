import Link from "next/link";

export default function DownloadPage() {
  return (
    <main className="relative mx-auto min-h-screen max-w-3xl px-6 py-16">
      <Link href="/" className="text-sm text-[var(--accent)]">
        ← MacTech Control
      </Link>
      <h1 className="mt-6 text-4xl font-semibold">Install MacTech AutoSeller</h1>
      <ol className="mt-8 list-decimal space-y-4 pl-5 text-[var(--muted)]">
        <li>
          Copy the folder{" "}
          <code className="font-[family-name:var(--font-mono)] text-[var(--ink)]">
            addons/MacTech_AutoSeller
          </code>{" "}
          into your Ascension{" "}
          <code className="font-[family-name:var(--font-mono)] text-[var(--ink)]">
            Interface\AddOns\
          </code>
        </li>
        <li>Restart Ascension (or reload UI if available).</li>
        <li>
          Type <code className="font-[family-name:var(--font-mono)] text-[var(--ink)]">/mtas</code>{" "}
          for options, open a vendor to auto-sell grays.
        </li>
        <li>
          On errors: <code className="font-[family-name:var(--font-mono)] text-[var(--ink)]">/mtdb export</code>{" "}
          then paste at <Link href="/debug" className="text-[var(--accent)] underline">/debug</Link>.
        </li>
      </ol>
      <p className="mt-8 text-sm text-[var(--muted)]">
        GitHub Releases will provide a one-click zip once the repo is published. Retail CurseForge/Wago
        packaging comes after the Ascension flavor is stable.
      </p>
    </main>
  );
}
