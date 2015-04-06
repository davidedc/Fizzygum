###
Copyright 2013 Craig Campbell
coffeescript port by Davide Della Casa

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Mousetrap is a simple keyboard shortcut library for Javascript with
no external dependencies

@version 1.3.1
@url craig.is/killing/mice
###

###
mapping of special keycodes to their corresponding keys

everything in this dictionary cannot use keypress events
so it has to be here to map to the correct keycodes for
keyup/keydown events

@type {Object}
###

_MAP =
  8: "backspace"
  9: "tab"
  13: "enter"
  16: "shift"
  17: "ctrl"
  18: "alt"
  20: "capslock"
  27: "esc"
  32: "space"
  33: "pageup"
  34: "pagedown"
  35: "end"
  36: "home"
  37: "left"
  38: "up"
  39: "right"
  40: "down"
  45: "ins"
  46: "del"
  91: "meta"
  93: "meta"
  224: "meta"

###
mapping for special characters so they can support

this dictionary is only used incase you want to bind a
keyup or keydown event to one of these keys

@type {Object}
###
_KEYCODE_MAP =
  106: "*"
  107: "+"
  109: "-"
  110: "."
  111: "/"
  186: ";"
  187: "="
  188: ","
  189: "-"
  190: "."
  191: "/"
  192: "`"
  219: "["
  220: "\\"
  221: "]"
  222: "'"

###
this is a mapping of keys that require shift on a US keypad
back to the non shift equivelents

this is so you can use keyup events with these keys

note that this will only work reliably on US keyboards

@type {Object}
###
_SHIFT_MAP =
  "~": "`"
  "!": "1"
  "@": "2"
  "#": "3"
  $: "4"
  "%": "5"
  "^": "6"
  "&": "7"
  "*": "8"
  "(": "9"
  ")": "0"
  _: "-"
  "+": "="
  ":": ";"
  "\"": "'"
  "<": ","
  ">": "."
  "?": "/"
  "|": "\\"

###
this is a list of special strings you can use to map
to modifier keys when you specify your keyboard shortcuts

@type {Object}
###
_SPECIAL_ALIASES =
  option: "alt"
  command: "meta"
  return: "enter"
  escape: "esc"

###
variable to store the flipped version of _MAP from above
needed to check if we should use keypress or not when no action
is specified

@type {Object|undefined}
###
_REVERSE_MAP = undefined

###
a list of all the callbacks setup via Mousetrap.bind()

@type {Object}
###
_callbacks = {}

###
direct map of string combinations to callbacks used for trigger()

@type {Object}
###
_directMap = {}

###
keeps track of what level each sequence is at since multiple
sequences can start out with the same sequence

@type {Object}
###
_sequenceLevels = {}

###
variable to store the setTimeout call

@type {null|number}
###
_resetTimer = undefined

###
temporary state where we will ignore the next keyup

@type {boolean|string}
###
_ignoreNextKeyup = false

###
are we currently inside of a sequence?
type of action ("keyup" or "keydown" or "keypress") or false

@type {boolean|string}
###
_sequenceType = false

###
loop through the f keys, f1 to f19 and add them to the map
programmatically
###
i = 1
while i < 20
  _MAP[111 + i] = "f" + i
  ++i

###
loop through to map numbers on the numeric keypad
###
i = 0
while i <= 9
  _MAP[i + 96] = i
  ++i


###
cross browser add event method

@param {Element|HTMLDocument} object
@param {string} type
@param {Function} callback
@returns void
###
_addEvent = (object, type, callback) ->
  if object.addEventListener
    object.addEventListener type, callback, false
    return
  object.attachEvent "on" + type, callback

###
takes the event and returns the key character

@param {Event} e
@return {string}
###
_characterFromEvent = (e) ->
  
  # for keypress events we should return the character as is
  return String.fromCharCode(e.which)  if e.type is "keypress"
  
  # for non keypress events the special maps are needed
  return _MAP[e.which]  if _MAP[e.which]
  return _KEYCODE_MAP[e.which]  if _KEYCODE_MAP[e.which]
  
  # if it is not in the special map
  String.fromCharCode(e.which).toLowerCase()

###
checks if two arrays are equal

@param {Array} modifiers1
@param {Array} modifiers2
@returns {boolean}
###
_modifiersMatch = (modifiers1, modifiers2) ->
  modifiers1.sort().join(",") is modifiers2.sort().join(",")

