#! /usr/bin/env ruby
# Stephanie Embgen
require "dynamic_graph_metrics/version"
require "dynamic_graph_metrics/mapping"
require "dynamic_graph_metrics/util"

module DynamicGraphMetrics
  
  map_instance = nil
  
  puts "What would you like to do?"
  args = gets.chomp.split(" ")
  
  # helptext
  if args[0] = "help"
    error(false)
    
  # create new mapping  
  elsif args[0] = "newmap"
    args[1] && args[2] && args[3] ? map_instance = Mapping.new(true, args[3], args[1], args[2]) : error(true)
    
  # get original id and name  
  elsif args[0] = "unmap"
    if map_instance
      args[1] ? puts "#{map_instance.getid(args[1])} #{map_instance.getname(args[1])}" :  error(true)
    else
      puts "mapping not initialized. please either"
      puts "   - create new mapping with \'newmap graphfile retweeterfile nameformappingfile\'"
      puts "or"
      puts "   - load existing mapping with \'loadmap mappingfile\'"
    end
    
  # load existing mapping
  elsif args[0] = "loadmap"
    args[1] ? map_instance = Mapping.new(false, args[1]) : error(true)
    
  # split graph into snapshots of a specific duration
  elsif args[0] = "split"
    args[1] && args[2] && args[3] ? create_snapshots(args[1], args[2], args[3]) : error(true)
   
  # anything else is unknown 
  else 
    error(true)
    
  end
  
  def error(admonish)
    if admonish
      puts "--------- ERROR ---------"
      puts "unknown command or missing arguments of arguments"
      puts "/n"
    end
    
    puts "--------- USAGE ---------"
    puts "- create a new mapping:"
    puts "\t \'newmap $graphfile $retweeterfile $nameformappingfile\'"
    puts "- load existing mapping"
    puts "\t \'loadmap $mappingfile\'"
    puts "- get original ID and Twitter handle of a mapped id"
    puts "\t \'unmap $id\'"
    puts "- split graph into snapshots of specific duration"
    puts "\t \'split $sortedgraphfile $splitfilename $minutes"
  end
      
    
    

  
  
end
