# How to play a test:
# from the Chrome console (Option-Command-J) OR Safari console (Option-Command-C):
# window.world.systemTestsRecorderAndPlayer.eventQueue = SystemTestsRepo_NAMEOFTHETEST.testData
# window.world.systemTestsRecorderAndPlayer.startPlaying()

# How to save a test:
# window.world.systemTestsRecorderAndPlayer.startRecording()
# ...do the test...
# window.world.systemTestsRecorderAndPlayer.stopRecording()
# if you want to verify the test on the spot:
# window.world.systemTestsRecorderAndPlayer.startPlaying()
# then to save the test:
# console.log(JSON.stringify( window.world.systemTestsRecorderAndPlayer.eventQueue ))
# copy that blurb
# Note for Chrome: You have to replace the data URL because
# it contains an ellipsis for more comfortable viewing in the console.
# Workaround: find that url and right-click: open in new tab and then copy the
# full data URL from the location bar and subsitute it with the one
# of the ellipses.
# Then pass the JSON into http://js2coffee.org/
# and save it in this file.

# Tests name must start with "SystemTest_"
class SystemTest_SimpleSpeechBubbleTest
  @testData: [
    type: "mouseMove"
    mouseX: 158
    mouseY: 26
    time: 479
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 218
    mouseY: 27
    time: 15
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 803
    mouseY: 97
    time: 1215
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseDown"
    mouseX: null
    mouseY: null
    time: 7
    button: 2
    ctrlKey: false
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 803
    mouseY: 100
    time: 28
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 803
    mouseY: 101
    time: 38
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseUp"
    mouseX: null
    mouseY: null
    time: 107
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 804
    mouseY: 101
    time: 81
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 805
    mouseY: 101
    time: 75
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 806
    mouseY: 101
    time: 300
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 807
    mouseY: 102
    time: 17
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 815
    mouseY: 108
    time: 16
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 819
    mouseY: 110
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 820
    mouseY: 112
    time: 17
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 822
    mouseY: 115
    time: 16
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 823
    mouseY: 118
    time: 22
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 824
    mouseY: 118
    time: 29
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 824
    mouseY: 120
    time: 49
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 825
    mouseY: 121
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 825
    mouseY: 122
    time: 16
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 825
    mouseY: 123
    time: 18
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 826
    mouseY: 123
    time: 149
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 826
    mouseY: 124
    time: 17
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 826
    mouseY: 126
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 827
    mouseY: 129
    time: 17
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 827
    mouseY: 134
    time: 22
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 829
    mouseY: 142
    time: 18
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 166
    time: 44
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 171
    time: 16
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 174
    time: 19
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 177
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 176
    time: 180
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 173
    time: 19
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 170
    time: 14
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 167
    time: 17
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 164
    time: 21
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 162
    time: 29
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 161
    time: 117
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 160
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 159
    time: 18
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 156
    time: 15
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 154
    time: 17
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 153
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 831
    mouseY: 151
    time: 94
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 830
    mouseY: 151
    time: 15
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 830
    mouseY: 148
    time: 25
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseDown"
    mouseX: null
    mouseY: null
    time: 196
    button: 0
    ctrlKey: false
    screenShotImageData: ""
  ,
    type: "mouseUp"
    mouseX: null
    mouseY: null
    time: 67
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 828
    mouseY: 148
    time: 370
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 825
    mouseY: 148
    time: 41
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 768
    mouseY: 145
    time: 36
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 723
    mouseY: 141
    time: 27
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 471
    mouseY: 131
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 341
    mouseY: 123
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 282
    mouseY: 114
    time: 32
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 266
    mouseY: 114
    time: 35
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 260
    mouseY: 114
    time: 12
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 257
    mouseY: 114
    time: 28
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 256
    mouseY: 114
    time: 63
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 255
    mouseY: 114
    time: 38
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 251
    mouseY: 114
    time: 29
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 246
    mouseY: 114
    time: 32
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 243
    mouseY: 114
    time: 35
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 242
    mouseY: 113
    time: 95
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 241
    mouseY: 113
    time: 66
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 239
    mouseY: 113
    time: 40
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 236
    mouseY: 113
    time: 37
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 224
    mouseY: 112
    time: 38
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 222
    mouseY: 111
    time: 35
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 213
    mouseY: 108
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 209
    mouseY: 107
    time: 31
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 208
    mouseY: 105
    time: 31
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 205
    mouseY: 104
    time: 2
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 203
    mouseY: 102
    time: 30
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 202
    mouseY: 101
    time: 4
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 200
    mouseY: 100
    time: 28
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 199
    mouseY: 100
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseDown"
    mouseX: null
    mouseY: null
    time: 118
    button: 2
    ctrlKey: false
    screenShotImageData: ""
  ,
    type: "mouseUp"
    mouseX: null
    mouseY: null
    time: 130
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 199
    mouseY: 101
    time: 356
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 202
    mouseY: 103
    time: 35
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 202
    mouseY: 108
    time: 30
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 205
    mouseY: 110
    time: 29
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 208
    mouseY: 116
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 210
    mouseY: 118
    time: 32
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 210
    mouseY: 121
    time: 27
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 210
    mouseY: 121
    time: 40
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 210
    mouseY: 122
    time: 24
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 210
    mouseY: 123
    time: 41
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 210
    mouseY: 124
    time: 110
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 210
    mouseY: 126
    time: 35
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 210
    mouseY: 128
    time: 31
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 210
    mouseY: 131
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 210
    mouseY: 132
    time: 32
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseDown"
    mouseX: null
    mouseY: null
    time: 215
    button: 0
    ctrlKey: false
    screenShotImageData: ""
  ,
    type: "mouseUp"
    mouseX: null
    mouseY: null
    time: 135
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 211
    mouseY: 132
    time: 501
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 217
    mouseY: 147
    time: 39
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 224
    mouseY: 184
    time: 36
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 229
    mouseY: 216
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 235
    mouseY: 234
    time: 48
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 236
    mouseY: 237
    time: 50
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 237
    mouseY: 238
    time: 51
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 238
    mouseY: 238
    time: 36
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 239
    mouseY: 239
    time: 22
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 240
    mouseY: 239
    time: 46
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 240
    mouseY: 240
    time: 30
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 240
    mouseY: 241
    time: 308
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 240
    mouseY: 242
    time: 151
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 241
    mouseY: 248
    time: 55
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 241
    mouseY: 248
    time: 30
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 241
    mouseY: 249
    time: 29
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 242
    mouseY: 249
    time: 66
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 242
    mouseY: 250
    time: 402
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 243
    mouseY: 256
    time: 35
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 243
    mouseY: 259
    time: 28
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 244
    mouseY: 263
    time: 18
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 245
    mouseY: 268
    time: 23
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 245
    mouseY: 271
    time: 38
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 245
    mouseY: 272
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 245
    mouseY: 274
    time: 29
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 245
    mouseY: 276
    time: 38
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 245
    mouseY: 278
    time: 15
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 245
    mouseY: 279
    time: 28
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 245
    mouseY: 280
    time: 6
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 247
    mouseY: 282
    time: 29
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 247
    mouseY: 283
    time: 37
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 247
    mouseY: 284
    time: 29
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 247
    mouseY: 285
    time: 64
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 247
    mouseY: 286
    time: 11
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 247
    mouseY: 287
    time: 6
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 247
    mouseY: 289
    time: 44
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 248
    mouseY: 291
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 248
    mouseY: 292
    time: 73
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 248
    mouseY: 293
    time: 83
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 249
    mouseY: 293
    time: 150
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseDown"
    mouseX: null
    mouseY: null
    time: 35
    button: 0
    ctrlKey: false
    screenShotImageData: ""
  ,
    type: "mouseUp"
    mouseX: null
    mouseY: null
    time: 95
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 248
    mouseY: 292
    time: 104
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 247
    mouseY: 290
    time: 36
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 240
    mouseY: 270
    time: 41
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 217
    mouseY: 218
    time: 51
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 214
    mouseY: 208
    time: 52
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 207
    mouseY: 191
    time: 54
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 198
    mouseY: 170
    time: 49
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 195
    mouseY: 163
    time: 50
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 195
    mouseY: 162
    time: 50
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 191
    mouseY: 159
    time: 55
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 180
    mouseY: 141
    time: 51
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 179
    mouseY: 140
    time: 42
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseDown"
    mouseX: null
    mouseY: null
    time: 124
    button: 0
    ctrlKey: false
    screenShotImageData: ""
  ,
    type: "mouseUp"
    mouseX: null
    mouseY: null
    time: 106
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 183
    mouseY: 141
    time: 63
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 189
    mouseY: 145
    time: 12
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 200
    mouseY: 151
    time: 27
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 237
    mouseY: 177
    time: 36
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 261
    mouseY: 191
    time: 30
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 294
    mouseY: 204
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 329
    mouseY: 205
    time: 33
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 343
    mouseY: 204
    time: 31
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 363
    mouseY: 202
    time: 41
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 366
    mouseY: 201
    time: 25
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 369
    mouseY: 201
    time: 7
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 372
    mouseY: 200
    time: 28
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 382
    mouseY: 194
    time: 35
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 389
    mouseY: 185
    time: 32
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 394
    mouseY: 171
    time: 32
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 394
    mouseY: 162
    time: 36
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 395
    mouseY: 158
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 394
    mouseY: 154
    time: 32
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 392
    mouseY: 152
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 391
    mouseY: 149
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 388
    mouseY: 146
    time: 6
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 387
    mouseY: 142
    time: 27
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 385
    mouseY: 135
    time: 32
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 385
    mouseY: 131
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 385
    mouseY: 119
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 385
    mouseY: 115
    time: 31
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 383
    mouseY: 113
    time: 34
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 383
    mouseY: 111
    time: 31
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 382
    mouseY: 111
    time: 75
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "mouseMove"
    mouseX: 383
    mouseY: 111
    time: 1566
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ,
    type: "takeScreenshot"
    mouseX: null
    mouseY: null
    time: 1475
    button: null
    ctrlKey: null
    screenShotImageData: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAA+UAAAJ2CAYAAAA5RiPTAAAgAElEQVR4Xu3dd4hd9dbH4Z+iudbYDdhFo8TYY8OGIvaGFYmCDUUFsWDDgihiww6K2Asq9oYNFHtvsQej2BvYFdEo8WXtlxnGmEkz5DtJngNyvc7MWXues/75zN77nNleffXVv5sHAQIECBAgQIAAAQIECBAgMN0FZhPl093cQAIECBAgQIAAAQIECBAg0AmIcotAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HZgigbFjx7aPP/64/fTTT23OOedsP/zwwxT9/Kz0zQsttFD7888/2wILLNCWW265NmjQoFnp1/e7EiBAgAABAgQIECAwGQKifDKQfMv/C3z77bdt9OjRbcSIEW3w4MFt0UUXRTMJgTKrP2C89tprbdiwYW2RRRZhRoAAAQIECBAgQIAAgV4BUW4ZJkug4rL+2XzzzSfr+33TvwUee+yxtvjii/tjhuUgQIAAAQIECBAgQECU24HJF6hL1l966aW2xx57TP4P+c4JCtx+++1t/fXX7y799yBAgAABAgQIECBAgIAz5XZgkgJjxoxpSy+9dFt++eX/8b1//PFH23rrrdtll13WVlllld6vPfLII+3mm29u1157bZt99tn7ff66N3233XZrTz75ZHcWvuff55tvvkke0/jfcPLJJ3f3bh977LHdl+qS8W222aYdddRRbc899+z+W83baqut2hNPPNGWWGKJyZrR9xjHP65PP/207bDDDu3pp5/uZp966qndveP7779/v8/9wQcftC+//LINHTp0sub7JgIECBAgQIAAAQIEZm4BUT5zv77T5Ld7+eWX24Ybbvivy64ryjfbbLN2+eWXtzXWWKN31v3339+uv/76dtttt00yynfaaacuausN43r+vQJ3Sh/33XdfO/fcc7vgnmOOOdorr7zSPd+WW27Z+8eBhx9+uJ122mnt8ccfb3PNNddkjago7++4Pvvss7b99tv3RvnRRx/dVltttYlGef3x4bnnnmvrrrvuZM33TQQIECBAgAABAgQIzNwConzmfn2nyW83atSotu222/7ruXqi/Oqrr/7XmfIrr7yyN8rrjHLF8EMPPdQOPPDAVvFa70zeN3jHj/K33nqrHXzwwe2TTz5pe+21VzvllFO6n+nv0XMWvAJ/yJAh7cILL2zPPvtse//997sIrzdYqzPZddl4nVXv7/nrLHb9QaHO/NfMm266qe2999694f3666+3ww47rDuWCuu7776792uHHnpoW2+99SYa5XX85bDmmmtOk9fGkxAgQIAAAQIECBAgMGMLiPIZ+/WbLkdfUTty5MgJRnldvl5niysy6+O/KnrrjHSdEa7L13/55Ze2ySabdDG+4447dmezv/nmm1b3Vn/++ee9Z6H7Rnlder7BBhu08847r/vZs88+u73xxhu9Z8En9Ev3XEpf31thXGfIL7744nbmmWe2ww8/vLuPu/7bSSed1FZcccV+n7+OqeeqgLPOOquttNJK3WX1FfsV7FtssUX3B4a11167N757Ll+/9dZbuzP+hxxyyERfl7q03xvmTZfVNYQAAQIECBAgQIDAgBcQ5QP+Jcof4MSifLvttmvvvfded9l2z6POQu+8887t0ksvbQ888EA755xzeoO6gnyttdZqL7zwQhs3btwEo7yi/qmnnup+vh4V9htttFEX8iuvvHK/IHUGfKmllmq77LJLF+B1CXuFcs3cb7/92uqrr979t4ro/p7/f//7X3ffeV1iXh/51vdsfr17ev3Tc1x1f/iuu+7ae6b8nnvuaV9//bUoz6+sIyBAgAABAgQIECAwwwiI8hnmpcod6MSivO4pv+qqq9rw4cN7D7DvPeUPPvhgdxn6+I+6hLvuHZ/QPeUnnHBCF+H77LNP92M9Z8EvuuiiiV72XW8wV5eTV1T3xHP9weCggw7qLl2vM9x1z3mdOe/v+RdccMF/3EPeN8rPOOOM7t75nuMa/35zZ8pzO2oyAQIECBAgQIAAgRlVQJTPqK/cdDzuSUX5xN7orc4e33jjjd395X/99Vf3z9tvv93WWWed9sUXX0wwyq+55po222yztSOPPLL7LX/77bfucvNJnSmvN16ry9TrUX8oqLP49bP1v3Vv+fHHH9+OOOKI7n7z/p6/zpT3fWO3vuF9wQUXdPeS9xzX+O++Pnr06O4S/r5XDUzoZXL5+nRcXqMIECBAgAABAgQIDHABUT7AX6CBcHiTeqO3iUX5O++8092Tfe+997Zhw4a1O+64o51++und557Xpd4TOlP+7rvvtn333bfVWfa6//uKK67o7k+vS87//vvvVm8sV288Vx8/1vdRQVyXzddl5Y8++mhbZpllui+feOKJ7brrrmt33XVXF/fPP/98v8/f9w8FdSa/b5T3HFddkr/sssu2uuf8zjvv7L18vS55r6gfMWLERF82b/Q2ELbaMRAgQIAAAQIECBAYGAKifGC8DgP6KOoj0TbeeOO28MIL/+M4+/uc8ron/JZbbun9KLI6M3zMMcf0/mx9ve7v7gneitl6Y7gK9Pr3eeedt11yySXdvej1qHu769LwivqaWe96fsMNN0zwUvbzzz+/i/eK5fpotHrUvOOOO673Xdgr7Pt7/r7HVJ9L3vf/13HV2fKaUY/dd9+9e4f3uiR+/vnn7z4jfYUVVpjoPeXff/99e+aZZ3wk2oDeeAdHgAABAgQIECBAYPoJiPLpZz3DTqpLv+usdJ0dntpHvVlbXbpe8doTy5N6rnoX9t9//737OLO+P1P3htcZ8f/6sWL9Pf+kjuvHH3/sPn998ODBk/rWf339o48+anWZ/dChQ6f4Z/0AAQIECBAgQIAAAQIzn4Aon/le02n+G40dO7bV2fI6M5x+1Jnyukf9gAMO6MJ4RnvU5ft13/vk/mFiRvv9HC8BAgQIECBAgAABAlMmIMqnzGuW/e6ff/65+2ixTTfddJY1+K+/eF1WP2TIkKk6w/5fZ/t5AgQIECBAgAABAgQGpoAoH5ivy4A8ql9//bW9+eab3RuZ1aXb499jPiAPOnxQdQ95Xbpfn49eH6dW96V7ECBAgAABAgQIECBAoEdAlNuFKRKojxKrjwL77rvv2qBBg9oWW2zxj5+vr40ZM6Y7qz6rP+qseF36X/fE1zvB1xvMeRAgQIAAAQIECBAgQKCvgCi3D1MlUG9WNvfcc/d+Jve4ceO6dzev/1111VWn6jn9EAECBAgQIECAAAECBGY1AVE+q73i0+j3rQAfOXJk92wffvhhe/HFF7sYX2yxxabRBE9DgAABAgQIECBAgACBmV9AlM/8r/E0/w17zpIPHz7c2fFprusJCRAgQIAAAQIECBCYlQRE+az0ak+j37XOktfHejk7Po1APQ0BAgQIECBAgAABArOsgCifZV/6qfvF6yz5V1991eaZZx73jk8doZ8iQIAAAQIECBAgQIBAr4AotwxTJDBq1Ki25JJLund8itR8MwECBAgQIECAAAECBCYsIMptBgECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIED1XExoAABhBSURBVAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQEOV2gAABAgQIECBAgAABAgQIhAREeQjeWAIECBAgQIAAAQIECBAgIMrtAAECBAgQIECAAAECBAgQCAmI8hC8sQQIECBAgAABAgQIECBAQJTbAQIECBAgQIAAAQIECBAgEBIQ5SF4YwkQIECAAAECBAgQIECAgCi3AwQIECBAgAABAgQIECBAICQgykPwxhIgQIAAAQIECBAgQIAAAVFuBwgQIECAAAECBAgQIECAQEhAlIfgjSVAgAABAgQIECBAgAABAqLcDhAgQIAAAQIECBAgQIAAgZCAKA/BG0uAAAECBAgQIECAAAECBES5HSBAgAABAgQIECBAgAABAiEBUR6CN5YAAQIECBAgQIAAAQIECIhyO0CAAAECBAgQIECAAAECBEICojwEbywBAgQIECBAgAABAgQIEBDldoAAAQIECBAgQIAAAQIECIQERHkI3lgCBAgQIECAAAECBAgQICDK7QABAgQIECBAgAABAgQIEAgJiPIQvLEECBAgQIAAAQIECBAgQECU2wECBAgQIECAAAECBAgQIBASEOUheGMJECBAgAABAgQIECBAgIAotwMECBAgQIAAAQIECBAgQCAkIMpD8MYSIECAAAECBAgQIECAAAFRbgcIECBAgAABAgQIECBAgEBIQJSH4I0lQIAAAQIECBAgQIAAAQKi3A4QIECAAAECBAgQIECAAIGQgCgPwRtLgAABAgQIECBAgAABAgREuR0gQIAAAQIECBAgQIAAAQIhAVEegjeWAAECBAgQIECAAAECBAiIcjtAgAABAgQIECBAgAABAgRCAqI8BG8sAQIECBAgQIAAAQIECBAQ5XaAAAECBAgQIECAAAECBAiEBER5CN5YAgQIECBAgAABAgQIECAgyu0AAQIECBAgQIAAAQIECBAICYjyELyxBAgQIECAAAECBAgQIEBAlNsBAgQIECBAgAABAgQIECAQEhDlIXhjCRAgQIAAAQIECBAgQICAKLcDBAgQIECAAAECBAgQIEAgJCDKQ/DGEiBAgAABAgQIECBAgAABUW4HCBAgQIAAAQIECBAgQIBASECUh+CNJUCAAAECBAgQIECAAAECotwOECBAgAABAgQIECBAgACBkIAoD8EbS4AAAQIECBAgQIAAAQIERLkdIECAAAECBAgQIECAAAECIQFRHoI3lgABAgQIECBAgAABAgQIiHI7QIAAAQIECBAgQIAAAQIEQgKiPARvLAECBAgQIECAAAECBAgQ+D+KzGgvI76PYwAAAABJRU5ErkJggg=="
  ,
    type: "mouseMove"
    mouseX: 381
    mouseY: 111
    time: 791
    button: null
    ctrlKey: null
    screenShotImageData: ""
  ]