import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import Stripe from "npm:stripe@14.10.0";
import { createClient } from "npm:@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
    if (!stripeKey) {
      throw new Error("Stripe secret key not configured");
    }

    const stripe = new Stripe(stripeKey, {
      apiVersion: "2023-10-16",
    });

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
      throw new Error("Unauthorized");
    }

    const { tokenAmount, companyId } = await req.json();

    if (!tokenAmount || tokenAmount < 1) {
      throw new Error("Invalid token amount");
    }

    if (!companyId) {
      throw new Error("Company ID required");
    }

    const { data: company } = await supabaseClient
      .from("companies")
      .select("id, company_name, email")
      .eq("id", companyId)
      .eq("user_id", user.id)
      .single();

    if (!company) {
      throw new Error("Company not found or unauthorized");
    }

    const pricePerToken = 5;
    const totalAmount = tokenAmount * pricePerToken;

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ["card"],
      line_items: [
        {
          price_data: {
            currency: "eur",
            product_data: {
              name: `${tokenAmount} Jeton${tokenAmount > 1 ? "s" : ""} de déverrouillage`,
              description: "Jetons pour déverrouiller les demandes de devis",
            },
            unit_amount: pricePerToken * 100,
          },
          quantity: tokenAmount,
        },
      ],
      mode: "payment",
      success_url: `${req.headers.get("origin")}/dashboard/quotes?success=true`,
      cancel_url: `${req.headers.get("origin")}/dashboard/quotes?canceled=true`,
      metadata: {
        company_id: companyId,
        token_amount: tokenAmount.toString(),
        user_id: user.id,
        type: "token_purchase",
      },
    });

    return new Response(
      JSON.stringify({ sessionId: session.id, url: session.url }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});