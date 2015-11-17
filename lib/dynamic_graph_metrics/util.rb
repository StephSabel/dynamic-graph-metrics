#!/usr/bin/env ruby
# Stephanie Embgen

# Collection of useful functions

require "set"
require_relative "component.rb"
require_relative "component_timeline.rb"


# Split a graph into snapshots of a specific duration

def create_snapshots(sortedgraphfile, splitfilefolder, hour = 4, days = 1)
  filenumber = 0
  timeoffset = hour * 3600
  dayseconds = 60*60*24*days
  nexttimestamp = Time.at(timeoffset + 1)
  splitfilename = splitfilefolder + '/' + sortedgraphfile.split('/')[-1] + "_split"
  splitfile = open(splitfilename + '00', 'w')
  
  File.open(sortedgraphfile, 'r') do |gf|
    while line = gf.gets
      
      timestamp = Time.at(line.split(" ")[2].to_i / 1000)
      
      unless timestamp < nexttimestamp
        unless filenumber == 0
          splitfile.close
          splitfile = open(splitfilename + (filenumber < 10 ? '0' : '') + filenumber.to_s, 'w')
        end
        filenumber += 1
        dayspassed = (timestamp - nexttimestamp)/dayseconds + days
        nexttimestamp += dayspassed.to_i*dayseconds
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


# cleanup community/component files: remove all files that are in a community of size 1
def cleanup(file)
  coms = Hash.new{|hash, key| hash[key] = Array.new}
  File.open(file, "r") do |f|
    while line = f.gets
      user = line.split(" ")[0].to_i
      com = line.split(" ")[1].to_i
      coms[com] << user
    end
  end 
  coms.delete_if {|key, value| value.size <= 1}
  File.open(file, "w") do |f|
    coms.each do |com, users|
      users.each do |user|
        f.puts "#{user} #{com}"
      end
    end
  end
end
  
