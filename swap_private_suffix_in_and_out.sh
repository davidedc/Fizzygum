# when we work from a private repo, we work in
# directories that have a "-private" suffix.
#
# Since the other scripts only work WITHOUT those
# suffixes, this script conveniently swaps the suffixes
# out.
#
# Since committing only works from the directories
# WITH the -private suffix, again this script
# adds the suffix if not there.

if [ ! -d ../../Zombie-Kernel ]; then
  echo
  echo ----------- error -------------
  echo You miss the overarching Zombie-Kernel directory.
  echo Please check the helper script that sorts this out
  echo for you, and the docs for
  echo what the directory structure for
  echo building Zombie-Kernel should be, here:
  echo '\t'http://
  echo
  exit
fi

if [ -d ../Zombie-Kernel-builds-private ]; then
  if [ -d ../Zombie-Kernel-core-private ]; then
    if [ -d ../Zombie-Kernel-tests-private ]; then
      mv ../Zombie-Kernel-builds-private ../Zombie-Kernel-builds
      mv ../Zombie-Kernel-tests-private ../Zombie-Kernel-tests
      mv ../Zombie-Kernel-core-private ../Zombie-Kernel-core
      cd ~/Zombie-Kernel/Zombie-Kernel-core
      exit
    fi
  fi
fi

if [ -d ../Zombie-Kernel-builds ]; then
  if [ -d ../Zombie-Kernel-core ]; then
    if [ -d ../Zombie-Kernel-tests ]; then
      mv ../Zombie-Kernel-builds ../Zombie-Kernel-builds-private
      mv ../Zombie-Kernel-tests ../Zombie-Kernel-tests-private
      mv ../Zombie-Kernel-core ../Zombie-Kernel-core-private
      cd ~/Zombie-Kernel/Zombie-Kernel-core-private
      exit
    fi
  fi
fi