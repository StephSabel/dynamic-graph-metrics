#!/usr/bin/env ruby
# Stephanie Embgen

# Collection of useful functions


# Split a graph into snapshots of a specific duration

def create_snapshots(sortedgraphfile, splitfilefolder, hour = 4)
  filenumber = 0
  timeoffset = hour * 3600
  lasttimestamp = Time.at(timeoffset + 1)
  splitfilename = splitfilefolder + '/' + sortedgraphfile.split('/')[-1] + "_split"
  splitfile = open(splitfilename + '00', 'w')
  
  File.open(sortedgraphfile, 'r') do |gf|
    while line = gf.gets
      
      timestamp = Time.at(line.split(" ")[2].to_i / 1000)
      timeos = timestamp - timeoffset
      lasttimeos = lasttimestamp - timeoffset
      
      unless timeos.yday == lasttimeos.yday and timeos.year == lasttimeos.year
        unless filenumber == 0
          splitfile.close
          splitfile = open(splitfilename + (filenumber < 10 ? '0' : '') + filenumber.to_s, 'w')
        end
        filenumber += 1
      end
      
      splitfile.write(line)
      lasttimestamp = timestamp
    end
  end
  splitfile.close
  puts "File split to #{splitfilefolder}"
end


# display help text

def help
  puts "--------- USAGE ---------"
  puts "unmap: get twitter id and user handle from mapped id"
  puts "split: split graph into snapshots of specific duration"
end


# This script measures how much activation happened between pairs of users
# if if only one direction of the communication should be included in PerUser, 
# uncomment the two 'unless'-controls

def user_pairs(originalfile, newfilePerUser, newfileTotal, newfileMM)
  
  # Hash of Arrays to store users communicated with for each user
  communications = Hash.new{|hash, key| hash[key] = Array.new}
  
  File.open(originalfile, 'r') do |of|
    while line = of.gets 
      line.force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
      user1 = line.split(' ')[0].to_i
      user2 = line.split(' ')[1].to_i
      # add communication to array of each user
      communications[user1] = communications[user1]<<user2 
      communications[user2] = communications[user2]<<user1
    end
    puts "created hash for all users"
  end
  
  users = communications.keys.sort
  pairs = 0
  
  File.open(newfileTotal, 'w') do |nft|
    File.open(newfilePerUser, 'w') do |nfpu|
      users.each do |user|
        userlist = communications[user]
        
        # number of communications total for the user is length of array
        nft.puts "#{user} #{userlist.length}"
        
        userlist.sort!
        i = 0
        thisuser = userlist[0]
        userlist.each do |u|
          # count occurrence of each user
          if thisuser == u
            i += 1
          else
            # if new user is encountered, write old user to file
            unless thisuser < user
              nfpu.puts "#{user} #{thisuser} #{i}"
              pairs += 1
            end
            i = 1
            thisuser = u
          end
        end
        # write last encountered user to file
        unless thisuser < user
          nfpu.puts "#{user} #{thisuser} #{i}"
          pairs += 1
        end
      end
    end
  end
  
  File.open(newfileMM, 'w') do |nfmm|
      # Matrix Market notation for _peruser file
      nfmm.puts "%%MatrixMarket matrix coordinate real general"
      # dimensions of the matrix are the highest user id, entries are the number of pairs
      nfmm.puts "#{users[-1]} #{users[-1]} #{pairs}"
      File.open(newfilePerUser, 'r') do |nfpu|
        while line = nfpu.gets
          nfmm.puts line
        end
      end
    end
  
  puts "created files #{newfileTotal}, #{newfilePerUser} and #{newfileMM}"
end

# calls a graphchi function
def do_graphchi(graphchi_f, file)
  graphchi_call = "#{graphchi_f} file #{file} filetype edgelist"
  system(graphchi_call)
  
  #deal with the shitton of files that graphchi creates
  system("rm -r #{folder}/*.edata*")
  system("rm #{folder}/*.1.intervals")
  system("rm #{folder}/*.4B.vout")
  system("rm #{folder}/*degs.bin")
  system("rm #{folder}/*.deltalog")
  system("rm #{folder}/*.numvertices")
  system("rm #{folder}/*.components")
end

# calculates the connected components for a set of splitfiles using graphchi
def connected_components(graphchi, folder, files)
  resultfiles = []
  for file in files
    graphchi_call = "#{graphchi}/bin/example_apps/connectedcomponents file #{folder}/#{file} filetype edgelist"
    system(graphchi_call)
    
    # save results
    resultfiles.push (file + ".components")
  end

  #deal with the shitton of files that graphchi creates
  system("rm -r #{folder}/*.edata*")
  system("rm #{folder}/*.1.intervals")
  system("rm #{folder}/*.4B.vout")
  system("rm #{folder}/*degs.bin")
  system("rm #{folder}/*.deltalog")
  system("rm #{folder}/*.numvertices")
  
  results = []
  
  i=0
  for file in resultfiles
    File.open(folder + '/' + file, 'r') do |f|
      j = 0
      while line = f.gets
        line.chomp!
        ary = results[j] || Array.new(resultfiles.size*2, "")
        ary[i*2] = line.split(',')[0]
        ary[i*2 + 1] = line.split(',')[1]
        results[j] = ary
        j += 1
      end
    end
    i += 1
  end
      
  File.open("connectedcomponents.csv", 'w') do |rf|
    results.each do |ary|
      rf.puts ary.join(";")
    end
  end

  system("rm #{folder}/*.components")
  
  puts "Connected components written to connectedcomponents.csv"
end

# transpose an array of arrays
# inspired by http://www.matthewbass.com/2009/05/02/how-to-safely-transpose-ruby-arrays/
def transpose_arrays(matrix)
  maxsize = matrix.max_by{|a| a.size}.size
  result = []
  
  maxsize.times do |i|
    result[i] = Array.new(matrix.size,0)
    matrix.each_with_index {|a, j| result[i][j] = a[i] || 0}
  end
  
  result
end
  

  
