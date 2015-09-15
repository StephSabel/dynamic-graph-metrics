#! /usr/bin/env ruby
# Stephanie Embgen
require_relative "dynamic_graph_metrics/version.rb"
require_relative "dynamic_graph_metrics/mapping.rb"
require_relative "dynamic_graph_metrics/util.rb"
require_relative "dynamic_graph_metrics/total_graph_metrics.rb"
require 'yaml'

module DynamicGraphMetrics
  
  @settings = {}
  @mapping = nil
  
  ###############################################
  ######## Query all necessary settings #########
  ###############################################
  
  if File.exists?("settings.yml")
    @settings = YAML::load_file "settings.yml"
    
    #get mapping in case of mapping file
    @mapping = @settings["mapping"] ? Mapping.new(false, @settings["mappingfile"]) : nil
    
  else
    
    puts "Please enter the path to a sorted graph file"
    @settings["sortedgraphfile"] = gets.chomp
    
    puts "Please enter the path to a retweeters file"
    @settings["retweeterfile"] = gets.chomp
    
    puts "Do you want to load an existing mapping? y/n"
    answer = gets.chomp
    
    if answer == "y"
      
      puts "Please enter the path to the mapping file"
      @settings["mappingfile"] = gets.chomp
      @mapping = Mapping.new(false, @settings["mappingfile"])
      @settings["mapping"] = true
      
    elsif answer == "n"
      
      puts "Do you want to create a mapping?"
      answer = gets.chomp
      
      if answer == "y"
        
        puts "Please enter the path to the mapping file you want to create"
        @settings["mappingfile"] = gets.chomp
         
        @mapping = Mapping.new(true,@settings["mappingfile"], @settings["sortedgraphfile"], @settings["retweeterfile"])
        @settings["mapping"] = true
        
        @settings["sortedgraphfile"] = @settings["sortedgraphfile"] + "-mapped"
        @settings["retweeterfile"] = @settings["retweeterfile"] + "-mapped"
        
      elsif answer == "n"
        
        @settings["mapping"] = false
        
      end
    end
      
    puts "Are there existing _peruser and _total files? y/n"
    answer = gets.chomp
    
    if answer == "y"
      
      puts "Please enter the path to the _peruser file"
      @settings["peruserfile"] = gets.chomp
      
      puts "Please enter the path to the _total file"
      @settings["totalfile"] = gets.chomp
      
    elsif answer == "n"
      
      puts "Do you want to create them? y/n"
      answer = gets.chomp
      
      if answer == "y"
        
        puts "Please enter a path to the _peruser file you want to create"
        @settings["peruserfile"] = gets.chomp
        
        puts "Please enter the path to the _total file you want to create"
        @settings["totalfile"] = gets.chomp
        
        user_pairs(@settings["sortedgraphfile"], @settings["peruserfile"], @settings["totalfile"])
        
      end   
    end
    
    puts "Please enter the path to your graphchi installation"
    @settings["graphchi"] = gets.chomp
    
  end
        
        
  #############################
  ######## Query loop #########
  #############################
  
  while true
    puts "What would you like to do?"
    task = gets.chomp
    
    # quit
    if task == "quit"
      File.open("settings.yml", "w") do |file|
        file.write @settings.to_yaml
      end
      exit
  
    # helptext
    elsif task == "help"
      help
      
    # set variables
    elsif task == "set"
      settings[args[1]] = args[2]
    
    # get original id and name  
    elsif task == "unmap"
      quit = false
      puts "Enter IDs to unmap (end with 'quit')"
      until quit
        input = gets.chomp
        input == "quit" ? quit = true : @mapping.unmap(input.to_i)
      end

    # split graph into snapshots of a specific duration
    elsif task == "split"
      puts "Please enter a file name for the split files"
      splitfilename = gets.chomp
      puts "How long should one timeslice be? (in minutes)"
      minutes = gets.chomp
      create_snapshots(@settings["sortedgraphfile"], splitfilename, minutes)
      
    # do something to all files in a folder  
    elsif task == "doall"
      puts "Please enter the path to the folder containing the files"
      folder = gets.chomp
      files = Dir.entries(folder).select { |f| File.file?(folder+'/'+f) }
      
      puts "What do you want to do to the files?"
      action = gets.chomp
      
      #calculate _peruser and _total files from sorted interaction file
      if action == "userpairs"
        pufolder = folder + "_peruser"
        Dir.mkdir(pufolder)
        tfolder = folder + "_total"
        Dir.mkdir(tfolder)
        for file in files
          user_pairs(folder+'/'+file, pufolder+'/'+file+"_peruser", tfolder+'/'+file+"_total")
        end
        
      # calculate degree distribution
      elsif action == "degdist"
        File.open("degreedistributions.csv", 'w') do |rf|
          for file in files
            tgm = TotalGraphMetrics.new(folder+'/'+file)
            rf.print file+';'
            rf.puts tgm.degree_distribution.join(';')
          end
        end
        
      else
        puts "Unknown command"
      end
   
    # anything else is unknown 
    else 
      puts "Unknown command"
      help
    end
  end
end
