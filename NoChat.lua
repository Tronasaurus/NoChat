print("|cff00ff00[NoChat] Loaded.|r")
-- Disable outgoing chat
local blockedCommands = {
    "SAY", "YELL", "PARTY", "RAID", "GUILD", "OFFICER", "WHISPER", "EMOTE", "CHANNEL", "INSTANCE_CHAT"
}

local function disableChat()
    
    -- Block chat send functions globally
    _G["ChatFrame_SendTell"] = function() end
    _G["SendChatMessage"] = function() end

--    -- Hide all chat input boxes
--    for i = 1, NUM_CHAT_WINDOWS do
--        local editBox = _G["ChatFrame"..i.."EditBox"]
--        if editBox then
--            editBox:Hide()
--            editBox:EnableMouse(false)
--            editBox:SetScript("OnShow", function(self) self:Hide() end)
--        end
--    end
end

disableChat()

-- Block all manual message sending via Enter key
local origChatEdit_OnEnterPressed = ChatEdit_OnEnterPressed
function ChatEdit_OnEnterPressed(editBox)
    local text = editBox:GetText()
    if text and text ~= "" and not text:match("^/") then
        print("|cffff0000[NoChat]|r Your message was blocked and not sent.")
        editBox:SetText("")
        editBox:ClearFocus()
        return
    end

    -- Allow original handler to process valid commands/macros
    origChatEdit_OnEnterPressed(editBox)
end

-- Storage for intercepted messages
local hiddenMessages = {}
local messageCounter = 0

local chatTypeLabels = {
    CHAT_MSG_WHISPER = "Whisper",
    CHAT_MSG_SAY = "Say",
    CHAT_MSG_YELL = "Yell",
    CHAT_MSG_PARTY = "Party",
    CHAT_MSG_PARTY_LEADER = "Party Leader",
    CHAT_MSG_RAID = "Raid",
    CHAT_MSG_RAID_LEADER = "Raid Leader",
    CHAT_MSG_RAID_WARNING = "Raid Warning",
    CHAT_MSG_GUILD = "Guild",
    CHAT_MSG_OFFICER = "Officer",
    CHAT_MSG_INSTANCE_CHAT = "Instance",
    CHAT_MSG_INSTANCE_CHAT_LEADER = "Instance Leader",
    CHAT_MSG_CHANNEL = "Channel"
}

-- Chat events to intercept
local eventsToIntercept = {
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_CHANNEL" -- Trade/general
}

-- Create handler frame
local f = CreateFrame("Frame")
for _, evt in ipairs(eventsToIntercept) do
    f:RegisterEvent(evt)
end

-- Handle intercepted message
f:SetScript("OnEvent", function(self, event, msg, sender, ...)
        -- Play sound for incoming whisper
    if event == "CHAT_MSG_WHISPER" then
        PlaySound(3081, "Master")  -- DEFAULT_WHISPER_SOUND
    end

    messageCounter = messageCounter + 1
    hiddenMessages[messageCounter] = {
        sender = sender,
        message = msg,
        chatType = event
    }

    local chatLabel = chatTypeLabels[event] or "Chat"
    local placeholder = string.format(
    "|cff9999ff[New %s message received. |cff00ff00Click to reveal|r|cff9999ff]|r",
    chatLabel
)

    local clickable = string.format("|HrevealMsg:%d|h%s|h", messageCounter, placeholder)

    DEFAULT_CHAT_FRAME:AddMessage(clickable)
end)

-- Reveal message when clicked
local origSetItemRef = SetItemRef

function SetItemRef(link, text, button, chatFrame)
    local id = link:match("^revealMsg:(%d+)$")
    if id then
        id = tonumber(id)
        local data = hiddenMessages[id]
        if data then
            local color = "|cffffff00"
            local label = chatTypeLabels[data.chatType] or "Chat"

            local revealed = string.format("%s[%s] %s: %s|r", color, label, data.sender, data.message)
            DEFAULT_CHAT_FRAME:AddMessage(revealed)
        end
    else
        origSetItemRef(link, text, button, chatFrame)
    end
end

-- Suppress chat output by overriding handlers on all chat windows
for _, eventName in ipairs(eventsToIntercept) do
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        if frame then
            frame:UnregisterEvent(eventName)
        end
    end
end