###
resets all sequence counters except for the ones passed in

@param {Object} doNotReset
@returns void
###
_resetSequences = (doNotReset, maxLevel) ->
  doNotReset = doNotReset or {}
  activeSequences = false
  key = undefined
  for key of _sequenceLevels
    if doNotReset[key] and _sequenceLevels[key] > maxLevel
      activeSequences = true
      continue
    _sequenceLevels[key] = 0
  _sequenceType = false  unless activeSequences

###
finds all callbacks that match based on the keycode, modifiers,
and action

@param {string} character
@param {Array} modifiers
@param {Event|Object} e
@param {boolean=} remove - should we remove any matches
@param {string=} combination
@returns {Array}
###
_getMatches = (character, modifiers, e, remove, combination) ->
  i = undefined
  callback = undefined
  matches = []
  action = e.type
  
  # if there are no events related to this keycode
  return []  unless _callbacks[character]
  
  # if a modifier key is coming up on its own we should allow it
  modifiers = [character]  if action is "keyup" and _isModifier(character)
  
  # loop through all callbacks for the key that was pressed
  # and see if any of them match
  for i in [0..._callbacks[character].length]
    callback = _callbacks[character][i]
    
    # if this is a sequence but it is not at the right level
    # then move onto the next match
    continue  if callback.seq and _sequenceLevels[callback.seq] isnt callback.level
    
    # if the action we are looking for doesn't match the action we got
    # then we should keep going
    continue  unless action is callback.action
    
    # if this is a keypress event and the meta key and control key
    # are not pressed that means that we need to only look at the
    # character, otherwise check the modifiers as well
    #
    # chrome will not fire a keypress if meta or control is down
    # safari will fire a keypress if meta or meta+shift is down
    # firefox will fire a keypress if meta or control is down
    if (action is "keypress" and not e.metaKey and not e.ctrlKey) or _modifiersMatch(modifiers, callback.modifiers)
      
      # remove is used so if you change your mind and call bind a
      # second time with a new function the first one is overwritten
      _callbacks[character].splice i, 1  if remove and callback.combo is combination
      matches.push callback
  matches

###
takes a key event and figures out what the modifiers are

@param {Event} e
@returns {Array}
###
_eventModifiers = (e) ->
  modifiers = []
  modifiers.push "shift"  if e.shiftKey
  modifiers.push "alt"  if e.altKey
  modifiers.push "ctrl"  if e.ctrlKey
  modifiers.push "meta"  if e.metaKey
  modifiers

###
actually calls the callback function

if your callback function returns false this will use the jquery
convention - prevent default and stop propagation on the event

@param {Function} callback
@param {Event} e
@returns void
###
_fireCallback = (callback, e, combo) ->
  
  # if this event should not happen stop here
  return  if Mousetrap.stopCallback(e, e.target or e.srcElement, combo)
  if callback(e, combo) is false
    e.preventDefault()  if e.preventDefault
    e.stopPropagation()  if e.stopPropagation
    e.returnValue = false
    e.cancelBubble = true

###
handles a character key event

@param {string} character
@param {Event} e
@returns void
###
_handleCharacter = (character, e) ->
  callbacks = _getMatches(character, _eventModifiers(e), e)
  i = undefined
  doNotReset = {}
  maxLevel = 0
  processedSequenceCallback = false
  
  # loop through matching callbacks for this key event
  i = 0
  while i < callbacks.length
    
    # fire for all sequence callbacks
    # this is because if for example you have multiple sequences
    # bound such as "g i" and "g t" they both need to fire the
    # callback for matching g cause otherwise you can only ever
    # match the first one
    if callbacks[i].seq
      processedSequenceCallback = true
      
      # as we loop through keep track of the max
      # any sequence at a lower level will be discarded
      maxLevel = Math.max(maxLevel, callbacks[i].level)
      
      # keep a list of which sequences were matches for later
      doNotReset[callbacks[i].seq] = 1
      _fireCallback callbacks[i].callback, e, callbacks[i].combo
      continue
    
    # if there were no sequence matches but we are still here
    # that means this is a regular match so we should fire that
    _fireCallback callbacks[i].callback, e, callbacks[i].combo  if not processedSequenceCallback and not _sequenceType
    ++i
  
  # if you are inside of a sequence and the key you are pressing
  # is not a modifier key then we should reset all sequences
  # that were not matched by this key event
  _resetSequences doNotReset, maxLevel  if e.type is _sequenceType and not _isModifier(character)

