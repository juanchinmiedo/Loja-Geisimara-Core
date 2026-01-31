const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const uids = require("./uids.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function mustExist(uid) {
  try {
    const u = await admin.auth().getUser(uid);
    console.log(`✅ Found: ${u.uid} | ${u.email || "no-email"}`);
    return u;
  } catch (e) {
    console.error(`❌ UID not found in Auth: ${uid}`);
    throw e;
  }
}

async function setClaims(uid, roles) {
  await admin.auth().setCustomUserClaims(uid, { roles });
  console.log(`✅ Claims set for ${uid}: ${JSON.stringify(roles)}`);
}

async function run() {
  console.log("Project:", serviceAccount.project_id);
  console.log("Setting claims...");

  // 🔥 Pega aquí los UID CORRECTOS (copiados de Authentication)
  const UID_GEISIMARA = uids.UID_GEISIMARA;
  const UID_JUAN = uids.UID_JUAN;

  // 1) Verifica que existen
  await mustExist(UID_GEISIMARA);
  await mustExist(UID_JUAN);

  // 2) Set claims
  await setClaims(UID_GEISIMARA, ["admin", "worker"]);
  await setClaims(UID_JUAN, ["admin"]);

  console.log("🎉 Done");
  process.exit(0);
}

run().catch((err) => {
  console.error("❌ Error:", err);
  process.exit(1);
});
