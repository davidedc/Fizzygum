
#Zombie-Kernel#



This document was adapted/extended from the Morphic.js documentation, written by Jens Mönig (jens@moenig.org).



##Intro##

Zombie Kernel is a lively Web-GUI built on top of a (slightly modified version of) Morphic.js. Think of it as a crazy web desktop environment.

Morphic.js is written by Jens Mönig (jens@moenig.org), Copyright (C) 2013 by Jens Mönig.



##Contents of this guide##



* Ch.1 **History of Morphic** where does Morphic come from.

* Ch.1 **Hierarchy** explains what a Morph is and which classes extend it.

* Ch.2 **Yet to implement** gives some ideas on what could be next.

* Ch.3 **Open issues** elaborates on some of the current "problems".

* Ch.4 **Browser compatibility** lists the browsers that can successfully run Zombie Kernel

* Ch.5 **The big picture** explains

* Ch.6 **Setting up words**

    * Ch.6.1 **Setting up a web page - basics** shows the basic steps of how to create worlds

    * Ch.6.2 **Setting up a web page for single world** shows how to create a simple world with one html file

    * Ch.6.3 **Setting up a web page for multiple worlds** illustrates how to put more than one world in the same page.

    * Ch.6.4 **Setting up an application**, i.e. how to make your world to run and host an application.

* Ch.7 **Manipulating morphs**

* Ch.8 **Events**

    * Ch.8.1 **Mouse events**

        * Ch.8.1.1 **Mouse events - context menu**

        * Ch.8.1.2 **Mouse events - dragging**

        * Ch.8.1.3 **Mouse events - dropping**

        * Ch.8.1.4 **Mouse events - resize event**

    * Ch.8.2 **Keyboard events**

    * Ch.8.3 **Resize events**

    * Ch.8.4 **Combined mouse-keyboard events**

* Ch.9 **Stepping**

* Ch.10 **Creating new kinds of morphs**

* Ch.11 **Development and user modes**

* Ch.12 **Turtle graphics**

* Ch.13 **Damage list housekeeping**

* Ch.14 **Minifying morphic.js**

* Ch.15 **Aknowlegments and contributors**



#1. History of Morphic#

As mentioned, Zombie Kernel is based on Morphic.js, which is an implementation of an existing UI framework from the late 90s called Morphic.

What makes Morphic special is that it's a) a direct manipulation system, b) it's highly compositive and c) it's highly orthogonal.

What a) means is that the user can compose and decompose UIs (and their behaviour) by direct manipulation of what she sees on her desktop (as opposed to only via scripting). Think of it as a glorified powerpoint system, where one can add/remove/modify widgets just by clicking around. For example one can attach/detach a slider from a window by just hovering over it, right-clicking and selecting the "pick up" option from the menu. b) "highly compositive" means that any part of the system is made from a few common building blocks, which at the basic level consist of little more than simple shapes. For example the menu is not a special bar with particular privileges - it's just a list of strings. A window is basically a rounded rectangle with some added behaviours.

"Highly-compositive" entails that any widget mostly consists of piecing together simple components,  meaning that the actual specific code for a new widget is small. Hence the "size" of the entire system is limited - Morphic.js and Zombie Kernel can be totally read and understood in a week-end. c) Highly-orthogonal means that any group of elements attempts to respond to the same operations that the basic elements respond to.

An example of this is the following: in powerpoint, when one creates a rectangle shape one expects at the very minimum to be able to stick it anywhere in the background of the slide. Beyond that, it follows that one can stick the same rectangle on any other shape or group of shapes. Similarly, in Morphic one can create a rectangle and stick it on the desktop, or inside any other shape. Since applies to a rectangle applies to any other widget, so one can stick a window inside a scrollable panel for example. Compare that to mainstream windowing system: can one normally drag a window and stick it inside another window?



#1. Hierarchy#





The following tree lists all constructors hierarchically, indentation indicating inheritance. Refer to this list to get a contextual overview:







- Point

- Rectangle

- Color

- Node

- Morph

    -  BlinkerMorph

    -  CaretMorph

    -  BouncerMorph*

    -  BoxMorph

    -  InspectorMorph

    -  MenuMorph

    -  MouseSensorMorph*

    -  SpeechBubbleMorph

    -  CircleBoxMorph

        -  SliderButtonMorph

        -  SliderMorph

    - ColorPaletteMorph

        -  GrayPaletteMorph

    - ColorPickerMorph

    - FrameMorph

        - ScrollFrameMorph

            -  ListMorph

        - StringFieldMorph

        - WorldMorph

    - HandleMorph

    - HandMorph

    - PenMorph

    - ShadowMorph

    - StringMorph

    - TextMorph

    - TriggerMorph

        -  MenuItemMorph





