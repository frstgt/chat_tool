#!/usr/bin/ruby
# encoding: utf-8

require "socket"
require "thread"

load "./chat_setting.rb"
require "./lib/log_util"
require "./lib/net_util"
require "./lib/chat_if"

# start connection to server
begin # init
  log = LogUtil.new("./log", CLIENT_NAME, LOG_ENABLE)

  socket = TCPSocket.open(SERVER_IP_ADDRESS, SERVER_PORT_NUMBER)
  server_key = socket.peeraddr.inspect
  log.time_rec(server_key + ": connecting...")

  util = EncryptNetUtil.new(socket, ENCRYPT_ENABLE)
  util.client_init(SERVER_PASSWORD, ENCRYPT_DEBUG_ENABLE)
rescue => e
  puts log.time_rec("init: #$! #$@")
else

  begin # main
    cif = ChatIf.new(CLIENT_NAME, CHAT_INTERFACE_ENABLE)

    # start thread for recieving message from server
    reciever = Thread.new() do

      begin
        server_name = nil
        client_id = nil
        member_array = Array.new

        while t_str = util.receive
          if /^!server_name:(.+)/ =~ t_str then
            server_name = $1
            log.rec("server_name: " + server_name)
          elsif /^!client_id:(.+)/ =~ t_str then
            client_id = $1
            cif.title_update(client_id + " connected to " + server_name)
            log.rec("client_id: " + client_id)
          elsif /^!add_members:(.+)/ =~ t_str then
            member_array += $1.split
            cif.member_update(member_array)
          elsif /^!add_member:(.+)/ =~ t_str then
            member_array.push($1)
            cif.member_update(member_array)
          elsif /^!del_member:(.+)/ =~ t_str then
            member_array.delete($1)
            cif.member_update(member_array)
          else
            cif.puts(log.rec(t_str))
          end
        end 

        cif.puts(log.time_rec("..." + server_name + " down"))
        cif.title_update(CLIENT_NAME)
      rescue => e
        log.time_rec("receiver: #$! #$@")
      end

    end # receiver

    util.send("!client_name:" + ((CLIENT_NAME) ? CLIENT_NAME : "Client"))

    # get input and send message to server
    while buf = cif.gets

      str = buf.chomp
#      if /^!.*/ =~ str then
        # do nothing
#      else
        util.send(str)
#      end
    end

  rescue => e
    puts log.time_rec("main: #$! #$@")
  ensure
    reciever.exit
    cif.finarize
  end # main

ensure
  socket.close
  log.time_rec(server_key + ": ...disconnected")
end # init

# end of code