###
handles a keydown event

@param {Event} e
@returns void
###
_handleKey = (e) ->
  
  # normalize e.which for key events
  # @see http://stackoverflow.com/questions/4285627/javascript-keycode-vs-charcode-utter-confusion
  e.which = e.keyCode  if typeof e.which isnt "number"
  character = _characterFromEvent(e)
  
  # no character found then stop
  return  unless character
  if e.type is "keyup" and _ignoreNextKeyup is character
    _ignoreNextKeyup = false
    return
  _handleCharacter character, e

###
determines if the keycode specified is a modifier key or not

@param {string} key
@returns {boolean}
###
_isModifier = (key) ->
  key is "shift" or key is "ctrl" or key is "alt" or key is "meta"

###
called to set a 1 second timeout on the specified sequence

this is so after each key press in the sequence you have 1 second
to press the next key before you have to start over

@returns void
###
_resetSequenceTimer = ->
  clearTimeout _resetTimer
  _resetTimer = setTimeout(_resetSequences, 1000)

###
reverses the map lookup so that we can look for specific keys
to see what can and can't use keypress

@return {Object}
###
_getReverseMap = ->
  unless _REVERSE_MAP
    _REVERSE_MAP = {}
    for key of _MAP
      
      # pull out the numeric keypad from here cause keypress should
      # be able to detect the keys from the character
      continue  if key > 95 and key < 112
      _REVERSE_MAP[_MAP[key]] = key  if _MAP.hasOwnProperty(key)
  _REVERSE_MAP

###
picks the best action based on the key combination

@param {string} key - character for key
@param {Array} modifiers
@param {string=} action passed in
###
_pickBestAction = (key, modifiers, action) ->
  
  # if no action was picked in we should try to pick the one
  # that we think would work best for this key
  action = (if _getReverseMap()[key] then "keydown" else "keypress")  unless action
  
  # modifier keys don't work as expected with keypress,
  # switch to keydown
  action = "keydown"  if action is "keypress" and modifiers.length
  action

###
binds a key sequence to an event

@param {string} combo - combo specified in bind call
@param {Array} keys
@param {Function} callback
@param {string=} action
@returns void
###
_bindSequence = (combo, keys, callback, action) ->
  
  # start off by adding a sequence level record for this combination
  # and setting the level to 0
  _sequenceLevels[combo] = 0
  
  # if there is no action pick the best one for the first key
  # in the sequence
  action = _pickBestAction(keys[0], [])  unless action
  
  ###
  callback to increase the sequence level for this sequence and reset
  all other sequences that were active
  
  @param {Event} e
  @returns void
  ###
  _increaseSequence = ->
    _sequenceType = action
    ++_sequenceLevels[combo]
    _resetSequenceTimer()

  
  ###
  wraps the specified callback inside of another function in order
  to reset all sequence counters as soon as this sequence is done
  
  @param {Event} e
  @returns void
  ###
  _callbackAndReset = (e) ->
    _fireCallback callback, e, combo
    
    # we should ignore the next key up if the action is key down
    # or keypress.  this is so if you finish a sequence and
    # release the key the final key will not trigger a keyup
    _ignoreNextKeyup = _characterFromEvent(e)  if action isnt "keyup"
    
    # weird race condition if a sequence ends with the key
    # another sequence begins with
    setTimeout _resetSequences, 10

  i = undefined
  
  # loop through keys one at a time and bind the appropriate callback
  # function.  for any key leading up to the final one it should
  # increase the sequence. after the final, it should reset all sequences
  i = 0
  while i < keys.length
    _bindSingle keys[i], (if i < keys.length - 1 then _increaseSequence else _callbackAndReset), action, combo, i
    ++i

###
binds a single keyboard combination

