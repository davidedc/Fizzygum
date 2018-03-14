# this file is excluded from the fizzygum homepage build

class InformationIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    outlineColor = 'rgba(184, 184, 184, 1)'
    #// Group
    #// outline Drawing
    @oval context, 3, 3, 94, 94
    context.fillStyle = outlineColor
    context.fill()
    #// the i letter
    #// i without dot Drawing
    context.beginPath()
    context.moveTo 54.1, 69.32
    context.lineTo 54.1, 38.2
    context.lineTo 41.39, 38.2
    context.lineTo 41.39, 43.4
    context.lineTo 45.9, 43.4
    context.lineTo 45.9, 69.32
    context.lineTo 41.39, 69.32
    context.lineTo 41.39, 74.52
    context.lineTo 58.61, 74.52
    context.lineTo 58.61, 69.32
    context.lineTo 54.1, 69.32
    context.closePath()
    context.fillStyle = black
    context.fill()
    #// i dot Drawing
    @oval context, 45, 23, 9, 10
    context.fillStyle = black
    context.fill()
    #// circle Drawing
    @oval context, 10, 10, 80, 80
    context.strokeStyle = 'rgb(0, 0, 0)'
    context.lineWidth = 6.5
    context.stroke()

