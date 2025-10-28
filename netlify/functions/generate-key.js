import fs from "fs";
import path from "path";

export async function handler(event) {
  if (event.httpMethod !== "POST") {
    return { statusCode: 405, body: JSON.stringify({ error: "Method not allowed" }) };
  }

  const { username, password, steamid } = JSON.parse(event.body || "{}");

  if (!username || !password || !steamid) {
    return { statusCode: 400, body: JSON.stringify({ error: "Missing username, password, or SteamID" }) };
  }

  const filePath = path.join(process.cwd(), "keys.json");
  let users = [];

  // Load existing data
  if (fs.existsSync(filePath)) {
    try {
      users = JSON.parse(fs.readFileSync(filePath, "utf8"));
    } catch {
      users = [];
    }
  }

  // Find existing user
  let user = users.find(u => u.username === username);

  // Generate new key
  const generated_key = Math.random().toString(36).substring(2, 10).toUpperCase();

  if (user) {
    // Verify password
    if (user.password !== password) {
      return { statusCode: 403, body: JSON.stringify({ error: "Invalid password" }) };
    }
    // Update SteamID and key
    user.steamid = steamid;
    user.generated_key = generated_key;
  } else {
    // Create new user
    user = { username, password, steamid, generated_key };
    users.push(user);
  }

  // Save updated list
  fs.writeFileSync(filePath, JSON.stringify(users, null, 2));

  return {
    statusCode: 200,
    body: JSON.stringify({ username, steamid, generated_key })
  };
}
