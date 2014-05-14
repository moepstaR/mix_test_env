require 'openssl'
require 'Base64'
require 'socket'
require 'digest/sha1'
require 'optparse'
require './protobuf/protocol.pb'
require './util.rb'

class Client
  include MixUtil

  def initialize(options = {})
    @id = options[:id]
    @client_name = "client#{@id}"
    @key_dir = File.join(File.dirname(__FILE__), 'keys')
    @send_real_percent = options[:send_real_percent] || 1
    @sleep = options[:sleep] || 0.05
    @level = options[:level] || 5

    @public_key = load_rsa_pub(File.join(@key_dir,@client_name))
    @private_key = load_rsa_priv(File.join(@key_dir,@client_name))

    prepare_adress_book
  end


  def encrypt_message(addr,msg)
    key = `openssl rand -base64 32`

    enc_key = addr != "NOISE" ? public_key_encrypt(key,@address_book[addr]) : key

    c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    c.encrypt
    c.iv = iv = c.random_iv
    c.key = key

    enc_msg = c.update(msg)
    enc_msg << c.final

    anonym_message = Protobuf::MixMessage.new
    anonym_message.addr = addr
    anonym_message.iv = iv
    anonym_message.key = enc_key
    anonym_message.msg = enc_msg

    anonym_message.serialize_to_string
  end

  def run
    while true
      if rand(100) < @send_real_percent
        addr = (@client_pool - [@client_name]).sample
        content = "Super secret and anonym message!"
      else
        addr = "NOISE"
        content = `openssl rand -base64 #{rand(500)+100}`
      end

      last_mix = ""
      msg = encrypt_message(addr,content)
      route = []
      @level.times do
        last_mix = (@server_pool - [last_mix]).sample
        route << last_mix
        msg = encrypt_message(last_mix, msg)
      end

      if addr == "NOISE"
        puts "[N] -> #{route.reverse.join(" -> ")} [#{msg.size}B]"
      else
        puts "[Message] -> #{route.reverse.join(" -> ")} -> #{addr} [#{msg.size}B]"
      end

      socket = TCPSocket.open('localhost', last_mix)
      socket.write(msg)
      socket.close
      sleep @sleep
    end
  end
end

options = {}

ARGV << '-h' if ARGV.empty?

parser = OptionParser.new do|opts|
  opts.banner = "Usage: client.rb [options]"
  opts.on('-i', '--id id', 'Client ID starting form 0') do |id|
    options[:id] = id.to_i;
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end

  opts.on('-s', '--sleep time_in_s', 'sleep seconds between messges') do |sleep|
    options[:sleep] = sleep.to_f;
  end

  opts.on('-p', '--send-real-percent percent', 'probablity to send real message [0..100]') do |percent|
    options[:send_real_percent] = percent.to_i;
  end

  opts.on('-l', '--levels levels', 'mix levels [3..]') do |level|
    options[:level] = level.to_i;
  end

end

parser.parse!

Client.new(options).run

