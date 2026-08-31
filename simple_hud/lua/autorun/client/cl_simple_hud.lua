-- Simple HUD DarkRP Modern + Visage 3D temps réel
-- Drop in garrysmod/addons/simple_hud/
if CLIENT then

    surface.CreateFont("SimpleHUD_Large", { font = "Roboto", size = 26, weight = 700 })
    surface.CreateFont("SimpleHUD_Medium", { font = "Roboto", size = 20, weight = 700 })
    surface.CreateFont("SimpleHUD_Small", { font = "Roboto", size = 16, weight = 600 })
    surface.CreateFont("SimpleHUD_Tiny", { font = "Roboto", size = 14, weight = 600 })
    surface.CreateFont("SimpleHUD_Money", { font = "Roboto", size = 18, weight = 800 })

    local BG = Color(20, 20, 25, 240)
    local BG2 = Color(45, 45, 52, 200)
    local BG_BAR = Color(35, 35, 42)
    local ACCENT = Color(99, 102, 241) -- indigo moderne

    -- Desactive tout l'HUD de base + DarkRP
    hook.Add("HUDShouldDraw", "SimpleHUD_HideDefaults", function(name)
        -- cache tout le HUD source + DarkRP HUD
        if name == "CHudChat" then return true end -- garder chat
        return false
    end)
    -- DarkRP dessine son HUD via HUDPaint, on l'empêche aussi
    hook.Add("PostGamemodeLoaded", "SimpleHUD_DisableDarkRP", function()
        if GAMEMODE and GAMEMODE.Config then
            GAMEMODE.Config.enableHUD = false
        end
        -- au cas où DarkRP hook encore
        if DarkRP and DarkRP.disabledHUD then return end
    end)
    timer.Simple(2, function()
        hook.Remove("HUDPaint", "DarkRP_HUD")
        hook.Remove("HUDPaint", "DarkRP_EntityDisplay")
    end)

    -- === Visage 3D temps réel ===
    local FacePanel
    local lastModel = ""

    local function CreateFacePanel()
        if IsValid(FacePanel) then FacePanel:Remove() end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        lastModel = ply:GetModel()

        FacePanel = vgui.Create("DModelPanel")
        FacePanel:SetSize(72, 72)
        FacePanel:SetModel(lastModel)
        FacePanel:SetFOV(42)
        FacePanel:SetLookAt(Vector(0, 0, 62))
        FacePanel:SetCamPos(Vector(32, 0, 64))
        FacePanel:SetAnimated(true)
        FacePanel.LayoutEntity = function(self, ent)
            if not IsValid(ent) then return end
            local ply2 = LocalPlayer()
            if not IsValid(ply2) then return end
            -- tête suit la vue du joueur (bouge en temps réel)
            local eyeAng = ply2:EyeAngles()
            -- yaw -> rotation tête, pitch léger
            local yaw = eyeAng.y - 90
            local pitch = math.Clamp(eyeAng.p * 0.3, -10, 10)
            ent:SetAngles(Angle(pitch, yaw, 0))
            -- yeux suivent la visée
            if ent.SetEyeTarget then
                ent:SetEyeTarget(ply2:EyePos() + eyeAng:Forward() * 80)
            end
            ent:FrameAdvance(FrameTime())
            self:RunAnimation()
        end
        -- fond transparent, on dessine HUDPaint derrière
        function FacePanel:Paint(w, h)
            -- petite ombre arrondie derrière le modèle
            draw.RoundedBox(12, 0, 0, w, h, Color(0,0,0,120))
            -- dessine modèle par dessus (ponytail: carré arrondi simple, stencil circulaire si tu veux parfait cercle)
            self:PaintModel()
            -- bordure
            surface.SetDrawColor(255,255,255,18)
            surface.DrawOutlinedRect(0,0,w,h,1)
            return true
        end
    end

    hook.Add("InitPostEntity", "SimpleHUD_CreateFace", CreateFacePanel)
    hook.Add("OnPlayerChangedTeam", "SimpleHUD_FaceTeam", function() timer.Simple(0.5, CreateFacePanel) end)

    -- update si changement de modèle
    hook.Add("Think", "SimpleHUD_FaceThink", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not IsValid(FacePanel) then return end
        if ply:GetModel() ~= lastModel then CreateFacePanel() end
        -- repositionne selon résolution (ancré au container HUD)
        local cw, ch = 420, 104
        local cx, cy = 16, ScrH() - ch - 16
        FacePanel:SetPos(cx + 10, cy + 16)
        FacePanel:SetVisible(not ply:ShouldDrawLocalPlayer() and ply:Alive())
    end)

    -- helpers
    local dispHealth, dispArmor, dispHunger = 100, 0, 100

    local function DrawBar(x, y, w, h, frac, col)
        frac = math.Clamp(frac, 0, 1)
        draw.RoundedBox(4, x, y, w, h, BG_BAR)
        if frac > 0 then
            draw.RoundedBox(4, x, y, w * frac, h, col)
        end
    end

    local function FormatMoney(n)
        if DarkRP and DarkRP.formatMoney then return DarkRP.formatMoney(n) end
        return "$" .. tostring(n or 0)
    end

    hook.Add("HUDPaint", "SimpleHUD_Draw", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local sw, sh = ScrW(), ScrH()

        -- valeurs lissées
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

        -- Container moderne bottom-left
        local cw, ch = 420, 104
        local cx, cy = 16, sh - ch - 16

        -- blur + fond (léger blur si dispo)
        -- Derma_DrawBackgroundBlur n'est pas dispo en HUDPaint, on simule avec fond sombre
        draw.RoundedBox(12, cx, cy, cw, ch, BG)
        -- petite ligne accent top
        draw.RoundedBoxEx(12, cx, cy, cw, 3, ACCENT, true, true, false, false)

        -- zone avatar : FacePanel est un VGUI par dessus, on laisse l'espace vide ici
        -- on dessine juste un fond pour l'avatar (au cas où FacePanel pas encore créé)
        if not IsValid(FacePanel) then
            draw.RoundedBox(10, cx + 10, cy + 16, 72, 72, BG2)
            draw.SimpleText("...", "SimpleHUD_Small", cx + 46, cy + 52, Color(255,255,255,80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Infos texte à droite de l'avatar
        local tx = cx + 92
        local ty = cy + 14

        -- Nom + Job
        local name = ply:Nick()
        if string.len(name) > 22 then name = string.sub(name, 1, 22) .. "…" end
        draw.SimpleText(name, "SimpleHUD_Medium", tx, ty, color_white)

        local job = "Inconnu"
        local money = 0
        local salary = 0
        if ply.getDarkRPVar then
            job = ply:getDarkRPVar("job") or job
            money = ply:getDarkRPVar("money") or 0
            salary = ply:getDarkRPVar("salary") or 0
        end
        -- job badge
        surface.SetFont("SimpleHUD_Tiny")
        local jw = surface.GetTextSize(job) + 16
        draw.RoundedBox(6, tx, ty + 22, jw, 16, Color(99,102,241, 220))
        draw.SimpleText(string.upper(job), "SimpleHUD_Tiny", tx + jw/2, ty + 30, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Argent à droite du container
        local moneyTxt = FormatMoney(money)
        local salaryTxt = "+" .. FormatMoney(salary)
        draw.SimpleText(moneyTxt, "SimpleHUD_Money", cx + cw - 12, ty + 2, Color(110, 231, 183), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText(salaryTxt .. " / paie", "SimpleHUD_Tiny", cx + cw - 12, ty + 20, Color(255,255,255,100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        -- wanted
        local wanted = ply.getDarkRPVar and ply:getDarkRPVar("wanted")
        if wanted then
            draw.RoundedBox(6, cx + cw - 70, ty + 38, 58, 16, Color(239,68,68,220))
            draw.SimpleText("RECHERCHÉ", "SimpleHUD_Tiny", cx + cw - 41, ty + 46, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Barres : Vie / Armure / Faim
        local bx = tx
        local bw = cw - (tx - cx) - 12 -- ~316
        local bh = 10
        local by = cy + 52

        -- Vie
        local hpFrac = dispHealth / maxHp
        local hpCol = hpFrac > 0.6 and Color(34,197,94) or hpFrac > 0.3 and Color(234,179,8) or Color(239,68,68)
        DrawBar(bx, by, bw, bh, hpFrac, hpCol)
        draw.SimpleText(math.max(0, math.Round(hp)) .. " HP", "SimpleHUD_Tiny", bx + 4, by + bh/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        by = by + 14

        -- Armure
        DrawBar(bx, by, bw, bh, dispArmor / 100, Color(59,130,246))
        draw.SimpleText(math.Round(armor) .. " ARMURE", "SimpleHUD_Tiny", bx + 4, by + bh/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        by = by + 14

        -- Faim (DarkRP)
        local hungerCol = dispHunger > 40 and Color(249,115,22) or Color(239,68,68)
        DrawBar(bx, by, bw, bh, dispHunger / 100, hungerCol)
        draw.SimpleText(math.Round(dispHunger) .. "% FAIM", "SimpleHUD_Tiny", bx + 4, by + bh/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Ammo bottom-right (garde l'ancien)
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
    end)
end
