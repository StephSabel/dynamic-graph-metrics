#!/usr/bin/env ruby
# Stephanie Embgen

# This class reads a graph from a _peruser file and calculates some basic metrics

class TotalGraphMetrics
  
  def initialize(totalfile)
    @interactions = {}
    @highestdegree = 0
    @edgenumber = 0
    @usernumber = 0
    
    File.open(totalfile, 'r') do |f|
      while line = f.gets
        user = line.split(' ')[0].to_i
        edges = line.split(' ')[1].to_i
        
        @interactions[user] = edges
        @edgenumber += edges
        @usernumber += 1
        
        @highestdegree = edges > @highestdegree ? edges : @highestdegree
      end
    end
  end
  
  # calculate graph density
  def density
    @edgenumber / (@usernumber * (@usernumber - 1))
  end
  
  # histogram over the node degrees
  def degree_distribution
    histogram = Array.new(@highestdegree + 1, 0)
    @interactions.each_value {|value| histogram[value] += 1}
    return histogram
  end
end
      
    