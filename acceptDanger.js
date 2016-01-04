// Generated by CoffeeScript 1.8.0
var closeThisTab;

chrome.downloads.onChanged.addListener(function(delta) {
  return console.log('download changed:', delta.previous, '->', delta.current, delta);
});

chrome.downloads.onChanged.addListener(function(delta) {
  if (delta.hasOwnProperty('danger')) {
    return chrome.downloads.acceptDanger(delta.id, function() {
      return console.log('got error', chrome.runtime.lastError.message);
    });
  }
});

chrome.runtime.onMessage.addListener(function(req, sender, sendResponse) {
  console.log('got message', req, sender);
  switch (req.msg) {
    case 'acceptDanger-download':
      return getPage(req.url).then(function(dataUri) {
        $("#downloads").append("<li><a href='" + dataUri + "' download='" + req.filename + "'>" + req.filename + "</a></li>");
        return downloadPage(dataUri, req.filename);
      }).then(function() {
        return closeThisTab;
      });
    case 'acceptDanger-partialDownload':
      return getPrefixed(req.urls, 'bookmark::').then(function(urlsToUris) {
        _.forEach(urlsToUris, function(uri, url) {
          var filename;
          filename = cleanFilename(url) + ".zip";
          return $("#downloads").append("<li><a href='" + uri + "' download='" + filename + "'>" + filename + "</a></li>");
        });
        return mkFullBundle(urlsToUris);
      }).then(function(bundle) {
        var filename;
        filename = 'backmark.zip';
        console.log('bundled', bundle, 'as', filename);
        $("#downloads").prepend("<li><a href='" + bundle + "' download='" + filename + "'>" + filename + "</a></li>");
        return downloadPage(bundle, filename);
      });
  }
});

closeThisTab = null;

//# sourceMappingURL=acceptDanger.js.map