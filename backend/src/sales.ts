import { randomUUID } from "node:crypto";
import { database, DEMO_STORE_ID } from "./database.js";
import type { Product, SaleItemInput, SalePreview } from "./domain.js";

const money=(value:number)=>Math.round(value);
export function getProduct(id:string):Product|undefined {
  const row=database.prepare("SELECT id,name,cost_price_cents,sale_price_cents,stock_quantity,stock_unit,min_stock_quantity,active,created_at,updated_at FROM products WHERE id=? AND store_id=? AND active=1").get(id,DEMO_STORE_ID) as (Omit<Product,"active">&{active:number})|undefined;
  return row?{...row,active:Boolean(row.active)}:undefined;
}

export function buildSalePreview(input:{items:SaleItemInput[];source:"TEXT"|"VOICE"|"MANUAL";original_input?:string|null;occurred_at?:string}):SalePreview {
  const warnings:string[]=[];
  const items=input.items.map(requested=>{
    const product=getProduct(requested.product_id); if(!product) throw new Error("PRODUCT_NOT_FOUND");
    const total=money(requested.quantity*requested.unit_price_cents), cost=money(requested.quantity*product.cost_price_cents), profit=total-cost, after=product.stock_quantity-requested.quantity;
    if(after<0) warnings.push(`${product.name}: o estoque ficará negativo.`); else if(after<=product.min_stock_quantity) warnings.push(`${product.name}: estoque baixo após a venda.`);
    if(requested.unit_price_cents!==product.sale_price_cents) warnings.push(`${product.name}: preço diferente do cadastro.`);
    if(profit<0) warnings.push(`${product.name}: esta venda terá margem negativa.`);
    return {product_id:product.id,product_name:product.name,quantity:requested.quantity,stock_unit:product.stock_unit,unit_price_cents:requested.unit_price_cents,unit_cost_cents:product.cost_price_cents,total_amount_cents:total,total_cost_cents:cost,gross_profit_cents:profit,margin_percent:total===0?null:Number(((profit/total)*100).toFixed(2)),stock_before:product.stock_quantity,stock_after:after};
  });
  const total=items.reduce((s,i)=>s+i.total_amount_cents,0),cost=items.reduce((s,i)=>s+i.total_cost_cents,0),profit=total-cost;
  return {description:`Venda de ${items.map(i=>i.product_name).join(", ")}`,source:input.source,original_input:input.original_input??null,occurred_at:input.occurred_at??new Date().toISOString(),items,total_amount_cents:total,total_cost_cents:cost,gross_profit_cents:profit,margin_percent:total===0?null:Number(((profit/total)*100).toFixed(2)),warnings};
}

const words:Record<string,number>={um:1,uma:1,dois:2,duas:2,tres:3,"três":3,quatro:4,cinco:5,seis:6,sete:7,oito:8,nove:9,dez:10,vinte:20,trinta:30,quarenta:40,cinquenta:50,sessenta:60,setenta:70,oitenta:80,noventa:90,cem:100};
function parseNumber(token?:string){if(!token)return undefined;const normalized=token.toLocaleLowerCase("pt-BR").replace(",",".");const numeric=Number(normalized);return Number.isFinite(numeric)?numeric:words[normalized];}
export function interpretSaleText(text:string):SalePreview {
  const normalized=text.toLocaleLowerCase("pt-BR");
  const products=database.prepare("SELECT id,name,sale_price_cents FROM products WHERE store_id=? AND active=1 ORDER BY length(name) DESC").all(DEMO_STORE_ID) as Array<{id:string;name:string;sale_price_cents:number}>;
  const product=products.find(p=>{const full=p.name.toLocaleLowerCase("pt-BR"),first=full.split(" ")[0]??full,singular=first.replace(/s$/,'');return normalized.includes(full)||normalized.includes(first)||normalized.includes(singular);});
  if(!product)throw new Error("PRODUCT_NOT_IDENTIFIED");
  const tokens=normalized.replace(/[.,!?]/g," ").split(/\s+/),verb=tokens.findIndex(t=>t.startsWith("vend")),quantity=parseNumber(tokens[verb+1]);
  if(!quantity||quantity<=0)throw new Error("QUANTITY_NOT_IDENTIFIED");
  const marker=tokens.findIndex(t=>t==="por"||t==="a"),spoken=parseNumber(tokens[marker+1]),each=normalized.includes("cada")||normalized.includes("unidade");
  const unitPrice=spoken?money((each?spoken:spoken/quantity)*100):product.sale_price_cents;
  return buildSalePreview({items:[{product_id:product.id,quantity,unit_price_cents:unitPrice}],source:"TEXT",original_input:text});
}

export function confirmSale(input:{items:SaleItemInput[];source:"TEXT"|"VOICE"|"MANUAL";original_input?:string|null;occurred_at?:string;idempotency_key:string}) {
  const existing=database.prepare("SELECT id FROM transactions WHERE store_id=? AND idempotency_key=?").get(DEMO_STORE_ID,input.idempotency_key) as {id:string}|undefined;
  if(existing)return {transaction_id:existing.id,already_confirmed:true};
  const preview=buildSalePreview(input),transactionId=randomUUID(),now=new Date().toISOString();
  database.exec("BEGIN IMMEDIATE");
  try {
    database.prepare("INSERT INTO transactions (id,store_id,type,status,source,description,total_amount_cents,total_cost_cents,gross_profit_cents,margin_percent,original_input,occurred_at,idempotency_key,created_at,updated_at) VALUES (?,?,'SALE','CONFIRMED',?,?,?,?,?,?,?,?,?,?,?)").run(transactionId,DEMO_STORE_ID,input.source,preview.description,preview.total_amount_cents,preview.total_cost_cents,preview.gross_profit_cents,preview.margin_percent,input.original_input??null,preview.occurred_at,input.idempotency_key,now,now);
    for(const item of preview.items){const current=getProduct(item.product_id);if(!current)throw new Error("PRODUCT_NOT_FOUND");const after=current.stock_quantity-item.quantity;
      database.prepare("INSERT INTO transaction_items (id,transaction_id,product_id,product_name_snapshot,stock_unit_snapshot,quantity,unit_price_cents,unit_cost_cents,total_amount_cents,total_cost_cents,gross_profit_cents,margin_percent,created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)").run(randomUUID(),transactionId,item.product_id,current.name,current.stock_unit,item.quantity,item.unit_price_cents,current.cost_price_cents,item.total_amount_cents,item.total_cost_cents,item.gross_profit_cents,item.margin_percent,now);
      database.prepare("UPDATE products SET stock_quantity=?,updated_at=? WHERE id=?").run(after,now,item.product_id);
      database.prepare("INSERT INTO stock_movements (id,store_id,product_id,transaction_id,type,quantity_delta,quantity_before,quantity_after,reason,occurred_at,created_at) VALUES (?,?,?,?,'SALE',?,?,?,NULL,?,?)").run(randomUUID(),DEMO_STORE_ID,item.product_id,transactionId,-item.quantity,current.stock_quantity,after,preview.occurred_at,now);
    }
    database.exec("COMMIT");return {transaction_id:transactionId,already_confirmed:false,preview};
  }catch(error){database.exec("ROLLBACK");throw error;}
}
