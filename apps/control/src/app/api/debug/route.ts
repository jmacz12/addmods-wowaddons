import { NextResponse } from "next/server";
import { addReport, listReports, type DebugError } from "@/lib/store";
import { isAdmin } from "@/lib/auth";

export async function GET() {
  if (!(await isAdmin())) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const reports = await listReports();
  return NextResponse.json({ reports });
}

export async function POST(req: Request) {
  try {
    const body = await req.json();
    let parsed = body;

    if (typeof body.raw === "string") {
      try {
        parsed = { ...JSON.parse(body.raw), raw: body.raw, source: body.source || "paste" };
      } catch {
        parsed = { raw: body.raw, errors: [], source: body.source || "paste" };
      }
    }

    const errors = (parsed.errors || []) as DebugError[];
    const report = await addReport({
      addon: parsed.addon,
      version: parsed.version,
      client: parsed.client,
      exportedAt: parsed.exportedAt,
      errors,
      raw: typeof body.raw === "string" ? body.raw : JSON.stringify(parsed),
      source: parsed.source === "api" ? "api" : "paste",
    });

    return NextResponse.json({ ok: true, report });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Failed to save report";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
