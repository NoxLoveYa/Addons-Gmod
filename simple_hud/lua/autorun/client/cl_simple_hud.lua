-- Simple HUD | Drop in garrysmod/addons/simple_hud/
-- Hides default health/armor/ammo and draws minimal bars.
if CLIENT then

    -- Fonts
    surface.CreateFont("SimpleHUD_Large", {
        font = "Roboto",
        size = 26,
        weight = 700,
        antialias = true
    })
    surface.CreateFont("SimpleHUD_Small", {
        font = "Roboto",
        size = 18,
        weight = 600,
        antialias = true
    })

    -- Config -- tweak here
    local PAD = 16
    local BAR_W, BAR_H = 240, 22
    local GAP = 6
    local BG = Color(30, 30, 30, 210)
    local BG2 = Color(50, 50, 50, 180)

    -- Hide ALL default HUD (desactive l'hud de base complet)
    -- Pour réactiver un élément, remplace "return false" par une liste:
    -- local hide = {["CHudHealth"]=true, ["CHudBattery"]=true, ["CHudAmmo"]=true, ["CHudSecondaryAmmo"]=true, ["CHudCrosshair"]=true}
    -- if hide[name] then return false end
    hook.Add("HUDShouldDraw", "SimpleHUD_HideDefaults", function()
        return false
    end)

    -- Smooth values
    local dispHealth = 100
    local dispArmor = 0

    local function DrawBar(x, y, w, h, frac, col)
        frac = math.Clamp(frac, 0, 1)
        -- bg
        draw.RoundedBox(6, x, y, w, h, BG)
        -- fill bg
        draw.RoundedBox(6, x + 2, y + 2, w - 4, h - 4, BG2)
        -- fill
        if frac > 0 then
            draw.RoundedBox(6, x + 2, y + 2, (w - 4) * frac, h - 4, col)
        end
    end

    local function HealthColor(hp, max)
        local f = hp / math.max(max, 1)
        if f > 0.6 then return Color(80, 200, 80) end
        if f > 0.3 then return Color(220, 180, 40) end
        return Color(210, 60, 60)
    end

    hook.Add("HUDPaint", "SimpleHUD_Draw", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local hp = ply:Health()
        local maxHp = ply:GetMaxHealth()
        if maxHp == 0 then maxHp = 100 end
        local armor = ply:Armor()

        -- smooth lerp (lazy 1-liner, no extra lib)
        dispHealth = Lerp(FrameTime() * 8, dispHealth, math.Clamp(hp, 0, maxHp))
        dispArmor = Lerp(FrameTime() * 8, dispArmor, armor)

        local sw, sh = ScrW(), ScrH()

        -- Bottom-left stack: Health + Armor
        local x = PAD
        local y = sh - PAD - BAR_H

        -- Armor goes above health if you have any
        local hasArmor = armor > 0 or dispArmor > 1
        if hasArmor then
            y = y - BAR_H - GAP
            DrawBar(x, y, BAR_W, BAR_H, dispArmor / 100, Color(60, 140, 220))
            draw.SimpleText(math.Round(armor) .. " ARMOR", "SimpleHUD_Small", x + BAR_W / 2, y + BAR_H / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            y = y + BAR_H + GAP
        end

        DrawBar(x, y, BAR_W, BAR_H, dispHealth / maxHp, HealthColor(dispHealth, maxHp))
        local hpText = math.max(0, math.Round(hp)) .. " / " .. maxHp .. " HP"
        -- show dead text
        if hp <= 0 then hpText = "DEAD" end
        draw.SimpleText(hpText, "SimpleHUD_Small", x + BAR_W / 2, y + BAR_H / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Bottom-right: Ammo (only if holding weapon)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            local clip = wep:Clip1()
            local reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
            local secondary = ply:GetAmmoCount(wep:GetSecondaryAmmoType())

            -- only draw if weapon uses ammo
            if clip ~= -1 then
                local ammoText = clip .. " / " .. reserve
                -- nice large number for clip
                local tw, th = 0, 0
                surface.SetFont("SimpleHUD_Large")
                tw, th = surface.GetTextSize(ammoText)

                local bw = math.max(140, tw + 24)
                local bh = 30
                local ax = sw - PAD - bw
                local ay = sh - PAD - bh

                draw.RoundedBox(6, ax, ay, bw, bh, BG)
                draw.SimpleText(ammoText, "SimpleHUD_Large", ax + bw / 2, ay + bh / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                -- weapon name small above
                local wname = wep:GetPrintName()
                if wname and wname ~= "" then
                    draw.SimpleText(string.upper(wname), "SimpleHUD_Small", ax + bw / 2, ay - 6, Color(255, 255, 255, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                end
            elseif secondary > 0 then
                -- for weapons with no clip but secondary (e.g. grenades)
                local ammoText = tostring(reserve + secondary)
                surface.SetFont("SimpleHUD_Large")
                local tw = surface.GetTextSize(ammoText)
                local bw = math.max(100, tw + 24)
                local bh = 30
                local ax = sw - PAD - bw
                local ay = sh - PAD - bh
                draw.RoundedBox(6, ax, ay, bw, bh, BG)
                draw.SimpleText(ammoText, "SimpleHUD_Large", ax + bw / 2, ay + bh / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        -- Optional: tiny top-left player name (comment out if you don't want it)
        -- draw.SimpleText(ply:Nick(), "SimpleHUD_Small", PAD, PAD, Color(255,255,255,200))
    end)
end
