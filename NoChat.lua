-- Print loaded confirmation
print("|cff00ff00[NoChat] Loaded.|r")

-- Disable outgoing chat (except BN_WHISPER)
local function disableChat()
    _G["ChatFrame_SendTell"] = function() end

    local orig_SendChatMessage = SendChatMessage
    _G["SendChatMessage"] = function(msg, chatType, language, channel, ...)
        if chatType and chatType:upper() ~= "BN_WHISPER" then
            print("|cffff0000[NoChat]|r Chat message blocked: " .. (chatType or "unknown"))
            return
        end
        return orig_SendChatMessage(msg, chatType, language, channel, ...)
    end
end

disableChat()

-- Block manual chat (except slash commands and BN_WHISPER)
local origChatEdit_OnEnterPressed = ChatEdit_OnEnterPressed
function ChatEdit_OnEnterPressed(editBox)
    local chatType = editBox:GetAttribute("chatType")
    local text = editBox:GetText()

    if text and text ~= "" and not text:match("^/") and chatType ~= "BN_WHISPER" then
        print("|cffff0000[NoChat]|r Your message was blocked and not sent.")
        editBox:SetText("")
        editBox:ClearFocus()
        return
    end

    origChatEdit_OnEnterPressed(editBox)
end

-- Incoming message storage (only for hidden messages)
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
    CHAT_MSG_CHANNEL = "Channel",
    CHAT_MSG_BN_WHISPER = "BN Whisper"
}

-- Only intercept messages we want to hide (everything but GUILD & BN_WHISPER)
local eventsToHide = {
    "CHAT_MSG_WHISPER", "CHAT_MSG_SAY", "CHAT_MSG_YELL",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING", "CHAT_MSG_OFFICER",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_CHANNEL"
}

local f = CreateFrame("Frame")
for _, evt in ipairs(eventsToHide) do
    f:RegisterEvent(evt)
end

f:SetScript("OnEvent", function(self, event, msg, sender)
    messageCounter = messageCounter + 1
    hiddenMessages[messageCounter] = {
        sender = sender,
        message = msg,
        chatType = event
    }
end)

-- Reveal handler (in case we later expose these)
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

-- Unregister blocked events from default chat frames
for _, eventName in ipairs(eventsToHide) do
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        if frame then
            frame:UnregisterEvent(eventName)
        end
    end
end

-- Allow outgoing Real ID whispers
hooksecurefunc("BNSendWhisper", function(toonID, message)
    -- Allowed
end)