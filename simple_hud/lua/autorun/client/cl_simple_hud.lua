-- Simple HUD DarkRP Modern | UX pass spacieux + animations | DrawOverlay (VGUI face on top)
if CLIENT then
    surface.CreateFont("SimpleHUD_Large",  { font = "Roboto", size = 28, weight = 800 })
    surface.CreateFont("SimpleHUD_Medium", { font = "Roboto", size = 21, weight = 700 })
    surface.CreateFont("SimpleHUD_Small",  { font = "Roboto", size = 16, weight = 600 })
    surface.CreateFont("SimpleHUD_Tiny",   { font = "Roboto", size = 13, weight = 700 })
    surface.CreateFont("SimpleHUD_Money",  { font = "Roboto", size = 19, weight = 800 })
    surface.CreateFont("SimpleHUD_Icon",   { font = "Roboto", size = 14, weight = 800 })

    local BG        = Color(16, 16, 20, 235)
    local BG2       = Color(28, 28, 34, 220)
    local BG_BAR    = Color(38, 38, 46)
    local ACCENT    = Color(99, 102, 241)
    local ACCENT2   = Color(129, 140, 248)

    local FACE      = 102
    local FACE_PAD  = 14
    local CON_W, CON_H = 490, 162
    local R = 16

    hook.Add("HUDShouldDraw", "SimpleHUD_HideDefaults", function(name)
        if name == "CHudChat" then return true end
        return false
    end)

    -- Face 3D - parented to OverlayPanel so PostRenderVGUI > DrawOverlay
    local FacePanel
    local lastModel = ""
    local function CreateFacePanel()
        if IsValid(FacePanel) then FacePanel:Remove() end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        lastModel = ply:GetModel()
        local parent = vgui.GetOverlayPanel and vgui.GetOverlayPanel() or nil
        FacePanel = vgui.Create("DModelPanel", parent)
        FacePanel:SetZPos(32767)
        FacePanel:SetSize(FACE, FACE)
        FacePanel:SetModel(lastModel)
        FacePanel:SetFOV(30)
        FacePanel:SetLookAt(Vector(0, 0, 64))
        FacePanel.curYaw = 0
        FacePanel:SetCamPos(Vector(40, 0, 64))
        FacePanel:SetAmbientLight(Color(90,90,90))
        FacePanel:SetDirectionalLight(BOX_FRONT, Color(255,255,255))
        FacePanel:SetDirectionalLight(BOX_BACK, Color(80,80,90))
        FacePanel:SetAnimated(true)
        FacePanel:SetMouseInputEnabled(false)
        FacePanel.OnMouseWheeled = function() return true end
        FacePanel.LayoutEntity = function(self, ent)
            if not IsValid(ent) then return end
            local ply2 = LocalPlayer()
            if not IsValid(ply2) then return end
            local eyeAng = ply2:EyeAngles()
            local targetYaw = eyeAng.y
            local pitch = math.Clamp(eyeAng.p * 0.35, -12, 12)
            ent:SetAngles(Angle(pitch, targetYaw, 0))
            if ent.SetEyeTarget then ent:SetEyeTarget(ply2:EyePos() + eyeAng:Forward()*100) end
            self.curYaw = self.curYaw or targetYaw
            self.curYaw = LerpAngle(FrameTime()*4.5, Angle(0,self.curYaw,0), Angle(0,targetYaw,0)).y -- lag doux
            local rad = math.rad(self.curYaw)
            local sway = math.sin(CurTime()*0.7)*0.8 -- micro respiration
            self:SetCamPos(Vector(math.cos(rad)*34, math.sin(rad)*34, 64 + sway))
            self:SetLookAt(Vector(0,0,62 + pitch*0.12))
            ent:FrameAdvance(FrameTime())
            self:RunAnimation()
        end
        local _old = FacePanel.Paint
        function FacePanel:Paint(w, h)
            -- fond clair pour contraste + ombre
            draw.RoundedBox(R, 0, 0, w, h, Color(245,245,248, 255))
            draw.RoundedBox(R, 1, 1, w-2, h-2, Color(18,18,22, 255))
            _old(self, w, h)
            -- anneau accent qui pulse si low hp
            local c = self._hpCol or Color(99,102,241, 22)
            surface.SetDrawColor(c.r, c.g, c.b, 28)
            surface.DrawOutlinedRect(0,0,w,h,2)
            surface.SetDrawColor(255,255,255,14)
            surface.DrawOutlinedRect(1,1,w-2,h-2,1)
        end
    end
    hook.Add("InitPostEntity", "SimpleHUD_CreateFace", CreateFacePanel)
    hook.Add("OnPlayerChangedTeam", "SimpleHUD_FaceTeam", function() timer.Simple(0.5, CreateFacePanel) end)

    -- anim states
    local openFrac = 0
    local dispHP, dispArmor, dispHunger, dispMoney = 100, 0, 100, 0
    local flashDamage = 0
    local lastHP = 100
    local lastMoney = 0
    local moneyPop = 0
    local ammoPop = 0
    local lastClip = -1

    local function HealthColor(frac)
        if frac > 0.55 then return Color(52, 211, 153) end -- emerald
        if frac > 0.30 then return Color(251, 191, 36) end -- amber
        return Color(248, 113, 113) -- red
    end
    local function FormatMoney(n)
        if DarkRP and DarkRP.formatMoney then return DarkRP.formatMoney(n) end
        return "$" .. tostring(math.floor(n or 0))
    end
    local function DrawBarAnimated(x, y, w, h, frac, col, bg)
        frac = math.Clamp(frac, 0, 1)
        -- fond pill
        draw.RoundedBox(h/2, x, y, w, h, bg or BG_BAR)
        -- fill pill avec inset 2px
        if frac > 0.001 then
            local fw = (w - 4) * frac
            -- arrondi seulement si quasi plein, sinon coin gauche arrondi
            if frac > 0.98 then
                draw.RoundedBox(h/2, x+2, y+2, fw, h-4, col)
            else
                draw.RoundedBox(4, x+2, y+2, fw, h-4, col)
            end
            -- highlight
            surface.SetDrawColor(255,255,255,18)
            surface.DrawRect(x+2, y+2, fw, 2)
        end
    end

    hook.Add("Think", "SimpleHUD_FaceThink", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not IsValid(FacePanel) then return end
        if ply:GetModel() ~= lastModel then CreateFacePanel() end
        local cx, cy = 18, ScrH() - CON_H - 18
        -- slide in anim
        openFrac = Lerp(FrameTime()*7, openFrac, 1)
        local slideOff = (1 - openFrac) * (CON_W + 30)
        cx = cx - slideOff
        FacePanel:SetPos(cx + FACE_PAD, cy + FACE_PAD)
        FacePanel:SetVisible(not ply:ShouldDrawLocalPlayer() and ply:Alive())
        if FacePanel:IsVisible() then FacePanel:MoveToFront() FacePanel:SetZPos(32767) end
        -- track damage flash
        local hp = ply:Health()
        if hp < lastHP then flashDamage = 1 end
        lastHP = hp
        flashDamage = math.max(0, flashDamage - FrameTime()*1.6)
        -- update face ring color
        if IsValid(FacePanel) then
            local maxHp = ply:GetMaxHealth() if maxHp==0 then maxHp=100 end
            local frac = math.Clamp(hp/maxHp,0,1)
            local c = HealthColor(frac)
            if frac < 0.3 then
                local pulse = 18 + math.abs(math.sin(CurTime()*3.2))*22
                c = Color(c.r, c.g, c.b, pulse)
            else
                c = Color(c.r, c.g, c.b, 18)
            end
            FacePanel._hpCol = c
        end
        -- money pop
        local money = ply.getDarkRPVar and ply:getDarkRPVar("money") or 0
        if money ~= lastMoney then moneyPop = 1 end
        lastMoney = money
        moneyPop = math.max(0, moneyPop - FrameTime()*3)
        -- ammo pop
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            local clip = wep:Clip1()
            if clip ~= lastClip and clip ~= -1 then ammoPop = 1 end
            lastClip = clip
        end
        ammoPop = math.max(0, ammoPop - FrameTime()*4)
    end)

    local function DrawHUD()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local sw, sh = ScrW(), ScrH()
        local hp = ply:Health()
        local maxHp = ply:GetMaxHealth() if maxHp==0 then maxHp=100 end
        local armor = ply:Armor()
        local hpFracReal = math.Clamp(hp/maxHp,0,1)
        local col = HealthColor(hpFracReal)

        dispHP = Lerp(FrameTime()*6, dispHP, hp)
        dispArmor = Lerp(FrameTime()*6, dispArmor, armor)
        local hunger = 100
        if ply.getDarkRPVar then local e=ply:getDarkRPVar("Energy") if e~=nil then hunger=e end end
        dispHunger = Lerp(FrameTime()*5, dispHunger, hunger)
        local money = ply.getDarkRPVar and ply:getDarkRPVar("money") or 0
        local salary = ply.getDarkRPVar and ply:getDarkRPVar("salary") or 0
        dispMoney = Lerp(FrameTime()*6, dispMoney, money)

        local cw, ch = CON_W, CON_H
        local baseCX, baseCY = 18, sh - ch - 18
        local slideOff = (1 - openFrac) * (cw + 30)
        local cx, cy = baseCX - slideOff, baseCY
        -- léger bob si low hp
        if hpFracReal < 0.25 then
            cx = cx + math.sin(CurTime()*10)*1.2
        end

        -- ombre portée
        draw.RoundedBox(R, cx+3, cy+4, cw, ch, Color(0,0,0,55))
        -- fond principal + effet glass
        draw.RoundedBox(R, cx, cy, cw, ch, BG)
        draw.RoundedBox(R, cx+1, cy+1, cw-2, ch-2, BG2)
        -- liseré top accent + flash damage
        local topCol = ACCENT
        if flashDamage > 0 then
            topCol = Color(Lerp(flashDamage, ACCENT.r, 248), Lerp(flashDamage, ACCENT.g, 113), Lerp(flashDamage, ACCENT.b, 113))
            -- vignette rouge flash
            surface.SetDrawColor(248,113,113, flashDamage*18)
            surface.DrawRect(0,0,sw,sh)
        end
        draw.RoundedBoxEx(R, cx, cy, cw, 4, topCol, true,true,false,false)
        -- inner highlight top
        surface.SetDrawColor(255,255,255,7)
        surface.DrawRect(cx+14, cy+6, cw-28, 1)

        if not IsValid(FacePanel) then
            draw.RoundedBox(12, cx + FACE_PAD, cy + FACE_PAD, FACE, FACE, Color(45,45,52,180))
            draw.SimpleText("…", "SimpleHUD_Small", cx + FACE_PAD + FACE/2, cy + FACE_PAD + FACE/2, Color(255,255,255,50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- health bar sous carré - pill animée
        local hbX = cx + FACE_PAD
        local hbY = cy + FACE_PAD + FACE + 10
        local hbW, hbH = FACE, 14
        local dispFrac = math.Clamp(dispHP / maxHp, 0, 1)
        -- pulse si <30%
        local hbPulse = 1
        if hpFracReal < 0.3 then hbPulse = 1 + math.abs(math.sin(CurTime()*4))*0.04 end
        local hbH2 = math.floor(hbH * hbPulse)
        local hbY2 = hbY - math.floor((hbH2 - hbH)/2)
        DrawBarAnimated(hbX, hbY2, hbW, hbH2, dispFrac, col, Color(42,42,52))
        -- glow fin
        if dispFrac > 0.02 then
            surface.SetDrawColor(col.r, col.g, col.b, 14)
            surface.DrawRect(hbX+2, hbY2+hbH2+1, (hbW-4)*dispFrac, 2)
        end
        local hpText = math.Round(hp) .. " HP"
        -- texte avec ombre portée
        draw.SimpleText(hpText, "SimpleHUD_Tiny", hbX + hbW/2 +1, hbY2 + hbH2/2+1, Color(0,0,0,180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(hpText, "SimpleHUD_Tiny", hbX + hbW/2, hbY2 + hbH2/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- colonne droite
        local tx = cx + FACE_PAD + FACE + 18
        local ty = cy + 16
        local rightW = cw - (tx - cx) - 16

        -- nom + status
        local name = ply:Nick()
        if string.len(name) > 24 then name = string.sub(name,1,24) .. "…" end
        draw.SimpleText(name, "SimpleHUD_Medium", tx, ty, color_white)
        -- petite ligne sous nom
        surface.SetDrawColor(255,255,255,6)
        surface.DrawRect(tx, ty+20, 28, 2)

        -- job badge - pill avec icône
        local job = ply.getDarkRPVar and ply:getDarkRPVar("job") or "Inconnu"
        surface.SetFont("SimpleHUD_Tiny")
        local jw = surface.GetTextSize(job) + 28
        local badgeY = ty + 26
        draw.RoundedBox(8, tx, badgeY, jw, 18, Color(99,102,241, 235))
        -- icône dot
        surface.SetDrawColor(255,255,255,230)
        surface.DrawRect(tx+7, badgeY+7, 6, 6)
        draw.SimpleText(string.upper(job), "SimpleHUD_Tiny", tx + 18, badgeY+9, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        -- wanted s'affiche à droite du badge si besoin
        if ply.getDarkRPVar and ply:getDarkRPVar("wanted") then
            local wx = tx + jw + 8
            draw.RoundedBox(8, wx, badgeY, 86, 18, Color(248,113,113,230))
            -- petit clignotement
            local a = 200 + math.abs(math.sin(CurTime()*6))*55
            surface.SetDrawColor(255,255,255,a)
            surface.DrawRect(wx+6, badgeY+7, 6, 6)
            draw.SimpleText("RECHERCHÉ", "SimpleHUD_Tiny", wx+16, badgeY+9, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        -- argent - avec pop scale
        local popScale = 1 + moneyPop * 0.12
        local mText = FormatMoney(math.Round(dispMoney))
        local sText = FormatMoney(salary) .. " / paie"
        -- fond argent discret
        draw.RoundedBox(10, cx + cw - 138, ty - 2, 122, 36, Color(255,255,255,6))
        draw.SimpleText(mText, "SimpleHUD_Money", cx + cw - 16, ty + 2 + (1-popScale)*4, Color(52,211,153), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        -- scale via font size trick: on décale un peu quand pop
        draw.SimpleText(sText .. " / paie", "SimpleHUD_Tiny", cx + cw - 16, ty + 22, Color(255,255,255, 90 + moneyPop*60), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        if moneyPop > 0.1 then
            surface.SetDrawColor(52,211,153, moneyPop*22)
            draw.RoundedBox(10, cx + cw - 138, ty -2, 122, 36, Color(52,211,153, moneyPop*10))
        end

        -- bars - plus spacieuses
        local bw = rightW
        local by = cy + 64
        local bh = 12
        local gap = 10

        -- HP bar droite (emoji + label)
        DrawBarAnimated(tx, by, bw, bh, dispFrac, col, BG_BAR)
        -- icône coeur
        draw.SimpleText("♥", "SimpleHUD_Icon", tx+7, by+bh/2, Color(255,255,255,210), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.Round(hp) .. "  HP", "SimpleHUD_Tiny", tx+18, by+bh/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.Round(hpFracReal*100) .. "%", "SimpleHUD_Tiny", tx+bw-8, by+bh/2, Color(255,255,255,140), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        by = by + bh + gap

        -- Armor
        local armorFrac = math.Clamp(dispArmor/100,0,1)
        DrawBarAnimated(tx, by, bw, bh, armorFrac, Color(96,165,250), BG_BAR)
        draw.SimpleText("◆", "SimpleHUD_Icon", tx+7, by+bh/2, Color(255,255,255,190), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.Round(dispArmor) .. "  ARMURE", "SimpleHUD_Tiny", tx+18, by+bh/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        by = by + bh + gap

        -- Faim / Stamina - reste visible même hors DarkRP (à 100% discret)
        local hungerFrac = math.Clamp(dispHunger/100,0,1)
        local hungerCol = hungerFrac > 0.45 and Color(251,146,60) or Color(248,113,113)
        -- si pas DarkRP on grise légèrement
        local isDarkRP = ply.getDarkRPVar and ply:getDarkRPVar("Energy") ~= nil
        if not isDarkRP then hungerCol = Color(110,110,118) end
        DrawBarAnimated(tx, by, bw, bh, hungerFrac, hungerCol, BG_BAR)
        draw.SimpleText(isDarkRP and "◒" or "○", "SimpleHUD_Icon", tx+7, by+bh/2, Color(255,255,255,170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.Round(dispHunger) .. (isDarkRP and "  FAIM" or "  ENDURANCE"), "SimpleHUD_Tiny", tx+18, by+bh/2, isDarkRP and color_white or Color(255,255,255,160), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- ammo - bottom-right pill avec pop
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            local clip = wep:Clip1()
            local reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
            if clip ~= -1 then
                local ammoText = clip .. "  /  " .. reserve
                surface.SetFont("SimpleHUD_Large")
                local tw = surface.GetTextSize(ammoText)
                local bw2 = math.max(148, tw + 34)
                local bh2 = 42
                local aPop = 1 + ammoPop * 0.08
                local ax = sw - 18 - bw2
                local ay = sh - 18 - bh2
                -- ombre
                draw.RoundedBox(14, ax+2, ay+3, bw2, bh2, Color(0,0,0,50))
                draw.RoundedBox(14, ax, ay, bw2, bh2, BG)
                -- inner
                draw.RoundedBox(14, ax+1, ay+1, bw2-2, bh2-2, BG2)
                draw.RoundedBoxEx(14, ax, ay, bw2, 4, Color(255,255,255, ammoPop>0 and 18 or 10), true,true,false,false)
                -- low ammo pulse
                if clip <= 5 and clip >=0 then
                    local pa = math.abs(math.sin(CurTime()*5))*18
                    surface.SetDrawColor(248,113,113, pa)
                    draw.RoundedBox(14, ax, ay, bw2, bh2, Color(248,113,113, pa*0.6))
                end
                draw.SimpleText(ammoText, "SimpleHUD_Large", ax + bw2/2, ay + bh2/2 + 1 + (1-aPop)*3, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                local wname = wep:GetPrintName()
                if wname and wname ~= "" then
                    draw.SimpleText(string.upper(wname), "SimpleHUD_Tiny", ax + bw2/2, ay - 8, Color(255,255,255,110), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                end
                -- réserve petite
                if reserve > 0 then
                    draw.SimpleText("RÉSERVE " .. reserve, "SimpleHUD_Tiny", ax + bw2/2, ay + bh2 - 6, Color(255,255,255,45), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                end
            end
        end
    end

    hook.Add("DrawOverlay", "SimpleHUD_Draw", DrawHUD)
end
