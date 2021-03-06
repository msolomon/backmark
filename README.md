# Backmark - Back up the pages you bookmark

A Google Chrome extension to automatically back up web pages you bookmark.

------------------------

Link rot is real. Stave off some of the damage by automatically backing up the pages you've bookmarked in Chrome.

Whenever you add a bookmark, Backmark will do its best to save a copy for you. You can then download it from an easy-to-use menu.


## Installation


### Chrome

Visit the [Chrome web store page](https://chrome.google.com/webstore/detail/backmark-back-up-the-page/cmbflafdbcidlkkdhbmechbcpmnbcfjf) and install the extension.


## Usage

Everything is done from an extension popup. It should be self explanatory.


## Known bugs and issues

Pull requests welcome! All contributions will be released under [the same license](LICENSE.md).


### Backmark doesn't differentiate 404s and other HTTP error pages

This information is not available from content scripts, and getting at it easily requires permission to read all web requests in Chrome. Consider this a tradeoff.


### Downloading large bundles crashes the extension

This is because Backmark loves to load everything into memory.


### Sometimes zips of multiple bookmarks are corrupted

Haven't really looked into this one. Work around it by downloading each bookmark individually, they won't be corrupted.


### Backmark doesn't respect robots.txt

Please bear this in mind if you have many bookmarks to a site with a demanding robots.txt policy.


## Libraries and thanks

Backmark uses these libraries, and I would like to thank all authors and contributors to them.

* [Bluebird](https://github.com/petkaantonov/bluebird)
* [Zip.js](https://gildas-lormeau.github.io/zip.js/)
* [Lodash](https://lodash.com/)
* [Handlebars](http://handlebarsjs.com/)
* [jQuery](https://jquery.com/)

------------------------

Brought to you by [msol](http://msol.io/), aka [@msol](https://twitter.com/msol)