#2. Yet to implement#



Keyboard support for scroll frames and lists.







#3. Open issues#



Blurry shadows don't work well in Chrome.







#4. Browser compatibility#



Great care and considerable effort has been taken to make morphic.js runnable and appearing exactly the same on all current browsers:





- Firefox for Windows

- Firefox for Mac

- Chrome for Windows (blurry shadows have some issues)

- Chrome for Mac

- Safari for Windows

- Safari for Mac

- Safari for iOS (mobile)

- IE for Windows

- Opera for Windows

- Opera for Mac







#5. The big picture#



Morphic.js is completely based on Canvas and JavaScript, it is just Morphic, nothing else. Morphic.js is very basic and covers only the bare essentials:





  * a stepping mechanism (a time-sharing multiplexer for lively user interaction  ontop of a single OS/browser thread)



  * progressive display updates (only dirty rectangles are redrawn in each display cycle)



  * a tree structure



  * a single World per Canvas element (although you can have multiple worlds in multiple Canvas elements on the same web page)



  * a single Hand per World (but you can support multi-touch events)



  * a single text entry focus per World





In its current state morphic.js doesn't support Transforms (you cannot rotate Morphs), but with PenMorph there already is a simple LOGO-like turtle that you can use to draw onto any Morph it is attached to. I'm planning to add special Morphs that support these operations later on, but not for every Morph in the system.

Therefore these additions ("sprites" etc.) are likely to be part of other libraries ("microworld.js") in separate files.





