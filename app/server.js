import http from "http";
import { EdgeFeatureHubConfig } from "featurehub-javascript-client-sdk";

const port = process.env.PORT || 8080;
const version = process.env.APP_VERSION || "dev";
const failHealth = process.env.FAIL_HEALTH === "1";

const featureHubUrl = process.env.FEATUREHUB_URL;
const featureKey = process.env.FEATURE_KEY;

let danishGreetingEnabled = false;

async function initFeatureHub() {
  if (!featureHubUrl || !featureKey) {
    console.log("FeatureHub not configured (FEATUREHUB_URL/FEATURE_KEY missing). Flags default OFF.");
    return;
  }

  const config = new EdgeFeatureHubConfig(featureHubUrl, featureKey);
  const fh = await config.newContext().build();

  const feature = fh.feature("DanishGreeting");
  danishGreetingEnabled = feature.isEnabled();

  feature.addListener((f) => {
    danishGreetingEnabled = f.isEnabled();
    console.log("Flag DanishGreeting changed:", danishGreetingEnabled);
  });

  console.log("Connected to FeatureHub. DanishGreeting =", danishGreetingEnabled);
}

initFeatureHub().catch((e) => console.error("FeatureHub init failed:", e));

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    if (failHealth) {
      res.statusCode = 500;
      res.end("unhealthy\n");
      return;
    }
    res.statusCode = 200;
    res.end("ok\n");
    return;
  }

  res.statusCode = 200;
  if (danishGreetingEnabled) {
    res.end(`Hej! (version: ${version})\n`);
  } else {
    res.end(`Hello from version: ${version}\n`);
  }
});

server.listen(port, () => {
  console.log(`Listening on :${port} (version=${version})`);
});
