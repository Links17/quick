.PHONY: build test app clean

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

clean:
	rm -rf .build dist
