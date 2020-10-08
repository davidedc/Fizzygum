class Utils

  @isFunction: (toBeChecked) ->
    typeof toBeChecked is "function"

  @isString: (toBeChecked) ->
    typeof toBeChecked is "string" or toBeChecked instanceof String

  @isObject: (toBeChecked) ->
    toBeChecked? and (typeof toBeChecked is "object" or toBeChecked instanceof Object)
