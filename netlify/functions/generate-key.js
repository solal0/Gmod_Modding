import fs from "fs";
import path from "path";

export async function handler(event){
  if(event.httpMethod!=="POST"){
    return {statusCode:405,body:JSON.stringify({error:"Method not allowed"})};
  }

  let username="", password="", steamid="";
  try{
    ({username,password,steamid} = JSON.parse(event.body||"{}"));
  } catch(e){
    return {statusCode:400, body: JSON.stringify({error:"Invalid JSON"})};
  }

  if(!username || !password) return {statusCode:400, body: JSON.stringify({error:"Missing username or password"})};

  // Use ephemeral writable path
  const filePath = path.join("/tmp", "keys.json");
  let users = [];

  if(fs.existsSync(filePath)){
    try{ users = JSON.parse(fs.readFileSync(filePath,"utf8")); }catch{ users=[]; }
  }

  let user = users.find(u=>u.username===username);

  // Generate new key if SteamID is provided
  let generated_key = user?.generated_key || "";
  if(steamid){
    generated_key = Math.random().toString(36).substring(2,10).toUpperCase();
    if(user){
      if(user.password!==password) return {statusCode:403,body:JSON.stringify({error:"Invalid password"})};
      user.steamid = steamid;
      user.generated_key = generated_key;
    } else {
      user = { username, password, steamid, generated_key };
      users.push(user);
    }
    fs.writeFileSync(filePath, JSON.stringify(users,null,2));
  }

  return {
    statusCode:200,
    body: JSON.stringify({
      username,
      steamid: steamid || user?.steamid || "",
      generated_key
    })
  };
}
