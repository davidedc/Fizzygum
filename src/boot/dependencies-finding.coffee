# The whole idea here is that
#    a needs b,c,d
#    b needs c
# forms a tree. (a root with b,c,d as children,
# and b's node has C as child)
# You basically find out the correct inclusion order
# by just doing a depth-first visit of that tree
# and collecting the nodes in reverse "coming back" from
# the leafs.
visit = (dependenciesMap, theClass, loadOrder) ->
  if dependenciesMap.has theClass
    for key from dependenciesMap.get theClass
      if loadOrder.has key
        # this needed thing is already in the dependency
        # list (and hence also all the things that needs
        # are in turn already in the list so we can move on
        # to the next needed thing)
        continue
      visit dependenciesMap, key, loadOrder
  # if theClass == "Widget" then debugger
  loadOrder.add theClass

# we still need to go through the classes in the
# correct order. We do that by looking at the sources
# and some hints in the sources.
# "dependenciesMap" here is a Map
extractDependenciesFromDependenciesMap = (dependenciesMap) ->
  # Returns a list of the coffee files. The list is ordered in such a way  that
  # the dependencies between the files are respected.

  # note that "Set" preserves the insertion order
  loadOrder = new Set

  for key from dependenciesMap.keys()
    #value = dependenciesMap[key]
    #console.log value
    # recursively find out what this needed thing needs
    # and add those to the dependency list
    visit dependenciesMap, key, loadOrder
  if srcLoadCompileDebugWrites then console.log "loadOrder: " + loadOrder
  return loadOrder


goodMatch = (theMatch, currentClass) ->
  theMatch? and theMatch[1] != currentClass and theMatch[1] not in ["Set", "Array", "Map"]

extractDependenciesFromSource = ->
  # find out the dependencies looking at each class'
  # source code and hints in it.
  dependenciesMap = new Map

  # currently REQUIRES is unused, it should be a debug or temporary option
  # as we should really pick up all the dependencies automatically from
  # the source code
  REQUIRES = ///\sREQUIRES\s*(\w+)///

  EXTENDS = ///\sextends\s*(\w+)///
  IS_CLASS = ///\s*class\s+(\w+)///
  REQUIRES_MIXIN = ///\s*@augmentWith\s+(\w+)/// 
  TRIPLE_QUOTES = ///'''///
  CONSTRUCTION_IN_CLASS_DECLARATION = ///^\s\s@?[a-zA-Z_$][0-9a-zA-Z_$]*\s*:\s*new\s*([a-zA-Z_$][0-9a-zA-Z_$]*)///
  CLASS_USE_IN_CLASS_DECLARATION = ///^\s\s@?[a-zA-Z_$][0-9a-zA-Z_$]*\s*:\s*([A-Z][0-9a-zA-Z_$]*)///

  allSources = Object.keys(window).filter (eachSourceFile) ->
    eachSourceFile.endsWith "_coffeSource"

  for eachFile in allSources

    eachFile = eachFile.replace "_coffeSource",""
    if eachFile == "Class" then continue
    if eachFile == "Mixin" then continue
    if srcLoadCompileDebugWrites then console.log eachFile + " - "
    fileDependenciesSet = new Set

    lines = window[eachFile + "_coffeSource"].split '\n'
    for eachLine in lines
      #console.log eachLine

      # everything depends on globalFunctions, let's get that out of the way
      fileDependenciesSet.add "globalFunctions"

      matches = eachLine.match EXTENDS
      if goodMatch matches, eachFile
        #console.log matches
        fileDependenciesSet.add matches[1]
        if srcLoadCompileDebugWrites then console.log eachFile + " extends " + matches[1]

      matches = eachLine.match REQUIRES
      if goodMatch matches, eachFile
        #console.log matches
        fileDependenciesSet.add matches[1]
        if srcLoadCompileDebugWrites then console.log eachFile + " requires " + matches[1]

      matches = eachLine.match REQUIRES_MIXIN
      if goodMatch matches, eachFile
        #console.log matches
        fileDependenciesSet.add matches[1]
        if srcLoadCompileDebugWrites then console.log eachFile + " requires the mixin" + matches[1]

      matches = eachLine.match CONSTRUCTION_IN_CLASS_DECLARATION
      if goodMatch matches, eachFile
        #console.log matches
        fileDependenciesSet.add matches[1]
        if srcLoadCompileDebugWrites then console.log eachFile + " has construction in class declaration " + matches[1]

      matches = eachLine.match CLASS_USE_IN_CLASS_DECLARATION
      if goodMatch matches, eachFile
        #console.log matches
        fileDependenciesSet.add matches[1]
        if srcLoadCompileDebugWrites then console.log eachFile + " has class use in class declaration " + matches[1]

      dependenciesMap.set eachFile, fileDependenciesSet

  return dependenciesMap

# In Javascript when you define a bunch of classes/mixins (just define them,
# before even running/instantiating/invoking them in any way) you have to
# define them in _some_ order.
# 
# There are the three rules that apply to us:
#  1. To extend a class A, A must have been defined first.
#  2. if you augment a class with a mixin A, the mixin A must have been
#     defined first.
#  3. if a class defines its fields (static or non-static) values mentioning
#     another class A, then A must have been defined first.
# 
# If you don't follow these rules, the definitions will reference unknown
# needed things (classes, mixins) and there will be an error.
# 
# Once the definitions happen in the right order, all definitions are ready
# and classes/mixins can then reference each other freely at "run" time.
# 
# TODO we should check that we have some sort of error/communication when
# there are circular dependencies or missing parts

findLoadOrder = ->
  dependenciesMap = extractDependenciesFromSource()
  loadOrder = extractDependenciesFromDependenciesMap dependenciesMap
