#!/usr/bin/ruby
# encoding: utf-8

require "socket"
require "thread"

load "./chat_setting.rb"
require "./lib/log_util"
require "./lib/net_util"
require "./lib/chat_sys"
require "./lib/util"

begin # init for server
  log = LogUtil.new("./log", SERVER_NAME, LOG_ENABLE)

  server = TCPServer.open('', SERVER_PORT_NUMBER)
  csys = ChatSys.new

  puts log.time_rec("chat server running...")

  receivers = Array.new
  while true

    # start thread for client
    receiver = Thread.new(server.accept) do |socket|

      begin # init for client
        util = EncryptNetUtil.new(socket, ENCRYPT_ENABLE)
        util.server_init(SERVER_PASSWORD, ENCRYPT_DEBUG_ENABLE)

        begin # main
          client_key = socket.peeraddr.inspect
          client_id = nil

          puts log.time_rec(client_key + ": connecting...")

          # start thread for sending message to client
          sender = Thread.new do
            begin
              while t_str = csys.receive(client_key)
                util.send(t_str)
              end
            rescue => e
              log.time_rec("sender: #$! #$@")
            end
          end

          # send server information and client members
          util.send("!server_name:" + ((SERVER_NAME) ? SERVER_NAME : "Server"))

          members = csys.members
          if members.size > 0 then
            util.send("!add_members:" + members.join(" "))
          end

          # receive message from client
          while str = util.receive
            if /^!client_name:(.+)/ =~ str then
              client_id = csys.add_member(client_key, $1)
              util.send("!client_id:" + client_id)
              csys.send_to_all_without_me("!add_member:" + client_id,
                                         client_id)
              puts log.rec("client_id: " + client_id)
            elsif /^!.*/ =~ str then
              # do nothing
            elsif /(.+):(.+)/ =~ str then
              to = $1.split
              csys.send_to("(" + client_id + "->" + to.join(" ") + ") " + $2,
                          to | [client_id])
            else
              csys.send_to_all("[" + client_id + "] " + str)
            end
          end

        rescue => e
          log.time_rec("main: #$! #$@")
        ensure
          csys.send_to_all_without_me("!del_member:" + client_id,
                                     client_id)
          csys.del_member(client_key)
          sender.exit

          puts log.time_rec(client_key + ": ...disconnected")
        end # main

      rescue => e
        log.time_rec("init for client: #$! #$@")
      ensure
        socket.close
      end # init for client

    end # receiver

    receivers.push(receiver)

  end # while

rescue => e
  log.time_rec("init for server: #$! #$@")
ensure
  for receiver in receivers do
    receiver.exit
  end
  server.close
  puts log.time_rec("... chat server stopped")
  exit!
end # init for server

# end of code
