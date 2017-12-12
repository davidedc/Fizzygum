if [ ! -d ../Fizzygum-builds ]; then
  echo
  echo ----------- warning! -------------
  echo You miss the destination Fizzygum-builds directory.
  exit
fi

cp ~/Downloads/pre-compiled.zip ../Fizzygum-builds/latest/js
yes | unzip  ../Fizzygum-builds/latest/js/pre-compiled.zip -d ../Fizzygum-builds/latest/js/
rm  ../Fizzygum-builds/latest/js/pre-compiled.zip
uglifyjs --compress --output ../Fizzygum-builds/latest/js/pre-compiled.js -- ../Fizzygum-builds/latest/js/pre-compiled.js
