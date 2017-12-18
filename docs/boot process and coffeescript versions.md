How the world boots
========
...and notes on compilation and Coffeescript v2
---

Fizzygum "runs" as JS, but it's coded in Coffeescript (v2, more on this later). Since Fizzygum can be modified from within itslef (by changing the source code), a mechanism is needed to expose the Coffeescript sources.

So this is how this has been achieved: the build script doesn't translate the coffeescript sources to JS as in "traditional" setups. It rather generates JS files such that each contains a string with the coffeescript source of a class (or a mixin).

So at boot there is just a special JS file that loads all such "cs sources in string" JS files, and
1) it compiles them to JS
2) it puts them in appropriate data structures so that the sources can be kept around and edited by the user.

This "dynamic" compilation has actually a couple of twists to it:

1. it's done "property by property" of a class rather than for a complete class in one go. This is because in Fizzygum it's often the case that the user changes a property (a field or a method).
2. some code is trasparently edited/injected:
   a. in the constructor, each Morph instance registers itself into special data structures (so some update mechanisms can work)
   b. because of point 1, "super" needs to be replaced with the equivalent functionality, since "super" can only be compiled as part of a class definition, it cannot be compiled in a stand-alone method definition as it is the case here.

In fact, because of 1, and also because the class hyerarchy is explicitly tracked in Fizzygum (user might want to change it), the class hyerarchy is "manually" handled, in the same way that Coffeescript v1 did, i.e. properly running JS code that adjusts the "constructor" and "prototype" links, and copies static properties into the constructor etc. etc.

So for this reason, although we use Coffeescript v2, we don't use the Coffeescript v2 way of dealing with classes and their hyerarchy (which is to just use the new ES6 syntax for it). We use the Coffeescript v2 compiler but the classes and their hyerarchy are still handled in the v1 way. This will probably have some performance implications in the medium/long term (since ES6 classes give strong high-level clues to the VM of what the user is doing rather than figuring it out from a number of constructor/prototype links, and with ES6 classes some "dynamic" games that would be hard to optimised are automatically ruled out, for example the class hyerarchy cannot change). On the other hand, because of its reliance on ES6, CS v2 introduce some limitations, see http://coffeescript.org/#breaking-changes-classes , most of those go away when we don't use CS v2 class handling.

Pre-compiling things
---
Because this whole loading sources / compiling sources boot process, the boot takes a few seconds. For a "snappier" feel, another way to boot is available, and that is to boot from a JS file that _really_ contains the JS version of the classes (and all the code needed to weave together the inheritance hyerarchy and the augmentation of mixin).

To _get_ this pre-compiled JS file, just add ```?generatePreCompiled``` to the URL, e.g. ```/index.html?generatePreCompiled```. This will cause all the compilations to be "stored" in a JS file that is automatically downloaded. It's as if the "standard" boot process was "traced" in this JS file. Then one needs to run the ```sh inject_pre-compiled_into_build.sh``` script, which gets the downloaded pre-compiled js and puts it in the right place.

When booting via this pre-compiled file, the world comes up almost instantly. The sources still have to be loaded (for user might want to edit them), but they can be loaded asynchronously after the world is already usable.

See also...
----
See also the long comment before/in the ```boot = ->``` function for more details on the boot process.



