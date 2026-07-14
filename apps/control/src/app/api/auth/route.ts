import { NextResponse } from "next/server";
import { ADMIN_COOKIE, checkPassword } from "@/lib/auth";

export async function POST(req: Request) {
  const body = await req.json();
  if (!checkPassword(String(body.password || ""))) {
    return NextResponse.json({ error: "Invalid password" }, { status: 401 });
  }
  const res = NextResponse.json({ ok: true });
  res.cookies.set(ADMIN_COOKIE, String(body.password), {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 60 * 24 * 14,
  });
  return res;
}
