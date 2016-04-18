# encoding: utf-8

require "socket"
require "openssl"

require "./lib/util"

class NetUtil
  def initialize(socket)
    @socket = socket
  end

  def send(str)
    @socket.write(str)
    @socket.flush
    sleep(0.1)
  end
  def receive
    buf = @socket.recv(1024)
    (buf != "") ? buf : nil
  end
end

class EncryptUtil

  def initialize(enable=true)
    @enable = enable 
    if @enalbe then
      OpenSSL::Random.seed(File.read("/dev/random",16))
      @rsa = nil
      @enc = nil
      @dec = nil
      @keyiv = nil
    end
  end

  def rsa_gen(key=nil)
    if @enable then
      if key == nil then
        @rsa = OpenSSL::PKey::RSA.generate(1024)
      else
        @rsa = OpenSSL::PKey::RSA.new(key)
      end
    end
  end
  def rsa_pblc_key
    if @enable then
      @rsa.public_key.to_s
    else
      "rsa_pblc_key"
    end
  end
  def rsa_prvt_enc(str)
    (@enable) ? @rsa.private_encrypt(str) : str
  end
  def rsa_prvt_dec(enc_str)
    (@enable) ? @rsa.private_decrypt(enc_str) : enc_str
  end
  def rsa_pblc_enc(str)
    (@enable) ? @rsa.public_encrypt(str) : str
  end
  def rsa_pblc_dec(enc_str)
    (@enable) ? @rsa.public_decrypt(enc_str) : enc_str
  end

  def cipher_gen(keyiv=nil, passwd=nil)

    if @enable then
      @enc = OpenSSL::Cipher.new("AES-256-CBC")
      @enc.encrypt
      @dec = OpenSSL::Cipher.new("AES-256-CBC")
      @dec.decrypt

      if keyiv == nil then
        if passwd == nil then
          passwd = OpenSSL::Random.random_bytes(16)
        end
        salt = OpenSSL::Random.random_bytes(8)
        @keyiv = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
          passwd, salt, 2000, @enc.key_len + @enc.iv_len)
      else
        @keyiv = keyiv
      end
    end
  end
  def cipher_keyiv
    if @enable then
      @keyiv
    else
      "cipher_keyiv"
    end
  end
  def cipher_enc(str)
    if @enable then
      @enc.key = @keyiv[0, @enc.key_len]
      @enc.iv = @keyiv[@enc.key_len, @enc.iv_len]
      enc_body = @enc.update(str)
      enc_body + @enc.final
    else
      str
    end
  end
  def cipher_dec(enc_str)
    if @enable then
      @dec.key = @keyiv[0, @dec.key_len]
      @dec.iv = @keyiv[@dec.key_len, @dec.iv_len]
      enc_body = @dec.update(enc_str)
      enc_body + @dec.final
    else
      enc_str
    end
  end

end

class EncryptNetUtil
  def initialize(socket, encrypt_enable=true)
    @n_util = NetUtil.new(socket)
    @e_util = EncryptUtil.new(encrypt_enable)
  end

  def server_init(passwd, debug_enable=false)
    rsa_key = @n_util.receive
    @e_util.rsa_gen(rsa_key)
    p "1" if debug_enable

    @e_util.cipher_gen
    enc_str = @e_util.rsa_pblc_enc(@e_util.cipher_keyiv)
    @n_util.send(enc_str)
    p "2" if debug_enable

    pw_dgst = hexdigest(passwd)
    str = self.receive
    p "3" if debug_enable

    if pw_dgst == str then
      self.send("!OK")
    else
      self.send("!NG")
      raise "unmatch password"
    end
    p "4" if debug_enable
  end
  def client_init(passwd, debug_enable=false)
    @e_util.rsa_gen
    @n_util.send(@e_util.rsa_pblc_key)
    p "1" if debug_enable

    enc_str = @n_util.receive
    cipher_keyiv = @e_util.rsa_prvt_dec(enc_str)
    @e_util.cipher_gen(cipher_keyiv)
    p "2" if debug_enable

    pw_dgst = hexdigest(passwd)
    self.send(pw_dgst)
    p "3" if debug_enable

    str = self.receive
    if str != "!OK" then
      raise "unmatch password"
    end
    p "4" if debug_enable
  end

  def send(str)
    enc_str = @e_util.cipher_enc(str)
    @n_util.send(enc_str)
  end
  def receive
    enc_str = @n_util.receive
    (enc_str) ? @e_util.cipher_dec(enc_str) : nil
  end
end

