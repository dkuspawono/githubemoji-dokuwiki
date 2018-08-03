# githubemoji-dokuwiki

githubemoji-dokuwiki provides a shell script to help ease the installation of the Github emoji set on Dokuwiki. In particular, it is not a Dokuwiki extension, and instead uses the smilies functionality built inside Dokuwiki for this purpose.

## Prerequisites

git and imagemagick need to be installed on your system.

## Using the script

The script is invoked as:

	./githubemoji-dokuwiki.sh <path>

If you have direct access to the Dokuwiki install, and do not use any other smileys, you can set `<path>` to your Dokuwiki install. Otherwise, set `<path>` to a custom directory, run the script, and copy over `data/`, `lib/` and `conf/` to your Dokuwiki install.

Please run the script as `./githubemoji-dokuwiki.sh -h` for a very thorough explanation of the above.

