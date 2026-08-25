# The double-chevron mark of a toolbar's overflow button: the "there is more, behind here"
# glyph every tablet and desktop toolbar draws. Two strokes in the shared 200x200 icon
# specification space, kept well inside it so the mark reads as INK INSET IN A TARGET (ruling
# G3) rather than as a glyph filling its box.

class OverflowChevronIconAppearance extends IconAppearance

  paintFunction: (context) ->
    context.strokeStyle = @_iconColorString()
    context.lineWidth = 16
    context.lineCap = 'round'
    context.lineJoin = 'round'

    context.beginPath()
    context.moveTo 58, 50
    context.lineTo 98, 100
    context.lineTo 58, 150
    context.stroke()

    context.beginPath()
    context.moveTo 103, 50
    context.lineTo 143, 100
    context.lineTo 103, 150
    context.stroke()
