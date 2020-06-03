# this file is excluded from the fizzygum homepage build

# adapted from http://stackoverflow.com/a/7616484

# Currently used to differentiate the filenames
# for test reference images taken in
# different os/browser config: a hash of the
# configuration is added to the filename.

class HashCalculator

  @calculateHash: (theString) ->
      hash = 0
      return hash  if theString.length is 0

      for i in [0...theString.length]
        chr = theString.charCodeAt i
        hash = ((hash << 5) - hash) + chr
        hash |= 0 # Convert to 32bit integer
        i++
      return hash
