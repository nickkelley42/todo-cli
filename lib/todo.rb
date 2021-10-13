require 'fileutils'
module ToDo
  module_function

  TODO_FILE = File.expand_path('~/.todo')

  def init
    raise "#{TODO_FILE} already exists" if File.exist?(TODO_FILE)

    FileUtils.touch(TODO_FILE)
  end

  def list_top(count)
    File.open(TODO_FILE, 'r') do |f|
      count.times { puts f.readline }
    end
  end

  def push
    print 'Enter todo: '
    todo = readline

    File.open(TODO_FILE, 'a') do |f|
      f.puts todo
    end
  end

  def sort
    items = File.readlines(TODO_FILE)
    items.sort! { |a, b| compare_todo(a, b) }

    File.open(TODO_FILE, 'w') do |f|
      items.each { |i| f.puts i }
    end
  end

  def top
    File.open(TODO_FILE, 'r') { |f| puts f.readline }
  end

  def compare_todo(a, b)
    @compare_memo ||= {}
    comparison = [a, b].sort
    @compare_memo[comparison] ||= begin
      chosen = false

      until chosen
        puts 'Choose higher priority:'
        puts "\t1. #{a}"
        puts "\t2. #{b}"
        print '> '
        choice = gets.chomp.to_i
        chosen = [1, 2].include? choice
      end

      chosen == 1 ? 1 : -1
    end
  end
end
