#!/usr/bin/env ruby
# Stephanie Embgen

# The original Twitter user IDs are too big for GraphChi to use as identifiers. 
# This script maps IDs from an interaction file to smaller numbers and creates a record of the mapping


Class Mapping
  
  idmap = {}
  namemap = {}

  def initialize(newmapping?, mappingfile, graphfile = nil, retweeterfile = nil)
    if newmapping?
      if (graphfile && retweeterfile)
        map_graph(graphfile, graphfile+"-mapped", retweeterfile, retweeterfile+"-mapped", mappingfile)
      else
        puts "graphfile and retweeterfile needed for new mapping"
      end
    else
      read_mapping(mappingfile)
    end
  end
  
  # read a mapping from a mapping file and create hashes
  def read_mapping(mappingfile)
    File.open(mappingfile, 'r') do |mf|
      while line = gf.gets
        newid = line.split(' ')[0].to_i
        name = line.split(' ')[1]
        oldid = line.split(' ')[2].to_i
        
        idmap[newid] = oldid
        namemap[newid] = name
      end
    end
  end

  # create a new mapping from a graph file and a retweeter file
  def map_graph(graphfile, mappedgraphfile, retweeterfile, mappedretweeterfile, mappingfile)
  
    # start new ids from 0
    i = 0
    # hash for reverse id'ing
    reverseidmap = {}
  
    # read from one file, create mapping and write to the other
    File.open(graphfile, 'r') do |gf|
      File.open(mappedfile, 'w') do |mgf|
        while line = gf.gets
          user1 = line.split(' ')[0].to_i
          user2 = line.split(' ')[1].to_i
          rest = line.split(' ')[2]
        
          unless reverseidmap[user1] 
            reverseidmap[user1] = i
            i += 1
          end
          unless reverseidmap[user2]
            reverseidmap[user2] = i
            i += 1
          end
        
          mgf.puts("#{idmap[user1]} #{idmap[user2]} #{rest}")
        end
      end
    end
  
    # read retweeters and map to a new file
    File.open(retweeterfile, 'r') do |rf|
      File.open(mappedretweeterfile, 'w') do |mrf|
        while line = rf.gets
          user = line.split(';')[1].to_i
          name = line.split(';')[0]
          rest = line.slice(line.index(';', line.index(';') + 1)..-1)
        
          namemap[reverseidmap[user]] = name
        
          mrf.puts("#{name};#{idmap[user]};rest")
  
    #save the mapping to a new file
    File.open(mappingfile, 'w') do |mf|
      reverseidmap.each do |oldid, newid|
        idmap[newid] = oldid
        idf.puts("#{newid} #{namemap[newid]} #{oldid}")
      end
    end
  end
  
  def get_id(newid)
    idmap[newid]
  end
  
  def get_name(newid)
    namemap[newid]
  end
  
end


