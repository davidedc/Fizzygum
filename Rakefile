JS_FILE = 'build/morphee-coffee.coffee'
 
def generate_inclusion_order(dependencies)
  inclusion_order = []
  nodes = {}
  files = dependencies.keys
 
  dependencies.each_pair do |file, requires|
    # remove duplicate dependencies
    requires.uniq!
    required_paths = []
    requires.each do |req|
      # convert class names to file paths
      class_file = "/" << req << '.coffee'
      files.each do |f|
        if f.include?(class_file)
          required_paths << f
        end
      end
    end
    nodes[file] = { "requires" => required_paths, "visited" => false }
  end
 
  nodes.each_pair do |file, node|
    visit(file, nodes, inclusion_order)
  end
 
  return inclusion_order
end
 
def visit(file, nodes, inclusion_order)
  if !nodes[file]['visited']
    nodes[file]['visited'] = true
    nodes[file]['requires'].each do |other_file|
      visit(other_file, nodes, inclusion_order)
    end
  end
 
  inclusion_order << file if !inclusion_order.include?(file)
end

task :default do
    dependencies = {}
 
    # read in each javascript file, and find dependencies
    FILES = FileList["src/*.coffee"]
 
    FILES.each do |f|
      file = File.new(f)
      lines = file.readlines
      lines.each do |line|
        # check if this extends anything
        itRequires = line.match('\sREQUIRES\s*(\w+)')
        extends = line.match('\sextends\s*(\w+)')
        dependencies[f] = [] if !dependencies.has_key?(f)
 
        if extends or itRequires
          if extends
          	dependencies[f] << extends[1]
          	print f,' extends ',extends[1],"\n"
          end
          if itRequires
          	dependencies[f] << itRequires[1] 
          	print f,' requires ',itRequires[1],"\n"
          end
        end

      end
    end
 
    # generate inclusion order for files to handle dependencies
    inclusion_order = generate_inclusion_order(dependencies)
    puts "Order /////////////////"
    inclusion_order.each do |i|
      puts i
    end
 
    File.open(JS_FILE, 'w') do |output|
      inclusion_order.each do |f|
        output.write(File.read(f))
      end
    end
  
 
  desc "Merges all Javascript files into a single file keeping the dependencies in mind"
  task :combine do
    # delete any existing file
    File.delete(JS_FILE) if File.exists?(JS_FILE)
    Rake::Task[JS_FILE].invoke
  end
end 
 