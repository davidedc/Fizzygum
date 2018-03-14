class SimpleWorldMapIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 500, 265
    @specificationSize = new Point 1000, 530

  paintFunction: (context) ->
    fillColor = @morph.color
    fillColorString = fillColor.toString()

    #// October revol + Bolshevik Islands Drawing
    context.beginPath()
    context.moveTo 732, 22
    context.lineTo 738, 20
    context.lineTo 762, 33
    context.lineTo 748, 35
    context.lineTo 728, 29
    context.lineTo 732, 22
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Svalbard Drawing
    context.beginPath()
    context.moveTo 525, 21
    context.lineTo 542, 23
    context.lineTo 544, 28
    context.lineTo 528, 31
    context.lineTo 537, 42
    context.lineTo 528, 42
    context.lineTo 525, 36
    context.lineTo 520, 42
    context.lineTo 509, 42
    context.lineTo 508, 35
    context.lineTo 503, 30
    context.lineTo 506, 26
    context.lineTo 525, 21
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Zemlya Georga + other islands Drawing
    context.save()
    context.translate 81, -263
    context.beginPath()
    context.moveTo 547, 277
    context.lineTo 558, 274
    context.lineTo 557, 284
    context.lineTo 548, 287
    context.lineTo 517, 288
    context.lineTo 515, 284
    context.lineTo 535, 278
    context.lineTo 547, 277
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    context.restore()
    #// Novaya Zemlya Drawing
    context.beginPath()
    context.moveTo 639, 46
    context.lineTo 659, 41
    context.lineTo 658, 46
    context.lineTo 643, 49
    context.lineTo 635, 53
    context.lineTo 625, 60
    context.lineTo 627, 73
    context.lineTo 616, 71
    context.lineTo 614, 67
    context.lineTo 621, 50
    context.lineTo 639, 46
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Siberian Island 3 Drawing
    context.beginPath()
    context.moveTo 854, 46
    context.lineTo 859, 46
    context.lineTo 859, 50
    context.lineTo 856, 53
    context.lineTo 854, 52
    context.lineTo 854, 46
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Siberian Island 2 Drawing
    context.beginPath()
    context.moveTo 862, 48
    context.lineTo 868, 51
    context.lineTo 863, 52
    context.lineTo 862, 48
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Siberian Island 1 Drawing
    context.beginPath()
    context.moveTo 859, 55
    context.lineTo 868, 60
    context.lineTo 859, 60
    context.lineTo 859, 55
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Iceland Drawing
    context.beginPath()
    context.moveTo 405, 98
    context.lineTo 411, 91
    context.lineTo 416, 96
    context.lineTo 427, 94
    context.lineTo 429, 103
    context.lineTo 412, 110
    context.lineTo 405, 98
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// GB Drawing
    context.beginPath()
    context.moveTo 454, 128
    context.lineTo 460, 126
    context.lineTo 459, 131
    context.lineTo 463, 132
    context.lineTo 468, 146
    context.lineTo 472, 149
    context.lineTo 471, 155
    context.lineTo 457, 159
    context.lineTo 460, 154
    context.lineTo 454, 152
    context.lineTo 460, 146
    context.lineTo 454, 128
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Ireland Drawing
    context.beginPath()
    context.moveTo 443, 147
    context.lineTo 452, 143
    context.lineTo 451, 152
    context.lineTo 448, 156
    context.lineTo 443, 156
    context.lineTo 443, 147
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Japan Drawing
    context.beginPath()
    context.moveTo 864, 158
    context.lineTo 868, 151
    context.lineTo 868, 168
    context.lineTo 866, 181
    context.lineTo 873, 188
    context.lineTo 861, 196
    context.lineTo 862, 205
    context.lineTo 857, 219
    context.lineTo 844, 223
    context.lineTo 831, 229
    context.lineTo 831, 222
    context.lineTo 855, 206
    context.lineTo 858, 194
    context.lineTo 865, 172
    context.lineTo 864, 158
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Sardinia Drawing
    context.beginPath()
    context.moveTo 493, 203
    context.lineTo 492, 197
    context.lineTo 494, 195
    context.lineTo 495, 203
    context.lineTo 493, 203
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Cuba Drawing
    context.beginPath()
    context.moveTo 236, 257
    context.lineTo 248, 258
    context.lineTo 262, 264
    context.lineTo 255, 266
    context.lineTo 246, 261
    context.lineTo 238, 260
    context.lineTo 236, 257
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Haiti + Dominican Republic Drawing
    context.beginPath()
    context.moveTo 270, 267
    context.lineTo 279, 272
    context.lineTo 265, 273
    context.lineTo 270, 267
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Philippines Drawing
    context.beginPath()
    context.moveTo 805, 272
    context.lineTo 808, 274
    context.lineTo 816, 296
    context.lineTo 819, 313
    context.lineTo 811, 311
    context.lineTo 805, 296
    context.lineTo 802, 276
    context.lineTo 805, 272
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// South America Drawing
    context.beginPath()
    context.moveTo 266, 296
    context.lineTo 281, 296
    context.lineTo 297, 300
    context.lineTo 313, 311
    context.lineTo 325, 315
    context.lineTo 334, 334
    context.lineTo 369, 346
    context.lineTo 373, 358
    context.lineTo 365, 371
    context.lineTo 358, 393
    context.lineTo 352, 405
    context.lineTo 338, 412
    context.lineTo 326, 436
    context.lineTo 317, 445
    context.lineTo 310, 455
    context.lineTo 296, 462
    context.lineTo 285, 481
    context.lineTo 285, 496
    context.lineTo 279, 509
    context.lineTo 284, 520
    context.lineTo 278, 524
    context.lineTo 269, 523
    context.lineTo 262, 506
    context.lineTo 260, 483
    context.lineTo 262, 468
    context.lineTo 268, 440
    context.lineTo 270, 421
    context.lineTo 271, 389
    context.lineTo 261, 380
    context.lineTo 255, 371
    context.lineTo 246, 354
    context.lineTo 249, 333
    context.lineTo 256, 320
    context.lineTo 255, 309
    context.lineTo 266, 296
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Sri Lanka Drawing
    context.beginPath()
    context.moveTo 691, 303
    context.lineTo 696, 310
    context.lineTo 691, 313
    context.lineTo 691, 303
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Kalimantan Drawing
    context.beginPath()
    context.moveTo 773, 325
    context.lineTo 797, 311
    context.lineTo 797, 325
    context.lineTo 792, 344
    context.lineTo 775, 340
    context.lineTo 773, 325
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Sulawesi Drawing
    context.beginPath()
    context.moveTo 803, 330
    context.lineTo 810, 330
    context.lineTo 811, 351
    context.lineTo 800, 348
    context.lineTo 803, 330
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Papua Drawing
    context.beginPath()
    context.moveTo 833, 335
    context.lineTo 867, 346
    context.lineTo 877, 352
    context.lineTo 884, 367
    context.lineTo 855, 359
    context.lineTo 849, 350
    context.lineTo 839, 345
    context.lineTo 833, 335
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Java Drawing
    context.beginPath()
    context.moveTo 763, 351
    context.lineTo 789, 355
    context.lineTo 795, 361
    context.lineTo 783, 360
    context.lineTo 763, 354
    context.lineTo 763, 351
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Madagascar Drawing
    context.beginPath()
    context.moveTo 607, 368
    context.lineTo 602, 395
    context.lineTo 595, 403
    context.lineTo 590, 398
    context.lineTo 594, 387
    context.lineTo 592, 377
    context.lineTo 607, 368
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Australia Drawing
    context.beginPath()
    context.moveTo 860, 388
    context.lineTo 864, 370
    context.lineTo 876, 391
    context.lineTo 887, 409
    context.lineTo 892, 421
    context.lineTo 890, 442
    context.lineTo 883, 458
    context.lineTo 871, 462
    context.lineTo 857, 456
    context.lineTo 850, 451
    context.lineTo 843, 441
    context.lineTo 837, 438
    context.lineTo 826, 436
    context.lineTo 812, 441
    context.lineTo 804, 441
    context.lineTo 791, 445
    context.lineTo 791, 435
    context.lineTo 786, 419
    context.lineTo 785, 403
    context.lineTo 804, 395
    context.lineTo 809, 390
    context.lineTo 817, 380
    context.lineTo 827, 380
    context.lineTo 833, 371
    context.lineTo 847, 371
    context.lineTo 847, 383
    context.lineTo 860, 388
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// New Zealand Drawing
    context.beginPath()
    context.moveTo 949, 449
    context.lineTo 965, 462
    context.lineTo 943, 489
    context.lineTo 934, 493
    context.lineTo 931, 488
    context.lineTo 946, 472
    context.lineTo 956, 461
    context.lineTo 949, 449
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Tasmania Drawing
    context.beginPath()
    context.moveTo 870, 469
    context.lineTo 880, 469
    context.lineTo 878, 478
    context.lineTo 872, 476
    context.lineTo 870, 469
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Corsica Drawing
    context.beginPath()
    context.moveTo 493, 195
    context.lineTo 493, 192
    context.lineTo 494, 191
    context.lineTo 494, 195
    context.lineTo 493, 195
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Africa Drawing
    context.beginPath()
    context.moveTo 477, 210
    context.lineTo 490, 211
    context.lineTo 499, 211
    context.lineTo 498, 223
    context.lineTo 518, 232
    context.lineTo 531, 225
    context.lineTo 550, 230
    context.lineTo 558, 229
    context.lineTo 574, 269
    context.lineTo 592, 297
    context.lineTo 611, 294
    context.lineTo 609, 307
    context.lineTo 602, 319
    context.lineTo 582, 337
    context.lineTo 578, 349
    context.lineTo 582, 364
    context.lineTo 578, 378
    context.lineTo 566, 387
    context.lineTo 568, 396
    context.lineTo 560, 406
    context.lineTo 553, 417
    context.lineTo 532, 426
    context.lineTo 524, 426
    context.lineTo 521, 423
    context.lineTo 513, 408
    context.lineTo 505, 388
    context.lineTo 503, 374
    context.lineTo 508, 357
    context.lineTo 494, 334
    context.lineTo 494, 322
    context.lineTo 486, 318
    context.lineTo 483, 313
    context.lineTo 444, 318
    context.lineTo 426, 295
    context.lineTo 424, 290
    context.lineTo 423, 262
    context.lineTo 428, 250
    context.lineTo 440, 235
    context.lineTo 443, 227
    context.lineTo 454, 215
    context.lineTo 463, 216
    context.lineTo 471, 212
    context.lineTo 477, 210
    context.lineTo 477, 210
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Greenland Drawing
    context.beginPath()
    context.moveTo 353, 5
    context.lineTo 370, 3
    context.lineTo 407, 6
    context.lineTo 435, 17
    context.lineTo 425, 23
    context.lineTo 415, 34
    context.lineTo 420, 40
    context.lineTo 419, 51
    context.lineTo 410, 59
    context.lineTo 413, 71
    context.lineTo 401, 80
    context.lineTo 360, 97
    context.lineTo 350, 121
    context.lineTo 336, 116
    context.lineTo 328, 83
    context.lineTo 313, 52
    context.lineTo 306, 46
    context.lineTo 300, 44
    context.lineTo 272, 43
    context.lineTo 271, 31
    context.lineTo 287, 28
    context.lineTo 301, 12
    context.lineTo 314, 10
    context.lineTo 326, 12
    context.lineTo 353, 5
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Noth America Drawing
    context.beginPath()
    context.moveTo 287, 23
    context.lineTo 278, 23
    context.lineTo 258, 36
    context.lineTo 253, 37
    context.lineTo 247, 54
    context.lineTo 254, 55
    context.lineTo 257, 61
    context.lineTo 264, 62
    context.lineTo 267, 68
    context.lineTo 276, 70
    context.lineTo 281, 76
    context.lineTo 282, 82
    context.lineTo 300, 88
    context.lineTo 293, 98
    context.lineTo 285, 94
    context.lineTo 289, 100
    context.lineTo 289, 104
    context.lineTo 283, 105
    context.lineTo 286, 111
    context.lineTo 272, 109
    context.lineTo 266, 104
    context.lineTo 253, 104
    context.lineTo 253, 100
    context.lineTo 266, 98
    context.lineTo 268, 86
    context.lineTo 259, 84
    context.lineTo 257, 76
    context.lineTo 241, 76
    context.lineTo 245, 91
    context.lineTo 236, 95
    context.lineTo 241, 103
    context.lineTo 239, 106
    context.lineTo 235, 107
    context.lineTo 221, 103
    context.lineTo 210, 114
    context.lineTo 207, 124
    context.lineTo 212, 126
    context.lineTo 214, 132
    context.lineTo 221, 133
    context.lineTo 230, 139
    context.lineTo 241, 143
    context.lineTo 240, 149
    context.lineTo 249, 155
    context.lineTo 248, 145
    context.lineTo 250, 142
    context.lineTo 256, 138
    context.lineTo 255, 128
    context.lineTo 252, 123
    context.lineTo 254, 112
    context.lineTo 265, 110
    context.lineTo 269, 111
    context.lineTo 275, 116
    context.lineTo 280, 125
    context.lineTo 287, 123
    context.lineTo 291, 120
    context.lineTo 298, 134
    context.lineTo 310, 145
    context.lineTo 313, 160
    context.lineTo 327, 168
    context.lineTo 326, 172
    context.lineTo 306, 169
    context.lineTo 311, 156
    context.lineTo 299, 159
    context.lineTo 294, 160
    context.lineTo 295, 176
    context.lineTo 302, 179
    context.lineTo 286, 186
    context.lineTo 283, 181
    context.lineTo 278, 185
    context.lineTo 273, 193
    context.lineTo 263, 201
    context.lineTo 257, 217
    context.lineTo 252, 222
    context.lineTo 242, 232
    context.lineTo 246, 245
    context.lineTo 244, 249
    context.lineTo 235, 233
    context.lineTo 206, 236
    context.lineTo 201, 240
    context.lineTo 199, 252
    context.lineTo 198, 260
    context.lineTo 203, 270
    context.lineTo 214, 271
    context.lineTo 218, 269
    context.lineTo 226, 262
    context.lineTo 224, 280
    context.lineTo 238, 284
    context.lineTo 239, 300
    context.lineTo 255, 304
    context.lineTo 241, 306
    context.lineTo 234, 302
    context.lineTo 228, 292
    context.lineTo 221, 287
    context.lineTo 205, 280
    context.lineTo 187, 276
    context.lineTo 180, 272
    context.lineTo 175, 267
    context.lineTo 174, 258
    context.lineTo 169, 249
    context.lineTo 163, 240
    context.lineTo 151, 230
    context.lineTo 164, 255
    context.lineTo 153, 245
    context.lineTo 141, 221
    context.lineTo 134, 218
    context.lineTo 130, 207
    context.lineTo 125, 203
    context.lineTo 122, 186
    context.lineTo 122, 163
    context.lineTo 113, 161
    context.lineTo 111, 149
    context.lineTo 83, 124
    context.lineTo 57, 116
    context.lineTo 56, 119
    context.lineTo 47, 122
    context.lineTo 48, 117
    context.lineTo 42, 120
    context.lineTo 39, 126
    context.lineTo 30, 136
    context.lineTo 12, 143
    context.lineTo 21, 135
    context.lineTo 28, 132
    context.lineTo 30, 124
    context.lineTo 12, 118
    context.lineTo 8, 111
    context.lineTo 12, 106
    context.lineTo 19, 105
    context.lineTo 20, 100
    context.lineTo 5, 99
    context.lineTo 3, 94
    context.lineTo 19, 93
    context.lineTo 8, 80
    context.lineTo 23, 70
    context.lineTo 57, 72
    context.lineTo 89, 78
    context.lineTo 113, 71
    context.lineTo 119, 75
    context.lineTo 144, 78
    context.lineTo 144, 69
    context.lineTo 128, 68
    context.lineTo 125, 56
    context.lineTo 131, 52
    context.lineTo 148, 52
    context.lineTo 148, 45
    context.lineTo 130, 45
    context.lineTo 125, 42
    context.lineTo 162, 30
    context.lineTo 207, 31
    context.lineTo 204, 17
    context.lineTo 215, 16
    context.lineTo 227, 10
    context.lineTo 235, 11
    context.lineTo 269, 6
    context.lineTo 291, 7
    context.lineTo 301, 12
    context.lineTo 287, 23
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Eurasia Drawing
    context.beginPath()
    context.moveTo 762, 38
    context.lineTo 767, 42
    context.lineTo 781, 42
    context.lineTo 787, 52
    context.lineTo 775, 55
    context.lineTo 776, 58
    context.lineTo 788, 56
    context.lineTo 798, 59
    context.lineTo 796, 60
    context.lineTo 810, 62
    context.lineTo 813, 57
    context.lineTo 826, 63
    context.lineTo 831, 71
    context.lineTo 849, 70
    context.lineTo 856, 69
    context.lineTo 861, 62
    context.lineTo 885, 67
    context.lineTo 899, 71
    context.lineTo 912, 71
    context.lineTo 915, 76
    context.lineTo 955, 76
    context.lineTo 996, 97
    context.lineTo 990, 104
    context.lineTo 981, 103
    context.lineTo 973, 100
    context.lineTo 965, 102
    context.lineTo 966, 112
    context.lineTo 941, 122
    context.lineTo 927, 122
    context.lineTo 925, 124
    context.lineTo 922, 137
    context.lineTo 919, 145
    context.lineTo 914, 151
    context.lineTo 905, 159
    context.lineTo 904, 156
    context.lineTo 902, 143
    context.lineTo 907, 131
    context.lineTo 917, 123
    context.lineTo 922, 120
    context.lineTo 921, 116
    context.lineTo 911, 115
    context.lineTo 905, 116
    context.lineTo 900, 124
    context.lineTo 863, 124
    context.lineTo 847, 143
    context.lineTo 859, 149
    context.lineTo 859, 167
    context.lineTo 848, 183
    context.lineTo 842, 191
    context.lineTo 834, 189
    context.lineTo 827, 200
    context.lineTo 829, 216
    context.lineTo 821, 220
    context.lineTo 816, 204
    context.lineTo 814, 201
    context.lineTo 805, 198
    context.lineTo 796, 207
    context.lineTo 808, 210
    context.lineTo 810, 212
    context.lineTo 801, 218
    context.lineTo 806, 228
    context.lineTo 800, 252
    context.lineTo 790, 260
    context.lineTo 768, 266
    context.lineTo 760, 272
    context.lineTo 768, 280
    context.lineTo 774, 294
    context.lineTo 764, 304
    context.lineTo 750, 293
    context.lineTo 748, 305
    context.lineTo 750, 311
    context.lineTo 759, 327
    context.lineTo 753, 326
    context.lineTo 751, 322
    context.lineTo 744, 301
    context.lineTo 739, 278
    context.lineTo 732, 281
    context.lineTo 725, 261
    context.lineTo 715, 263
    context.lineTo 709, 268
    context.lineTo 693, 282
    context.lineTo 689, 302
    context.lineTo 682, 305
    context.lineTo 677, 295
    context.lineTo 674, 285
    context.lineTo 671, 264
    context.lineTo 665, 266
    context.lineTo 655, 249
    context.lineTo 644, 252
    context.lineTo 633, 249
    context.lineTo 616, 243
    context.lineTo 608, 234
    context.lineTo 606, 235
    context.lineTo 605, 241
    context.lineTo 610, 248
    context.lineTo 615, 250
    context.lineTo 635, 258
    context.lineTo 627, 274
    context.lineTo 621, 278
    context.lineTo 594, 291
    context.lineTo 590, 279
    context.lineTo 566, 236
    context.lineTo 562, 236
    context.lineTo 559, 229
    context.lineTo 567, 228
    context.lineTo 569, 213
    context.lineTo 549, 212
    context.lineTo 547, 210
    context.lineTo 543, 199
    context.lineTo 559, 194
    context.lineTo 566, 193
    context.lineTo 585, 196
    context.lineTo 582, 189
    context.lineTo 576, 184
    context.lineTo 570, 183
    context.lineTo 556, 178
    context.lineTo 553, 180
    context.lineTo 549, 187
    context.lineTo 548, 195
    context.lineTo 536, 198
    context.lineTo 534, 211
    context.lineTo 531, 209
    context.lineTo 524, 195
    context.lineTo 505, 181
    context.lineTo 505, 187
    context.lineTo 514, 196
    context.lineTo 521, 201
    context.lineTo 516, 201
    context.lineTo 511, 211
    context.lineTo 505, 208
    context.lineTo 513, 204
    context.lineTo 505, 196
    context.lineTo 495, 185
    context.lineTo 488, 186
    context.lineTo 478, 190
    context.lineTo 470, 201
    context.lineTo 465, 212
    context.lineTo 465, 212
    context.lineTo 465, 212
    context.lineTo 465, 212
    context.lineTo 465, 212
    context.lineTo 465, 212
    context.lineTo 465, 212
    context.lineTo 465, 212
    context.lineTo 456, 212
    context.lineTo 444, 205
    context.lineTo 448, 188
    context.lineTo 458, 187
    context.lineTo 467, 187
    context.lineTo 467, 180
    context.lineTo 459, 168
    context.lineTo 481, 155
    context.lineTo 485, 150
    context.lineTo 493, 148
    context.lineTo 493, 134
    context.lineTo 499, 132
    context.lineTo 499, 139
    context.lineTo 505, 139
    context.lineTo 524, 132
    context.lineTo 536, 115
    context.lineTo 527, 107
    context.lineTo 536, 93
    context.lineTo 531, 91
    context.lineTo 514, 112
    context.lineTo 514, 124
    context.lineTo 506, 132
    context.lineTo 499, 124
    context.lineTo 493, 128
    context.lineTo 489, 115
    context.lineTo 516, 86
    context.lineTo 513, 81
    context.lineTo 534, 69
    context.lineTo 551, 70
    context.lineTo 559, 78
    context.lineTo 568, 80
    context.lineTo 577, 83
    context.lineTo 582, 92
    context.lineTo 575, 94
    context.lineTo 564, 91
    context.lineTo 573, 102
    context.lineTo 576, 104
    context.lineTo 584, 95
    context.lineTo 590, 93
    context.lineTo 592, 83
    context.lineTo 597, 83
    context.lineTo 597, 92
    context.lineTo 610, 85
    context.lineTo 628, 83
    context.lineTo 639, 78
    context.lineTo 642, 79
    context.lineTo 660, 85
    context.lineTo 658, 73
    context.lineTo 659, 68
    context.lineTo 666, 58
    context.lineTo 678, 63
    context.lineTo 694, 63
    context.lineTo 697, 57
    context.lineTo 710, 56
    context.lineTo 715, 47
    context.lineTo 751, 43
    context.lineTo 753, 41
    context.lineTo 754, 39
    context.lineTo 762, 38
    context.lineTo 762, 38
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()
    #// Sumatra Drawing
    context.beginPath()
    context.moveTo 764, 341
    context.lineTo 762, 350
    context.lineTo 754, 345
    context.lineTo 748, 336
    context.lineTo 736, 315
    context.lineTo 748, 323
    context.lineTo 764, 341
    context.closePath()
    context.fillStyle = fillColorString
    context.fill()