@param {string} combination
@param {Function} callback
@param {string=} action
@param {string=} sequenceName - name of sequence if part of sequence
@param {number=} level - what part of the sequence the command is
@returns void
###
_bindSingle = (combination, callback, action, sequenceName, level) ->
  
  # store a direct mapped reference for use with Mousetrap.trigger
  _directMap[combination + ":" + action] = callback
  
  # make sure multiple spaces in a row become a single space
  combination = combination.replace(/\s+/g, " ")
  sequence = combination.split(" ")
  i = undefined
  key = undefined
  keys = undefined
  modifiers = []
  
  # if this pattern is a sequence of keys then run through this method
  # to reprocess each pattern one key at a time
  if sequence.length > 1
    _bindSequence combination, sequence, callback, action
    return
  
  # take the keys from this pattern and figure out what the actual
  # pattern is all about
  keys = (if combination is "+" then ["+"] else combination.split("+"))
  i = 0
  while i < keys.length
    key = keys[i]
    
    # normalize key names
    key = _SPECIAL_ALIASES[key]  if _SPECIAL_ALIASES[key]
    
    # if this is not a keypress event then we should
    # be smart about using shift keys
    # this will only work for US keyboards however
    if action and action isnt "keypress" and _SHIFT_MAP[key]
      key = _SHIFT_MAP[key]
      modifiers.push "shift"
    
    # if this key is a modifier then add it to the list of modifiers
    modifiers.push key  if _isModifier(key)
    ++i
  
  # depending on what the key combination is
  # we will try to pick the best event for it
  action = _pickBestAction(key, modifiers, action)
  
  # make sure to initialize array if this is the first time
  # a callback is added for this key
  _callbacks[key] = []  unless _callbacks[key]
  
  # remove an existing match if there is one
  _getMatches key, modifiers,
    type: action
  , not sequenceName, combination
  
  # add this call back to the array
  # if it is a sequence put it at the beginning
  # if not put it at the end
  #
  # this is important because the way these are processed expects
  # the sequence ones to come first
  _callbacks[key][(if sequenceName then "unshift" else "push")]
    callback: callback
    modifiers: modifiers
    action: action
    seq: sequenceName
    level: level
    combo: combination


###
binds multiple combinations to the same callback

@param {Array} combinations
@param {Function} callback
@param {string|undefined} action
@returns void
###
_bindMultiple = (combinations, callback, action) ->
  i = 0

  while i < combinations.length
    _bindSingle combinations[i], callback, action
    ++i


# start!
_addEvent document, "keypress", _handleKey
_addEvent document, "keydown", _handleKey
_addEvent document, "keyup", _handleKey
Mousetrap =
  
  ###
  binds an event to mousetrap
  
  can be a single key, a combination of keys separated with +,
  an array of keys, or a sequence of keys separated by spaces
  
  be sure to list the modifier keys first to make sure that the
  correct key ends up getting bound (the last key in the pattern)
  
  @param {string|Array} keys
  @param {Function} callback
  @param {string=} action - 'keypress', 'keydown', or 'keyup'
  @returns void
  ###
  bind: (keys, callback, action) ->
    keys = (if keys instanceof Array then keys else [keys])
    _bindMultiple keys, callback, action
    this

  
  ###
  unbinds an event to mousetrap
  
  the unbinding sets the callback function of the specified key combo
  to an empty function and deletes the corresponding key in the
  _directMap dict.
  
  TODO: actually remove this from the _callbacks dictionary instead
  of binding an empty function
  
  the keycombo+action has to be exactly the same as
  it was defined in the bind method
  
  @param {string|Array} keys
  @param {string} action
  @returns void
  ###
  unbind: (keys, action) ->
    Mousetrap.bind keys, (->
    ), action

  
  ###
  triggers an event that has already been bound
  
  @param {string} keys
  @param {string=} action
  @returns void
  ###
  trigger: (keys, action) ->
    _directMap[keys + ":" + action] {}, keys  if _directMap[keys + ":" + action]
    this

  
  ###
  resets the library back to its initial state.  this is useful
  if you want to clear out the current keyboard shortcuts and bind
  new ones - for example if you switch to another page
  
  @returns void
  ###
  reset: ->
    _callbacks = {}
    _directMap = {}
    this

  
  ###
  should we stop this event before firing off callbacks
  
  @param {Event} e
  @param {Element} element
  @return {boolean}
  ###
  stopCallback: (e, element) ->
    
    # if the element has the class "mousetrap" then no need to stop
    return false  if (" " + element.className + " ").indexOf(" mousetrap ") > -1
    
    # stop for input, select, and textarea
    element.tagName is "INPUT" or element.tagName is "SELECT" or element.tagName is "TEXTAREA" or (element.contentEditable and element.contentEditable is "true")

window.Mousetrap = Mousetrap
