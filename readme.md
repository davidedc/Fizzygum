Zombie Kernel
============

Zombie Kernel is a minimal live desktop system similar in concept to Squeak and Lively Kernel.

![alt tag](https://raw.githubusercontent.com/davidedc/Zombie-Kernel-builds/gh-pages/other-support-files/docs/other/imgs/ZombieKernelScreenshot5thSept2013.png)

It's "live" in the sense that it allows direct interaction/inspection with/of all its elements. Everything in Zombie Kernel is an object that can be inspected and changed "live".

Play with it
-------------------
Try it [here](http://davidedc.github.io/Zombie-Kernel-builds/latest/worldWithSystemTestHarness.html)

Download it / build it
-------------------
Install npm. Then install coffeescript. Run the "build_it_please.sh" script. No server needed, just drag "index.html" from the "build" directory into any browser and right click to open a system menu. The "demo" section has some elements that you can play with.

The docs
-------------------
[Here](http://davidedc.github.io/Zombie-Kernel-builds/latest/other-support-files/docs/index.html), it contains an overview of the system, and links to detailed docco files (and more).


Hack it
---------------------------------------------
If you make changes to any of the coffeescript .coffee files in the src directory, just run the script "build_it_please.sh", which will rebuild everything.

Standing on the shoulders of giants
-----------------------------------
Zombie Kernel was inspired by [Lively Kernel](http://www.lively-kernel.org/).
Zombie Kernel was built starting from [Morphic.js](https://github.com/jmoenig/morphic.js) by [Jens Mönig](https://twitter.com/moenig).
Parts of Zombie Kernel are adapted from the compact and awesome [Cuis Smalltalk](http://www.jvuletich.org/Cuis/Index.html) by [Juan Vuletich](http://www.jvuletich.org/).

The MIT License
-----------------------------------

Copyright (c) 2015 All Zombie Kernel contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.