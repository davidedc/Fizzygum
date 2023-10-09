# this file is excluded from the fizzygum homepage build

# adapted from http://stackoverflow.com/a/7616484

# Currently used to differentiate the filenames
# for test reference images taken in
# different os/browser config: a hash of the
# configuration is added to the filename.

# TODO if you look for "charCodeAt", you'll find a duplicate.
# This one has more comments and can be versioned for more optimised hashing
# of particular types of data, e.g. boolean arrays etc.
# to see source code for Java's hashCode() method for Arrays see
# https://github.com/openjdk-mirror/jdk7u-jdk/blob/master/src/share/classes/java/util/Arrays.java#L2893

class HashCalculator

  @calculateHash: (theString) ->
      # TODO this should really be called somethind like "stringHash" or
      # "calculateStringHash" as you might want to hash all kinds of
      # things of types that's impossible to practically identify
      # at runtime, e.g. a boolean array vs. int32 array etc.
      #
      # Returns a 32 bit integer hash of the string
      # uses Horner's Method, same used in Java
      # see https://mathcenter.oxford.emory.edu/site/cs171/generatingHashCodes/
      # which suggests how to make hashes of arbitrary data.
      #
      # NOTE 1: Javasctrips uses 64 bit floats, which can safely represent
      # integers up to 2^53 - 1, so we are not making optimal use of "space"
      # here, however we are using the standard Java hash algorithms here
      # which 1) are nice and standard and return Java ints (which are 32 bits) and
      # 2) probably the JS VM can see the truncation we are doing at each step and
      # actually use 32 bit ints internally.
      # Hence, in javascript below, the hash is truncated to 32 bits at
      # each "step" of the calculation.
      #
      # NOTE 2: we give some hints to the JS VM that we are working with
      # 32 bit ints just in case it helps, in the vein of what asm.js did
      # see https://github.com/zbjornson/human-asmjs#1-types .
      #
      # NOTE 3: since the charCodeAt function returns a 16 bit number
      # we could stuff two characters into one 32 bit int for each
      # hash step, however here we keep things simple.
      #
      # NOTE 4: To print the returned 32 bit int as a fixed-length hex string
      # (i.e. with leading zeros so that it's always 8 characters long):
      # 
      # function int32ToPaddedHexString(i) {
      #   const hex = (i + 0x100000000).toString(16);
      #   return hex.substring(1, 9);
      # }
      #
      # NOTE 5: if you wanted to do a hash of an array of booleans
      # you would do the same as below just using the numbers
      # 1231 for true, and 1237 for false (in fact you COULD pack 32 booleans
      # into one 32 bit int for one step of hashing, but that's a bit more complicated
      # and we stick to the simple version used by Java here).
      #
      # i.e. in Javascript:
      #
      # calculateBooleanArrayHash(booleanArray) {
      #   let hash = 0|0;
      #   if (booleanArray.length === 0) return hash|0;
      #
      #   for (let i = 0; i < booleanArray.length; i++) {
      #     // use ternary operator to convert boolean to 1231 for true, and 1237 for false
      #     // this is what Java does
      #     const valueForBoolean = booleanArray[i] ? 1231 : 1237;
      #     hash = ((hash << 5) - hash) + valueForBoolean;
      #     hash |= 0; // Convert to 32bit integer
      #   }
      # 
      #   return hash|0;
      # }

      # first hint to JS VM that we are working with 32 bit int
      # note according to https://github.com/zbjornson/human-asmjs#1-types
      # this is not needed, however I don't think it's going to hurt either
      hash = 0|0
      return hash|0  if theString.length is 0

      for i in [0...theString.length]
        # charCodeAt() returns a number between 0 and 65535 i.e. it's a 16bit integer
        # and let's make that clear to the optimizers just in case they don't know
        chr = (theString.charCodeAt i) & 0xFFFF
        # this one below is equal to hash = hash * 31 + chr,
        # see https://stackoverflow.com/questions/299304/why-does-javas-hashcode-in-string-use-31-as-a-multiplier
        # whay this is done
        hash = ((hash << 5) - hash) + chr
        # Convert to 32bit integer, hopefully the JS VM can see this and
        # actually use 32 bit ints internally.
        # Reason that |= 0 converts to 32bit integer is that bitwise operators implicitly
        # convert their arguments to 32-bit ints before applying the operator. (Other
        # than that, | 0 performs a bitwise OR with 0, which is essentially a no-op).
        hash |= 0
        i++
      # again another hint to optimizers that we are returning a 32 bit int
      return hash|0
