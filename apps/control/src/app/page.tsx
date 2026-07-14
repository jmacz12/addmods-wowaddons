import Link from "next/link";

const links = [
  { href: "/download", label: "Download AutoSeller", desc: "Ascension-ready addon zip + install steps" },
  { href: "/debug", label: "Submit debug export", desc: "Paste /mtdb export from in-game" },
  { href: "/errors", label: "Error control", desc: "Password-gated inbox for reports" },
  { href: "/api/donate", label: "Donate", desc: "Support via Stripe (when linked)" },
];

export default function HomePage() {
  return (
    <main className="relative mx-auto flex min-h-screen max-w-5xl flex-col px-6 py-16">
      <header className="max-w-2xl">
        <p className="font-[family-name:var(--font-mono)] text-sm tracking-[0.2em] text-[var(--accent)]">
          MACTECH CONTROL
        </p>
        <h1 className="mt-4 text-5xl font-semibold tracking-tight text-[var(--ink)] md:text-6xl">
          MacTech
        </h1>
        <p className="mt-4 max-w-xl text-lg leading-relaxed text-[var(--muted)]">
          WoW addons for Ascension first, retail flavors next — with built-in debug export into this control room.
        </p>
      </header>

      <section className="mt-14 grid gap-4 md:grid-cols-2">
        {links.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="rounded-2xl border border-[var(--line)] bg-[var(--panel)] p-6 backdrop-blur transition hover:-translate-y-0.5 hover:border-[var(--accent)]"
          >
            <h2 className="text-xl font-medium">{item.label}</h2>
            <p className="mt-2 text-[var(--muted)]">{item.desc}</p>
          </Link>
        ))}
      </section>

      <footer className="mt-auto pt-16 font-[family-name:var(--font-mono)] text-xs text-[var(--muted)]">
        AutoSeller v0.1.0 · Ascension client 1.0.102 · /mtas in-game
      </footer>
    </main>
  );
}
