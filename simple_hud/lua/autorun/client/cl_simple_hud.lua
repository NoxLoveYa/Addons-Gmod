-- Simple HUD DarkRP Modern + Visage 3D temps réel | final DrawOverlay
if CLIENT then
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

    -- Face 3D - VGUI renders at PostRenderVGUI which is AFTER DrawOverlay, so it stays on top
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
        FacePanel.curYaw = 0
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
            -- unclamped: entity follows view directly
            local targetYaw = eyeAng.y
            local pitch = math.Clamp(eyeAng.p * 0.4, -15, 15)
            ent:SetAngles(Angle(pitch, targetYaw, 0))
            if ent.SetEyeTarget then
                ent:SetEyeTarget(ply2:EyePos() + eyeAng:Forward() * 100)
            end
            -- camera lags behind and orbits to stay in front of face
            self.curYaw = self.curYaw or targetYaw
            -- LerpAngle for smooth lag ( ~0.08 = slight lag, increase 0.15 for faster)
            local curAng = Angle(0, self.curYaw, 0)
            local tgtAng = Angle(0, targetYaw, 0)
            self.curYaw = LerpAngle(FrameTime() * 5, curAng, tgtAng).y
            local rad = math.rad(self.curYaw)
            local dist = 32
            local camPos = Vector(math.cos(rad) * dist, math.sin(rad) * dist, 64 + pitch * 0.2)
            self:SetCamPos(camPos)
            self:SetLookAt(Vector(0, 0, 62 + pitch * 0.1))
            ent:FrameAdvance(FrameTime())
            self:RunAnimation()
        end
        local _old = FacePanel.Paint
        function FacePanel:Paint(w, h)
            draw.RoundedBox(12, 0, 0, w, h, Color(0,0,0,120))
            _old(self, w, h)
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
        if FacePanel:IsVisible() then FacePanel:MoveToFront() end
    end)

    local function HealthColor(frac)
        if frac > 0.6 then return Color(34,197,94) end
        if frac > 0.3 then return Color(234,179,8) end
        return Color(239,68,68)
    end
    local function FormatMoney(n)
        if DarkRP and DarkRP.formatMoney then return DarkRP.formatMoney(n) end
        return "$" .. tostring(n or 0)
    end

    local function DrawHUD()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local sw, sh = ScrW(), ScrH()
        local hp = ply:Health()
        local maxHp = ply:GetMaxHealth() if maxHp == 0 then maxHp = 100 end
        local armor = ply:Armor()
        local hpFrac = math.Clamp(hp / maxHp, 0, 1)
        local col = HealthColor(hpFrac)

        local cw, ch = CON_W, CON_H
        local cx, cy = 16, sh - ch - 16

        draw.RoundedBox(12, cx, cy, cw, ch, BG)
        draw.RoundedBoxEx(12, cx, cy, cw, 3, ACCENT, true, true, false, false)

        if not IsValid(FacePanel) then
            draw.RoundedBox(10, cx + FACE_PAD, cy + FACE_PAD, FACE, FACE, Color(45,45,52))
        end

        -- health bar under square
        local hbX = cx + FACE_PAD
        local hbY = cy + FACE_PAD + FACE + 6
        local hbW, hbH = FACE, 16
        surface.SetDrawColor(0,0,0,255)
        surface.DrawRect(hbX, hbY, hbW, hbH)
        surface.SetDrawColor(45,45,52,255)
        surface.DrawRect(hbX+2, hbY+2, hbW-4, hbH-4)
        surface.SetDrawColor(col.r, col.g, col.b, 255)
        if hpFrac > 0 then
            surface.DrawRect(hbX+2, hbY+2, (hbW-4)*hpFrac, hbH-4)
        end
        surface.SetDrawColor(255,255,255,40)
        surface.DrawOutlinedRect(hbX, hbY, hbW, hbH, 1)
        draw.SimpleText(math.Round(hp) .. " HP", "SimpleHUD_Tiny", hbX + hbW/2 +1, hbY + hbH/2+1, Color(0,0,0,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.Round(hp) .. " HP", "SimpleHUD_Tiny", hbX + hbW/2, hbY + hbH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- infos à droite
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
        draw.RoundedBox(6, tx, ty + 22, jw, 16, Color(99,102,241,220))
        draw.SimpleText(string.upper(job), "SimpleHUD_Tiny", tx + jw/2, ty + 30, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(FormatMoney(money), "SimpleHUD_Money", cx + cw - 12, ty + 2, Color(110,231,183), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText("+" .. FormatMoney(salary) .. " / paie", "SimpleHUD_Tiny", cx + cw - 12, ty + 20, Color(255,255,255,100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        if ply.getDarkRPVar and ply:getDarkRPVar("wanted") then
            draw.RoundedBox(6, cx + cw - 70, ty + 38, 58, 16, Color(239,68,68,220))
            draw.SimpleText("RECHERCHÉ", "SimpleHUD_Tiny", cx + cw - 41, ty + 46, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- bars à droite
        local bw = cw - (tx - cx) - 12
        local by = cy + 56
        -- health right
        draw.RoundedBox(4, tx, by, bw, 10, BG_BAR)
        draw.RoundedBox(4, tx, by, bw*hpFrac, 10, col)
        draw.SimpleText(math.Round(hp) .. " HP", "SimpleHUD_Tiny", tx+4, by+5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        by = by + 14
        -- armor
        local armorFrac = math.Clamp(armor/100,0,1)
        draw.RoundedBox(4, tx, by, bw, 10, BG_BAR)
        draw.RoundedBox(4, tx, by, bw*armorFrac, 10, Color(59,130,246))
        draw.SimpleText(math.Round(armor) .. " ARMURE", "SimpleHUD_Tiny", tx+4, by+5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        by = by + 14
        -- hunger
        local hunger = 100
        if ply.getDarkRPVar then local e = ply:getDarkRPVar("Energy") if e~=nil then hunger=e end end
        local hungerFrac = hunger/100
        local hungerCol = hunger > 40 and Color(249,115,22) or Color(239,68,68)
        draw.RoundedBox(4, tx, by, bw, 10, BG_BAR)
        draw.RoundedBox(4, tx, by, bw*hungerFrac, 10, hungerCol)
        draw.SimpleText(math.Round(hunger) .. "% FAIM", "SimpleHUD_Tiny", tx+4, by+5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- ammo bottom-right
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
                draw.SimpleText(ammoText, "SimpleHUD_Large", ax + bw2/2, ay + bh2/2 +1, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                local wname = wep:GetPrintName()
                if wname and wname ~= "" then
                    draw.SimpleText(string.upper(wname), "SimpleHUD_Tiny", ax + bw2/2, ay - 6, Color(255,255,255,140), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                end
            end
        end
    end

    hook.Add("DrawOverlay", "SimpleHUD_Draw", DrawHUD)
end
