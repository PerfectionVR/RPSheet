-- Every class, subclass and specialization at a spread of levels: put on a sheet, then
-- everything on it is read, clicked and cast once.
NUM_CHAT_WINDOWS = 10
RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"
SENT = {}
C_ChatInfo = { SendChatMessage = function(msg, channel)
    SENT[#SENT + 1] = msg
    if type(msg) ~= "string" then Problem("chat message is " .. type(msg))
    elseif #msg > 255 then Problem("chat message over 255: " .. msg:sub(1, 80))
    elseif msg:find("|") or msg:find("\n") then Problem("chat message with a pipe or line break: " .. msg:sub(1, 200)) end
end }
