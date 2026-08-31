-- Simple HUD v7 DIAG - bare minimal draw first
if CLIENT then
    print("[SimpleHUD] file loaded v7 - bare draw test")

    surface.CreateFont("SimpleHUD_Large", { font = "Roboto", size = 26, weight = 700 })
    surface.CreateFont("SimpleHUD_Medium", { font = "Roboto", size = 20, weight = 700 })
    surface.CreateFont("SimpleHUD_Small", { font = "Roboto", size = 16, weight = 600 })
    surface.CreateFont("SimpleHUD_Tiny", { font = "Roboto", size = 14, weight = 600 })
    surface.CreateFont("SimpleHUD_Money", { font = "Roboto", size = 18, weight = 800 })

    local BG = Color(20, 20, 25, 240)
    local BG_BAR = Color(35, 35, 42)
    local ACCENT = Color(99, 102, 241)
    local FACE = 96
    local FACE_PAD = 12
    local CON_W, CON_H = 420, 146

    hook.Add("HUDShouldDraw", "SimpleHUD_HideDefaults", function(name)
        if name == "CHudChat" then return true end
        return false
    end)

    -- keep FacePanel but don't let its errors break HUDPaint
    local FacePanel
    local lastModel = ""
    local function CreateFacePanel()
        if IsValid(FacePanel) then FacePanel:Remove() end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        lastModel = ply:GetModel()
        FacePanel = vgui.Create("DModelPanel")
        FacePanel:SetSize(FACE, FACE)
        FacePanel:SetModel(lastModel)
        FacePanel:SetFOV(44)
        FacePanel:SetLookAt(Vector(0, 0, 62))
        FacePanel:SetCamPos(Vector(30, 0, 64))
        FacePanel:SetAnimated(true)
        FacePanel:SetMouseInputEnabled(false)
        FacePanel.OnMouseWheeled = function() return true end
        FacePanel.OnMousePressed = function() end
        FacePanel.DoClick = function() end
        FacePanel.OnCursorMoved = function() end
        FacePanel.LayoutEntity = function(self, ent)
            if not IsValid(ent) then return end
            local ply2 = LocalPlayer()
            if not IsValid(ply2) then return end
            local eyeAng = ply2:EyeAngles()
            local baseYaw = 0
            local rawDelta = math.NormalizeAngle(eyeAng.y)
            local clampedDelta = math.Clamp(rawDelta, -25, 25)
            local yaw = baseYaw + clampedDelta
            local pitch = math.Clamp(eyeAng.p * 0.15, -6, 6)
            ent:SetAngles(Angle(pitch, yaw, 0))
            if ent.SetEyeTarget then
                local eyeFwd = Angle(0, clampedDelta, 0):Forward()
                ent:SetEyeTarget(Vector(80,0,64) + eyeFwd * 12)
            end
            ent:FrameAdvance(FrameTime())
            self:RunAnimation()
        end
        local _oldPaint = FacePanel.Paint
        function FacePanel:Paint(w, h)
            -- pcall so face errors don't spam
            local ok, err = pcall(function()
                draw.RoundedBox(12, 0, 0, w, h, Color(0,0,0,120))
                _oldPaint(self, w, h)
                surface.SetDrawColor(255,255,255,18)
                surface.DrawOutlinedRect(0,0,w,h,1)
            end)
            if not ok then print("[SimpleHUD FacePaint err] " .. err) end
        end
    end
    hook.Add("InitPostEntity", "SimpleHUD_CreateFace", CreateFacePanel)
    hook.Add("Think", "SimpleHUD_FaceThink", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not IsValid(FacePanel) then return end
        if ply:GetModel() ~= lastModel then CreateFacePanel() end
        local cx, cy = 16, ScrH() - CON_H - 16
        FacePanel:SetPos(cx + FACE_PAD, cy + FACE_PAD)
        FacePanel:SetVisible(not ply:ShouldDrawLocalPlayer() and ply:Alive())
        if FacePanel:IsVisible() then FacePanel:MoveToFront() end
    end)

    CreateClientConVar("simplehud_debug", "0", false, false)
    local nextPrint = 0
    local frameCount = 0

    local function SafeGetCVarInt(name, def)
        local cv = GetConVar(name)
        if cv then return cv:GetInt() end
        return def
    end

    local function HealthColor(frac)
        if frac > 0.6 then return Color(34,197,94) end
        if frac > 0.3 then return Color(234,179,8) end
        return Color(239,68,68)
    end

    local function PaintHUDCommon()
        -- BARE MINIMAL FIRST DRAW - before any risky code, should always appear if hook runs
        local sw, sh = ScrW(), ScrH()
        -- hard red bar top - no dependencies
        surface.SetDrawColor(255, 0, 0, 255)
        surface.DrawRect(sw/2 - 160, 20, 320, 24)
        draw.SimpleText("HUD ACTIVE v7", "SimpleHUD_Medium", sw/2, 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        -- magenta center fallback bar - always 50% fill
        surface.SetDrawColor(0,0,0,255)
        surface.DrawRect(sw/2 - 160, sh/2, 320, 24)
        surface.SetDrawColor(255,0,255,255)
        surface.DrawRect(sw/2 - 158, sh/2+2, 160, 20)
        surface.SetDrawColor(255,255,255,80)
        surface.DrawOutlinedRect(sw/2 - 160, sh/2, 320, 24, 2)
        draw.SimpleText("CENTER FALLBACK - if you see this, HUDPaint works", "SimpleHUD_Tiny", sw/2, sh/2+12, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- now try real hud with pcall
        local ok, err = pcall(function()
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            local hp = ply:Health()
            local maxHp = ply:GetMaxHealth() if maxHp == 0 then maxHp = 100 end
            local armor = ply:Armor()
            local hpFrac = math.Clamp(hp / math.max(maxHp,1), 0, 1)
            local col = HealthColor(hpFrac)

            -- prove we got here
            surface.SetDrawColor(0,255,0,255)
            surface.DrawRect(sw/2 - 160, 50, 320 * hpFrac, 6)

            local cw, ch = CON_W, CON_H
            local cx, cy = 16, sh - ch - 16
            draw.RoundedBox(12, cx, cy, cw, ch, BG)
            draw.RoundedBoxEx(12, cx, cy, cw, 3, ACCENT, true, true, false, false)

            if not IsValid(FacePanel) then
                draw.RoundedBox(10, cx + FACE_PAD, cy + FACE_PAD, FACE, FACE, Color(45,45,52))
            end

            -- health bar under square - ultra simple surface path
            local hbX = cx + FACE_PAD
            local hbY = cy + FACE_PAD + FACE + 6
            local hbW = FACE
            local hbH = 16
            surface.SetDrawColor(0,0,0,255)
            surface.DrawRect(hbX, hbY, hbW, hbH)
            surface.SetDrawColor(45,45,52,255)
            surface.DrawRect(hbX+2, hbY+2, hbW-4, hbH-4)
            if hpFrac > 0 then
                surface.SetDrawColor(col.r, col.g, col.b, 255)
                surface.DrawRect(hbX+2, hbY+2, (hbW-4)*hpFrac, hbH-4)
            end
            surface.SetDrawColor(255,255,0,255)
            surface.DrawOutlinedRect(hbX-1, hbY-1, hbW+2, hbH+2, 2)
            local txt = math.Round(hp) .. " HP"
            draw.SimpleText(txt, "SimpleHUD_Tiny", hbX + hbW/2 +1, hbY + hbH/2+1, Color(0,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(txt, "SimpleHUD_Tiny", hbX + hbW/2, hbY + hbH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- also draw real hp green line under red top bar so you see hpFrac works
            draw.SimpleText("hp="..hp.." max="..maxHp.." frac="..math.Round(hpFrac*100).."% hb@"..hbX..","..hbY, "SimpleHUD_Tiny", sw/2, 62, Color(0,255,0), TEXT_ALIGN_CENTER)

            -- right bars simplified
            local tx = cx + FACE_PAD + FACE + 12
            local bw2 = cw - (tx - cx) - 12
            local by = cy + 56
            surface.SetDrawColor(35,35,42,255)
            surface.DrawRect(tx, by, bw2, 10)
            surface.SetDrawColor(col.r, col.g, col.b, 255)
            surface.DrawRect(tx, by, bw2*hpFrac, 10)
            by = by + 14
            surface.SetDrawColor(35,35,42,255)
            surface.DrawRect(tx, by, bw2, 10)
            surface.SetDrawColor(59,130,246,255)
            surface.DrawRect(tx, by, bw2 * math.Clamp(armor/100,0,1), 10)
        end)
        if not ok then
            -- show error on screen + console
            surface.SetDrawColor(255,0,0,200)
            surface.DrawRect(sw/2 - 200, 80, 400, 22)
            draw.SimpleText("HUD ERROR: " .. tostring(err):sub(1,80), "SimpleHUD_Tiny", sw/2, 91, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if CurTime() > nextPrint then
                print("[SimpleHUD v7 ERROR] " .. err)
                nextPrint = CurTime() + 2
            end
        else
            frameCount = frameCount + 1
            if frameCount == 60 or (GetConVar("simplehud_debug"):GetBool() and CurTime() > nextPrint) then
                if frameCount == 60 then print("[SimpleHUD v7] HUDPaint called successfully, frame 60, sw="..sw.." sh="..sh) end
                if GetConVar("simplehud_debug"):GetBool() then
                    print("[SimpleHUD v7] ok frame " .. frameCount)
                    nextPrint = CurTime() + 1
                end
            end
        end
    end

    hook.Add("HUDPaint", "SimpleHUD_Draw", PaintHUDCommon)
    -- also try HUDPaintBackground to catch if something blocks HUDPaint
    hook.Add("HUDPaintBackground", "SimpleHUD_Draw_BG", PaintHUDCommon)

    concommand.Add("simplehud_test", function()
        local ply = LocalPlayer()
        print("[SimpleHUD test v7] Health="..ply:Health().." Max="..ply:GetMaxHealth().." cl_drawhud="..SafeGetCVarInt("cl_drawhud",-1).." Scr="..ScrW().."x"..ScrH().." hooks HUDPaint="..tostring(hook.GetTable()["HUDPaint"]["SimpleHUD_Draw"] ~= nil).." BG="..tostring(hook.GetTable()["HUDPaintBackground"]["SimpleHUD_Draw_BG"] ~= nil))
        -- force print if hook was called
        print("[SimpleHUD test v7] frameCount="..frameCount.." nextPrint="..nextPrint.." curTime="..CurTime())
    end)
    timer.Simple(2, function()
        print("[SimpleHUD] v7 hooks: HUDPaint="..tostring(hook.GetTable()["HUDPaint"]["SimpleHUD_Draw"] ~= nil).." BG="..tostring(hook.GetTable()["HUDPaintBackground"]["SimpleHUD_Draw_BG"] ~= nil))
    end)
end
