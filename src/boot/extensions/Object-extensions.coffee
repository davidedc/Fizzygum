# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

## -------------------------------------------------------
# These two methods are for mixins
## -------------------------------------------------------
# adds class properties
# these are added to the constructor
Object::augmentWith = (obj, fromClass) ->
  for key, value of obj when key not in MixedClassKeywords
    @[key] = value
  obj.onceAddedClassProperties?.apply @, [fromClass]
  this

# adds instance properties
# these are added to the prototype
Object::addInstanceProperties = (fromClass, obj) ->
  for own key, value of obj when key not in MixedClassKeywords
    # Assign properties to the prototype
    @::[key] = value

    # this is so we can use "super" in a mixin.
    # we normally can't compile "super" in a mixin because
    # we can't tell which class this will be mixed in in advance,
    # i.e. at compile time it doesn't
    # belong to a class, so at compile time it doesn't know which class
    # it will be injected in.
    # So that's why _at time of injection_ we need
    # to store the class it's injected in in a special
    # variable... and then at runtime we use that variable to
    # implement super
    if fromClass?
      if typeof(value) is "function"
        @::[key + "_class_injected_in"] = fromClass
        if srcLoadCompileDebugWrites then console.log "addingClassToMixin " + key + "_class_injected_in"

  obj.included?.apply @
  this

# This is used a) for testing, we hash the
# data URL of a canvas object so to get a fingerprint
# of the image data, and compare it with "OK" pre-recorded
# values and b) to generate keys for some caches.
# adapted from http://werxltd.com/wp/2010/05/13/javascript-implementation-of-javas-string-hashcode-method/

Object::hashCode = ->
  stringToBeHashed = @toString()
  hash = 0
  return hash  if stringToBeHashed.length is 0
  for i in [0...stringToBeHashed.length]
    char = stringToBeHashed.charCodeAt i
    hash = ((hash << 5) - hash) + char
    hash = hash & hash # Convert to 32bit integer
  hash
