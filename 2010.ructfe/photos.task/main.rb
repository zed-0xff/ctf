#!/usr/bin/ruby

#coding: utf-8

#* Authors: andgein, ld
#* RuCTFE 2010
#* http://ructf.org/e/

require 'sinatra'
require 'haml'
require 'sqlite3'
require 'json'
require 'fileutils'
require 'socket'
require 'digest/md5'

include Socket::Constants

set :run, true
set :views, 'views'
enable :sessions

$SitePrefix = '/photos'
$LogFilename = 'sinatra.log'

log = File.new($LogFilename, 'a')
STDOUT.reopen(log)
STDERR.reopen(log)

class Albums
  def initialize
    @db = SQLite3::Database.new('database.db')
    @db.execute 'CREATE TABLE IF NOT EXISTS pictures (
                   pid INTEGER PRIMARY KEY ASC,
                   aid INT NOT NULL,
                   title VARCHAR(255),
                   src VARCHAR(255)
                 )'
    @db.execute 'CREATE TABLE IF NOT EXISTS albums (
                   aid INTEGER PRIMARY KEY ASC,
                   owner VARCHAR(255),
                   mode INT NOT NULL
                 )'
    @db.execute 'CREATE TABLE IF NOT EXISTS comments (
                   pid INT NOT NULL,
                   author VARCHAR(255),
                   text VARCHAR(255)
                 )'

  end
  def addAlbum(mode, owner)
    mode = mode.to_i
    @db.execute('BEGIN TRANSACTION')
    @db.execute "INSERT INTO albums (owner, mode) VALUES ('#{ owner }', '#{ mode }')"
    aid = @db.execute 'SELECT last_insert_rowid()'
    @db.execute('COMMIT')
    return aid[0][0]
  end
  def addPicture(aid, title, src)
    @db.execute "INSERT INTO pictures (aid, title, src) VALUES ('#{ aid }', '#{ title }', '#{ src }')"
  end
  def getPictures(aid)
    @db.execute "SELECT * FROM pictures WHERE aid = '#{ aid }'"
  end
  def getPicture(pid)
    result = @db.execute "SELECT * FROM pictures WHERE pid = '#{ pid }'"
    return '' unless result[0]
    return result[0][3]
  end
  def findAlbum(pid)
    result = @db.execute "SELECT * FROM pictures WHERE pid = '#{ pid }'"
    return '' unless result[0]
    return result[0][1]
  end
  def getAlbum(aid)
    return @db.execute "SELECT * FROM albums WHERE aid = '#{ aid }'"
  end
  def getAllAlbums(login)
    unless login
      File.open 'zlog','a' do |f|
        f.puts 'SELECT * FROM albums WHERE mode = 0 ORDER BY aid DESC LIMIT 16'
      end
      return (@db.execute 'SELECT * FROM albums WHERE mode = 0 ORDER BY aid DESC LIMIT 16')
    else
      File.open 'zlog','a' do |f|
        f.puts request.inspect
        f.puts "SELECT * FROM albums WHERE mode = 0 OR owner = '#{ login }' ORDER BY aid DESC LIMIT 16"
      end
      return (@db.execute "SELECT * FROM albums WHERE mode = 0 OR owner = '#{ login }' ORDER BY aid DESC LIMIT 16")
    end
  end
  def getComments(pid)
    @db.execute "SELECT author, text FROM comments WHERE pid = #{ pid }"
  end
  def addComment(pid, text, author)
    @db.execute "INSERT INTO comments (pid, author, text) VALUES (#{ pid }, '#{ author }', '#{ text }')"
  end
end

def auth(login, password)
  return false unless (login =~ /\w+/ and password =~ /\w+/)

  # Only for debug! ;-)
#  return true

  socket = Socket.new(AF_INET, SOCK_STREAM, 0)
  sockaddr = Socket.pack_sockaddr_in(80, '127.0.0.1')
  socket.connect(sockaddr)
  socket.write("GET /auth/check/#{ login }/#{ password } HTTP/1.0\r\n\r\n")
  results = socket.read
  socket.close
  return ( (results =~ /OK/i) != nil )
end

def register(login, password)
  return false unless (login =~ /\w+/ and password =~ /\w+/)
  socket = Socket.new(AF_INET, SOCK_STREAM, 0)
  sockaddr = Socket.pack_sockaddr_in(80, '127.0.0.1');
  socket.connect(sockaddr);
  socket.write("GET /auth/register/#{ login }/#{ password } HTTP/1.0\r\n\r\n");
  results = socket.read
  socket.close
  return ( (results =~ /OK/i) != nil )
end

before do
  content_type 'text/html'
end

