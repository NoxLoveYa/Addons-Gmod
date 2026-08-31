-- Simple HUD DarkRP Modern + Visage 3D temps réel | v5 FORCED VISIBLE
if CLIENT then
    print("[SimpleHUD] file loaded v5 - if you don't see this, addon not installed correctly")

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
    hook.Add("PostGamemodeLoaded", "SimpleHUD_DisableDarkRP", function()
        if GAMEMODE and GAMEMODE.Config then GAMEMODE.Config.enableHUD = false end
    end)
    timer.Simple(2, function()
        hook.Remove("HUDPaint", "DarkRP_HUD")
        hook.Remove("HUDPaint", "DarkRP_EntityDisplay")
        hook.Remove("HUDPaintBackground", "DarkRP_HUD")
    end)

    -- === Visage 3D ===
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
            local baseYaw = 0 -- facing camera (180 flip from -180)
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
            draw.RoundedBox(12, 0, 0, w, h, Color(0,0,0,120))
            _oldPaint(self, w, h)
            surface.SetDrawColor(255,255,255,18)
            surface.DrawOutlinedRect(0,0,w,h,1)
        end
    end
    hook.Add("InitPostEntity", "SimpleHUD_CreateFace", CreateFacePanel)
    hook.Add("OnPlayerChangedTeam", "SimpleHUD_FaceTeam", function() timer.Simple(0.5, CreateFacePanel) end)
    hook.Add("Think", "SimpleHUD_FaceThink", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not IsValid(FacePanel) then return end
        if ply:GetModel() ~= lastModel then CreateFacePanel() end
        local cx, cy = 16, ScrH() - CON_H - 16
        FacePanel:SetPos(cx + FACE_PAD, cy + FACE_PAD)
        FacePanel:SetVisible(not ply:ShouldDrawLocalPlayer() and ply:Alive())
    end)

    local dispHealth, dispArmor, dispHunger = 100, 0, 100
    local function DrawBar(x, y, w, h, frac, col)
        frac = math.Clamp(frac, 0, 1)
        draw.RoundedBox(4, x, y, w, h, BG_BAR)
        if frac > 0 then draw.RoundedBox(4, x, y, w * frac, h, col) end
    end
    local function HealthColor(frac)
        if frac > 0.6 then return Color(34,197,94) end
        if frac > 0.3 then return Color(234,179,8) end
        return Color(239,68,68)
    end
    local function FormatMoney(n)
        if DarkRP and DarkRP.formatMoney then return DarkRP.formatMoney(n) end
        return "$" .. tostring(n or 0)
    end

    CreateClientConVar("simplehud_debug", "0", false, false)
    local nextPrint = 0

    -- Helper that draws health bar with FORCED visibility - called from 2 hooks
    local function DrawHealthBarUnderSquare(cx, cy, hp, maxHp, label)
        local hbX = cx + FACE_PAD
        local hbY = cy + FACE_PAD + FACE + 6
        local hbW = FACE
        local hbH = 16
        local hpFrac = math.Clamp(hp / math.max(maxHp,1), 0, 1)
        local col = HealthColor(hpFrac)
        -- outer black
        surface.SetDrawColor(0,0,0,255)
        surface.DrawRect(hbX, hbY, hbW, hbH)
        -- inner dark
        surface.SetDrawColor(45,45,52,255)
        surface.DrawRect(hbX+2, hbY+2, hbW-4, hbH-4)
        -- fill
        if hpFrac > 0 then
            surface.SetDrawColor(col.r, col.g, col.b, 255)
            surface.DrawRect(hbX+2, hbY+2, (hbW-4) * hpFrac, hbH-4)
        else
            surface.SetDrawColor(180, 0, 0, 255)
            surface.DrawRect(hbX+2, hbY+2, hbW-4, hbH-4)
        end
        surface.SetDrawColor(255,255,255,60)
        surface.DrawOutlinedRect(hbX, hbY, hbW, hbH, 1)
        local txt = math.max(0, math.Round(hp)) .. " HP"
        if label then txt = txt .. " " .. label end
        draw.SimpleText(txt, "SimpleHUD_Tiny", hbX + hbW/2 + 1, hbY + hbH/2 + 1, Color(0,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(txt, "SimpleHUD_Tiny", hbX + hbW/2, hbY + hbH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return hbX, hbY, hbW, hbH, hpFrac, col
    end

    local function PaintHUDCommon()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local sw, sh = ScrW(), ScrH()
        local hp = ply:Health()
        local maxHp = ply:GetMaxHealth() if maxHp == 0 then maxHp = 100 end
        local armor = ply:Armor()
        local hunger = 100
        if ply.getDarkRPVar then
            local e = ply:getDarkRPVar("Energy")
            if e ~= nil then hunger = e end
        end
        dispHealth = Lerp(FrameTime() * 8, dispHealth, math.Clamp(hp, 0, maxHp))
        dispArmor = Lerp(FrameTime() * 8, dispArmor, armor)
        dispHunger = Lerp(FrameTime() * 8, dispHunger, hunger)

        local cw, ch = CON_W, CON_H
        local cx, cy = 16, sh - ch - 16

        -- PROOF hud is drawing: red bar at top center (impossible to miss) + container
        -- If you don't see this red bar, HUDPaint hook isn't running at all
        surface.SetDrawColor(255, 0, 0, 255)
        surface.DrawRect(sw/2 - 120, 40, 240, 18)
        draw.SimpleText("HUD ACTIVE v5 - HP " .. hp .. "/" .. maxHp, "SimpleHUD_Small", sw/2, 49, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.RoundedBox(12, cx, cy, cw, ch, BG)
        draw.RoundedBoxEx(12, cx, cy, cw, 3, ACCENT, true, true, false, false)

        if not IsValid(FacePanel) then
            draw.RoundedBox(10, cx + FACE_PAD, cy + FACE_PAD, FACE, FACE, Color(45,45,52))
            draw.SimpleText("...", "SimpleHUD_Small", cx + FACE_PAD + FACE/2, cy + FACE_PAD + FACE/2, Color(255,255,255,80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- HEALTH BAR UNDER SQUARE - guaranteed surface path
        local hbX, hbY, hbW, hbH, hpFrac, col = DrawHealthBarUnderSquare(cx, cy, hp, maxHp)

        -- DEBUG box around it if enabled
        if GetConVar("simplehud_debug"):GetBool() then
            surface.SetDrawColor(255,255,0,255)
            surface.DrawOutlinedRect(hbX-2, hbY-2, hbW+4, hbH+4, 2)
            local dbgW, dbgH = 300, 22
            local dbgX, dbgY = sw/2 - dbgW/2, 65
            surface.SetDrawColor(0,0,0,220)
            surface.DrawRect(dbgX, dbgY, dbgW, dbgH)
            surface.SetDrawColor(col.r, col.g, col.b, 255)
            surface.DrawRect(dbgX+2, dbgY+2, (dbgW-4)*hpFrac, dbgH-4)
            draw.SimpleText(hp .. "/" .. maxHp .. " frac " .. math.Round(hpFrac*100) .. "% @" .. hbX .. "," .. hbY, "SimpleHUD_Tiny", sw/2, dbgY+dbgH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if CurTime() > nextPrint then
                print("[SimpleHUD v5] hp="..hp.." maxHp="..maxHp.." hpFrac="..hpFrac.." hb="..hbX..","..hbY.." sw="..sw.." sh="..sh.." cy="..cy.." hook=HUDPaint")
                nextPrint = CurTime() + 2
            end
        end

        -- Infos à droite
        local tx = cx + FACE_PAD + FACE + 12
        local ty = cy + 14
        local name = ply:Nick()
        if string.len(name) > 22 then name = string.sub(name, 1, 22) .. "…" end
        draw.SimpleText(name, "SimpleHUD_Medium", tx, ty, color_white)
        local job = "Inconnu"
        local money, salary = 0, 0
        if ply.getDarkRPVar then
            job = ply:getDarkRPVar("job") or job
            money = ply:getDarkRPVar("money") or 0
            salary = ply:getDarkRPVar("salary") or 0
        end
        surface.SetFont("SimpleHUD_Tiny")
        local jw = surface.GetTextSize(job) + 16
        draw.RoundedBox(6, tx, ty + 22, jw, 16, Color(99,102,241, 220))
        draw.SimpleText(string.upper(job), "SimpleHUD_Tiny", tx + jw/2, ty + 30, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(FormatMoney(money), "SimpleHUD_Money", cx + cw - 12, ty + 2, Color(110, 231, 183), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText("+" .. FormatMoney(salary) .. " / paie", "SimpleHUD_Tiny", cx + cw - 12, ty + 20, Color(255,255,255,100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        local wanted = ply.getDarkRPVar and ply:getDarkRPVar("wanted")
        if wanted then
            draw.RoundedBox(6, cx + cw - 70, ty + 38, 58, 16, Color(239,68,68,220))
            draw.SimpleText("RECHERCHÉ", "SimpleHUD_Tiny", cx + cw - 41, ty + 46, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local bx = tx
        local bw = cw - (tx - cx) - 12
        local bh = 10
        local by = cy + 56
        DrawBar(bx, by, bw, bh, hpFrac, HealthColor(hpFrac))
        draw.SimpleText(math.max(0, math.Round(hp)) .. " HP", "SimpleHUD_Tiny", bx + 4, by + bh/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        by = by + 14
        DrawBar(bx, by, bw, bh, dispArmor / 100, Color(59,130,246))
        draw.SimpleText(math.Round(armor) .. " ARMURE", "SimpleHUD_Tiny", bx + 4, by + bh/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        by = by + 14
        local hungerCol = dispHunger > 40 and Color(249,115,22) or Color(239,68,68)
        DrawBar(bx, by, bw, bh, dispHunger / 100, hungerCol)
        draw.SimpleText(math.Round(dispHunger) .. "% FAIM", "SimpleHUD_Tiny", bx + 4, by + bh/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            local clip = wep:Clip1()
            local reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
            if clip ~= -1 then
                local ammoText = clip .. " / " .. reserve
                surface.SetFont("SimpleHUD_Large")
                local tw = surface.GetTextSize(ammoText)
                local bw2 = math.max(140, tw + 28)
                local bh2 = 36
                local ax = sw - 16 - bw2
                local ay = sh - 16 - bh2
                draw.RoundedBox(10, ax, ay, bw2, bh2, BG)
                draw.RoundedBoxEx(10, ax, ay, bw2, 3, Color(255,255,255,12), true, true, false, false)
                draw.SimpleText(ammoText, "SimpleHUD_Large", ax + bw2/2, ay + bh2/2 + 1, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                local wname = wep:GetPrintName()
                if wname and wname ~= "" then
                    draw.SimpleText(string.upper(wname), "SimpleHUD_Tiny", ax + bw2/2, ay - 6, Color(255,255,255,140), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                end
            end
        end
    end

    -- Draw in BOTH hooks so DarkRP can't hide us - if one is blocked the other shows
    hook.Add("HUDPaint", "SimpleHUD_Draw", PaintHUDCommon)
    hook.Add("HUDPaintBackground", "SimpleHUD_Draw_BG", PaintHUDCommon)

    -- Console helpers
    concommand.Add("simplehud_test", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then print("no ply") return end
        print("[SimpleHUD test] Health="..ply:Health().." Max="..ply:GetMaxHealth().." Armor="..ply:Armor().." Energy="..tostring(ply.getDarkRPVar and ply:getDarkRPVar("Energy") or "no DarkRP").." hooks="..table.ToString(hook.GetTable()["HUDPaint"] or {}))
    end)

    timer.Simple(3, function() print("[SimpleHUD] v5 hooks: HUDPaint="..tostring(hook.GetTable()["HUDPaint"]["SimpleHUD_Draw"] ~= nil).." BG="..tostring(hook.GetTable()["HUDPaintBackground"]["SimpleHUD_Draw_BG"] ~= nil)) end)
end
