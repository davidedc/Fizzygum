if [ ! -d ../Fizzygum-builds ]; then
  echo
  echo ----------- warning! -------------
  echo You miss the destination Fizzygum-builds directory.
  exit
fi

unzip -o ~/Downloads/pre-compiled.zip -d ../Fizzygum-builds/latest/js/
uglifyjs --compress --output ../Fizzygum-builds/latest/js/pre-compiled.js -- ../Fizzygum-builds/latest/js/pre-compiled.js

say precompiled
echo done!!!!!!!!!!!!