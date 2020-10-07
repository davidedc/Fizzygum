class Utils

  @isFunction: (functionToCheck) ->
    typeof(functionToCheck) is "function"

  @isString: (target) ->
    typeof target is "string" or target instanceof String

  @isObject: (target) ->
    target? and (typeof target is "object" or target instanceof Object)
