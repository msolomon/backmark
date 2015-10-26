# register event listeners
chrome.runtime.onInstalled.addListener (details) ->
  console.log(details)
  if details.reason == 'install'
    console.log "just installed, prompting user"
    chrome.tabs.createAsync({url: 'popup.html?reason=firstrun'})

chrome.bookmarks.onCreated.addListener (id, bookmark) ->
  console.log "bookmark created, running full backup"
  runMissingBackup()
chrome.bookmarks.onRemoved.addlistener (id, info) ->
  console.log "bookmark removed, deleting entry"
  if info.hasOwnProperty('node') && info.node.hasOwnProperty('url')
    removeEntry(info.node.url)
  else
    console.log('not removing entry, newer Chrome required')
chrome.bookmarks.onChanged.addListener (id, info) ->
  console.log "bookmark changed, running full backup"
  runMissingBackup()
chrome.bookmarks.onMoved.addListener (id, info) ->
  console.log "bookmark moved, running full backup"
  runMissingBackup()

chrome.runtime.onMessage.addListener (req, sender, sendResponse) ->
    if req.msg == 'partialBackup'
        urls = req.urls
        console.log('user requested backup of:', urls)
        getBookmarks()
          .then (bookmarks) -> _.filter(bookmarks, (b) -> _.includes(urls, b.url))
          .then (bookmarks) -> runBackup(bookmarks, true)
          .then () -> console.log('responding'); sendResponse({msg: 'backupComplete'})
    else if req.msg == 'missingBackup'
        console.log('user requested missing backup:', urls)
        runMissingBackup()
          .then () -> console.log('responding'); sendResponse({msg: 'backupComplete'})
    else if req.msg == 'partialDownload'
        urls = req.urls
        console.log('user requested download of:', urls)
        getPrefixed(urls, 'bookmark::')
          .then (urlsToUris) -> mkFullBundle(urlsToUris)
          .then (bundle) ->
            console.log('bundled', bundle)
            downloadPage(bundle, "backmark")
          .then () -> console.log('responding'); sendResponse({msg: 'downloadComplete'})
