.PHONY: build test app zip dmg install clean

build:
	swift build

test:
	swift test

app:
	swift build -c release
	rm -rf dist/Quick.app
	mkdir -p dist/Quick.app/Contents/MacOS
	mkdir -p dist/Quick.app/Contents/Resources
	cp .build/release/Quick dist/Quick.app/Contents/MacOS/Quick
	cp AppBundle/Info.plist dist/Quick.app/Contents/Info.plist
	chmod +x dist/Quick.app/Contents/MacOS/Quick

zip: app
	cd dist && ditto -c -k --sequesterRsrc --keepParent Quick.app Quick.app.zip

dmg: app
	rm -rf dist/dmg-root
	mkdir -p dist/dmg-root
	cp -R dist/Quick.app dist/dmg-root/Quick.app
	ln -s /Applications dist/dmg-root/Applications
	rm -f dist/Quick.dmg
	hdiutil create -volname Quick -srcfolder dist/dmg-root -ov -format UDZO dist/Quick.dmg

install: app
	rm -rf /Applications/Quick.app
	cp -R dist/Quick.app /Applications/Quick.app

clean:
	rm -rf .build dist
