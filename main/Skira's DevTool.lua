--[[

NOTES:
- If it crashes your game restart it and re execute it, it'll work soon enough.
- If all props don't show up, it might be because you didn't load the chunk props are in.
- You can set distance to inf in settings.

]]--

if not CLIENT then return end

-- ===== State =====
local guiVisible = false
local optionsState = {["Prop ESP"]=false}
local propFilters = {}
local filterEnabled = false
local currentPopup = nil
local propSettings = {
    showBox=true,
    showOutline=true,
    showHighlight=true,
    showName=true,
    showDistance=false,
    boxColor=Color(0,150,255,255),
    outlineColor=Color(0,255,0,255),
    highlightColor=Color(255,0,0,100),
    nameColor=Color(255,255,255,255),
    maxDistance=2000,
    nameHeight=0
}

-- ===== Remove old hooks =====
hook.Remove("HUDPaint","PropESP")
hook.Remove("Think","SkiraPropESP_Toggle")

-- ===== Draw Prop ESP =====
local function DrawPropESP(ent,settings)
    if not IsValid(ent) then return end
    local ply = LocalPlayer()
    local dist = ply:GetPos():Distance(ent:GetPos())
    if settings.maxDistance ~= math.huge and dist > settings.maxDistance then return end

    -- Box (world)
    if settings.showBox then
        render.SetColorMaterial()
        render.DrawWireframeBox(ent:GetPos(),ent:GetAngles(),ent:OBBMins(),ent:OBBMaxs(),settings.boxColor,true)
    end

    -- Outline
    local pos = ent:LocalToWorld(ent:OBBCenter()):ToScreen()
    if settings.showOutline then
        surface.SetDrawColor(settings.outlineColor)
        surface.DrawOutlinedRect(pos.x-10,pos.y-10,20,20)
    end

    -- Name
    if settings.showName then
        draw.SimpleText(ent:GetClass(),"DermaDefault",pos.x,pos.y-settings.nameHeight,settings.nameColor,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end

    -- Distance
    if settings.showDistance then
        draw.SimpleText(math.Round(dist).." units","DermaDefault",pos.x,pos.y-settings.nameHeight+15,Color(255,255,0),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
end

local function UpdateESP()
    hook.Remove("HUDPaint","PropESP")
    if optionsState["Prop ESP"] then
        hook.Add("HUDPaint","PropESP",function()
            local entsAll = ents.GetAll()
            for i=1,#entsAll do
                local ent = entsAll[i]
                if ent:IsPlayer() then continue end
                if filterEnabled and next(propFilters) and not propFilters[ent:GetClass()] then continue end
                if filterEnabled and propFilters[ent:GetClass()] and not propFilters[ent:GetClass()].enabled then continue end
                DrawPropESP(ent,propSettings)
            end
        end)
    end
end

-- ===== Filter Popup =====
local function OpenFilterPopup()
    if IsValid(currentPopup) then currentPopup:Close() end
    local f = vgui.Create("DFrame")
    f:SetSize(400,400)
    f:SetTitle("Prop Filter")
    f:Center()
    f:MakePopup()
    currentPopup = f

    local scroll = vgui.Create("DScrollPanel",f)
    scroll:Dock(FILL)

    local enableCB = vgui.Create("DCheckBoxLabel",scroll)
    enableCB:SetText("Enable Filter")
    enableCB:SetValue(filterEnabled)
    enableCB:Dock(TOP)
    enableCB.OnChange = function(_,val)
        filterEnabled = val
        UpdateESP()
    end

    local addBtn = vgui.Create("DButton",scroll)
    addBtn:SetText("+ Add Prop")
    addBtn:Dock(TOP)
    addBtn.DoClick = function()
        Derma_StringRequest("Add Prop","Enter prop class:","",function(txt)
            if txt~="" then
                propFilters[txt] = {enabled=true}
                f:Close()
                OpenFilterPopup()
            end
        end)
    end

    local importBtn = vgui.Create("DButton",scroll)
    importBtn:SetText("Import List")
    importBtn:Dock(TOP)
    importBtn.DoClick = function()
        Derma_StringRequest("Import Props","Paste JSON list:","",function(txt)
            local ok,data = pcall(util.JSONToTable,txt)
            if ok and type(data)=="table" then
                propFilters = {}
                for _,v in ipairs(data) do
                    propFilters[v] = {enabled=true}
                end
                f:Close()
                OpenFilterPopup()
            end
        end)
    end

    local exportBtn = vgui.Create("DButton",scroll)
    exportBtn:SetText("Export List")
    exportBtn:Dock(TOP)
    exportBtn.DoClick = function()
        local list = {}
        for k,_ in pairs(propFilters) do table.insert(list,k) end
        SetClipboardText(util.TableToJSON(list))
        chat.AddText(Color(0,255,0),"Prop list copied to clipboard")
    end

    for class,info in pairs(propFilters) do
        local pnl = vgui.Create("DPanel",scroll)
        pnl:SetTall(25)
        pnl:Dock(TOP)
        pnl:DockMargin(5,2,5,2)
        local cb = vgui.Create("DCheckBoxLabel",pnl)
        cb:SetText(class)
        cb:SetValue(info.enabled)
        cb:Dock(FILL)
        cb.OnChange = function(_,val)
            propFilters[class].enabled = val
        end
        local rm = vgui.Create("DButton",pnl)
        rm:SetText("X")
        rm:SetSize(25,25)
        rm:Dock(RIGHT)
        rm.DoClick = function()
            propFilters[class]=nil
            f:Close()
            OpenFilterPopup()
        end
    end
end

-- ===== Settings Popup =====
local function OpenSettingsPopup()
    if IsValid(currentPopup) then currentPopup:Close() end
    local f = vgui.Create("DFrame")
    f:SetSize(450,450)
    f:SetTitle("Prop ESP Settings")
    f:Center()
    f:MakePopup()
    currentPopup = f

    local y=30
    local function AddCB(text,settingKey)
        local cb = vgui.Create("DCheckBoxLabel",f)
        cb:SetText(text)
        cb:SetValue(propSettings[settingKey])
        cb:SetPos(10,y)
        cb:SizeToContents()
        cb.OnChange = function(_,val) propSettings[settingKey]=val end

        local colorBtn = vgui.Create("DButton",f)
        colorBtn:SetText("Color")
        colorBtn:SetPos(150,y)
        colorBtn:SetSize(50,20)
        colorBtn.DoClick = function()
            local colPicker = vgui.Create("DFrame")
            colPicker:SetSize(300,300)
            colPicker:SetTitle("Pick color for "..text)
            colPicker:Center()
            colPicker:MakePopup()
            local cp = vgui.Create("DColorMixer",colPicker)
            cp:Dock(FILL)
            cp:SetColor(propSettings[settingKey.."Color"] or Color(255,255,255))
            local okBtn = vgui.Create("DButton",colPicker)
            okBtn:Dock(BOTTOM)
            okBtn:SetText("OK")
            okBtn.DoClick = function()
                propSettings[settingKey.."Color"]=cp:GetColor()
                colPicker:Close()
            end
        end

        y=y+30
    end

    AddCB("Show Box","showBox")
    AddCB("Show Outline","showOutline")
    AddCB("Show Highlight","showHighlight")
    AddCB("Show Name","showName")
    AddCB("Show Distance","showDistance")

    -- Distance textbox
    local lbl = vgui.Create("DLabel",f)
    lbl:SetText("Max Distance (type 'inf' for unlimited)")
    lbl:SetPos(10,y)
    lbl:SizeToContents()

    local distBox = vgui.Create("DTextEntry",f)
    distBox:SetPos(200,y)
    distBox:SetSize(100,20)
    distBox:SetText(propSettings.maxDistance == math.huge and "inf" or tostring(propSettings.maxDistance))
    distBox.OnEnter = function(self)
        local val = self:GetValue()
        if val=="inf" then
            propSettings.maxDistance = math.huge
        else
            local num = tonumber(val)
            if num then propSettings.maxDistance=num end
        end
    end
    y=y+30

    -- Name height
    local lbl2 = vgui.Create("DLabel",f)
    lbl2:SetText("Name Height Offset (can be negative)")
    lbl2:SetPos(10,y)
    lbl2:SizeToContents()

    local heightBox = vgui.Create("DTextEntry",f)
    heightBox:SetPos(200,y)
    heightBox:SetSize(100,20)
    heightBox:SetText(tostring(propSettings.nameHeight))
    heightBox.OnEnter = function(self)
        local val = tonumber(self:GetValue())
        if val then propSettings.nameHeight=val end
    end
end

-- ===== Main GUI =====
local function BuildGUI()
    if IsValid(MainFrame) then MainFrame:Remove() end
    MainFrame = vgui.Create("DFrame")
    MainFrame:SetSize(250,150)
    MainFrame:Center()
    MainFrame:SetTitle("Skira's Prop ESP")
    MainFrame:SetDraggable(true)
    MainFrame:MakePopup()

    local cb = vgui.Create("DCheckBoxLabel",MainFrame)
    cb:SetText("Enable Prop ESP")
    cb:SetValue(optionsState["Prop ESP"])
    cb:SetPos(10,30)
    cb:SizeToContents()
    cb.OnChange = function(_,val)
        optionsState["Prop ESP"] = val
        UpdateESP()
    end

    local settingsBtn = vgui.Create("DButton",MainFrame)
    settingsBtn:SetText("Settings")
    settingsBtn:SetPos(120,30)
    settingsBtn:SetSize(100,25)
    settingsBtn.DoClick = OpenSettingsPopup

    local filterBtn = vgui.Create("DButton",MainFrame)
    filterBtn:SetText("Filter")
    filterBtn:SetPos(120,60)
    filterBtn:SetSize(100,25)
    filterBtn.DoClick = OpenFilterPopup
end

-- ===== Toggle GUI =====
hook.Add("Think","SkiraPropESP_Toggle",function()
    if input.IsKeyDown(KEY_N) and not _G._NKeyDown then
        _G._NKeyDown = true
        guiVisible = not guiVisible
        if guiVisible then BuildGUI() end
        if IsValid(MainFrame) then MainFrame:SetVisible(guiVisible) end
    elseif not input.IsKeyDown(KEY_N) then
        _G._NKeyDown = false
    end
end)

UpdateESP()
