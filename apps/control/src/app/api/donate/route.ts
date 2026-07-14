import { NextResponse } from "next/server";

export async function GET() {
  const link = process.env.STRIPE_PAYMENT_LINK;
  if (!link) {
    return NextResponse.json(
      {
        error:
          "Stripe donation link not configured yet. Set STRIPE_PAYMENT_LINK after Stripe MCP auth.",
      },
      { status: 503 }
    );
  }
  return NextResponse.redirect(link);
}
