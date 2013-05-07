# This rake file performs only some of the
# steps of the build:
#  1) generates an ordered list of the coffee
#     files, so the order respects the
#     dependencies between the files
#  2) for each class file (not all of the
#     coffee files are class files), it
#     adds a special string that contains
#     the source of the file itself.
#     This is so we can allow some editing
#     of the classes in coffeescript, and do
#     something like generating the
#     documentation on the fly.
#  3) finally, combine the "extended" coffee
#     files.
# Note that 2) is a bit naive because we just
# do some simple string checks. So, there
# could be strings in the source code that
# mangle this process. It's not likely
# though.

finalOutputFile = 'build/morphee-coffee.coffee'
 
# The order in which the files are combined does matter.
# There are three cases where order matters:
#   1) if class A extends class B, then B needs
#      to be before class A. This dependency can be
#      figured out automatically (although at the
#      moment in a sort of naive way) by looking at the
#      source code.
#   2) no objects of a class can be instantiated before
#      the definition of the class. This dependency can be
#      figured out automatically (although at the
#      moment in a sort of naive way) by looking at the
#      source code.
#   3) some classes use global functions or global
#      variables. These dependencies must be manually
#      specified by creating a specially formatted comment.

# These two functions search for "requires" comments in the
# files and generate a list of the order in which the files
# should be combined. Basically creates a directed graph
# and creates the list making sure that the dependencies
# are respected.

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

# The main Rake task.
# Invokes the ordering of the coffee files, then
# goes through the ordered list, adds the source code
# to each file and the combine all into one final
# output file.

task :default do
    dependencies = {}
 
    # read in each javascript file, and find dependencies
    FILES = FileList["src/*.coffee"]
 
    FILES.each do |f|
      file = File.new(f, "r+")
      lines = file.readlines
      lines.each do |line|

        # There are three sorts of dependencies
        itRequires = line.match('\sREQUIRES\s*(\w+)')
        extends = line.match('\sextends\s*(\w+)')
        dependencyInInstanceVariableInit = line.match('\s\w+:\s*new\s*(\w+)')
        dependencies[f] = [] if !dependencies.has_key?(f)
 
        if extends or itRequires or dependencyInInstanceVariableInit
          if extends
            dependencies[f] << extends[1]
            print f,' extends ',extends[1],"\n"
          end
          if itRequires
            dependencies[f] << itRequires[1] 
            print f,' requires ',itRequires[1],"\n"
          end
          if dependencyInInstanceVariableInit
            dependencies[f] << dependencyInInstanceVariableInit[1] 
            print f,' has class init in instance variable ',dependencyInInstanceVariableInit[1],"\n"
          end
        end

      end
      file.close
    end
 
    # Generate inclusion order for files to handle dependencies
    # and prints it.
    inclusion_order = generate_inclusion_order(dependencies)
    puts "Order /////////////////"
    inclusion_order.each do |i|
      puts i
    end
 
    File.open(finalOutputFile, 'w') do |output|
      inclusion_order.each do |f|
        output.write(File.read(f))
        lines = File.readlines(f)

        # let's add a newline between coffeescript files
        # otherwise the end of one and the start of the
        # next could end up on the same line.
        output.write("\n")

        # first check whether this file is a class
        # we do that by scanning all the lines looking
        # for a class ... declaration
        fileIsAClass = false
        lines.each do |line|
          # check if this is a class
          if fileIsAClass == false
            fileIsAClass = ((line =~ /class\s+(\w+)/)!=nil)
          end
        end

        # if the file is a class, then we add its
        # source code as a static variable as a
        # string block. If there is a string block in
        # the source, then we need to escape it.
        if fileIsAClass
          output.puts "  @coffeeScriptSourceOfThisClass: '''"
          lines.each do |line|
            line.gsub(/'''/, "\\'\\'\\'")
            output.puts line
          end
          output.puts "  '''"
        end # end of if file is a class
      end # end of scanning through all the files

      # add the morphic version. This is used in the about
      # box.
      time = Time.new
      output.puts "\nmorphicVersion = 'version of "+time.strftime("%Y-%m-%d %H:%M:%S")+"'"

    end # end of writing the huge final .coffee file
end # end of default task
 