module MixUtil

  def load_rsa_pub(path)
    OpenSSL::PKey::RSA.new(File.read(File.join(path,"id_rsa.pub")))
  end

  def load_rsa_priv(path)
    OpenSSL::PKey::RSA.new(File.read(File.join(path,"id_rsa")))
  end

  def public_key_encrypt(data, key)
    Base64::encode64(key.public_encrypt(data)).rstrip
  end

  def decrypt_public_key(message)
    @private_key.private_decrypt(Base64::decode64(message))
  end

  def prepare_adress_book
    @address_book = {}
    @client_pool = []
    @server_pool = []

    directories = Dir.entries(@key_dir)[2..-1]

    directories.each do |dir|
      if dir.match(/client/)
        @client_pool << dir
      else
        @server_pool << dir
      end
      @address_book[dir] = load_rsa_pub(File.join(@key_dir, dir))
    end
  end


end
