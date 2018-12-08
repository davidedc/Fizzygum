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
      if isFunction value
        @::[key + "_class_injected_in"] = fromClass
        if srcLoadCompileDebugWrites then console.log "addingClassToMixin " + key + "_class_injected_in"

  obj.included?.apply @
  this
