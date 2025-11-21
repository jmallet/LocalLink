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
    const authHeader = req.headers.get("Authorization");
    console.log("Auth header:", authHeader ? "present" : "missing");

    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
    if (!stripeKey) {
      return new Response(
        JSON.stringify({ error: "Stripe secret key not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const stripe = new Stripe(stripeKey, {
      apiVersion: "2023-10-16",
    });

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    );

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();

    console.log("User error:", userError?.message);
    console.log("User ID:", user?.id);

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized: " + (userError?.message || "No user") }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { tokenAmount, companyId } = await req.json();

    if (!tokenAmount || tokenAmount < 1) {
      return new Response(
        JSON.stringify({ error: "Invalid token amount" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!companyId) {
      return new Response(
        JSON.stringify({ error: "Company ID required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { data: company, error: companyError } = await supabaseClient
      .from("companies")
      .select("id, company_name, email")
      .eq("id", companyId)
      .eq("user_id", user.id)
      .maybeSingle();

    if (companyError) {
      console.error("Company fetch error:", companyError);
      return new Response(
        JSON.stringify({ error: "Error fetching company: " + companyError.message }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!company) {
      return new Response(
        JSON.stringify({ error: "Company not found or unauthorized" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const pricePerToken = 5;

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
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (error: any) {
    console.error("Function error:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});