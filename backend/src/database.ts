import { mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { DatabaseSync } from "node:sqlite";
import { randomUUID } from "node:crypto";

const here = dirname(fileURLToPath(import.meta.url));
const dataDirectory = join(here, "..", "data");
mkdirSync(dataDirectory, { recursive: true });
export const database = new DatabaseSync(join(dataDirectory, "contaai.db"));
database.exec("PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL;");
export const DEMO_STORE_ID = "00000000-0000-4000-8000-000000000001";

export function migrate(): void {
  database.exec(`
    CREATE TABLE IF NOT EXISTS stores (id TEXT PRIMARY KEY, name TEXT NOT NULL, currency TEXT NOT NULL DEFAULT 'BRL', timezone TEXT NOT NULL DEFAULT 'America/Sao_Paulo', created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS products (id TEXT PRIMARY KEY, store_id TEXT NOT NULL REFERENCES stores(id), name TEXT NOT NULL, cost_price_cents INTEGER NOT NULL CHECK(cost_price_cents>=0), sale_price_cents INTEGER NOT NULL CHECK(sale_price_cents>=0), stock_quantity REAL NOT NULL DEFAULT 0, stock_unit TEXT NOT NULL DEFAULT 'UNIT', min_stock_quantity REAL NOT NULL DEFAULT 0 CHECK(min_stock_quantity>=0), active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
    CREATE UNIQUE INDEX IF NOT EXISTS products_active_name ON products(store_id, lower(trim(name))) WHERE active=1;
    CREATE TABLE IF NOT EXISTS transactions (id TEXT PRIMARY KEY, store_id TEXT NOT NULL REFERENCES stores(id), type TEXT NOT NULL CHECK(type IN ('SALE','PURCHASE','EXPENSE','INCOME')), status TEXT NOT NULL CHECK(status IN ('CONFIRMED','CANCELLED')), source TEXT NOT NULL CHECK(source IN ('TEXT','VOICE','MANUAL')), description TEXT NOT NULL, total_amount_cents INTEGER NOT NULL, total_cost_cents INTEGER NOT NULL, gross_profit_cents INTEGER NOT NULL, margin_percent REAL, original_input TEXT, occurred_at TEXT NOT NULL, idempotency_key TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(store_id,idempotency_key));
    CREATE TABLE IF NOT EXISTS transaction_items (id TEXT PRIMARY KEY, transaction_id TEXT NOT NULL REFERENCES transactions(id), product_id TEXT NOT NULL REFERENCES products(id), product_name_snapshot TEXT NOT NULL, stock_unit_snapshot TEXT NOT NULL, quantity REAL NOT NULL CHECK(quantity>0), unit_price_cents INTEGER NOT NULL, unit_cost_cents INTEGER NOT NULL, total_amount_cents INTEGER NOT NULL, total_cost_cents INTEGER NOT NULL, gross_profit_cents INTEGER NOT NULL, margin_percent REAL, created_at TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS stock_movements (id TEXT PRIMARY KEY, store_id TEXT NOT NULL REFERENCES stores(id), product_id TEXT NOT NULL REFERENCES products(id), transaction_id TEXT REFERENCES transactions(id), type TEXT NOT NULL CHECK(type IN ('INITIAL','SALE','PURCHASE','ADJUSTMENT','REVERSAL')), quantity_delta REAL NOT NULL CHECK(quantity_delta<>0), quantity_before REAL NOT NULL, quantity_after REAL NOT NULL, reason TEXT, occurred_at TEXT NOT NULL, created_at TEXT NOT NULL);
    CREATE INDEX IF NOT EXISTS transactions_store_date ON transactions(store_id,occurred_at DESC);
    CREATE INDEX IF NOT EXISTS movements_product_date ON stock_movements(product_id,occurred_at DESC);
  `);
}

export function seed(): void {
  const now = new Date().toISOString();
  database.prepare("INSERT OR IGNORE INTO stores (id,name,currency,timezone,created_at,updated_at) VALUES (?,?,'BRL','America/Sao_Paulo',?,?)").run(DEMO_STORE_ID,"Loja Demonstração",now,now);
  const count = database.prepare("SELECT count(*) total FROM products WHERE store_id=?").get(DEMO_STORE_ID) as {total:number};
  if (count.total > 0) return;
  const products = [["Camiseta básica",3000,5000,10,"UNIT",2],["Boné",2000,4000,8,"UNIT",2],["Garrafa térmica",3500,6500,5,"UNIT",1]] as const;
  const productInsert = database.prepare("INSERT INTO products (id,store_id,name,cost_price_cents,sale_price_cents,stock_quantity,stock_unit,min_stock_quantity,active,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,1,?,?)");
  const movementInsert = database.prepare("INSERT INTO stock_movements (id,store_id,product_id,transaction_id,type,quantity_delta,quantity_before,quantity_after,reason,occurred_at,created_at) VALUES (?,?,?,NULL,'INITIAL',?,0,?,'Estoque inicial',?,?)");
  database.exec("BEGIN");
  try {
    for (const [name,cost,price,stock,unit,minimum] of products) {
      const id=randomUUID(); productInsert.run(id,DEMO_STORE_ID,name,cost,price,stock,unit,minimum,now,now); movementInsert.run(randomUUID(),DEMO_STORE_ID,id,stock,stock,now,now);
    }
    database.exec("COMMIT");
  } catch(error) { database.exec("ROLLBACK"); throw error; }
}

