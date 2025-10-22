local addonName, ns = ...
ns = ns or {}
local M = {}

local frame
local scrollFrame
local content
local clearButton
local rows = {}
local rowHeight = 18
local padding = 8

function GetHonorString(number)
    local num = tonumber(number)
    if not num then
        print("Ошибка: GetHonorString - аргумент не является числом (" .. tostring(number) .. ")")
        return number .. " побед"
    end

    num = math.floor(num)

    local lastTwoDigits = num % 100
    local lastDigit = lastTwoDigits % 10

    local suffix
    if lastTwoDigits >= 11 and lastTwoDigits <= 14 then
        suffix = "побед"
    else
        if lastDigit == 1 then
            suffix = "победа"
        elseif lastDigit >= 2 and lastDigit <= 4 then
            suffix = "победы"
        else
            suffix = "побед"
        end
    end

    return num .. " " .. suffix
end

function M.CreateDetailWindow(parent, key, data)
    if frame then return end

    local parentFrame = parent or UIParent
    frame = CreateFrame("Frame", "MyHonorTrackerDetailFrame", parentFrame)
    frame:SetSize(400, 300)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -8)
    frame.title:SetText("История сбросов")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -6, -6)
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    scrollFrame = CreateFrame("ScrollFrame", "MyHonorTrackerDetailScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -36)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    content = CreateFrame("Frame", "MyHonorTrackerDetailContent", scrollFrame)
    local scrollWidth = 360
    content:SetSize(scrollWidth, 1)
    scrollFrame:SetScrollChild(content)

    clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearButton:SetSize(80, 22)
    clearButton:SetPoint("BOTTOMRIGHT", -28, 10)
    clearButton:SetText("Очистить")

    clearButton:SetScript("OnClick", function()
        local playerKey = key
        local currentData = MyHonorTracker_Data and MyHonorTracker_Data[playerKey]
        if currentData and currentData.honorables then
            wipe(currentData.honorables)
            M.UpdateDetailWindow()
            print("|cff00ff00MyHonorTracker:|r История сбросов очищена.")
        end
    end)

    frame:SetScript("OnSizeChanged", function(self, width)
        if content then
            local newW = math.max(100, width - padding * 4)
            content:SetWidth(newW)
            for _, fs in ipairs(rows) do
                if fs then fs:SetWidth(newW - 10) end
            end
        end
    end)
end



function M.UpdateDetailWindow(newData)
    if not content then return end

    if not newData or not newData.honorables then
        local playerName = UnitName("player") or "Неизвестно"
        local realm = GetRealmName() or "Неизвестно"
        local playerKey = playerName .. "-" .. realm
        newData = MyHonorTracker_Data and MyHonorTracker_Data[playerKey] or {}
    end

    newData = newData or {}
    local list = newData.honorables or {}

    if #rows == 1 and rows[1]:IsShown() and rows[1]:GetText() == "История пуста." then
        rows[1]:Hide()
        wipe(rows)
    end

    for _, r in ipairs(rows) do r:Hide() end

    local y = -6
    local index = 1
    local contentWidth = content:GetWidth()
    if contentWidth == 0 then contentWidth = 360 end

    for i = #list, 1, -1 do
        local entry = list[i]
        local row = rows[index]
        if not row then
            row = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row:SetJustifyH("LEFT")
            row:SetPoint("TOPLEFT", 6, y)
            rows[index] = row
        else
            row:SetPoint("TOPLEFT", 6, y)
        end

        local count = entry.count or 0
        local time = entry.time or "?"
        local text = string.format("%s — %s", GetHonorString(count), time)

        row:SetText(text)
        row:SetWidth(contentWidth - 12)
        row:SetTextColor(1, 0.82, 0)
        row:Show()

        y = y - rowHeight
        index = index + 1
    end

    if index == 1 then
        if not rows[1] then
            rows[1] = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            rows[1]:SetPoint("TOPLEFT", 6, -6)
        end
        rows[1]:SetText("История пуста.")
        rows[1]:Show()
        index = 2
    end

    content:SetHeight(math.max(1, (index - 1) * rowHeight + 12))
end


function M.ToggleDetailWindow(newData)
    if not frame then return end
    if frame:IsShown() then
        frame:Hide()
    else
        M.UpdateDetailWindow(newData)
        frame:Show()
    end
end

ns.DetailWindow = M
