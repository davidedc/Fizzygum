Zombie Kernel uses an inexpensive external number keypad to help recording tests by triggering operations (such as take a snapshot of the screen, check the pixel color under the pointer, check the string currently under the pointer, etc.).

It's simpler (from a usage perspective) to issue special commands during a test recording by pressing these dedicated external keys (and stick custom labels on the keys so to remember quickly which one to press) rather than odd character combinations on the main keyboard.

The external keypad I use is http://www.amazon.co.uk/Perixx-PERIPAD-201PLUS-Numeric-Keypad-Laptop/dp/B001R6FZLU/

This private.xml file is used by a program called keyremap4macbook (it's free) to remap these external keys into very strange (to me) Thai characters. The point being to map into rarely-used characters that are not likely to be used often - you can change these mappings if you want to.

These Thai characters are then treated in a special way by Zombie Kernel so to do any wanted special operations.

Note that private.xml contains the special product and vendor ID that are specific of the keypad, so that the remapping only happend for that keypad (which also means that in theory one could add more than one keypad as well) - so you might want to change those. keyremap4macbook includes an Event-viewer tool to find out those two codes.

In order to remap those keys to special Thai characters, the Thai keyboard must be enabled in System Preferences (which is easy to do). When an external keypad key is pressed, keyremap4macbook switches from the normal keyboard layout to the Thai keypad, sends the wanted key, and then switches back the keyboard to the normal one.

The effect is that special Thai chars are sent to any wanted app to be processed as wished.

The only additional complication is that these inexpensive keypads often have an additional "00" key. This key actually sends two "0" keypresses. So some special logic needs to be added in the app to process such "double keys" of whatever special Thai char the "0" button is mapped to, so that the "00" can be detected as a separate command. This double-key processing cannot be done with keyremap4macbook or other shortcut software I found - because the first char of the two gets through all of those - so the app-logic solution seems to be the only way.