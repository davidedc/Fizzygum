# this file is excluded from the fizzygum homepage build

class NonStaticPropertyOfClassSource extends Source

  @fromFileAndMethodName: (fileName, methodName) ->
    new @ window[fileName].class.nonStaticPropertiesSources[methodName]
