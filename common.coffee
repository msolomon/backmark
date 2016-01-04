## a bunch of functions used by other scripts

# how to transform a callback-driven chrome api into a promise-driven api
ChromePromisifier = (originalMethod) ->
  () ->
    args = [].slice.call(arguments)
    # Needed so that the original method can be called with the correct receiver
    self = this

    new Promise (resolve, reject) ->
        checkedResolve = (v) =>
            if chrome.runtime.lastError
                reject chrome.runtime.lastError.message
            else
                resolve v
        args.push checkedResolve
        originalMethod.apply self, args

# requires bluebird
chromePromisify = (pkg) -> Promise.promisifyAll(pkg, {promisifier: ChromePromisifier})
chromePromisify(chrome.bookmarks)
chromePromisify(chrome.downloads)
chromePromisify(chrome.history)
chromePromisify(chrome.tabs)
chromePromisify(chrome.storage.local)
chromePromisify(chrome.pageCapture)
chromePromisify(chrome.runtime)

# ajax file contents
fetchContent = (url) -> Promise.resolve($.get(url)).then (jqXhr) -> jqXhr
# ajax file contents as blob
readBlob = (url, mime) -> fetchContent(url).then (data) -> new Blob([data], {type: mime || ''})
getBlob = (url) ->
  new Promise((resolve, reject) ->
    xhr = new XMLHttpRequest()
    xhr.responseType = 'blob'
    xhr.open 'GET', url
    xhr.onload = (e) -> resolve(xhr.response)
    xhr.onerror = reject
    xhr.send()
  )


# add all files from one zip file to another
combineZipFiles = (targetWriter, sourceReader) ->
  new Promise (resolve, reject) -> sourceReader.getEntries(resolve)
  .then (entries) ->
    Promise.resolve(entries).each (e) ->
      tmpWriter = new zip.BlobWriter()
      new Promise (resolve, reject) -> e.getData(tmpWriter, resolve)
      .then (data) -> addToZip(targetWriter, e.filename, new zip.BlobReader(data))
  .then () -> targetWriter

# make a zip reader that reads a data uri
mkDataUriZipReader = (dataUri) ->
  new Promise (resolve, reject) ->
    zip.createReader(new zip.Data64URIReader(dataUri), resolve, reject)

# add contents of a zipReader to zipWriter as filname
addToZip = (zipWriter, filename, zipReader) ->
  new Promise (resolve, reject) ->
    zipWriter.add(filename, zipReader, resolve, ((p, t) -> null))
  .then () -> zipWriter

# close a zip writer
closeZipWriter = (zw) -> new Promise (resolve, reject) -> zw.close(resolve)

# make an empty zip writer
mkEmptyZip = () ->
  new Promise (resolve, reject) ->
      zip.createWriter(new zip.Data64URIWriter('application/zip'), resolve, reject)

# zip up a data uri page into a data uri
zipPage = (url, blob, extension = 'mhtml') ->
  mkEmptyZip()
  .then (zw) -> addToZip(zw, makeFilename(cleanFilename(url), extension), new zip.BlobReader(blob))
  .then(closeZipWriter)

savePage = (url, dataUri) -> saveSingle("bookmark::" + url, dataUri)
getPage = (url) -> getSingle("bookmark::" + url)

mkFullBundle = (urlsToDataUri) ->
  mkEmptyZip().then (base) ->
    Promise.resolve(_.keys(urlsToDataUri)).map((url) ->
      mkDataUriZipReader(urlsToDataUri[url])
      .then (reader) -> combineZipFiles(base, reader)
    ).then () -> base
  .then(closeZipWriter)

cleanFilename = (filename) -> filename.replace(/\W+/g, '-').replace(/^https?/, '').replace(/(^-+|-+$)/g, '').replace(/^www-/, '')
makeFilename = (filename, extension) -> cleanFilename(filename) + "." + extension

# use acceptDanger.html to accept a download. takes orignal url, not data uri
downloadPageWithAccept = (url) ->
    chrome.tabs.createAsync({
        url: 'acceptDanger.html',
        active: true,
        selected: true
    })
    .then (tab) -> chrome.runtime.sendMessageAsync(null, {
      msg: 'download',
      tabId: tab.id,
      acceptDangerDownload: {
        msg: 'acceptDanger-download',
        url: url,
        filename: cleanFilename(url) + ".zip",
      }
      })

