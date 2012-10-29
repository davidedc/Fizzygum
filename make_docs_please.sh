rake

# unfortunately the -o option of docco doesn't work
cd docs
rm -r docco-code-commentary
docco ../src/*.coffee
docco ../build/morphee-coffee.coffee
mv ./docs ./docco-code-commentary

cd ..
cd buildSystem
python generateOverviewDoc.py
pandoc -s -S --toc -c pandoc.css ../docs/overview/filteredCommentsForReadableStandaloneDoc.md -o ../docs/overview/overview.html

# go back to the root directory
cd ../
coffeedoc -o ./docs/quick-api-reference ./build/morphee-coffee.coffee
codo -o ./docs/detailed-api-reference ./src/*.coffee
