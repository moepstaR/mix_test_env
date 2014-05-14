require 'openssl'
require 'Base64'
require 'openssl'
require 'digest/sha1'
require './protobuf/protocol.pb'
require 'optparse'


options = {}

ARGV << '-h' if ARGV.empty?

parser = OptionParser.new do|opts|
  opts.banner = "Usage: decryptor.rb [options]"

  opts.on('-r', '--client id', 'Receipient id (client0) etc') do |id|
    options[:id] = id
  end

  opts.on('-m', '--message hash', 'published sha1') do |path|
    options[:path] = path
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

parser.parse!


message = Protobuf::MixMessage.new
message.parse_from_string(File.read(File.join('messages',options[:path])))

privk = OpenSSL::PKey::RSA.new( File.read( File.join(File.dirname(__FILE__), 'keys', options[:id], 'id_rsa')))

dec_key = privk.private_decrypt(Base64::decode64(message.key))
c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
c.decrypt
c.iv = message.iv
c.key = dec_key

dec_msg = c.update(message.msg)
dec_msg << c.final

puts "\n* Message to token: #{message.addr}"
puts "\n* Encrypted message key:"
puts message.key
puts "\n* Decrypted message key:"
puts dec_key
puts "\n* IV:"
puts message.iv
puts "\n* Decrypted Message"
puts dec_msg
