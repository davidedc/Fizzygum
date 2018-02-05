# Pencil2IconAppearance //////////////////////////////////////////////////////

class Pencil2IconAppearance extends IconAppearance

  paintFunction: (context) ->
    fillColor = @morph.color

    context.beginPath()
    context.moveTo 130.06, 5.85
    context.lineTo 130.08, 5.84
    context.bezierCurveTo 129.08, 6.22, 128.25, 6.92, 127.7, 7.83
    context.lineTo 42.95, 154.23
    context.lineTo 42.94, 154.24
    context.bezierCurveTo 42.44, 155.11, 42.23, 156.11, 42.33, 157.11
    context.lineTo 45.8, 189.26
    context.lineTo 45.8, 189.24
    context.bezierCurveTo 46.07, 191.86, 48.42, 193.75, 51.04, 193.48
    context.bezierCurveTo 51.54, 193.43, 52.03, 193.3, 52.49, 193.09
    context.lineTo 82.12, 179.94
    context.lineTo 82.11, 179.95
    context.bezierCurveTo 83.01, 179.57, 83.77, 178.92, 84.29, 178.09
    context.lineTo 169.04, 31.69
    context.lineTo 169.06, 31.67
    context.bezierCurveTo 170.37, 29.39, 169.59, 26.48, 167.31, 25.17
    context.bezierCurveTo 167.28, 25.15, 167.26, 25.14, 167.24, 25.13
    context.lineTo 134.23, 6.12
    context.lineTo 134.25, 6.13
    context.bezierCurveTo 132.98, 5.4, 131.44, 5.29, 130.08, 5.84
    context.lineTo 130.06, 5.85
    context.closePath()
    context.moveTo 133.54, 16.77
    context.lineTo 158.31, 31.1
    context.lineTo 152.4, 41.3
    context.lineTo 127.58, 27.07
    context.lineTo 133.54, 16.77
    context.closePath()
    context.moveTo 122.79, 35.35
    context.lineTo 147.55, 49.67
    context.lineTo 76.8, 171.9
    context.lineTo 54.59, 181.76
    context.lineTo 52.03, 157.57
    context.lineTo 122.79, 35.35
    context.closePath()
    context.fillStyle = fillColor.toString()
    context.fill()
