rake

# unfortunately the -o option of docco doesn't work
cd docs
rm -r docco-code-commentary
docco ../src/*.coffee
docco ../build/morphee-coffee.coffee
mv ./docs ./docco-code-commentary

# go back to the root directory
cd ../
coffeedoc -o ./docs/quick-api-reference ./build/morphee-coffee.coffee
codo -o ./docs/detailed-api-reference ./src/*.coffee
