#!/usr/bin/env ruby
# Stephanie Embgen

require "set"
#require_relative "component.rb"

class ComponentTimeline
  
  def initialize(component)
    @timeline = [component] 
    $lastTimelineID += 1
    @timelineID = $lastTimelineID
  end
  
  def pop!
    @timeline.pop
  end
  
  def get_front()
    return @timeline[-1]
  end
  
  def add(component)
    @timeline << component
  end
  
  def get_lifetime()
    return @timeline[-1].get_day() - @timeline[0].get_day() + 1
  end
  
  def get_days()
    return @timeline.size
  end
  
  def new_ID()
    $lastTimelineID += 1
    @timelineID = $lastTimelineID
  end
  

end