# THE PERSON'S PAINT TOOL for one key, what `new` makes: every member a tool's prototype has is
# DrawingToolBase's, and I declare none of my own beyond the constructor every class's prototype owns,
# so an inspector on a tool lists the tool's own members alone (DrawingToolBase's header says why) and
# its class button reads my name. My CLASS side makes and keeps the tools (of); statics live on the class
# function, which no member list of a tool enumerates.
class DrawingTool extends DrawingToolBase

  # THE PERSON'S TOOL FOR `toolKey`, or undefined for a key naming no tool: one per key per person (the
  # acting person, world.user: what a palette and a paint surface ask), kept on the person
  # (User.drawingTools) and made from what the key means now -- the person's edit of it, else its stock
  # members (PaintToolbarWdgt.stockToolMembers) -- the first time it is asked, and again whenever that
  # meaning is another record than the one it was made from or last wrote (a world load replaced the
  # person's table: User.replaceDrawingToolOverrides). The same object every time, so an inspector open
  # on it goes on editing the person's tool. Compared by identity, so an ask costs a lookup and a compare.
  @of: (toolKey) ->
    stock = PaintToolbarWdgt.stockToolMembers toolKey
    return undefined unless stock?
    person = world.user
    meaning = person.drawingToolOverrideFor(toolKey) ? stock
    person.drawingTools ?= {}
    tool = person.drawingTools[toolKey]  if Object::hasOwnProperty.call person.drawingTools, toolKey
    tool ?= person.drawingTools[toolKey] = new DrawingTool toolKey
    tool._takeMembersFrom meaning  unless tool._madeFrom is meaning
    tool
