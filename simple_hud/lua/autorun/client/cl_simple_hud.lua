-- Simple HUD v8 - try ALL 2D hooks + force GAMEMODE hook
if CLIENT then
    print("[SimpleHUD] file loaded v8 - all hooks")

    surface.CreateFont("SimpleHUD_Large", { font = "Roboto", size = 26, weight = 700 })
    surface.CreateFont("SimpleHUD_Medium", { font = "Roboto", size = 20, weight = 700 })
    surface.CreateFont("SimpleHUD_Small", { font = "Roboto", size = 16, weight = 600 })
    surface.CreateFont("SimpleHUD_Tiny", { font = "Roboto", size = 14, weight = 600 })

    local BG = Color(20, 20, 25, 240)
    local ACCENT = Color(99, 102, 241)
    local FACE = 96
    local FACE_PAD = 12
    local CON_W, CON_H = 420, 146

    hook.Add("HUDShouldDraw", "SimpleHUD_HideDefaults", function(name)
        if name == "CHudChat" then return true end
        return false
    end)

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
        local _old = FacePanel.Paint
        function FacePanel:Paint(w,h) pcall(function() draw.RoundedBox(12,0,0,w,h,Color(0,0,0,120)); _old(self,w,h); surface.SetDrawColor(255,255,255,18); surface.DrawOutlinedRect(0,0,w,h,1) end) end
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

    local function HealthColor(frac)
        if frac > 0.6 then return Color(34,197,94) end
        if frac > 0.3 then return Color(234,179,8) end
        return Color(239,68,68)
    end

    local counts = {HUDPaint=0, HUDPaintBackground=0, PostDrawHUD=0, DrawOverlay=0, PostRenderVGUI=0, PreDrawHUD=0}
    local function MakePainter(name)
        return function()
            counts[name] = counts[name] + 1
            local sw, sh = ScrW(), ScrH()
            -- top proof for each hook - different Y so you know which fired
            local yMap = {HUDPaint=20, HUDPaintBackground=48, PostDrawHUD=76, DrawOverlay=104, PostRenderVGUI=132, PreDrawHUD=160}
            local y = yMap[name] or 20
            surface.SetDrawColor(255,0,0,255)
            surface.DrawRect(sw/2 - 160, y, 320, 22)
            draw.SimpleText(name .. " ACTIVE v8 " .. counts[name], "SimpleHUD_Small", sw/2, y+11, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- also draw center health bar if HUDPaint
            if name == "HUDPaint" or name == "DrawOverlay" then
                local ply = LocalPlayer()
                if not IsValid(ply) then return end
                local hp = ply:Health()
                local maxHp = ply:GetMaxHealth() if maxHp==0 then maxHp=100 end
                local hpFrac = math.Clamp(hp/maxHp,0,1)
                local col = HealthColor(hpFrac)
                -- center bar
                local cW, cH = 320, 22
                local cX, cY = sw/2 - cW/2, sh/2
                surface.SetDrawColor(0,0,0,255)
                surface.DrawRect(cX, cY, cW, cH)
                surface.SetDrawColor(col.r,col.g,col.b,255)
                surface.DrawRect(cX+2,cY+2,(cW-4)*hpFrac,cH-4)
                draw.SimpleText("HP "..hp.."/"..maxHp, "SimpleHUD_Small", cX+cW/2, cY+cH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                -- bottom container + bar
                local cw,ch = CON_W, CON_H
                local cx, cy = 16, sh - ch - 16
                draw.RoundedBox(12, cx, cy, cw, ch, BG)
                draw.RoundedBoxEx(12, cx, cy, cw, 3, ACCENT, true, true, false, false)
                local hbX = cx + FACE_PAD
                local hbY = cy + FACE_PAD + FACE + 6
                local hbW, hbH = FACE, 16
                surface.SetDrawColor(0,0,0,255)
                surface.DrawRect(hbX, hbY, hbW, hbH)
                surface.SetDrawColor(45,45,52,255)
                surface.DrawRect(hbX+2,hbY+2,hbW-4,hbH-4)
                surface.SetDrawColor(col.r,col.g,col.b,255)
                surface.DrawRect(hbX+2,hbY+2,(hbW-4)*hpFrac,hbH-4)
                surface.SetDrawColor(255,255,0,255)
                surface.DrawOutlinedRect(hbX-1,hbY-1,hbW+2,hbH+2,2)
                draw.SimpleText(hp.." HP", "SimpleHUD_Tiny", hbX+hbW/2, hbY+hbH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    -- Hook ALL 2D hooks - wiki list
    hook.Add("HUDPaint", "SimpleHUD_Draw", MakePainter("HUDPaint"))
    hook.Add("HUDPaintBackground", "SimpleHUD_Draw_BG", MakePainter("HUDPaintBackground"))
    hook.Add("PostDrawHUD", "SimpleHUD_Draw_PostHUD", MakePainter("PostDrawHUD"))
    hook.Add("DrawOverlay", "SimpleHUD_Draw_Overlay", MakePainter("DrawOverlay"))
    hook.Add("PostRenderVGUI", "SimpleHUD_Draw_PostVGUI", MakePainter("PostRenderVGUI"))
    hook.Add("PreDrawHUD", "SimpleHUD_Draw_PreHUD", MakePainter("PreDrawHUD"))

    -- Force GAMEMODE to call hook.Run if it was blocking (common fix)
    timer.Simple(2, function()
        if GAMEMODE then
            print("[SimpleHUD] GAMEMODE=" .. (GAMEMODE.Name or "unknown") .. " - patching HUDPaint to force hook.Run")
            local oldPaint = GAMEMODE.HUDPaint
            local oldBG = GAMEMODE.HUDPaintBackground
            function GAMEMODE:HUDPaint()
                if oldPaint then pcall(oldPaint, self) end
                hook.Run("HUDPaint")
            end
            function GAMEMODE:HUDPaintBackground()
                if oldBG then pcall(oldBG, self) end
                hook.Run("HUDPaintBackground")
            end
            print("[SimpleHUD] patched GAMEMODE HUDPaint")
        end
        -- print counts after 4s
        timer.Simple(2, function()
            print("[SimpleHUD v8 counts] " .. table.ToString(counts))
            for k,v in pairs(counts) do if v>0 then print("[SimpleHUD] hook " .. k .. " fired " .. v .. " times") end end
            if counts.HUDPaint==0 and counts.DrawOverlay==0 then
                print("[SimpleHUD] WARNING: no 2D hook fired - gamemode is not calling them. Using cam.Start2D fallback in Think")
                hook.Add("Think", "SimpleHUD_FallbackDraw", function()
                    -- cam.Start2D works anywhere
                    cam.Start2D()
                        local ok, err = pcall(MakePainter("HUDPaint"))
                        if not ok then print(err) end
                    cam.End2D()
                    -- only once per frame is okay but we do it in Think so it will spam - limit
                end)
            end
        end)
    end)

    concommand.Add("simplehud_test", function()
        local ply = LocalPlayer()
        print("[SimpleHUD test v8] HP="..ply:Health().." counts="..table.ToString(counts).." GAMEMODE="..(GAMEMODE and GAMEMODE.Name or "nil"))
    end)
end
