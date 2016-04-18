#!/usr/bin/ruby
# encoding: utf-8

require "socket"
require "thread"

load "./chat_setting.rb"
require "./lib/log_util"
require "./lib/net_util"
require "./lib/chat_sys"
require "./lib/util"

begin # init
  log = LogUtil.new("./log", SERVER_NAME, LOG_ENABLE)

  server = TCPServer.open('', SERVER_PORT_NUMBER)
  csys = ChatSys.new

  puts log.time_rec("chat server running...")
rescue
  log.time_rec("init: #$! #$@")
else

  sub_servers = Array.new
  while true

    # start thread for client
    sub_server = Thread.new(server.accept) do |socket|
      begin
        client_key = socket.peeraddr.inspect
        client_id = nil

        util = EncryptNetUtil.new(socket, ENCRYPT_ENABLE)
        util.server_init(SERVER_PASSWORD, ENCRYPT_DEBUG_ENABLE)
        puts log.time_rec(client_key + ": connecting...")
      rescue
        puts log.time_rec("sub_server: #$! #$@")
      else

        # start thread for receiving message from client
        receiver = Thread.new do
          begin
            while str = util.receive

              if /^!client_name:(.+)/ =~ str then

                # send server name
                util.send("!server_name:" + SERVER_NAME)

                # entry client information
                client_id = csys.add_member(client_key, $1)
                util.send("!client_id:" + client_id)
                csys.send_to_all_without_me("!add_member:" + client_id,
                                            client_id)
                puts log.rec("client_id: " + client_id)

                # send client members
                members = csys.members
                if members.size > 0 then
                  util.send("!add_members:" + members.join(" "))
                end

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
          rescue
            log.time_rec("receiver: #$! #$@")
          ensure
            # delete client information
            csys.send_to_all_without_me("!del_member:" + client_id, client_id)
            csys.del_member(client_key)
          end
        end # receiver

        # start thread for sending message to client
        sender = Thread.new do
          begin
            while t_str = csys.receive(client_key)
              util.send(t_str)
            end
          rescue
            log.time_rec("sender: #$! #$@")
          end
        end # sender

        loop do
          sleep(0.1)
        end

      ensure
        receiver.exit
        sender.exit
        socket.close
        puts log.time_rec(client_key + ": ...disconnected")
      end
    end # sub_server

    sub_servers.push(sub_server)

  end # while

ensure
  for sub_server in sub_servers do
    sub_server.exit
  end
  server.close
  puts log.time_rec("... chat server stopped")
  exit!
end # init

# end of code
