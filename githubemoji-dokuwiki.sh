#!/bin/bash

# Exit on errors, and display all commands that are run.
set -e

printhelp () {
	echo "Usage: $0 <path>"
	echo "Generates the set of files required to enable the Github emoji set on a Dokuwiki installation."
	cat << EOM
<path> is the path to a directory where the generated files are stored.

* If you do not use any custom smileys, then you can copy over the generated
  content directly to your Dokuwiki installation.

  * If you have direct filesystem access to your server, you can invoke this
    script directly as shown (assuming /opt/server/htdocs/wiki is the path in
	which Dokuwiki is installed.

	./githubemoji-dokuwiki.sh /opt/server/htdocs/wiki

* If you are currently using some custom smileys, only copy over data/ and lib/
  to your Dokuwiki install. Then, append the contents of
  conf/smileys.local.conf to the conf/smileys.local.conf on your Dokuwiki
  install.

* If you are upgrading this emoji set and only use the Github emoji set smileys
  generated from the script, you can overwrite as described in point 1.

* If you are upgrading this emoji set and use the Github emoji set along with
  custom smileys, then, copy over data/ and lib/ as described in point 2, but
  in this case, remove the Github emoji section in conf/smileys.local.conf of
  your Dokuwiki install, and add the contents of your locally generated
  conf/smileys.local.conf to the one in your Dokuwiki install.

* A list of the emojis can be viewed under wiki:github_emojis.

* Remember to purge your cache after installing, otherwise the emojis may not
  work.
EOM

}

bail () {
	echo "$1" >&2
	if [[ $2 -gt 0 ]]; then
		exit $2
	else
		exit 1
	fi
}

if [[ -z "$1" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
	printhelp
	exit 0
fi

deps=("git" "convert")
pkgs=("git" "imagemagick")

for ((i = 0; i < ${#deps[@]}; i++)); do
	if ! which "${deps[i]}" &>/dev/null; then
		bail "The program ${deps[i]} is not installed. Please install ${pkgs[i]} and try again."
	fi
done

if ! dest_dir="$(cd "$1" && pwd -P)"; then
	echo "$dest_dir"
	bail "Destination directory does not exist."
fi

cd "$(mktemp -d /tmp/githubemoji-dokuwiki.XXXXXXXX)"

echo "Retrieving smiley data..."
git clone "https://github.com/arvida/emoji-cheat-sheet.com.git" --depth 1 > /dev/null

echo "Creating the necessary file structure..."
mkdir -p dokuwiki/conf dokuwiki/lib/images/smileys/ghemojis dokuwiki/data/pages/wiki/
mv emoji-cheat-sheet.com/public/graphics/emojis/* dokuwiki/lib/images/smileys/ghemojis

echo "Resizing images..."
cd dokuwiki/lib/images/smileys/ghemojis
while read f; do
	convert "$f" -resize 22x22 "$f"
done < <(find . -type f | sed 's~./~~g')

cd -

echo "Parsing smiley data..."
grep '<img src="graphics/emojis' emoji-cheat-sheet.com/public/index.html | sed -r 's~.*src="(graphics/emojis/[a-z0-9+_.-]+)"~\1~gI;s~>.*class=\"name\"[^>]*>([^<]+).*~ :\1:~gI' > smiley-data.txt

if [[ "$(grep -Eo '^graphics/emojis/[a-z0-9+_.-]+ :[a-z0-9_+-]+:$' smiley-data.txt | cksum)" != "$(cksum < smiley-data.txt)" ]] && [[ "$(wc < smiley-data.txt)" -eq 0 ]]; then
	bail "The HTML parsing did not generate expected results. This is likely caused due to a change in the HTML structure."
fi

sed -ri 's~graphics/emojis~ghemojis~g;s~^(.*) (.*)~\2 \1~g' smiley-data.txt

echo "Generating configuration file..."
cp smiley-data.txt dokuwiki/conf/smileys.local.conf

sed -i "1i # =============== Github emoji section start =============== #" dokuwiki/conf/smileys.local.conf
sed -i "2i # This is a smiley configuration file for Dokuwiki that has been generated" dokuwiki/conf/smileys.local.conf
sed -i "3i # automatically by githubemoji-dokuwiki. It is not recommended to edit this" dokuwiki/conf/smileys.local.conf
sed -i "4i # file directly." dokuwiki/conf/smileys.local.conf
echo "# =============== Github emoji section end =============== #" >> dokuwiki/conf/smileys.local.conf

echo "Generating test page..."
grep -Eo '^:[a-z0-9_+-]+:' smiley-data.txt | sed -r 's~^(.*)$~  * \1 %% \1 %%~g' > dokuwiki/data/pages/wiki/github_emojis.txt

sed -i "1i ====== Github Emojis ======" dokuwiki/data/pages/wiki/github_emojis.txt
sed -i "2i This page lists all the Github emojis installed on your Dokuwiki install." dokuwiki/data/pages/wiki/github_emojis.txt
sed -i "3i ===== List of emojis =====" dokuwiki/data/pages/wiki/github_emojis.txt

cp -r dokuwiki/* "$dest_dir/"

echo "The files have been generated in $dest_dir. If you do not know how to install them into your Dokuwiki install, please type in \`$0 -h' for instructions."