# compare all communities/connected components of two days that have at least n users
# outputs list of community/concom pairs with jaccard coefficient > x
def compare_components(files, folder, n = 5, x = 0.3)
  
  days = []
  fronts = Set.new
  timelines = Set.new
  births = 0
  deaths = 0
  splitevents = 0
  mergeevents = 0
  timestart = Time.now
  #communitymetrics = Hash.new{|hash, key| hash[key] = Array.new}
  
  version = "2.0"
  deathoffset = 5
  
  #metrics
  times = []
  communitynumbers = []
  usersnapshots = []
  userdays = []
  
  timelog = Time.now
  
  # read all files
  files.each_with_index do |file, i|
    puts "\n----------- Day #{i} -----------"
    dayusers = {}
    File.open(folder+'/'+file, 'r') do |df|
      
      # read all communities from file
      daycommunities = Hash.new{|hash, key| hash[key] = Component.new(i, key)}
      while line = df.gets
        user = line.split(" ")[0].to_i
        com = line.split(" ")[1].to_i
        
        # add user to matching component
        daycommunities[com].add_user(user)
        dayusers[user] = com
        
        # save metrics 
        usersnapshots[user] = usersnapshots[user] || [] 
        usersnapshots[user] << i
      end
      
      puts "reading files: #{(Time.now - timelog).round} seconds"
      timelog = Time.now
      # daycommunities.each_value {|comp| communitymetrics["#{i}_#{comp.get_ID}"] = [comp.size, 0]}
      
      # read _per_user-files to get edges within communities
      pufile = "#{folder.chomp("/communities")}/#{file.chomp(".communities")}"
      File.open(pufile, 'r') do |puf|
        while line = puf.gets
          user1 = line.split(" ")[0].to_i
          user2 = line.split(" ")[1].to_i
          edges = line.split(" ")[2].to_i
          if dayusers[user1] == dayusers[user2]
            daycommunities[dayusers[user1]].add_edges(edges)
          end
        end
      end
      
      daycommunities.delete_if {|key, value| value.size < n}
      puts "after culling: #{daycommunities.size} communities"
      days << daycommunities
      communitynumbers << daycommunities.size
      userdays << dayusers
      
      puts "reading edges: #{(Time.now - timelog).round} seconds"
      timelog = Time.now
      
      
      
      # set up data structures to store matched fronts and next generation of fronts
      matches = Hash.new{|hash,key| hash[key] = Array.new}
      newfronts = Set.new
      
      # iterate through set of fronts to find matches
      fronts.each do |frontcom|
        matchfound = false
        
        
        # iterate through new communities and compare them with fronts
        days[i].each_value do |newcom|
          
          # get jaccard factor
          
          ###### version 1: just intersect
          # inter = frontcom.get_set() & newcom.get_set()
          
          ###### version 2: put smaller set in front
          # inter = frontcom.get_set().size < newcom.get_set().size ? frontcom.get_set() & newcom.get_set() : newcom.get_set() & frontcom.get_set()
          
          ###### version 3: only intersect if sizes are compatible
          set1 = frontcom.get_set().size < newcom.get_set().size ? frontcom.get_set() : newcom.get_set()
          set2 = frontcom.get_set().size < newcom.get_set().size ? newcom.get_set() : frontcom.get_set()
          
          if set1.size.to_f/set2.size.to_f > x
            inter = set1 & set2
          else 
            inter = Set.new
          end
          
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
      
      puts "number of fronts: #{fronts.size}"
      puts "matching: #{(Time.now - timelog).round} seconds"
      puts "time per front: #{((Time.now - timelog)/fronts.size).round(3)}" unless fronts.size == 0
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
                  newtimeline.add(newcom)
                  timelines.add(newtimeline)
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
      newfronts.select {|front| front.get_day() >= i - deathoffset}
      fronts = newfronts
      
      puts "number of timelines: #{timelines.size}"
      timeused = Time.now - timestart
      timestart = Time.now
      times << timeused.to_i
      puts "#{timeused.round(0)} seconds / #{(timeused/60).round(1)} minutes"


    end
  end
  
  Dir.mkdir("#{folder}/metrics") unless File.exists?("#{folder}/metrics")
  
  # get size, lifetime and density distribution
  sizes_avg = Hash.new(0)
  lifetimes = Hash.new(0)
  densities = Hash.new(0)
  timelinemetrics = Hash.new()
  timelines.each do |tl| 
    sld = [tl.get_size_avg, tl.get_lifetime, tl.get_den_avg]
    timelinemetrics[tl.get_ID] = sld
    sizes_avg[sld[0].round(0)] += 1
    lifetimes[sld[1]] += 1
    densities[sld[2].round(5)] += 1
  end
  
  File.open("#{folder}/metrics/sizedistribution_#{version}_#{n}_#{x}_#{deathoffset}.csv", 'w') do |sdf|
    sizes_avg.keys.sort
    sizes_avg.each do |key, value|
      sdf.puts "#{key};#{value}"
    end
  end
  
  File.open("#{folder}/metrics/lifetimedistribution_#{version}_#{n}_#{x}_#{deathoffset}.csv", 'w') do |ldf|
    lifetimes.keys.sort
    lifetimes.each do |key, value|
      ldf.puts "#{key};#{value}"
    end
  end
  
  File.open("#{folder}/metrics/densitydistribution_#{version}_#{n}_#{x}_#{deathoffset}.csv", 'w') do |ddf|
    densities.keys.sort
    densities.each do |key, value|
      ddf.puts "#{key};#{value}"
    end
  end
  
  File.open("#{folder}/metrics/timelinemetrics_#{version}_#{n}_#{x}_#{deathoffset}.csv", "w") do |tmf|
    tmf.puts "TimelineID;Average Size;Lifetime;Average Density"
    timelinemetrics.each do |key, value|
      tmf.puts "#{key};#{value[0]};#{value[1]};#{value[2]}"
    end
  end
  
  File.open("#{folder}/metrics/usersnapshots_#{version}_#{n}_#{x}_#{deathoffset}.csv", "w") do |usf|
    usf.puts "UserID;Active in snapshots;Time from first to last snapshot, number of timelines"
    usersnapshots.each_with_index do |snapshots, user|
      communities = 0
      timelines = Set.new
      if snapshots
        snapshots.reverse_each do |i|
          thistl = days[i][userdays[i][user]].get_front_of
          unless thistl < timelines
            communities += 1
            timelines += thistl
          end
        end
        
        usf.puts "#{user};#{snapshots.size};#{snapshots[-1] - snapshots[0] + 1};#{communities}"
      end
    end
  end
  
  File.open("#{folder}/metrics/metrics_#{version}_#{n}_#{x}_#{deathoffset}", "w") do |mf|
    mf.puts "Minimum community size: #{n}"
    mf.puts "Minimum jaccard coefficient: #{x}"
    mf.puts "Maximum survival without matches: #{deathoffset} days"
    mf.puts "Algorithm Version: #{version}"
    mf.puts "Number of snapshots: #{days.size}"
    mf.puts "Births: #{births}"
    mf.puts "Deaths: #{deaths}"
    mf.puts "Split Events: #{splitevents}"
    mf.puts "Merge Events: #{mergeevents}"
    mf.puts "Timelines: #{timelines.size}"
    
    timesum = 0
    times.each{|time| timesum += time}
    
    mf.puts "Runtime: #{timesum/3600} hours, #{(timesum%3600)/60} minutes, #{timesum%60} seconds"
    mf.puts "\n Runtime per snapshot"
    mf.puts "snapshotID;runtime, no of communities"
    
    times.each_with_index{|time, i| mf.puts "#{i};#{time.round()};#{communitynumbers[i]}"}

  end
  
  puts "Births: #{births}"
  puts "Deaths: #{deaths}"
  puts "Split Events: #{splitevents}"
  puts "Merge Events: #{mergeevents}"
  puts "Timelines: #{timelines.size}"
end
