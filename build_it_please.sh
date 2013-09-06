rm build/*
rake
coffee -b -c -o build ./build/morphee-coffee.coffee 
cp src/morphee-coffee.html build
cp src/morphee-coffee-test-launcher.html build
# add these back if you want the minified build.
# The minified build makes all objects uninspectable
#cd buildSystem
#python build.py --all --minified