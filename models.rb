require "mongoid_config"
require "json"
require "pp"

class BusLine
  include Mongoid::Document

  field :name
  field :number

  embeds_many :hours_tables, :as => :array, :default => []
end

class HoursTable
  include Mongoid::Document

  field :name

  embeds_many :bus_times, :as => :array, :default => []
end

class BusTime
  include Mongoid::Document

  field :hour
  field :minutes, :type => Array, :default => []
end
