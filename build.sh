#!/bin/sh
set -e -x
LAYOUT="Programmer Dvorak"
VERSION=1.2
COPYRIGHT="Copyright 1997--2012 (c) Roland Kaufmann"

# copy files from where this script is located
pushd $(dirname $0)
SRC_DIR="$(pwd)"
popd

# create a fakeroot directory and path therein
ROOT_DIR="$LAYOUT.tmp"
rm -rf "$ROOT_DIR"
mkdir -p "$ROOT_DIR/Library/Keyboard Layouts"
pushd "$ROOT_DIR/Library/Keyboard Layouts"

# Recipe by jagboy
# <http://hints.macworld.com/comment.php?mode=view&cid=60218>
mkdir "$LAYOUT.bundle"
mkdir "$LAYOUT.bundle/Contents"

cat >> "$LAYOUT.bundle/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>CFBundleIdentifier</key><string>com.apple.keyboardlayout.$LAYOUT</string>
<key>CFBundleName</key><string>$LAYOUT</string>
<key>CFBundleVersion</key><string>$VERSION</string>
</dict>
</plist>
EOF

cat >> "$LAYOUT.bundle/Contents/version.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>BuildVersion</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>ProjectName</key><string>$LAYOUT</string>
<key>SourceVersion</key><string>$VERSION</string>
</dict>
</plist>
EOF

mkdir "$LAYOUT.bundle/Contents/Resources"
cp "$SRC_DIR/$LAYOUT.keylayout" "$LAYOUT.bundle/Contents/Resources/"
# Install Keyboard Tools (needs Rosetta from Optional Installs) from:
# http://developer.apple.com/fonts/fonttools/AppleFontToolSuite3.1.0.dmg.zip
[ -x /usr/bin/klcompiler ] && /usr/bin/klcompiler "$SRC_DIR/$LAYOUT.keylayout" > /dev/null
if [ -e "$SRC_DIR/$LAYOUT.icns" ]; then
  cp "$SRC_DIR/$LAYOUT.icns" "$LAYOUT.bundle/Contents/Resources/";
fi

mkdir "$LAYOUT.bundle/Contents/Resources/English.lproj"
cat >> "$LAYOUT.bundle/Contents/Resources/English.lproj/InfoPlist.strings" <<EOF
NSHumanReadableCopyright = "$COPYRIGHT";
"$LAYOUT" = "$LAYOUT";
EOF

# bundle bit must be set on the directory for it to be recognized as a bundle
/Developer/Tools/SetFile -a B "$LAYOUT.bundle"

# leave fakeroot
popd

# create a package
# <http://www.manpagez.com/man/1/packagemaker/>
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker \
  -v \
  -k \
  -r "$ROOT_DIR" \
  -f "$ROOT_DIR/Library/Keyboard Layouts/$LAYOUT.bundle/Contents/Info.plist" \
  -o "$LAYOUT v$VERSION.pkg" \
  -n "$VERSION" \
  -t "$LAYOUT" \
  -x \\.DS_Store \
  -g 10.3 \
  -h system \

# final files that are uploaded should be without spaces
TRANSLATED=$(echo "$LAYOUT" | sed 's/\ //g')-$(echo "$VERSION" | sed 's/\./_/g')
rm -rf "$TRANSLATED.pkg.zip"
rm -rf "$TRANSLATED.src.zip"

# create a packed file from the directory (use -k for .zip)
ditto -c -k --noacl --sequesterRsrc --keepParent "$LAYOUT v$VERSION.pkg" "$TRANSLATED.pkg.zip"

# create source distribution
rm -rf "$LAYOUT.src"
mkdir "$LAYOUT.src"
cp "$SRC_DIR/$LAYOUT.keylayout" "$LAYOUT.src"
cp "$SRC_DIR/build.sh" "$LAYOUT.src"
ditto -c -k --noacl --sequesterRsrc "$LAYOUT.src" "$TRANSLATED.src.zip"

# sudo installer -pkg "$LAYOUT v$VERSION.pkg" -target /
# lsbom -fls "/var/db/receipts/com.apple.keyboardlayout.$LAYOUT.bom"

# uninstall:
# sudo rm -rf "/Library/Keyboard Layouts/$LAYOUT.bundle/"
# sudo rm "/var/db/receipts/com.apple.keyboardlayout.$LAYOUT.*"
# sudo rm /System/Library/Caches/com.apple.IntlDataCache.le*
# rm /private/var/folders/*/*/-Caches-/com.apple.IntlDataCache.le*
# sudo shutdown -r now