get '/' do
  @auth = session['login'] != nil
  @login = session['login'] == nil ? '' : session['login']
  haml :index
end

post '/ajax/upload' do
  if params[:file_input] != nil
    fileHandle = params[:file_input][:tempfile]
    fileExt = params[:file_input][:filename].split('.')[-1];
    fileName = Digest::MD5.hexdigest(params[:file_input][:filename] + Time.new.to_s)
    fileFullName = [fileName , fileExt].join('.')
    FileUtils.cp(fileHandle.path, "files/photos/#{ fileFullName }")
    (Albums.new).addPicture( quote_string(params[:aid]) , quote_string(params[:title_input]) , fileFullName )
  end
  "<script type='text/javascript' language='javascript'>window.parent.location = '#{ $SitePrefix }/#albums'</script>"
end

post '/ajax/create' do
  unless session['login']
    JSON 'fail' => '1', 'error' => 'denied'
  else
    name = quote_string(params[:name])
    mode = params[:mode].to_i
    login = quote_string(session['login'])
    aid = (Albums.new).addAlbum( mode, login )
    # Create avatar
    `perl avatar.pl "#{ login }" "#{ name }" | perl create_avatar.pl files/avatars/#{ aid }.png`
    # Waiting avatar
    sleep 2
    JSON 'fail' => '0', 'aid' => aid
  end
end

post '/ajax/photos' do
  if params[:aid]
    aid = params[:aid].to_i
    album = (Albums.new).getAlbum(aid)
    if album[0] == nil
      JSON 'fail' => 1, 'error' => 'not found'
    elsif album[0][2] == 0 or album[0][1] == session['login']
      JSON 'photos' => (Albums.new).getPictures(aid), 'aid' => aid, 'album' => album, 'fail' => 0
    else
      JSON 'fail' => 1, 'error' => 'denied'
    end
  else
    JSON 'fail' => 1, 'error' => 'need aid'
  end
end

post '/ajax/albums' do
  JSON 'albums' => (Albums.new).getAllAlbums( quote_string(session['login']) )
end

post '/ajax/getcomments' do
  if params[:pid]
    pid = params[:pid].to_i
    album = (Albums.new).getAlbum( (Albums.new).findAlbum(pid) )
    if album[0] == nil
      JSON 'fail' => 1, 'error' => 'not found'
    elsif album[0][2] == 0 or album[0][1] == session['login']
      JSON 'comments' => (Albums.new).getComments(pid), 'src' => (Albums.new).getPicture(pid), 'fail' => 0
    else
      JSON 'fail' => 1, 'error' => 'denied'
    end
  else
    JSON 'fail' => 1, 'error' => 'need pid'
  end
end

post '/ajax/putcomment' do
  if params[:pid] != nil and params[:comment] != nil
    pid = params[:pid].to_i
    comment = params[:comment]
    album = (Albums.new).getAlbum((Albums.new).findAlbum(pid))
    if album[0] == nil or session['login'] == nil
      JSON 'fail' => 1, 'error' => 'not found'
    elsif album[0][2] == 0 or album[0][1] == session['login']
      (Albums.new).addComment(pid, comment, quote_string(session['login']) )
      JSON 'fail' => 0
    else
      JSON 'fail' => 1, 'error' => 'denied'
    end
  else
    JSON 'fail' => 1, 'error' => 'need pid and comment'
  end
end

get '/files/:dirname/:filename' do
  if params[:dirname] == 'css' or params[:dirname] == 'javascript'
    content_type "text/#{ params[:dirname] }", :charset => 'utf-8'
  elsif params[:dirname] =~ /image|photos|avatars/
    content_type 'image/' + params[:filename].split('.')[-1]
    response.headers['Cache-Control'] = 'public, max-age=30000'
  end
  return '' unless File.exist?("files/#{ params[:dirname] }/#{ params[:filename] }")
  file = File.open("files/#{ params[:dirname] }/#{ params[:filename] }", 'rb')
  content = file.read
  file.close
  return content
end

post '/login' do
  login = params[:login]
  password = params[:password]
  ok = auth(login, password)
  puts "Access user: #{ login } with password: #{ password }"
  ok = register(login, password) unless ok
  if ok
    session['login'] = login
    @nickname = login
    redirect "#{ $SitePrefix }/"
  else
    redirect "#{ $SitePrefix }/#fail"
  end
end

get '/logout' do
  session['login'] = nil
end

get '/feed.rss' do
  file = File.open($LogFilename , 'r')
  content = file.read()
  file.close
  return content
end

get '/photos' do
  redirect "#{ $SitePrefix }/"
end

def quote_string(v)
  v.to_s.gsub(/[\"\'\|\`]/, '')
end
