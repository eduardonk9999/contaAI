export type Product = {
  id: string; name: string; cost_price_cents: number; sale_price_cents: number;
  stock_quantity: number; stock_unit: string; min_stock_quantity: number;
  active: boolean; created_at: string; updated_at: string;
};

export type SaleItemInput = { product_id: string; quantity: number; unit_price_cents: number };

export type SalePreview = {
  description: string;
  source: "TEXT" | "VOICE" | "MANUAL";
  original_input: string | null;
  occurred_at: string;
  items: Array<{
    product_id: string; product_name: string; quantity: number; stock_unit: string;
    unit_price_cents: number; unit_cost_cents: number; total_amount_cents: number;
    total_cost_cents: number; gross_profit_cents: number; margin_percent: number | null;
    stock_before: number; stock_after: number;
  }>;
  total_amount_cents: number; total_cost_cents: number; gross_profit_cents: number;
  margin_percent: number | null; warnings: string[];
};

