// Reactive Resume bootstrap for Railway (run by boot.sh in the background).
// Waits until the app is healthy (migrations are applied before it listens), then writes the administrator account and
// an API key straight into the database. Sign-up stays closed (FLAG_DISABLE_SIGNUPS), so this is the only way in.
// Idempotent: an existing account keeps its password; the API key is the template variable, so a changed API_KEY
// replaces the stored key.
const crypto = require("crypto");
const { Client } = require(process.env.PG_MODULE);
const bcrypt = require(process.env.BCRYPT_MODULE);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const uid = () => crypto.randomUUID();

async function waitHealthy() {
  for (let i = 0; i < 180; i++) {
    try {
      const r = await fetch(`http://127.0.0.1:${process.env.PORT}/api/health`);
      if (r.ok) return;
    } catch {}
    await sleep(2000);
  }
  throw new Error("app never became healthy");
}

async function main() {
  await waitHealthy();
  const email = process.env.ADMIN_EMAIL;
  const db = new Client({ connectionString: process.env.DATABASE_URL });
  await db.connect();
  try {
    await db.query("BEGIN");
    let id;
    const found = await db.query(`SELECT id FROM "user" WHERE lower(email) = lower($1)`, [email]);
    if (found.rows.length) {
      id = found.rows[0].id;
    } else {
      id = uid();
      await db.query(
        `INSERT INTO "user"(id, name, email, email_verified, username, display_username) VALUES ($1, 'Administrator', $2, true, 'admin', 'admin')`,
        [id, email]);
      const hash = await bcrypt.hash(process.env.ADMIN_PASSWORD, 10);
      await db.query(
        `INSERT INTO account(id, account_id, provider_id, user_id, password) VALUES ($1, $2, 'credential', $2, $3)`,
        [uid(), id, hash]);
    }
    const key = crypto.createHash("sha256").update(process.env.API_KEY).digest("base64url");
    await db.query(`DELETE FROM apikey WHERE reference_id = $1 AND name = 'railway-template' AND key <> $2`, [id, key]);
    await db.query(
      `INSERT INTO apikey(id, name, start, prefix, key, reference_id, rate_limit_enabled, rate_limit_time_window, rate_limit_max)
       SELECT $1, 'railway-template', $2, NULL, $3, $4, true, 3600000, 1000
       WHERE NOT EXISTS (SELECT 1 FROM apikey WHERE key = $3)`,
      [uid(), process.env.API_KEY.slice(0, 6), key, id]);
    await db.query("COMMIT");
    console.log("reactive-resume boot: administrator and API key seeded");
  } catch (e) {
    await db.query("ROLLBACK").catch(() => {});
    throw e;
  } finally {
    await db.end();
  }
}

main().catch((e) => { console.error("reactive-resume seed:", e.message); process.exit(1); });
