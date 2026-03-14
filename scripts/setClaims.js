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

async function setClaims(uid, roles, workerId = null) {
  const claims = { roles };
  if (workerId) claims.workerId = workerId;
  await admin.auth().setCustomUserClaims(uid, claims);
  console.log(`✅ Claims set for ${uid}: ${JSON.stringify(claims)}`);
}

async function run() {
  console.log("Project:", serviceAccount.project_id);
  console.log("Setting claims...");

  const UID_GEISIMARA = uids.UID_GEISIMARA;
  const UID_JUAN      = uids.UID_JUAN;
  const UID_ANA       = uids.UID_ANA;

  await mustExist(UID_GEISIMARA);
  await mustExist(UID_JUAN);
  await mustExist(UID_ANA);

  // admin + worker  → preselecciona su propia pill, puede ver todo
  await setClaims(UID_GEISIMARA, ["admin", "worker"], "Geisimara_Santos_Souza");

  // admin puro      → empieza en ALL, puede ver todo
  await setClaims(UID_JUAN, ["admin"]);

  // worker puro     → bloqueada a su propio worker, no ve nada de otros
  await setClaims(UID_ANA, ["worker"], "Flavia_Flores");

  console.log("🎉 Done");
  process.exit(0);
}

run().catch((err) => {
  console.error("❌ Error:", err);
  process.exit(1);
});
