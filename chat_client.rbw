#!/usr/bin/ruby
# encoding: utf-8

require "socket"
require "thread"

load "./chat_setting.rb"
require "./lib/log_util"
require "./lib/net_util"
require "./lib/chat_if"
require "./lib/util"

begin # init
  log = LogUtil.new("./log", CLIENT_NAME, CLIENT_LOG_ENABLE)
  cif = ChatIf.new(CLIENT_NAME, CHAT_INTERFACE_ENABLE)

  socket = TCPSocket.open(SERVER_IP_ADDRESS, SERVER_PORT_NUMBER)
  server_key = socket.peeraddr.inspect

  util = EncryptNetUtil.new(socket, ENCRYPT_ENABLE)
  util.client_init(SERVER_PASSWORD, ENCRYPT_DEBUG_ENABLE)
  cif.puts log.time_rec(server_key + ": connecting...")
rescue
  cif.puts log.time_rec("init: #$! #$@")
else

  sender = Proc.new {
    begin
      s_buf = cif.gets
      s_str = s_buf.chomp
      if s_str != "" then
        util.send(s_str)
      end
    rescue
      cif.puts log.time_rec("sender: #$! #$@")
    end
  }

  receiver = Proc.new {
    begin
      server_name = nil
      client_id = nil
      member_array = Array.new

      util.send("!client_name:" + CLIENT_NAME)

      while r_str = util.receive
        if /^!server_name:(.+)/ =~ r_str then
          server_name = $1
          log.rec("server_name: " + server_name)
        elsif /^!client_id:(.+)/ =~ r_str then
          client_id = $1
          cif.title_update(client_id + " connected to " + server_name)
          log.rec("client_id: " + client_id)
        elsif /^!add_members:(.+)/ =~ r_str then
          member_array += $1.split
          cif.member_update(member_array)
        elsif /^!add_member:(.+)/ =~ r_str then
          member_array.push($1)
          cif.member_update(member_array)
        elsif /^!del_member:(.+)/ =~ r_str then
          member_array.delete($1)
          cif.member_update(member_array)
        else
          cif.puts log.rec(r_str)
        end
      end 

      cif.puts log.time_rec("..." + server_name + " down")
      cif.title_update(CLIENT_NAME)
    rescue
      cif.puts log.time_rec("receiver: #$! #$@")
    end
  }

  begin # main
    cif.mainloop(sender, receiver)
  rescue
    cif.puts log.time_rec("main: #$! #$@")
  ensure
    socket.close if socket
    puts log.time_rec(server_key + ": ...disconnected")
  end

end # init

# end of code
