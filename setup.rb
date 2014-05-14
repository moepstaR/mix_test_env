require 'openssl'
require 'optparse'
require 'fileutils'

options = {}

ARGV << '-h' if ARGV.empty?

parser = OptionParser.new do|opts|
  opts.banner = "Usage: setup.rb [options]"
  opts.on('-b', '--base-port port', '') do |baseport|
    options[:baseport] = baseport.to_i;
  end

  opts.on('-c', '--client-instances clients', '') do |clients|
    options[:clients] = clients.to_i;
  end

  opts.on('-s', '--server-instances servers', '') do |server|
    options[:server] = server.to_i;
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

parser.parse!

if options[:baseport] && options[:server] && options[:clients]
  path = File.dirname(__FILE__)
  key_dir = File.join(path, 'keys')
  message_dir = File.join(path, 'messages')

  unless File.exists?(message_dir)
    Dir.mkdir(message_dir)
  end

  if File.exists?(key_dir)
    puts "Clean up old keys ..."
    FileUtils.rm_rf(key_dir)
    Dir.mkdir(key_dir)
  else
    Dir.mkdir(key_dir)
  end

  options[:server].times do |idx|
    puts "Creating server keypair"
    server_dir = File.join(key_dir, "#{options[:baseport] + idx}")
    Dir.mkdir(server_dir)

    pub = File.join(server_dir, 'id_rsa.pub')
    priv = File.join(server_dir, 'id_rsa')

    keypair = OpenSSL::PKey::RSA.generate(4096)
    File.open(priv, 'w') { |f| f.write keypair.to_pem }
    File.open(pub, 'w') { |f| f.write keypair.public_key.to_pem }
  end

  options[:clients].times do |idx|
    puts "Creating client keypair"
    client_dir = File.join(key_dir, "client#{idx}")
    Dir.mkdir(client_dir)

    pub = File.join(client_dir, 'id_rsa.pub')
    priv = File.join(client_dir, 'id_rsa')

    keypair = OpenSSL::PKey::RSA.generate(4096)
    File.open(priv, 'w') { |f| f.write keypair.to_pem }
    File.open(pub, 'w') { |f| f.write keypair.public_key.to_pem }
  end


else
  puts "Please set all options"
end
