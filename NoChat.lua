print("|cff00ff00[NoChat] Loaded.|r")

local allowedOutgoing = {
    BN_WHISPER = true,
    BN_CONVERSATION = true,
    GUILD = true,
    OFFICER = true
}

local allowedIncoming = {
    CHAT_MSG_BN_WHISPER = true,
    CHAT_MSG_BN_CONVERSATION = true,
    CHAT_MSG_GUILD = true,
    CHAT_MSG_OFFICER = true
}

local orig_SendChatMessage = SendChatMessage
SendChatMessage = function(msg, chatType, language, channel, ...)
    chatType = chatType and chatType:upper() or ""

    if allowedOutgoing[chatType] then
        return orig_SendChatMessage(msg, chatType, language, channel, ...)
    end

    local blockedTypes = {
        SAY = true, YELL = true, PARTY = true, RAID = true,
        INSTANCE_CHAT = true, WHISPER = true, CHANNEL = true, EMOTE = true
    }

    if blockedTypes[chatType] then
        print("|cffff0000[NoChat]|r Outgoing chat blocked.")
        return
    end

    return orig_SendChatMessage(msg, chatType, language, channel, ...)
end

ChatFrame_SendTell = function() end

local orig_ChatEdit_OnEnterPressed = ChatEdit_OnEnterPressed
ChatEdit_OnEnterPressed = function(editBox)
    local text = editBox:GetText()
    local chatType = editBox:GetAttribute("chatType")
    chatType = chatType and chatType:upper() or ""

    if text:match("^/") or allowedOutgoing[chatType] then
        return orig_ChatEdit_OnEnterPressed(editBox)
    end

    local blockedTypes = {
        SAY = true, YELL = true, PARTY = true, RAID = true,
        INSTANCE_CHAT = true, WHISPER = true, CHANNEL = true, EMOTE = true
    }

    if blockedTypes[chatType] then
        print("|cffff0000[NoChat]|r Message blocked (manual input).")
        editBox:SetText("")
        editBox:ClearFocus()
        return
    end

    return orig_ChatEdit_OnEnterPressed(editBox)
end

local hiddenMessages, messageCounter = {}, 0
local chatTypeLabels = {
    CHAT_MSG_WHISPER = "Whisper",
    CHAT_MSG_SAY = "Say",
    CHAT_MSG_YELL = "Yell",
    CHAT_MSG_PARTY = "Party",
    CHAT_MSG_PARTY_LEADER = "Party Leader",
    CHAT_MSG_RAID = "Raid",
    CHAT_MSG_RAID_LEADER = "Raid Leader",
    CHAT_MSG_RAID_WARNING = "Raid Warning",
    CHAT_MSG_INSTANCE_CHAT = "Instance",
    CHAT_MSG_INSTANCE_CHAT_LEADER = "Instance Leader",
    CHAT_MSG_CHANNEL = "Channel"
}

local eventsToIntercept = {}
for _, evt in ipairs({
    "CHAT_MSG_WHISPER", "CHAT_MSG_SAY", "CHAT_MSG_YELL",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_CHANNEL", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER"
}) do
    if not allowedIncoming[evt] then
        table.insert(eventsToIntercept, evt)
    end
end

local function NoChat_ObfuscateHandler(self, event, msg, sender, ...)
    messageCounter = messageCounter + 1
    hiddenMessages[messageCounter] = {
        sender = sender,
        message = msg,
        chatType = event
    }

    if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_SAY" then
        PlaySound(3081, "Master")
    end

    local label = chatTypeLabels[event] or "Chat"
    local placeholder = string.format(
        "|HrevealMsg:%d|h|cff888888[%s from |Hplayer:%s|h%s|h hidden. |cff00ff00Click to reveal|r|cff888888]|r|h",
        messageCounter, label, sender, sender
    )

    DEFAULT_CHAT_FRAME:AddMessage(placeholder)
    return true
end

for _, event in ipairs(eventsToIntercept) do
    ChatFrame_AddMessageEventFilter(event, NoChat_ObfuscateHandler)
end

local orig_SetItemRef = SetItemRef
SetItemRef = function(link, text, button, chatFrame)
    local id = link:match("^revealMsg:(%d+)$")
    if id then
        local data = hiddenMessages[tonumber(id)]
        if data then
            local label = chatTypeLabels[data.chatType] or "Chat"
            local revealed = string.format("|cffffff00[%s] |Hplayer:%s|h%s|h: %s|r", label, data.sender, data.sender, data.message)
            chatFrame:AddMessage(revealed)
        end
    else
        orig_SetItemRef(link, text, button, chatFrame)
    end
end
