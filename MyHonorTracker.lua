MyHonorTracker_Data = MyHonorTracker_Data or {}

local addonName, ns = ...
MyHonorTracker_NS = ns or {}

local function GetPlayerKey()
    local name = UnitName("player") or "Неизвестно"
    local realm = GetRealmName() or "Неизвестно"
    return name .. "-" .. realm
end

local killSounds = {
    "Interface\\AddOns\\MyHonorTracker\\sound\\godlike.ogg",
    "Interface\\AddOns\\MyHonorTracker\\sound\\headshot.ogg",
    "Interface\\AddOns\\MyHonorTracker\\sound\\holyshit.ogg",
    "Interface\\AddOns\\MyHonorTracker\\sound\\humiliation.ogg",
    "Interface\\AddOns\\MyHonorTracker\\sound\\killingspree.ogg",
    "Interface\\AddOns\\MyHonorTracker\\sound\\monsterkill.ogg",
    "Interface\\AddOns\\MyHonorTracker\\sound\\multikill.ogg",
    "Interface\\AddOns\\MyHonorTracker\\sound\\rampage.ogg",
    "Interface\\AddOns\\MyHonorTracker\\sound\\ultrakill.ogg",
}

local frame = CreateFrame("Button", "MyHonorTrackerFrame", UIParent)

local playerKey = GetPlayerKey()
local pdata

local DetailWindow = MyHonorTracker_NS.DetailWindow
DetailWindow.CreateDetailWindow(frame, playerKey, nil)

local function updateKills()
    if not pdata then return end
    local currentSessionKills = pdata.sessionKills or 0
    frame.text:SetText("Победы: " .. currentSessionKills)
end

local function SetSavedPosition()
    if pdata and pdata.pos then
        local pos = pdata.pos
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        frame:SetPoint("CENTER")
    end
end

local function ApplyFrameSettings()
    if not pdata then return end

    if pdata.width and pdata.height then
        frame:SetSize(pdata.width, pdata.height)
    else
        frame:SetSize(140, 40)
    end

    pdata.scale = pdata.scale or 1
    pdata.alpha = pdata.alpha or 1
    pdata.isVisible = pdata.isVisible ~= false
    pdata.soundEnabled = pdata.soundEnabled ~= false

    frame:SetScale(pdata.scale)
    frame:SetAlpha(pdata.alpha)
    if pdata.isVisible then frame:Show() else frame:Hide() end
end

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    if pdata then
        pdata.pos = { point = point, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
    end
end)

local resizeButton = CreateFrame("Button", nil, frame)
resizeButton:SetSize(16, 16)
resizeButton:SetPoint("BOTTOMRIGHT", -2, 2)
resizeButton.texture = resizeButton:CreateTexture(nil, "OVERLAY")
resizeButton.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton.texture:SetAllPoints()

resizeButton:SetScript("OnMouseDown", function(self)
    self:GetParent():StartSizing("BOTTOMRIGHT")
end)
resizeButton:SetScript("OnMouseUp", function(self)
    local parent = self:GetParent()
    parent:StopMovingOrSizing()
    if pdata then
        pdata.width, pdata.height = parent:GetWidth(), parent:GetHeight()
    end
end)

frame:SetResizable(true)

frame:RegisterForClicks("AnyUp")
frame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        if pdata then
            DetailWindow.ToggleDetailWindow(pdata)
        end
    end
end)

frame.bg = frame:CreateTexture(nil, "BACKGROUND")
frame.bg:SetAllPoints(true)
frame.bg:SetTexture(0, 0, 0, 0.5)

frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.text:SetPoint("LEFT", 10, 0)

frame.resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
frame.resetButton:SetSize(50, 24)
frame.resetButton:SetPoint("RIGHT", -5, 0)
frame.resetButton:SetText("Сброс")
frame.resetButton:SetScript("OnClick", function()
    if not pdata then return end
    local count = pdata.sessionKills or 0
    local now = date("%d.%m.%Y | %H:%M:%S")
    if count > 0 then
        table.insert(pdata.honorables, {
            count = count,
            time = now,
        })
    end

    pdata.sessionKills = 0
    updateKills()
    DetailWindow.UpdateDetailWindow(pdata)
end)

