#!/usr/bin/env ruby
# Stephanie Embgen

# Collection of useful functions

require "set"
require_relative "component.rb"
require_relative "component_timeline.rb"


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
def do_graphchi(graphchi_f, folder, file)
  graphchi_call = "#{graphchi_f} file #{folder}/#{file} filetype edgelist"
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
  
# compare all communities/connected components of two days that have at least n users
# outputs list of community/concom pairs with jaccard coefficient > x
def compare_components(files, folder, n = 3, x = 0.3)
  
  days = []
  fronts = Set.new
  timelines = Set.new
  births = 0
  splitevents = 0
  mergeevents = 0
  timelog = Time.now
  
  # read all files
  files.each_with_index do |file, i|
    puts "Reading Day #{i}"
    File.open(folder+'/'+file, 'r') do |df|
      
      # read all communities from file
      daycommunities = Hash.new{|hash, key| hash[key] = Component.new(i, key)}
      while line = df.gets
        
        #add user to matching component
        daycommunities[line.split(" ")[1]].add_user(line.split(" ")[0].to_i)
        
      end
      
      daycommunities.delete_if {|key, value| value.size < n}
      days << daycommunities
      
      puts "reading files: #{Time.now - timelog} seconds"
      timelog = Time.now
      
      # set up data structures to store matched fronts and next generation of fronts
      matches = Hash.new{|hash,key| hash[key] = Array.new}
      newfronts = Set.new
      
      # iterate through set offronts to find matches
      fronts.each do |frontcom|
        matchfound = false
        
        # iterate through new communities and compare them with fronts
        days[i].each_value do |newcom|
          
          # get jaccard factor
          inter = frontcom.get_set().size < newcom.get_set().size ? frontcom.get_set() & newcom.get_set() : newcom.get_set() & frontcom.get_set()
          jaccard = inter.size.to_f / (frontcom.get_set().size + newcom.get_set().size - inter.size)
          
          if jaccard >= x
            # if there has been a match already, we have a split event
            splitevents += 1 if matchfound
            
            # add to matches 
            matches[newcom.get_ID] << frontcom
            matchfound = true
          end
        end
        
        # front survives if no match has been found
        newfronts.add(frontcom) unless matchfound
      end
      
      puts "matching: #{Time.now - timelog} seconds"
      puts "number of fronts: #{fronts.size}"
      timelog = Time.now
      
      # iterate through new communities to add them to timelines
      days[i].each_value do |newcom|
        
        # get matched fronts
        frontmatches = matches[newcom.get_ID]
        # if more than 1 match, we have a merge event
        mergeevents += 1 if frontmatches.size > 1
        
        #  if match found: extend timeline, add to fronts
          if frontmatches.size >= 1
            
            # iterate through matched fronts
            frontmatches.each do |frontcom|
              
              # if it has already been matched, we need to create a duplicate
              if frontcom.matched?
                
                # iterate through all timelines this front belongs to
                frontcom.get_front_of.each do |timeline|
                  
                  newtimeline = timeline.dup
                  newtimeline.new_ID()
                  newtimeline.pop!
                  timelines.add(newtimeline.add(newcom))
                  newcom.add_front(newtimeline)
                  
                end
              else
                
                # iterate through all timelines this front belongs to
                frontcom.get_front_of.each do |timeline|
                  
                  #puts timeline.inspect
                  #puts timeline.instance_of?(ComponentTimeline)
                  newcom.add_front(timeline)
                  timeline.add(newcom)
                  
                  # indicate that match has been found
                  frontcom.match
                end
              end
            end
      
        # if no match found: create new timeline
          else
            newtimeline = ComponentTimeline.new(newcom)
            timelines.add(newtimeline)
            newcom.add_front(newtimeline)
            births += 1
          end
          
        newfronts.add(newcom)
      end
      
      fronts = newfronts
      
      puts "updating timelines: #{Time.now - timelog} seconds"
      puts "number of timelines: #{timelines.size}"
      timelog = Time.now


    end
  end
  puts "Births: #{births}"
  puts "Split Events: #{splitevents}"
  puts "Merge Events: #{mergeevents}"
  puts "Timelines: #{timelines.size}"
end

  