# initiate download directly
downloadPage = (dataUri, filename) ->
    chrome.downloads.downloadAsync({
        url: dataUri,
        filename: filename
        saveAs: false
    })

# store the fact that we saved a url
recordSaved = (url) ->
    console.log 'saved ', url
    saveSingle("savedat::" + url, Date.now())

# record the fact that we failed to save a url
recordFailed = (url) ->
    console.log 'failed ', url
    saveSingle("failedat::" + url, Date.now())

# save a single key value pair
saveSingle = (k, v) ->
    store = {}
    store[k] = v
    chrome.storage.local.setAsync store

# get a single value, given a key
getSingle = (k) -> chrome.storage.local.getAsync(k).then (data) -> data[k]

getSinglePrefixed = (prefix, k) -> getSingle(prefix + k)
getSavedAtTimestamp = (k) -> getSinglePrefixed("savedat::", k)
getSavedAtDate = (k) -> getSinglePrefixed("savedat::", k).then (v) -> if v then new Date(v) else v
getFailedAtTimestamp = (k) -> getSinglePrefixed("failedat::", k)
getFailedAtDate = (k) -> getSinglePrefixed("failedat::", k).then (v) -> if v then new Date(v) else v
getConcurrency = () -> getSingle("settings::concurrency").then (v)-> v || 3
setConcurrency = (concurrency) -> saveSingle("settings::concurrency", concurrency)
getRetryDays = () -> getSingle("settings::retrydays").then (v)-> v || 7
setRetryDays = (retrydays) -> saveSingle("settings::retrydays", retrydays)
removeEntry = (url) ->
  chrome.storage.local.remove("bookmark::" + url)
  chrome.storage.local.remove("savedat::" + url)
  chrome.storage.local.remove("failedat::" + url)

eraseStorage = () -> chrome.storage.local.clearAsync()

# make a promise that's fulfilled when a given tab id has loaded. it will be passed a Tab object
mkTabLoaded = (tabId) ->
    console.log('mkTabLoaded')
    new Promise (resolve, reject) ->
        listener = chrome.tabs.onUpdated.addListener (id, info, tab) ->
            if id == tabId && info.status == 'complete'
                chrome.tabs.onUpdated.removeListener(listener)
                console.log('tab loaded')
                resolve(tab)

# walks a forest and produces an array of the results
linearizeTree = (nodes) ->
    go = (nodes) ->
        nodes.map (node) ->
            if node.hasOwnProperty('children')
                [node].concat linearizeTree(node.children)
            else node
    go(nodes).reduce(((a, b) -> a.concat(b)), [])

# get a list of bookmarks
getBookmarks = () ->
    chrome.bookmarks.getTreeAsync()
    .then (tree) ->
       _.filter(linearizeTree(tree), (n) -> n.hasOwnProperty('url'))

# fetch namespaced data
getPrefixed = (ids, prefix) ->
    l = prefix.length
    chrome.storage.local.getAsync(ids.map((id) -> prefix + id))
    .then (result) -> _.mapKeys(result, (v, k) -> k.slice(l))

getSavedAtTimestamps = (urls) -> getPrefixed(urls, "savedat::")
getSavedAtDates = (urls) ->
    getSavedAtTimestamps(urls).then (results) -> _.mapValues(results, (v, k) -> new Date(v))
getFailedAtTimestamps = (urls) -> getPrefixed(urls, "failedat::")

# attach backup status info to a single book mark object
getOneInfo = (bookmark) -> getInfo([bookmark]).then (bookmarks) -> bookmarks[0]
# add backup status info to bookmark objects
getInfo = (bookmarks) ->
    urls = bookmarks.map((b) -> b.url)
    Promise.join(
        getSavedAtTimestamps(urls),
        getFailedAtTimestamps(urls),
        (allSavedAt, allFailedAt) ->
            bookmarks.map (b) ->
                _.assign(b, {
                    savedAt: allSavedAt[b.url],
                    failedAt: allFailedAt[b.url],
                    favicon: 'chrome://favicon/' + b.url
                })
    )

