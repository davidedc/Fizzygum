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
#
# This is the single implementation of the string hash: HashCalculator.calculateHash
# delegates here (it used to be a byte-identical copy of the loop below).
# TODO you can optimise for particular types of data, e.g. canvas image data, boolean arrays etc.
# ...see how Java does it for arrays at
# https://github.com/openjdk-mirror/jdk7u-jdk/blob/master/src/share/classes/java/util/Arrays.java#L2893

# Memoized by STRING VALUE (the hash is a pure function of @toString(), so caching
# by that string is always correct regardless of receiver — no invalidation needed).
# Why: StringWdgt/TextWdgt rebuild their back-buffer cache keys on EVERY paint by
# re-hashing the full label / wrapped-paragraph string, so the same short strings are
# hashed every frame (O2, docs/runtime-performance-optimization-plan.md §5B; measured
# 1.5–5.4% of a busy-desktop frame). Byte-identical — identical hash values, just not
# recomputed. Only SHORT strings are cached (the repeated cache-key texts): large blobs
# like canvas data-URLs (hashed once for a screenshot fingerprint, not per frame — see
# the note above) are skipped so the cache can't bloat, with a size-cap backstop.
do ->
  stringHashCache = new Map()
  MAX_CACHED_HASHES = 16384
  CACHEABLE_MAX_LEN = 2048
  Object::hashCode = ->
    stringToBeHashed = @toString()
    len = stringToBeHashed.length
    return 0|0  if len is 0
    cacheable = len <= CACHEABLE_MAX_LEN
    if cacheable
      cachedHash = stringHashCache.get stringToBeHashed
      return cachedHash if cachedHash?
    hash = 0|0
    for i in [0...len]
      char = stringToBeHashed.charCodeAt i
      hash = ((hash << 5) - hash) + char
      hash |= 0 # Convert to 32bit integer
    hash = hash|0
    if cacheable
      stringHashCache.clear()  if stringHashCache.size >= MAX_CACHED_HASHES
      stringHashCache.set stringToBeHashed, hash
    hash
