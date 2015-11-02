#!/usr/bin/env ruby
# Stephanie Embgen

require "set"
#require_relative "component_timeline.rb"

class Component
  
  def initialize(snapshotID, componentID)
    @snapshotID = snapshotID
    @componentID = componentID
    @users = Set.new
    @edges = 0
    @frontof = Set.new
    @frontmatched = false
  end
  
  def add_user(userID)
    @users.add userID
  end

  def add_edges(edges)
    @edges += edges
  end
  
  def density()
    if @users.size > 1
      return @edges/(@users.size * (@users.size - 1))
    end
  end
  
  def get_set()
    return @users
  end
  
  def get_day()
    return @snapshotID
  end
  
  def add_front(timeline)
    @frontof.add(timeline)
  end
  
  def clear_front()
    @frontof.clear()
  end
  
  def is_front?
    return @frontof.size > 0
  end
  
  def size
    return @users.size
  end
  
  def get_ID
    return @componentID
  end
  
  def matched?
    return @frontmatched
  end
  
  def match
    @frontmatched = true
  end
  
  def get_front_of
    return @frontof
  end
end