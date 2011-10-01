class Notes
  def Notes.read(id)
    return 'fsck yslf' if id.to_s['..']
    if Dir.glob("./notes/#{id}").length==1 #returns an empty array if file does not exist
      return File.read("./notes/#{id}").strip #read back content if it exists
    else
      return "there is no such note stored on the server"
    end
  end

  def Notes.store(text)
    name=hash(text)
    seed=1
    while Dir.glob("./notes/#{name}").length==1 #if there is such a file -> avoid collisions
      name=hash(text,seed+=1)
    end
    File.open("./notes/#{name}","w") do |f|
      f.puts text #store with the hased name
    end
    return "your note has been stored with the id: #{name}"
  end

  def Notes.hash(text,seed=0)
    srand(text.length+100*Time.now.to_i+seed*10000) #seed with milliseconds
    id=rand(999999)*999999+rand(999999) # get an random id -> big enough that colisions are unlikely
    return id.to_s 16 #hexencode it
  end

  def Notes.list
    #return `ls ./notes/`
    return "FOO"
  end
end
