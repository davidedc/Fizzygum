# fswatch doesn't come by default, look it up on github
fswatch -o ./src | xargs -n1 -I{} sh ./build_it_please.sh
