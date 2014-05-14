Mix Test Env
=========

1. Dependencies:

```sh
ruby 2.1.0p0
protobuf
ruby-protofbu (bundle)
openssl (available in path)
```

2. Setup keys

```sh
#-b server base port
#-s server instances
#-c client instances
ruby setup.rb -b 10000 -s 5 -c 5
```

3. Start server

```sh
#-b base port as used in setup.rb
#-i server id 0..4
ruby server.rb -b 10000 -i {0,..,4}
```

3. Start clients

```sh
#-i client id 0..4
# more options available with -h
ruby client.rb -i {0,..,4}
```

4. Decrypt messages

To decrypt the following messages

```sh
[M] -> client1 [bbc4aa3fa029fd3e59f6f68d0017ea4a90ed138c]
```

run

```sh
ruby decryptor.rb -r client1 -m bbc4aa3fa029fd3e59f6f68d0017ea4a90ed138c
```
