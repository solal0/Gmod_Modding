import fs from "fs";
import path from "path";

export async function handler(event){
  if(event.httpMethod!=="POST"){
    return {statusCode:405,body:JSON.stringify({error:"Method not allowed"})};
  }

  const {username,password,steamid} = JSON.parse(event.body||"{}");
  if(!username||!password) return {statusCode:400,body:JSON.stringify({error:"Missing username or password"})};

  const filePath = path.join(process.cwd(),"keys.json");
  let users = [];

  if(fs.existsSync(filePath)){
    try{
      users = JSON.parse(fs.readFileSync(filePath,"utf8"));
    }catch{ users=[]; }
  }

  let user = users.find(u=>u.username===username);

  // If SteamID is empty and user exists, only login (return current key)
  if(user && !steamid){
    if(user.password!==password) return {statusCode:403,body:JSON.stringify({error:"Invalid password"})};
    return {statusCode:200,body:JSON.stringify({username,user,password,steamid:user.steamid,generated_key:user.generated_key})};
  }

  // Generate new key
  const generated_key = Math.random().toString(36).substring(2,10).toUpperCase();

  if(user){
    if(user.password!==password) return {statusCode:403,body:JSON.stringify({error:"Invalid password"})};
    user.steamid = steamid;
    user.generated_key = generated_key;
  } else {
    user = {username,password,steamid,generated_key};
    users.push(user);
  }

  fs.writeFileSync(filePath,JSON.stringify(users,null,2));

  return {statusCode:200,body:JSON.stringify({username,steamid,generated_key})};
}
