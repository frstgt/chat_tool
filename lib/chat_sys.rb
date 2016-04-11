# encoding: utf-8

require "./lib/util"

class ChatSys

  def initialize
    @client_hash = Hash.new
    @serial_number = 0
  end

  def add_member(key, name)
    client = Hash.new
    client[:id] = sprintf("%.8s%02d", name, @serial_number)
    client[:queue] = Queue.new
    @client_hash[key] = client
    @serial_number += 1
    client[:id]
  end
  def del_member(key)
    @client_hash.delete(key)
  end
  def members
    ary = Array.new
    @client_hash.each_value do |val|
      ary.push(val[:id])
    end
    ary
  end

  def send_to_all(msg)
    @client_hash.each_value do |val|
      val[:queue].push(msg)
    end
  end
  def send_to_all_without_me(msg, from)
    @client_hash.each_value do |val|
      if val[:id] != from then
        val[:queue].push(msg)
      end
    end
  end
  def send_to(msg, to)
    for id in to do
      @client_hash.each_value do |val|
        if id == val[:id] then
          val[:queue].push(msg)
        end
      end
    end
  end

  def receive(key)
    nop until @client_hash.has_key?(key)
    @client_hash[key][:queue].pop
  end
end
