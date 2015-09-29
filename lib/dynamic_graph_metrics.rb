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
        @settings["peruserfile"] = @settings["sortedgraphfile"] + "_peruser"
        @settings["totalfile"] = @settings["sortedgraphfile"] + "_total"
        @settings["mmfile"] = @settings["sortedgraphfile"] + "_mm"
        
        user_pairs(@settings["sortedgraphfile"], @settings["peruserfile"], @settings["totalfile"], @settings["mmfile"])
        
      end   
    end
    
    puts "Please enter the path to your graphchi installation"
    @settings["graphchi"] = gets.chomp.chomp("/")
    
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
      puts "Please enter a folder name for the split files"
      folder = gets.chomp.chomp('/')
      @settings["splitfiles"] = folder
      puts "At what hour (in GMT) should the days be split?"
      time = gets.chomp.to_i
      create_snapshots(@settings["sortedgraphfile"], folder, time)
      
    # calculate degree distribution
    elsif task == "degdist"
      histograms = []
      filetitles = []
      folder = @settings["splitfiles_total"]
      files = Dir.entries(folder).select { |f| File.file?(folder+'/'+f) }
      files.sort!
        
      # calculate all histograms
      for file in files
        tgm = TotalGraphMetrics.new(folder+'/'+file)
        histograms << tgm.degree_distribution
        filetitles << file[-2..-1]
      end
      
      histograms = transpose_arrays(histograms)
        
      File.open("degreedistributions.csv", 'w') do |rf|
        # name the columns
        rf.puts "Degree;Day" + filetitles.join(';Day')
        
        # enter data
        histograms.each_with_index {|data, i| rf.puts "#{i+1};#{data.join(';')}"}
      end
      puts "Wrote degree distribution to degreedistributions.csv"
      
    # calculate connected components  
    elsif task == "concom"
      folder = @settings["splitfiles_peruser"]
      files = Dir.entries(folder).select { |f| File.file?(folder+'/'+f) }
      
      connected_components(@settings["graphchi"],folder, files)
      
    # do something to all files in a folder  
    elsif task == "doall"
      puts "Please enter the path to the folder containing the files"
      folder = gets.chomp.chomp('/')
      files = Dir.entries(folder).select { |f| File.file?(folder+'/'+f) }
      files.sort!
      
      puts "What do you want to do to the files?"
      action = gets.chomp
      
      #calculate _peruser and _total files from sorted interaction file
      if action == "userpairs"
        pufolder = folder + "_peruser"
        @settings["splitfiles_peruser"] = pufolder
        
        Dir.mkdir(pufolder)
        tfolder = folder + "_total"
        @settings["splitfiles_total"] = tfolder
        Dir.mkdir(tfolder)
        mmfolder = folder + "_mm"
        @settings["splitfiles_mm"] = mmfolder
        Dir.mkdir(mmfolder)
        for file in files
          user_pairs(folder+'/'+file, pufolder+'/'+file.insert(-3,"_peruser"), tfolder+'/'+file.gsub!("peruser","total"), mmfolder+'/'+file.gsub!("total","mm"))
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
