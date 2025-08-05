print("|cff00ff00[NoChat] Loaded.|r")

local allowedOutgoing = {
    BN_WHISPER = true,
    BN_CONVERSATION = true,
    GUILD = true,
    OFFICER = true
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

local allowedIncoming = {
    CHAT_MSG_BN_WHISPER = true,
    CHAT_MSG_BN_CONVERSATION = true,
    CHAT_MSG_GUILD = true,
    CHAT_MSG_OFFICER = true
}

local blockedChatEvents = {
    CHAT_MSG_WHISPER = true,
    CHAT_MSG_SAY = true,
    CHAT_MSG_YELL = true,
    CHAT_MSG_PARTY = true,
    CHAT_MSG_PARTY_LEADER = true,
    CHAT_MSG_RAID = true,
    CHAT_MSG_RAID_LEADER = true,
    CHAT_MSG_RAID_WARNING = true,
    CHAT_MSG_INSTANCE_CHAT = true,
    CHAT_MSG_INSTANCE_CHAT_LEADER = true,
    CHAT_MSG_CHANNEL = true
}

local function OnChatMessage(frame, event, message, sender, ...)
    if allowedIncoming[event] or not blockedChatEvents[event] then
        return false
    end
    messageCounter = messageCounter + 1
    hiddenMessages[messageCounter] = {
        sender = sender,
        message = message,
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
    return false, placeholder, sender, ...
end

for event in pairs(blockedChatEvents) do
    ChatFrame_AddMessageEventFilter(event, OnChatMessage)
end

local orig_SetItemRef = SetItemRef
SetItemRef = function(link, text, button, chatFrame)
    local id = link:match("^revealMsg:(%d+)$")
    if id then
        local data = hiddenMessages[tonumber(id)]
        if data then
            local label = chatTypeLabels[data.chatType] or "Chat"
            local revealed = string.format("|cffffff00[%s] |Hplayer:%s|h%s|h: %s|r",
                label, data.sender, data.sender, data.message)
            chatFrame:AddMessage(revealed)
        end
    else
        return orig_SetItemRef(link, text, button, chatFrame)
    end
end