local function playKillSound()
    if pdata and pdata.soundEnabled then
        PlaySoundFile(killSounds[math.random(#killSounds)], "Master")
    end
end

-- Тестовая кнопка начало

-- frame.testButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
-- frame.testButton:SetSize(50, 24)
-- frame.testButton:SetPoint("RIGHT", frame.resetButton, "LEFT", -5, 0)
-- frame.testButton:SetText("Тест")

-- frame.testButton:SetScript("OnClick", function()
--     pdata.sessionKills = (pdata.sessionKills or 0) + 1

--     frame.text:SetText("Победы: " .. pdata.sessionKills)

--     if pdata.soundEnabled then
--         PlaySoundFile(killSounds[math.random(#killSounds)], "Master")
--     end

--     print("|cff00ff00MyHonorTracker:|r Тестовая почётная победа засчитана! (всего: " .. pdata.sessionKills .. ")")
-- end)

-- Тестовая кнопка конец

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_PVP_KILLS_CHANGED")
frame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, msg)
    if event == "PLAYER_LOGIN" then
        pdata = MyHonorTracker_Data[playerKey] or {}
        MyHonorTracker_Data[playerKey] = pdata
        pdata.honorables = pdata.honorables or {}
        pdata.sessionKills = pdata.sessionKills or 0
        pdata.baseKills = pdata.baseKills or GetStatistic(588) or 0

        ApplyFrameSettings()
        SetSavedPosition()
        updateKills()
        DetailWindow.UpdateDetailWindow(pdata)

        print("|cff00ff00MyHonorTracker:|r Данные загружены для " .. playerKey)

    elseif event == "PLAYER_PVP_KILLS_CHANGED" or event == "UPDATE_BATTLEFIELD_SCORE" then
        if pdata then
            local currentBaseKills = GetStatistic(588) or 0
            local previousBaseKills = pdata.baseKills or 0
            if currentBaseKills > previousBaseKills then
                local killsGained = currentBaseKills - previousBaseKills
                pdata.sessionKills = (pdata.sessionKills or 0) + killsGained
                pdata.baseKills = currentBaseKills
                updateKills()
            end
        end
    elseif event == "CHAT_MSG_LOOT" then
        if pdata and pdata.soundEnabled then
            local honorItems = {
                "Эмблема Орды",
                "Эмблема Ренегата",
                "Эмблема Альянса",
            }

            for _, emblemName in ipairs(honorItems) do
                if msg and msg:find(emblemName) then
                    playKillSound()
                    break
                end
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        if pdata then
            MyHonorTracker_Data[playerKey] = pdata
        end
    end
end)

SLASH_MYHONORTRACKER1 = "/mht"
SlashCmdList["MYHONORTRACKER"] = function(msg)
    if not pdata then
        print("|cffff0000MyHonorTracker:|r Ошибка - данные не готовы.")
        return
    end

    msg = msg and msg:lower() or ""
    if msg == "visible" then
        if frame:IsShown() then
            frame:Hide()
            pdata.isVisible = false
        else
            frame:Show()
            pdata.isVisible = true
        end
    elseif msg == "sound" then
        pdata.soundEnabled = not pdata.soundEnabled
        print(pdata.soundEnabled and "Звуки включены" or "Звуки отключены")
    elseif msg:find("scale") then
        local s = tonumber(msg:match("scale%s+(%d%.?%d*)"))
        if s then
            frame:SetScale(s)
            pdata.scale = s
            print("Масштаб: " .. s)
        else
            print("Пример: /mht scale 1.2")
        end
    elseif msg:find("opacity") then
        local a = tonumber(msg:match("opacity%s+(%d%.?%d*)"))
        if a and a >= 0 and a <= 1 then
            frame:SetAlpha(a)
            pdata.alpha = a
            print("Прозрачность: " .. a)
        else
            print("Пример: /mht opacity 0.8")
        end
    elseif msg == "reset" then
        pdata.pos, pdata.width, pdata.height = nil, nil, nil
        pdata.scale, pdata.alpha = 1, 1
        pdata.isVisible, pdata.soundEnabled = true, true
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
        frame:SetScale(1)
        frame:SetAlpha(1)
        frame:Show()
        print("MyHonorTracker: настройки сброшены.")
    else
        print("|cff00ff00MyHonorTracker команды:|r")
        print("/mht visible - Показать/скрыть окно")
        print("/mht scale <число> - Масштаб окна")
        print("/mht opacity <число> - Прозрачность окна (0–1)")
        print("/mht reset - Сброс настроек окна")
        print("/mht sound - Вкл/Выкл звуки")
    end
end