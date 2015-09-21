#!/usr/bin/env ruby
# Stephanie Embgen

# Collection of useful functions


# Split a graph into snapshots of a specific duration

def create_snapshots(sortedgraphfile, splitfilefolder, hour = 4)
  filenumber = 0
  lasthour = 0
  splitfilename = splitfilefolder + '/' + sortedgraphfile.split('/')[-1] + "_split"
  splitfile = open(splitfilename + '00', 'w')
  
  File.open(sortedgraphfile, 'r') do |gf|
    while line = gf.gets
      
      timestamp = Time.at(line.split(" ")[2].to_i)
      
      if timestamp.hour == 4 and lasthour == 3
        unless filenumber == 0
          splitfile.close
          splitfile = open(splitfilename + filenumber < 10 ? '0' : '' + filenumber.to_s, 'w')
        end
        filenumber += 1
      end
      
      splitfile.write(line)
      lasthour = timestamp.hour
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

def user_pairs(originalfile, newfilePerUser, newfileTotal)
  
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
            end
            i = 1
            thisuser = u
          end
        end
        # write last encountered user to file
        unless thisuser < user
          nfpu.puts "#{user} #{thisuser} #{i}"
        end
      end
    end
  end
  puts "created files #{newfileTotal} and #{newfilePerUser}"
end

# calculates the connected components for a set of splitfiles using graphchi
def connected_components(graphchi, splitfilefolder, files)
  resultfiles = []
  for file in files
    graphchi_call = "#{graphchi}/bin/example_apps/connectedcomponents file #{folder}/#{file} filetype edgelist"
    system(graphchi_call)
    
    # deal with all the files graphchi creates
    resultfiles.push (file + ".components")
    File.delete(file + ".1.intervals", file + ".4B.vout", file + "_degs.bin", file + ".deltalog", file + ".numvertices")
    system("rm #{file}.edata*")
  end
  
  results = []
  default_array = Array.new(resultfiles.size*2, "")
  
  for file in resultfiles
    File.open(folder + '/' + file, 'r') do |f|
      i = 0
      while line = f.gets
        ary = results[i] || default_array
        ary[i*2] = line.split(" ")[0]
        ary[i*2 + 1] = line.split(" ")[1]
        i += 1
      end
    end
  end
      
  File.open(connectedcomponents.csv, 'w') do |rf|
    results.each do |ary|
      rf.puts ary.join(";")
    end
  end
  
  puts "Connected components written to connectedcomponents.csv"
end

