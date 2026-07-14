import { getSupabase } from "./supabase";

export type DebugError = {
  id?: number;
  time?: string;
  message?: string;
  stack?: string;
};

export type DebugReport = {
  id: string;
  receivedAt: string;
  addon?: string;
  version?: string;
  client?: string;
  exportedAt?: string;
  errors: DebugError[];
  raw?: string;
  source: "paste" | "api";
};

type DbRow = {
  id: string;
  addon: string | null;
  version: string | null;
  client: string | null;
  exported_at: string | null;
  source: string;
  errors: DebugError[];
  raw: string | null;
  created_at: string;
};

function mapRow(row: DbRow): DebugReport {
  return {
    id: row.id,
    receivedAt: row.created_at,
    addon: row.addon ?? undefined,
    version: row.version ?? undefined,
    client: row.client ?? undefined,
    exportedAt: row.exported_at ?? undefined,
    errors: row.errors || [],
    raw: row.raw ?? undefined,
    source: (row.source as "paste" | "api") || "paste",
  };
}

export async function listReports(): Promise<DebugReport[]> {
  const supabase = getSupabase();
  const { data, error } = await supabase
    .from("wow_addon_debug_reports")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(100);

  if (error) throw error;
  return (data as DbRow[]).map(mapRow);
}

export async function addReport(
  report: Omit<DebugReport, "id" | "receivedAt"> & { id?: string }
): Promise<DebugReport> {
  const supabase = getSupabase();
  const { data, error } = await supabase
    .from("wow_addon_debug_reports")
    .insert({
      addon: report.addon ?? null,
      version: report.version ?? null,
      client: report.client ?? null,
      exported_at: report.exportedAt ?? null,
      source: report.source,
      errors: report.errors ?? [],
      raw: report.raw ?? null,
    })
    .select("*")
    .single();

  if (error) throw error;
  return mapRow(data as DbRow);
}
