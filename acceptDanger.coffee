chrome.downloads.onChanged.addListener((delta) -> console.log('download changed:', delta.previous, '->', delta.current, delta))
chrome.downloads.onChanged.addListener((delta) -> if delta.hasOwnProperty('danger') then chrome.downloads.acceptDanger(delta.id, () -> console.log('got error', chrome.runtime.lastError.message)))

chrome.runtime.onMessage.addListener (req, sender, sendResponse) ->
  console.log 'got message', req, sender

  switch req.msg
    when 'acceptDanger-download'
      getPage(req.url)
        .then (dataUri) ->
          $("#downloads").append("<li><a href='"+dataUri+"' download='"+req.filename+"'>"+req.filename+"</a></li>")
          downloadPage(dataUri, req.filename)
        .then () -> closeThisTab
    when 'acceptDanger-partialDownload'
        getPrefixed(req.urls, 'bookmark::')
          .then (urlsToUris) ->
            _.forEach(urlsToUris, (uri, url) ->
              filename = cleanFilename(url) + ".zip"
              $("#downloads").append("<li><a href='"+uri+"' download='"+filename+"'>"+filename+"</a></li>")
            )
            mkFullBundle(urlsToUris)
          .then (bundle) ->
            filename = 'backmark.zip'
            console.log('bundled', bundle, 'as', filename)
            $("#downloads").prepend("<li><a href='"+bundle+"' download='"+filename+"'>"+filename+"</a></li>")
            downloadPage(bundle, filename)

# closeThisTab = chrome.tabs.getCurrent (tab) -> chrome.tabs.remove(tab.id)
closeThisTab = null
