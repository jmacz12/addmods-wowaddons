import { cookies } from "next/headers";

export const ADMIN_COOKIE = "mactech_control_admin";

export async function isAdmin(): Promise<boolean> {
  const password = process.env.CONTROL_ADMIN_PASSWORD;
  if (!password) return false;
  const jar = await cookies();
  return jar.get(ADMIN_COOKIE)?.value === password;
}

export function checkPassword(input: string): boolean {
  const password = process.env.CONTROL_ADMIN_PASSWORD;
  return Boolean(password && input === password);
}