The purpose of morphic.js is to provide a malleable framework that will let me experiment with lively GUIs for my hobby horse, which is drag-and-drop, blocks based programming languages. Those things (BYOB4 - http://byob.berkeley.edu) will be written using morphic.js as a library.







#6. Setting up words#



Morphic.js provides a library for lively GUIs inside single HTML Canvas elements. Each such canvas element functions as a "world" in which other visible shapes ("morphs") can be positioned and manipulated, often directly and interactively by the user. Morphs are tree nodes and may contain any number of submorphs ("children").



All things visible in a morphic World are morphs themselves, i.e. all text rendering, blinking cursors, entry fields, menus, buttons, sliders, windows and dialog boxes etc. are created with morphic.js rather than using HTML DOM elements, and as a consequence can be changed and adjusted by the programmer regardless of proprietary browser behavior.



Each World has an - invisible - "Hand" resembling the mouse cursor (or the user's finger on touch screens) which handles mouse events, and may also have a keyboardEventsReceiver to handle key events.



The basic idea of Morphic is to continuously run display cycles and to incrementally update the screen by only redrawing those  World regions which have been "dirtied" since the last redraw. Before each shape is processed for redisplay it gets the chance to perform a "step" procedure, thus allowing for an illusion of concurrency.





##1. Setting up a web page - basics##



Setting up a web page for Morphic always involves three steps: adding one or more Canvas elements, defining one or more worlds, initializing and starting the main loop.





##2. Setting up a web page for single world##



Most commonly you will want your World to fill the browsers's whole client area. This default situation is easiest and most straight forward.



Example html file:



    <!DOCTYPE html>  

    <html>

      <head>

        <title>Morphic!</title>

        <script type="text/javascript" src="morphic.js"></script>

        <script type="text/javascript">

    

          var world;

    

          window.onload = function () {

            world = new WorldMorph(

              document.getElementById('world'));

            setInterval(loop, 50);

          };

    

          function loop() {

            world.doOneCycle();

          }

    

        </script>

      </head>

      <body>

    

        <canvas id="world" tabindex="1" width="800" height="600">

          <p>Your browser doesn't support canvas.</p>

        </canvas>

    

      </body>

    </html>







if you use ScrollFrames or otherwise plan to support mouse wheel scrolling events, you might also add the following inline-CSS attribute to the Canvas element:



    style="position: absolute;"



which will prevent the World to be scrolled around instead of the elements inside of it in some browsers.





##3. Setting up multiple worlds##



If you wish to create a web page with more than one world, make sure to prevent each world from auto-filling the whole page and include	it in the main loop. It's also a good idea to give each world its own tabindex:



Example html file:



    <!DOCTYPE html>

    <html>

      <head>

        <title>Morphic!</title>

        <script type="text/javascript" src="morphic.js"></script>

        <script type="text/javascript">

    

          var world1, world2;

    

          window.onload = function () {

            world1 = new WorldMorph(document.getElementById('world1'), false);

            world2 = new WorldMorph(document.getElementById('world2'), false);

            setInterval(loop, 50);

          };

    

    

          function loop() {

            world1.doOneCycle();

            world2.doOneCycle();

          }

    

        </script>

      </head>

      <body>

    

        <p>first world:</p>

    

        <canvas id="world1" tabindex="1" width="600" height="400">

          <p>Your browser doesn't support canvas.</p>

        </canvas>

    

        <p>second world:</p>

    

        <canvas id="world2" tabindex="2" width="400" height="600">

          <p>Your browser doesn't support canvas.</p>

        </canvas>

    

      </body>

    </html>





##4. Setting up an application##



Of course, most of the time you don't want to just plain use the standard Morhic World "as is" out of the box, but write your own application (something like Scratch!) in it. For such an application you'll create your own morph prototypes, perhaps assemble your own "window frame" and bring it all to life in a customized World state. the following example creates a simple snake-like mouse drawing game.



Example html file:



    <!DOCTYPE html>

    <html>

      <head>

        <title>touch me!</title>

        <script type="text/javascript" src="morphic.js"></script>

        <script type="text/javascript">

    

          var worldCanvas, sensor;

    

          window.onload = function () {

    

            var x, y, w, h;

            worldCanvas = document.getElementById('world');

            world = new WorldMorph(worldCanvas);

            world.isDevMode = false;

            world.color = new Color();

    

            w = 100;

            h = 100;

    

            x = 0;

            y = 0;

    

            while ((y * h) < world.height()) {

              while ((x * w) < world.width()) {

    

                sensor = new MouseSensorMorph();

                sensor.setPosition(new Point(x * w, y * h));

                sensor.alpha = 0;

                sensor.setExtent(new Point(w, h));

                world.add(sensor);

                x += 1;

    

              }

              

              x = 0;

              y += 1;

    

            }

            setInterval(loop, 50);

          };

    

    

          function loop() {

            world.doOneCycle();

          }

    

        </script>

      </head>

    

      <body bgcolor='black'>

        <canvas id="world" width="800" height="600">

          <p>Your browser doesn't support canvas.</p>

        </canvas>

      </body>

    </html>







To get an idea how you can craft your own custom morph prototypes I've included two examples which should give you an idea how to add properties, override inherited methods and use the stepping mechanism for "livelyness": **BouncerMorph** and **MouseSensorMorph**.



For the sake of sharing a single file I've included those examples in morphic.js itself. Usually you'll define your additions in a separate file and keep morphic.js untouched.





#7. Manipulating morphs#



There are many methods to programmatically manipulate morphs. Among the most important and common ones among all morphs are the following nine:



* hide()

* show()



* setPosition(aPoint)

* setExtent(aPoint)

* setColor(aColor)



* add(submorph)			- attaches submorph ontop

* addBack(submorph)		- attaches submorph underneath



* fullCopy()			- duplication

* destroy()				- deletion



#8. Events#



All user (and system) interaction is triggered by events, which are passed on from the root element - the World - to its submorphs. The World contains a list of system (browser) events it reacts to in its



    initEventListeners()



method. Currently there are:



  - mouse

  - touch

  - drop

  - keyboard

  - (window) resize



events.





##8.1 Mouse events##



The Hand dispatches the following mouse events to relevant morphs:



  - mouseDownLeft

  - mouseDownRight

  - mouseClickLeft

  - mouseClickRight

  - mouseEnter

  - mouseLeave

  - mouseEnterDragging

  - mouseLeaveDragging

  - mouseMove

  - mouseScroll



If you wish your morph to react to any such event, simply add a method of the same name as the event, e.g:



    MyMorph.prototype.mouseMove = function(pos) {};



The only optional parameter of such a method is a Point object indicating the current position of the Hand inside the World's coordinate system.



Events may be "bubbled" up a morph's owner chain by calling



    this.escalateEvent(functionName, arg)



in the event handler method's code.



Likewise, removing the event handler method will render your morph passive to the event in question.





###8.1.1 Context menu###



By default right-clicking (or single-finger tap-and-hold) on a morph also invokes its context menu (in addition to firing the mouseClickRight event). A morph's context menu can be customized by assigning a Menu instance to its **customContextMenu**. property, or altogether suppressed by overriding its inherited **contextMenu()** method.





###8.1.2 Dragging###



Dragging a morph is initiated when the left mouse button is pressed, held and the mouse is moved.





You can control whether a morph is draggable by setting its **isDraggable** property either to false or true. If a morph isn't draggable itself it will pass the pick-up request up its owner chain. This lets you create draggable composite morphs like Windows, DialogBoxes, Sliders etc.



Sometimes it is desireable to make "template" shapes which cannot be moved themselves, but from which instead duplicates can be peeled off. This is especially useful for building blocks in construction kits, e.g. the MIT-Scratch palette. Morphic.js lets you control this functionality by setting the **isTemplate** property flag to true for any morph whose "isDraggable" property is turned off. When dragging such a Morph the hand will instead grab a duplicate of the template whose "isDraggable" flag is true and whose "isTemplate" flag is false, in other words: a non-template.



Dragging is indicated by adding a drop shadow to the morph in hand. If a morph follows the hand without displaying a drop shadow it is merely being moved about without changing its parent (owner morph), e.g. when "dragging" a morph handle to resize its owner, or when "dragging" a slider button.



Right before a morph is picked up its **prepareToBeGrabbed(handMorph)** method is invoked, if it is present. Immediately after the pick-up the former parent's **reactToGrabOf(grabbedMorph)** method is called, again only if it exists.



Similar to events, these  methods are optional and don't exist by default. For a simple example of how they can be used to adjust scroll bars in a scroll frame please have a look at their implementation in FrameMorph.





###8.1.3 Dropping###



Dropping is triggered when the left mouse button is either pressed or released while the Hand is dragging a morph.



Dropping a morph causes it to become embedded in a new owner morph.



You can control this embedding behavior by setting the prospective drop target's **acceptsDrops** property to either true or false, or by overriding its inherited **wantsDropOf(aMorph)** method.





Right after a morph has been dropped its **justDropped(handMorph)** method is called, and its new parent's **reactToDropOf(droppedMorph, handMorph)** method is invoked, again only if each method exists.





Similar to events, these  methods are optional and by default are not present in morphs by default (watch out for inheritance, though!). For a simple example of how they can be used to adjust scroll bars in a scroll frame please have a look at their implementation in FrameMorph.



Drops of image elements from outside the world canvas are dispatched as **droppedImage(aCanvas, name)** and **droppedSVG(anImage, name)** events to interested Morphs at the mouse pointer. If you want you Morph to e.g. import outside images you can add the droppedImage() and / or the droppedSVG() methods to it. The parameter passed to the event handles is a new offscreen canvas element representing a copy of the original image element which can be directly used, e.g. by assigning it to another Morph's image property. In the case of a dropped SVG it is an image element (not a canvas), which has to be rasterized onto a canvas before it can be used. The benefit of handling SVGs as image elements is that rasterization can be deferred until the destination scale is known, taking advantage of SVG's ability for smooth scaling. If instead SVGs are to be rasterized right away, you can set the **MorphicPreferences.rasterizeSVGs** preference to <true>. In this case dropped SVGs also trigger the droppedImage() event with a canvas containing a rasterized version of the SVG.



The same applies to drops of audio or text files from outside the world canvas.



Those are dispatched as  



    droppedAudio(anAudio, name)

    droppedText(aString, name)



events to interested Morphs at the mouse pointer.



##8.1 Keyboard events##



Keyboard events are:



  - keypress

  - keydown

  - keyup



These are caught by either the Canvas or, in the case of touch devices, by a hidden textbox (which needs to be in focus so that the virtual keyboard is brought up). Either case, the keyboard events are dispatched to the active keyboardEventsReceiver.



Currently the only morph which acts as keyboard receiver is CaretMorph, the basic text editing widget. If you wish to add keyboard support to your morph you need to add event handling methods for



  - processKeyPress(event)

  - processKeyDown(event)

  - processKeyUp(event)



and activate them by assigning your morph to the World's **keyboardEventsReceiver** property.



Note that processKeyUp() is optional and doesn't have to be present if your morph doesn't require it.



##8.3 Resize events##



The Window resize event is handled by the World and allows the World's extent to be adjusted so that it always completely fills the browser's visible page. You can turn off this default behavior by setting the World's **useFillPage** property to false.



Alternatively you can also initialize the World with the useFillPage switch turned off from the beginning by passing the false value as second parameter to the World's constructor:



    world = new World(aCanvas, false);



Use this when creating a web page with multiple Worlds.



if "useFillPage" is turned on the World dispatches an **reactToWorldResize(newBounds)** events to all of its children (toplevel only), allowing each to adjust to the new World bounds by implementing a corresponding method, the passed argument being the World's new dimensions after completing the resize. By default, the "reactToWorldResize" Method does not exist.



Example:



Add the following method to your Morph to let it automatically fill the whole World, but leave a 10 pixel border uncovered:



    MyMorph.prototype.reactToWorldResize = function (rect) {

      this.changed();

      this.bounds = rect.insetBy(10);

      this.drawNew();

      this.changed();

    };





##8.4 Combined mouse-keyboard events##



Occasionally you'll want an object to react differently to a mouse click or to some other mouse event while the user holds down a key on the keyboard. Such "shift-click", "ctl-click", or "alt-click" events can be implemented by querying the World's **currentKey** property inside the function that reacts to the mouse event. This property stores the keyCode of the key that's currently pressed.

Once the key is released by the user it reverts to null.





#9 Stepping#



Stepping is what makes Morphic "magical". Two properties control a morph's stepping behavior: the fps attribute and the step() method.



By default the **step()** method does nothing. As you can see in the examples of BouncerMorph and MouseSensorMorph you can easily override this inherited method to suit your needs.



By default the step() method is called once per display cycle.



Depending on the number of actively stepping morphs and the complexity of your step() methods this can cause quite a strain on your CPU, and also result in your application behaving differently on slower computers than on fast ones.



Setting **myMorph.fps** to a number lower than the interval for the main loop lets you free system resources (albeit at the cost of a less responsive or slower behavior for this particular morph).





#10. Creating new kinds of morphs#



The real fun begins when you start to create new kinds of morphs with customized shapes. Imagine, e.g. jigsaw puzzle pieces or musical notes. For this you have to override the default **drawNew()** method.



This method creates a new offscreen Canvas and stores it in the morph's **image** property.



Use the following template for a start:



    MyMorph.prototype.drawNew = function() {

      var context;

      this.image = newCanvas(this.extent());

      context = this.image.getContext('2d');

      // use context to paint stuff here

    };



If your new morph stores or references other morphs outside of the submorph tree in other properties, be sure to also override the default **copyRecordingReferences()** method accordingly if you want it to support duplication.



#11 Development and user modes#



When working with Squeak on Scratch or BYOB among the features I like the best and use the most is inspecting what's going on in the World while it is up and running. That's what development mode is for (you could also call it debug mode). In essence development mode controls which context menu shows up. In user mode right clicking (or double finger tapping) a morph invokes its **customContextMenu** property, whereas in development mode only the general **developersMenu()** method is called and the resulting menu invoked. The developers' menu features Gui-Builder-wise functionality to directly inspect, take apart, reassamble and otherwise manipulate morphs and theircontents.



Instead of using the "customContextMenu" property you can also assign a more dynamic contextMenu by overriding the general **userMenu()** method with a customized menu constructor. The difference between the customContextMenu property and the userMenu() method is that the former is also present in development mode and overrides the developersMenu() result. For an example of how to use the customContextMenu property have a look at TextMorph's evaluation menu, which is used for the Inspector's evaluation pane.



When in development mode you can inspect every Morph's properties with the inspector, including all of its methods. The inspector also lets you add, remove and rename properties, and even edit their values at runtime. Like in a Smalltalk environment the inspect features an evaluation pane into which you can type in arbitrary JavaScript code and evaluate it in the context of the inspectee.



Use switching between user and development modes while you are developing an application and disable switching to development once you're done and deploying, because generally you don't want to confuse end-users with inspectors and meta-level stuff.



#12 Turtle graphics#



The basic Morphic kernel features a simple LOGO turtle constructor called **PenMorph** , which you can use to draw onto its parent Morph. By default every Morph in the system (including the World) is able to act as turtle canvas and can display pen trails. Pen trails will be lost whenever the trails morph (the pen's parent) performs a "drawNew()" operation. If you want to create your own pen trails canvas, you may wish to modify its **penTrails()** property, so that it keeps a separate offscreen canvas for pen trails (and doesn't loose these on redraw).



The following properties of PenMorph are relevant for turtle graphics:



  - color		, a Color

  - size		, line width of pen trails

  - heading	, degrees

  - isDown	, drawing state



The following commands can be used to actually draw something:



  - up()		, lift the pen up, further movements leave no trails

  - down()	, set down, further movements leave trails

  - clear()	, remove all trails from the current parent

  - forward(n) , move n steps in the current direction (heading)

  - turn(n) , turn right n degrees



Turtle graphics can best be explored interactively by creating a new PenMorph object and by manipulating it with the inspector widget.



NOTE: PenMorph has a special optimization for recursive operations called **warp(function)**.



You can significantly speed up recursive ops and increase the depth of recursion that's displayable by wrapping WARP around your recursive function call:



Example:



    myPen.warp(function () {

      myPen.tree(12, 120, 20);

    })



will be much faster than just invoking the tree function, because it prevents the parent's parent from keeping track of every single line segment and instead redraws the outcome in a single pass.





#13 Damage list housekeeping#



Morphic's progressive display update comes at the cost of having to cycle through a list of "broken rectangles" every display cycle. If this list gets very long working this damage list can lead to a seemingly dramatic slow-down of the Morphic system. Typically this occurs when updating the layout of complex Morphs with very many submorphs, e.g. when resizing an inspector window.



An effective strategy to cope with this is to use the inherited **trackChanges** property of the Morph prototype for damage list housekeeping.



The trackChanges property of the Morph prototype is a Boolean switch that determines whether the World's damage list ('broken' rectangles) tracks changes. By default the switch is always on. If set to false changes are not stored. This can be very useful for housekeeping of the damage list in situations where a large number of (sub-) morphs are changed more or less at once. Instead of keeping track of every single submorph's changes tremendous performance improvements can be achieved by setting the trackChanges flag to false before propagating the layout changes, setting it to true again and then storing the full bounds of the surrounding morph. An an example refer to the **moveBy()** method of HandMorph, and to the **fixLayout()** method of InspectorMorph, or the



  - startLayout()

  - endLayout()



methods of SyntaxElementMorph in the Snap application.	



 

#14 Minifying morphic.js#



Coming from Smalltalk and being a Squeaker at heart I am a huge fan of browsing the code itself to make sense of it. Therefore I have included this documentation and (too little) inline comments so all you need to get going is this very file.



Nowadays with live streaming HD video even on mobile phones 250 KB shouldn't be a big strain on bandwith, still minifying and even compressing morphic.js down do about 100 KB may sometimes improve performance in production use.



Being an attorney-at-law myself you programmer folk keep harassing me with rabulistic nitpickings about free software licenses. I'm releasing morphic.js under an AGPL license. Therefore please make sure to adhere to that license in any minified or compressed version.





#15 Aknowlegments and contributors#



The original Morphic was designed and written by Randy Smith and John Maloney for the SELF programming language, and later ported to Squeak (Smalltalk) by John Maloney and Dan Ingalls, who has also ported it to JavaScript (the Lively Kernel), once again setting a "Gold Standard" for self sustaining systems which morphic.js cannot and does not aspire to meet.



This Morphic implementation for JavaScript is not a direct port of Squeak's Morphic, but still many individual functions have been ported almost literally from Squeak, sometimes even including their comments, e.g. the morph duplication mechanism fullCopy(). Squeak has been a treasure trove, and if morphic.js looks, feels and smells a lot like Squeak, I'll take it as a compliment.



Evelyn Eastmond has inspired and encouraged me with her wonderful implementation of DesignBlocksJS. Thanks for sharing code, ideas and enthusiasm for programming.



John Maloney has been my mentor and my source of inspiration for these Morphic experiments. Thanks for the critique, the suggestions and explanations for all things Morphic and for being my all time programming hero.



I have originally written morphic.js in Florian Balmer's Notepad2 editor for Windows and later switched to Apple's Dashcode. I've also come to depend on both Douglas Crockford's JSLint, Mozilla's Firebug and Google's Chrome to get it right.





###Contributors###



- Joe Otto found and fixed many early bugs and taught me some tricks.

- Nathan Dinsmore contributed mouse wheel scrolling, cached background texture handling and countless bug fixes.

- Ian Reynolds contributed backspace key handling for Chrome.


