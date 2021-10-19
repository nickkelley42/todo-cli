# frozen_string_literal: true

require 'fileutils'

# Stupid simple Todo list manager and sorter
module ToDo
  TODO_FILE = File.expand_path('~/.todo')

  def self.init
    raise "#{TODO_FILE} already exists" if File.exist?(TODO_FILE)

    FileUtils.touch(TODO_FILE)
  end

  def self.list_top(count)
    File.open(TODO_FILE, 'r') do |f|
      count.times { puts f.readline }
    end
  end

  def self.add
    print 'Enter todo: '
    todo = readline

    File.open(TODO_FILE, 'a') do |f|
      f.puts todo
    end
  end

  def self.top
    File.open(TODO_FILE, 'r') { |f| puts f.readline }
  end

  def self.pop
    items = File.readlines(TODO_FILE)

    removed = items.shift
    removed = removed[0...-1] if removed[-1] == "\n"
    puts "Removing: '#{removed}'"

    File.open(TODO_FILE, 'w') do |f|
      items.each { |i| f.puts i }
    end
  end

  def self.sort
    items = File.readlines(TODO_FILE)
    insertion_sort(items)

    File.open(TODO_FILE, 'w') do |f|
      items.each { |i| f.puts i }
    end
  end

  private_class_method def self.insertion_sort(array)
    sorter = Sorter.new
    1.upto(array.length - 1).each do |i|
      # don't bother with bsearch if it's already in the correct position
      next unless sorter.less?(array[i], array[i - 1])

      position = array[0, i].bsearch_index { |val| sorter.less?(array[i], val) }
      move_to_position(array, i, position) if position
    end
  end

  private_class_method def self.move_to_position(array, from, to)
    value = array[from]
    array.slice!(from)
    array.insert(to, value)
  end

  # Used for building up an order of values. Asks the user to give the higher
  # priority item if it cannot figure it out on its own.
  class Sorter
    def initialize
      @hierarchy = {}
    end

    def less?(value_a, value_b)
      compare(value_a, value_b).negative?
    end

    private

    def compare(value_a, value_b)
      find_transitive!(value_a, value_b)
      return 1 if @hierarchy[value_a]&.include? value_b
      return -1 if @hierarchy[value_b]&.include? value_a

      result = ask_for_higher(value_a, value_b)

      if result.positive?
        insert_hierarchy(value_a, value_b)
      else
        insert_hierarchy(value_b, value_a)
      end

      result
    end

    def insert_hierarchy(higher, lower)
      @hierarchy[higher] ||= []
      @hierarchy[higher] << lower unless @hierarchy[higher].include? lower
    end

    def ask_for_higher(value_a, value_b)
      chosen = false

      until chosen
        puts 'Choose higher priority:'
        puts "\t1. #{value_a}"
        puts "\t2. #{value_b}"
        print '> '
        choice = gets.chomp.to_i
        chosen = [1, 2].include? choice
      end

      choice == 1 ? -1 : 1
    end

    def find_transitive!(value_a, value_b)
      insert_hierarchy(value_a, value_b) if downward_path_exists?(value_a, value_b)
      insert_hierarchy(value_b, value_a) if downward_path_exists?(value_b, value_a)
    end

    def downward_path_exists?(higher, lower)
      return false unless @hierarchy[higher]
      return true if @hierarchy[higher].include?(lower)

      @hierarchy[higher].any? { |i| downward_path_exists?(i, lower) }
    end
  end
end
