#!/usr/bin/env ruby
# Stephanie Embgen

# Collection of useful functions


# Split a graph into snapshots of a specific duration
def create_snapshots(sortedgraphfile, splitfilename, minutes)
  timestepsize = minutes * 60000
  lasttimesteptime = 0
  filenumber = 0
  splitfile = File.new
  
  File.open(sortedgraphfile, 'r') do |gf|
    while line = gf.gets
      
      timestamp = line.split(" ")[2].to_i
      
      if timestamp - lasttimesteptime >= timestepsize
        lasttimesteptime = timestamp
        splitfile.close
        splitfile = open(splitfilename + filenumber.to_s)
        filenumber += 1
      end
      
      splitfile.write(line)
      splitfile.write("\n")
    end
  end
  splitfile.close
end


