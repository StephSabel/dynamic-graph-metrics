#!/usr/bin/env ruby
# Stephanie Embgen

# Collection of useful functions


# Split a graph into snapshots of a specific duration

def create_snapshots(sortedgraphfile, splitfilename, minutes)
  timestepsize = minutes * 60000
  lasttimesteptime = 0
  filenumber = 0
  splitfile = open(splitfilename + filenumber.to_s, 'w')
  
  File.open(sortedgraphfile, 'r') do |gf|
    while line = gf.gets
      
      timestamp = line.split(" ")[2].to_i
      
      if timestamp - lasttimesteptime >= timestepsize
        lasttimesteptime = timestamp
        unless filenumber == 0
          splitfile.close
          splitfile = open(splitfilename + filenumber.to_s, 'w')
        end
        filenumber += 1
      end
      
      splitfile.write(line)
    end
  end
  splitfile.close
end


# display error message

def error(admonish)
  if admonish
    puts "--------- ERROR ---------"
    puts "unknown command or missing arguments of arguments"
    puts "\n"
  end
  
  puts "--------- USAGE ---------"
  puts "- create a new mapping:"
  puts "\t newmap $graphfile $retweeterfile $nameformappingfile"
  puts "- load existing mapping"
  puts "\t loadmap $mappingfile"
  puts "- get original ID and Twitter handle of a mapped id"
  puts "\t unmap $id"
  puts "- split graph into snapshots of specific duration"
  puts "\t split $sortedgraphfile $splitfilename $minutes"
  puts "- create _peruser and _total files"
  puts "\t userpairs $sortedgraphfile ($peruserfilename $totalfilename)"
end


# This script measures how much activation happened between pairs of users
# if if only one direction of the communication should be included in PerUser, 
# uncomment the two 'unless'-controls

def user_pairs(originalfile, newfilePerUser, newfileTotal)
  
  # Hash of Arrays to store users communicated with for each user
  communications = Hash.new{|hash, key| hash[key] = Array.new}
  
  File.open(originalfile, 'r') do |of|
    while line = of.gets 
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
            # !!! uncomment this if you don't want each pair twice
            unless thisuser < user
              nfpu.puts "#{user} #{thisuser} #{i}"
            end
            i = 1
            thisuser = u
          end
        end
        # write last encountered user to file
        # !!! uncomment this if you don't want each pair twice
        unless thisuser < user
          nfpu.puts "#{user} #{thisuser} #{i}"
        end
      end
    end
  end
  puts "created files #{newfileTotal} and #{newfilePerUser}"
end
    
  



