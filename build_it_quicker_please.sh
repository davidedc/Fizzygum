rm src/morphee-coffee.coffee
rm build/*
#cat src/*.coffee >> src/morphee-coffee.coffee

cat src/morphicVersion.coffee >> src/morphee-coffee.coffee
cat src/globalFunctions.coffee >> src/morphee-coffee.coffee
cat src/globalSettings.coffee >> src/morphee-coffee.coffee
cat src/Color.coffee >> src/morphee-coffee.coffee
cat src/Point.coffee >> src/morphee-coffee.coffee
cat src/Rectangle.coffee >> src/morphee-coffee.coffee
cat src/MorphicNode.coffee >> src/morphee-coffee.coffee
cat src/Morph.coffee >> src/morphee-coffee.coffee
cat src/HandleMorph.coffee >> src/morphee-coffee.coffee
cat src/ShadowMorph.coffee >> src/morphee-coffee.coffee
cat src/PenMorph.coffee >> src/morphee-coffee.coffee
cat src/ColorPaletteMorph.coffee >> src/morphee-coffee.coffee
cat src/GrayPaletteMorph.coffee >> src/morphee-coffee.coffee
cat src/ColorPickerMorph.coffee >> src/morphee-coffee.coffee
cat src/BlinkerMorph.coffee >> src/morphee-coffee.coffee
cat src/CursorMorph.coffee >> src/morphee-coffee.coffee
cat src/BoxMorph.coffee >> src/morphee-coffee.coffee
cat src/SpeechBubbleMorph.coffee >> src/morphee-coffee.coffee
cat src/CircleBoxMorph.coffee >> src/morphee-coffee.coffee
cat src/MouseSensorMorph.coffee >> src/morphee-coffee.coffee
cat src/InspectorMorph.coffee >> src/morphee-coffee.coffee
cat src/MenuMorph.coffee >> src/morphee-coffee.coffee
cat src/StringMorph.coffee >> src/morphee-coffee.coffee
cat src/TextMorph.coffee >> src/morphee-coffee.coffee
cat src/TriggerMorph.coffee >> src/morphee-coffee.coffee
cat src/MenuItemMorph.coffee >> src/morphee-coffee.coffee
cat src/FrameMorph.coffee >> src/morphee-coffee.coffee
cat src/BouncerMorph.coffee >> src/morphee-coffee.coffee
cat src/HandMorph.coffee >> src/morphee-coffee.coffee
cat src/StringFieldMorph.coffee >> src/morphee-coffee.coffee
cat src/WorldMorph.coffee >> src/morphee-coffee.coffee
cat src/SliderButtonMorph.coffee >> src/morphee-coffee.coffee
cat src/SliderMorph.coffee >> src/morphee-coffee.coffee
cat src/ScrollFrameMorph.coffee >> src/morphee-coffee.coffee
cat src/ListMorph.coffee >> src/morphee-coffee.coffee
cat src/MorphsListMorph.coffee >> src/morphee-coffee.coffee

coffee -b -c -o build ./src/morphee-coffee.coffee 
cp src/morphee-coffee.html build
