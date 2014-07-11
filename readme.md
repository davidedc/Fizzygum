Zombie Kernel
============

Zombie Kernel is a minimal live desktop system similar in concept to Squeak and Lively Kernel. Try it 
[here](http://davidedc.github.io/Zombie-Kernel/build/morphee-coffee.html).

![alt tag](https://raw.github.com/davidedc/Zombie-Kernel/master/docs/other/imgs/ZombieKernelScreenshot5thSept2013.png)

It's "live" in the sense that it allows direct interaction/inspection with/of all its elements. Everything in Zombie Kernel is an object that can be inspected and changed "live".

How to play with it
-------------------
Just drag "morphee-coffee.html" from the "build" directory into any browser and right click to open a system menu. The "demo" section has some elements that you can play with.

Where are the docs?
-------------------
[Here](http://davidedc.github.io/Zombie-Kernel/docs/index.html), it contains an overview of the system, and links to detailed docco files (and more).

I made changes - how do I try them / re-build?
---------------------------------------------
If you make changes to any of the coffeescript .coffee files in the src directory, just run the script "build_it_please.sh", which will rebuild everything.

Standing on the shoulders of giants
-----------------------------------
Zombie Kernel was inspired by [Lively Kernel](http://www.lively-kernel.org/).
Zombie Kernel was built starting from [Morphic.js](https://github.com/jmoenig/morphic.js) by [Jens Mönig](https://twitter.com/moenig).
Parts of Zombie Kernel are adapted from the compact and awesome [Cuis Smalltalk](http://www.jvuletich.org/Cuis/Index.html) by [Juan Vuletich](http://www.jvuletich.org/).