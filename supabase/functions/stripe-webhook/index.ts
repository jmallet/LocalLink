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
    const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
    
    if (!stripeKey || !webhookSecret) {
      throw new Error("Stripe keys not configured");
    }

    const stripe = new Stripe(stripeKey, {
      apiVersion: "2023-10-16",
    });

    const signature = req.headers.get("stripe-signature");
    if (!signature) {
      throw new Error("No signature");
    }

    const body = await req.text();
    const event = stripe.webhooks.constructEvent(body, signature, webhookSecret);

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    if (event.type === "checkout.session.completed") {
      const session = event.data.object as Stripe.Checkout.Session;

      if (session.metadata?.type === "token_purchase") {
        const companyId = session.metadata.company_id;
        const tokenAmount = parseInt(session.metadata.token_amount || "0");

        const { data: payment, error: paymentError } = await supabaseClient
          .from("payments")
          .insert({
            company_id: companyId,
            type: "token_purchase",
            amount: session.amount_total ? session.amount_total / 100 : 0,
            stripe_payment_id: session.payment_intent as string,
            stripe_session_id: session.id,
            status: "succeeded",
            metadata: {
              token_amount: tokenAmount,
            },
          })
          .select()
          .single();

        if (paymentError) {
          console.error("Payment insert error:", paymentError);
          throw paymentError;
        }

        const { data: result, error: tokenError } = await supabaseClient
          .rpc("add_tokens_after_purchase", {
            p_company_id: companyId,
            p_token_amount: tokenAmount,
            p_payment_id: payment.id,
          });

        if (tokenError) {
          console.error("Token add error:", tokenError);
          throw tokenError;
        }

        console.log("Tokens added successfully:", result);
      }
    }

    return new Response(
      JSON.stringify({ received: true }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (error: any) {
    console.error("Webhook error:", error);
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