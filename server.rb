require 'openssl'
require 'Base64'
require 'socket'
require 'digest/sha1'
require 'optparse'
require './protobuf/protocol.pb'
require './util.rb'

class Mix
  include MixUtil

  def initialize(options = {})
    @id = options[:id]
    @baseport = options[:baseport]
    @port = @baseport + @id
    @server_name = @port.to_s

    @key_dir = File.join(File.dirname(__FILE__), 'keys')

    @public_key = load_rsa_pub(File.join(@key_dir,@server_name))
    @private_key = load_rsa_priv(File.join(@key_dir,@server_name))

    prepare_adress_book
    puts "Known server: #{@server_pool.join(",")}"
    puts "Known clients: #{@client_pool.join(",")}"

  end

  def run

    puts "Starting server @ port #{@port}"
    acceptor = TCPServer.open(@port)

    fds = [acceptor]
    while true
      if ios = select(fds, [], [], 1)
        reads = ios.first
        reads.each do |client|
          if client == acceptor
            client = acceptor.accept
            fds << client
          elsif client.eof?
            fds.delete(client)
            client.close
          else
            packet = client.read

            mix_message = Protobuf::MixMessage.new
            mix_message.parse_from_string(packet)

            key = decrypt_public_key(mix_message.key)

            c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
            c.decrypt
            c.iv = mix_message.iv
            c.key = key
            decrypted_msg = c.update(mix_message.msg)
            decrypted_msg << c.final

            decrypted_mix_message = Protobuf::MixMessage.new
            decrypted_mix_message.parse_from_string(decrypted_msg)

            msg = decrypted_mix_message.serialize_to_string

            addr = decrypted_mix_message.addr

            if addr != "NOISE"
              unless @server_pool.include?(addr)
                filename = Digest::SHA1.hexdigest(msg)

                f = File.open(File.join("messages",filename),'w')
                f.write msg
                f.close

                puts "\n[M] -> #{addr} [#{filename}]"
              else
                print "."
                receiver = TCPSocket.open('localhost', addr)
                receiver.write(msg)
                receiver.close
              end
            end

          end
        end
      end
    end
  end
end

options = {}

ARGV << '-h' if ARGV.empty?

parser = OptionParser.new do|opts|
  opts.banner = "Usage: server.rb [options]"

  opts.on('-b', '--baseport port', 'Base Port') do |port|
    options[:baseport] = port.to_i;
  end

  opts.on('-i', '--id id', 'Server ID starting form 0') do |id|
    options[:id] = id.to_i;
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

parser.parse!

Mix.new(options).run


