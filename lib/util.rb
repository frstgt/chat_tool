# encoding: utf-8

require "digest/sha2"

def nop
  # do nothing
end

def hexdigest(str)
  Digest::SHA256.hexdigest(str)
end