# fetches bookmark objects joined with information about their backup status
getBookmarksInfo = () ->
    getBookmarks()
        .then getInfo

# remove a url that exactly matches from chrome's history. unfortunately clears all visits....
# TODO: when a better chrome API exists, only remove visits caused by BackMark
removeExactUrlFromHistory = (url) -> chrome.history.deleteUrlAsync({url: url})

# remove a url from history, searching to find it if the url may be inexact
removeUrlFromHistory = (url, title) ->
  chrome.history.getVisitsAsync({url: url})
  .then (results) ->
    if results.length > 0
      removeExactUrlFromHistory(url)
    else
      chrome.history.searchAsync({text: title+" "+url, startTime: new Date() - 30*1000, maxResults: 1})
      .then (results) ->
        if results.length > 0 and results[0].hasOwnProperty('url')
          removeExactUrlFromHistory(results[0].url)

# backup a single url
backupUrl = (url) ->
  t = null
  chrome.tabs.createAsync({
      url: url,
      active: false,
      selected: false
  })
  .then (tab) ->
    t = tab
    mkTabLoaded(tab.id)
  .then (tab) ->
    chrome.tabs.executeScriptAsync(tab.id, {file: 'detector.js'})
  .then (results) ->
    _.forEach(results, (result) ->
      saving = switch result.msg
        when 'saveMHTML'
          chrome.pageCapture.saveAsMHTMLAsync({tabId: t.id})
            .then (blob) -> zipPage(url, blob)
        when 'saveEmbed'
          # could probably close the tab sooner, but meh
          extension = /-(\w+)$/.exec(cleanFilename(url))[1]
          getBlob(result.url)
            .then (blob) -> zipPage(url, blob, extension)

      saving
        .then (zip) -> savePage(url, zip)
        .then (evt) ->
          recordSaved url
          removeUrlFromHistory t.url, t.title
          chrome.tabs.removeAsync t.id

    )
  .timeout(15000) # only give the page so long to load. unclear if 15 is the max anyway
  .catch(Promise.TimeoutError, (e) ->
    console.log('timed out loading page:', url)
    recordFailed url
    chrome.tabs.removeAsync(t.id)
  )

# run the backup, skipping pages that already have been backed up or failed recently
runMissingBackup = () -> getBookmarks().then (bs) -> runBackup(bs, false)
# run the backup process with the stored concurrency
runBackup = (bookmarks, force) ->
  keepalive = mkKeepAlive()
  getRetryDays().then (retryDays) ->
    isRecent = (ts) -> (new Date() - ts) < retryDays*24*60*60*1000
    getConcurrency().then (concurrency) ->
      Promise.resolve(bookmarks).map((bookmark) ->
          # # get fresh info in case anything's changed
          getOneInfo(bookmark).then (bookmark) ->
              if (switch
                when bookmark.url.startsWith("chrome:") then true
                when bookmark.url.startsWith("javascript:") then true
                when bookmark.url.startsWith("data:") then true
                else false)
                  # console.log('started with:', bookmark.url.match(///^[^/]+///), 'skipping', bookmark.url)
              else if !force && bookmark.savedAt
                  # console.log('already saved at', new Date(bookmark.savedAt), 'skipping', bookmark.url)
              else if !force && bookmark.failedAt && isRecent(bookmark.failedAt)
                  # console.log('failed recently at', new Date(bookmark.failedAt), 'skipping', bookmark.url)
              else
                  console.log('backing up', bookmark.url)
                  backupUrl(bookmark.url)
      , {concurrency: concurrency})
    .finally () -> keepalive.cancel(); true

# keep the event page alive until this promise is cancelled
mkKeepAlive = () ->
    port = chrome.runtime.connect({name: "keepalive-" + _.random()})
    go = () ->
        new Promise (resolve, reject) -> null
        .timeout(1000)
        .catch(Promise.TimeoutError, (e) -> console.log('keepalive'); go())
        .catch(Promise.CancellationError, (e) -> port.disconnect(); console.log('cancelled!'))
    go()
