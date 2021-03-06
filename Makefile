.PHONY: watch all chrome notifyfailure clean

watch:
	# you must install entr to watch for changes
	find . -maxdepth 1 -not -type d | entr ${MAKE} all

all:
	${MAKE} chrome || ${MAKE} notifyfailure

chrome: backmark.js popup.js common.js templates.js acceptDanger.js detector.js
	rm -rf build/chrome
	mkdir -p build/chrome
	cp -r lib/*.* assets/*.png *.* build/chrome/
	rm -f build/chrome/extension.zip
	rm -f build/chrome/screenshot.png
	cd build/chrome && zip -1 extension.zip *

backmark.js: backmark.coffee
	coffee -c -b -m backmark.coffee

popup.js: popup.coffee
	coffee -c -b -m popup.coffee

common.js: common.coffee
	coffee -c -b -m common.coffee

acceptDanger.js: acceptDanger.coffee
	coffee -c -b -m acceptDanger.coffee

detect.js: detect.coffee
	coffee -c -b -m detect.coffee

templates.js: popup-bookmark.handlebars *.handlebars
	# you must install handlebars with npm to precompile templates
	handlebars -m *.handlebars -f templates.js

detector.js: lib/jquery-2.1.4.min.js lib/lodash.min.js detect.js
	# concatenates deps at top for injection
	cat lib/jquery-2.1.4.min.js lib/lodash.min.js detect.js > detector.js

notifyfailure:
	osascript -e 'display notification "failed" with title "make"'

clean:
	rm -r build
	rm *.js *.js.map
