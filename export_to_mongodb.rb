# -*- coding: utf-8 -*-
require "rubygems"
require "models"

class NextBus
  attr_reader :agenda

  def initialize(options = {})
    import_agenda(options[:filename])
  end

  def export_to_mongodb
    agenda.collect do |entry|
      name, number = entry.first.gsub(/\((.*)\)$/, ""), $1
      bl = BusLine.new(:name => name, :number => number)
      bl.hours_tables = build_hours_table(entry.last)
      bl.save
      bl
    end
  end

  def build_hours_table(hours_tables)
    hours_tables.collect do |hash|
      ht = HoursTable.create(:name => hash["table_name"])
      ht.bus_times = build_times(hash["agenda"])
      ht.save
      ht
    end
  end

  def build_times(times)
    times.collect do |hour, minutes|
      bt = BusTime.create(:hour => hour, :minutes => minutes)
      bt
    end
  end

  private
  def import_agenda(filename)
    @agenda = clean_attributes(JSON.load(File.read(filename)))
  end

  def clean_attributes(hash_array)
    remove_whitespaces("table_name", hash_array)
    remove_empty_hours(hash_array)
  end

  def remove_whitespaces(attr, hash_array)
    hash_array.each do |entry|
      entry.last.each do |table|
        table[attr] = table[attr].sub("\302\240 ", "")
      end
    end
  end

  def remove_empty_hours(hash_array)
    hash_array.each do |entry|
      entry.last.each do |table|
        table["agenda"] = Hash[table["agenda"].reject { |h, m| m.empty? }]
      end
    end
  end
end

nb = NextBus.new :filename => "agenda.json"
@buslines = nb.export_to_mongodb



