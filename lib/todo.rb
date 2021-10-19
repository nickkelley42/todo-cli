require 'fileutils'

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
    sorter = Sorter.new
    shellsort(items)

    File.open(TODO_FILE, 'w') do |f|
      items.each { |i| f.puts i }
    end
  end

  private_class_method def self.shellsort(array)
    sorter = Sorter.new
    length = array.length
    h = 1
    h = 3 * h + 1 while h < length / 3

    while h >= 1
      (h...length).each do |i|
        j = i
        while j >= h && sorter.compare(array[j], array[j - h]).negative?
          swap(array, j, j - h)
          j -= h
        end
      end

      h /= 3
    end
  end

  private_class_method def self.swap(array, first, second)
    t = array[first]
    array[first] = array[second]
    array[second] = t
  end

  class Sorter
    def initialize
      @hierarchy = {}
    end

    def compare(a, b)
      find_transitive!(a, b)
      return 1 if @hierarchy[a]&.include? b
      return -1 if @hierarchy[b]&.include? a

      result = ask_for_higher(a, b)

      if result.positive?
        insert_hierarchy(a, b)
      else
        insert_hierarchy(b, a)
      end

      result
    end

    private

    def insert_hierarchy(higher, lower)
      @hierarchy[higher] ||= []
      @hierarchy[higher] << lower unless @hierarchy[higher].include? lower
    end

    def ask_for_higher(a, b)
      chosen = false

      until chosen
        puts 'Choose higher priority:'
        puts "\t1. #{a}"
        puts "\t2. #{b}"
        print '> '
        choice = gets.chomp.to_i
        chosen = [1, 2].include? choice
      end

      choice == 1 ? -1 : 1
    end

    def find_transitive!(a, b)
      insert_hierarchy(a, b) if downward_path_exists?(a, b)
      insert_hierarchy(b, a) if downward_path_exists?(b, a)
    end

    def downward_path_exists?(higher, lower)
      return false unless @hierarchy[higher]
      return true if @hierarchy[higher].include?(lower)

      @hierarchy[higher].any? { |i| downward_path_exists?(i, lower) }
    end
  end
end
