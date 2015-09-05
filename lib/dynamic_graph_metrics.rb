#! /usr/bin/env ruby
# Stephanie Embgen
require_relative "dynamic_graph_metrics/version.rb"
require_relative "dynamic_graph_metrics/mapping.rb"
require_relative "dynamic_graph_metrics/util.rb"

module DynamicGraphMetrics
  
  map_instance = nil
  
  while true
    puts "What would you like to do?"
    args = gets.chomp.split(" ")
    
    # quit
    if args[0] == "quit"
      exit
  
    # helptext
    elsif args[0] == "help"
      error(false)
    
    # create new mapping  
    elsif args[0] == "newmap"
      args[1] && args[2] && args[3] ? map_instance = Mapping.new(true, args[3], args[1], args[2]) : error(true)
      puts "mapping created"
    
    # get original id and name  
    elsif args[0] == "unmap"
      if map_instance
        args[1] ? puts("#{map_instance.get_id(args[1].to_i)} #{map_instance.get_name(args[1].to_i)}") :  error(true)
      else
        puts "mapping not initialized. please either"
        puts "   - create new mapping with \'newmap graphfile retweeterfile nameformappingfile\'"
        puts "or"
        puts "   - load existing mapping with \'loadmap mappingfile\'"
      end
    
    # load existing mapping
    elsif args[0] == "loadmap"
      args[1] ? map_instance = Mapping.new(false, args[1]) : error(true)
    
    # split graph into snapshots of a specific duration
    elsif args[0] == "split"
      args[1] && args[2] && args[3] ? create_snapshots(args[1], args[2], args[3]) : error(true)
   
    # anything else is unknown 
    else 
      error(true)
    
    end
  end
end
