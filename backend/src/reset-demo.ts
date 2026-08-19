import { existsSync, unlinkSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const databasePath = join(here, "..", "data", "contaai.db");

for (const path of [databasePath, `${databasePath}-shm`, `${databasePath}-wal`]) {
  if (existsSync(path)) unlinkSync(path);
}

console.log("Demonstração restaurada. Execute npm start para recriar o banco e o seed.");
