#!/usr/bin/ruby
@chars = "23456789TJQKAhscd "

def check c
  system "echo #{c}44444 | wine pe1.exe"
  r = $?.exitstatus
  printf "[.] %10s : %d %s\n", c, r, "*"*r if r>6
  r
end

def loop s0=""
  @chars.each_char do |c|
    s = s0 + c
    r = check s
    if r >= s.size
      print "\r#{s}: #{r}"
      loop s
    end
  end
end

loop
