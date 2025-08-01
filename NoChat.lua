-- Print loaded confirmation
print("|cff00ff00[NoChat] Loaded.|r")

-- Disable outgoing chat
local blockedCommands = {
    "SAY", "YELL", "PARTY", "RAID", "GUILD", "OFFICER",
    "WHISPER", "EMOTE", "CHANNEL", "INSTANCE_CHAT"
}

local function disableChat()
    _G["ChatFrame_SendTell"] = function() end

    local orig_SendChatMessage = SendChatMessage
    _G["SendChatMessage"] = function(msg, chatType, language, channel, ...)
        if chatType and not chatType:upper():match("^BN_WHISPER$") then
            print("|cffff0000[NoChat]|r Chat message blocked: " .. (chatType or "unknown"))
            return
        end
        return orig_SendChatMessage(msg, chatType, language, channel, ...)
    end
end


disableChat()

-- Block manual chat (except slash commands)
local origChatEdit_OnEnterPressed = ChatEdit_OnEnterPressed
function ChatEdit_OnEnterPressed(editBox)
    local chatType = editBox:GetAttribute("chatType")
    local text = editBox:GetText()

    -- Allow if it's a command or a BN whisper
    if text and text ~= "" and not text:match("^/") and chatType ~= "BN_WHISPER" then
        print("|cffff0000[NoChat]|r Your message was blocked and not sent.")
        editBox:SetText("")
        editBox:ClearFocus()
        return
    end

    origChatEdit_OnEnterPressed(editBox)
end


-- Intercepted message storage
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

-- Intercept chat events
local eventsToIntercept = {
    "CHAT_MSG_WHISPER", "CHAT_MSG_SAY", "CHAT_MSG_YELL",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING", "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER", "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_CHANNEL",
    "CHAT_MSG_BN_WHISPER" -- BN whisper allowed
}

-- Create handler frame
local f = CreateFrame("Frame")
for _, evt in ipairs(eventsToIntercept) do
    f:RegisterEvent(evt)
end

-- Handle intercepted messages
f:SetScript("OnEvent", function(self, event, msg, sender, _, _, _, _, _, _, _, _, _, _, bnetIDAccount)
    if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_BN_WHISPER" then
        PlaySound(3081, "Master")
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

-- Reveal message handler
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

-- Suppress intercepted chat from being shown in chat frames
for _, eventName in ipairs(eventsToIntercept) do
    if eventName ~= "CHAT_MSG_BN_WHISPER" then -- Allow BN whisper to show
        for i = 1, NUM_CHAT_WINDOWS do
            local frame = _G["ChatFrame"..i]
            if frame then
                frame:UnregisterEvent(eventName)
            end
        end
    end
end

-- Allow outgoing Real ID whispers
hooksecurefunc("BNSendWhisper", function(toonID, message)
    -- Optionally log or allow
end)
