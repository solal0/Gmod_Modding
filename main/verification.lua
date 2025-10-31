-- SHS (Skira's Handshake)
local API_BASE = "https://linkvertise-verifier.linkvertise-verifier-gmod.workers.dev"
local VERIFY_URL = "https://solal0.github.io/Gmod_Modding/"
local REMOTE_CODE_URL = "https://solal0.github.io/Gmod_Modding/main/helloworld.lua"

local function cleanup_cmds()
    if concommand.Remove then
        pcall(function()
            concommand.Remove("shs_copy")
            concommand.Remove("shs_verify")
            concommand.Remove("shs_kill")
        end)
    end
end

local function getPlayerSteam64()
    local ply = LocalPlayer()
    if not IsValid(ply) then return nil end
    if ply.SteamID64 and ply:SteamID64() ~= "" then return ply:SteamID64() end
    if ply.SteamID and util and util.SteamIDTo64 then
        return util.SteamIDTo64(ply:SteamID())
    end
    return nil
end

print("SHS (Skira's Handshake) initializing...")
print("[SHS]: Success !")
print("          _____                    _____                    _____          ")
print("         /\    \                  /\    \                  /\    \         ")
print("        /::\    \                /::\____\                /::\    \        ")
print("       /::::\    \              /:::/    /               /::::\    \       ")
print("      /::::::\    \            /:::/    /               /::::::\    \      ")
print("     /:::/\:::\    \          /:::/    /               /:::/\:::\    \     ")
print("    /:::/__\:::\    \        /:::/____/               /:::/__\:::\    \    ")
print("    \:::\   \:::\    \      /::::\    \               \:::\   \:::\    \   ")
print("  ___\:::\   \:::\    \    /::::::\    \   _____    ___\:::\   \:::\    \  ")
print(" /\   \:::\   \:::\    \  /:::/\:::\    \ /\    \  /\   \:::\   \:::\    \ ")
print("/::\   \:::\   \:::\____\/:::/  \:::\    /::\____\/::\   \:::\   \:::\____\")
print("\:::\   \:::\   \::/    /\::/    \:::\  /:::/    /\:::\   \:::\   \::/    /")
print(" \:::\   \:::\   \/____/  \/____/ \:::\/:::/    /  \:::\   \:::\   \/____/ ")
print("  \:::\   \:::\    \               \::::::/    /    \:::\   \:::\    \     ")
print("   \:::\   \:::\____\               \::::/    /      \:::\   \:::\____\    ")
print("    \:::\  /:::/    /               /:::/    /        \:::\  /:::/    /    ")
print("     \:::\/:::/    /               /:::/    /          \:::\/:::/    /     ")
print("      \::::::/    /               /:::/    /            \::::::/    /      ")
print("       \::::/    /               /:::/    /              \::::/    /       ")
print("        \::/    /                \::/    /                \::/    /        ")
print("         \/____/kira's            \/____/and               \/____/hake     ")

local ply = LocalPlayer()
if not IsValid(ply) then
    print("[SHS]: Could not find LocalPlayer().")
    return
end

local steam64 = getPlayerSteam64()
if not steam64 then
    print("[SHS]: Could not determine SteamID64.")
    return
end

print("[SHS]: Trying to do that lovely handshake for "..steam64.." with our good homie the API...")

http.Fetch(API_BASE.."/api/check?steamid="..steam64,
    function(body)
        local ok, data = pcall(util.JSONToTable, body)
        if ok and data and data.verified then
            print("[SHS]: Already valid ? That's my man right there, enjoy and thank you !")
            cleanup_cmds()
        else
            print("[SHS]: Meh, I could've seen this coming from a mile away. But no worries, it happens that i added the url to gain access in your clipboard just now !")
            print(" ")
            print("|      -- == Skira's Handshake Commands == --      |")
            print("|  shs_copy   | copy verification url to clipboard.        |")
            print("|  shs_verify | tries another handshake with the API      |")
            print("|  shs_kill   | Clear everything the script created.      |")
            print("|     -- == -- -- -- -- | == -- == | -- -- -- -- == --      |")
            print(" ")
            print("Having troubles ? Check out my github profile, there's a link to my discord. https://github.com/solal0")

            pcall(function() SetClipboardText(VERIFY_URL) end)

            concommand.Add("shs_copy", function()
                pcall(function() SetClipboardText(VERIFY_URL) end)
                print("[SHS] Verification URL copied to clipboard.")
            end)

            concommand.Add("shs_verify", function()
                print("[SHS] Attempting handshake again...")
                local checkUrl = API_BASE.."/api/check?steamid="..steam64
                http.Fetch(checkUrl,
                    function(resp)
                        local ok2, data2 = pcall(util.JSONToTable, resp)
                        if ok2 and data2 and data2.verified then
                            print("[SHS]: Handshake was a success. Status: true")
                            http.Fetch(REMOTE_CODE_URL,
                                function(code)
                                    local func = CompileString(code or "", "shs_remote_code", false)
                                    if isfunction(func) then
                                        local ok3, err3 = pcall(func)
                                        if not ok3 then print("[SHS] Remote code error: "..tostring(err3)) end
                                    else
                                        print("[SHS] Compile error: "..tostring(func))
                                    end
                                    cleanup_cmds()
                                    print("[SHS] Cleanup done. Shutting down SHS.")
                                end,
                                function(err)
                                    print("[SHS] Failed to fetch remote code: "..tostring(err))
                                    cleanup_cmds()
                                    print("[SHS] Cleanup done. Shutting down SHS.")
                                end
                            )
                        else
                            print("[SHS]: Nuh uh, you're still not verified, do all 3 checkpoints and put your SteamID64 to verify, else it won't work.")
                        end
                    end,
                    function(err)
                        print("[SHS] Handshake retry failed (network): "..tostring(err))
                        pcall(function() SetClipboardText(VERIFY_URL) end)
                        print("[SHS] Verification URL copied to clipboard.")
                    end
                )
            end)

            concommand.Add("shs_kill", function()
                cleanup_cmds()
                print("[SHS] All SHS resources cleared.")
            end)
        end
    end,
    function(err)
        print("[SHS] Handshake failed (network): "..tostring(err))
        pcall(function() SetClipboardText(VERIFY_URL) end)
        print("[SHS] Verification URL copied to clipboard.")
    end
)
