
# this is leftover scraps from an attempt to use the acceptDanger API to authorise MHTML downloads.
# it seems to just fail. maybe this will be of use for anyone trying to fix this

# chrome.downloads.onChanged.addListener((delta) -> console.log('download changed:', delta.previous, '->', delta.current, delta))

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  console.log 'got message', request, sender
  if request.msg == 'acceptDanger'
    chrome.downloads.acceptDangerAsync(request.downloadId)
    .then () ->
      if chrome.runtime.lastError
        console.log(chrome.runtime.lastError)
      else console.log('no error')


  if request.msg == 'download'
    $("#downloads").append("<li><a href='"+request.url+"' download='"+request.filename+"'>"+request.filename+"</a></li>")
    chrome.downloads.download({
      filename: request.filename,
      url: request.url
    },
    (downloadId) -> chrome.downloads.acceptDanger(downloadId, () -> if chrome.runtime.lastError then console.log('got error', chrome.runtime.lastError.message) and closeThisTab() else closeThisTab())
    )


# closeThisTab = chrome.tabs.getCurrent (tab) -> chrome.tabs.remove(tab.id)
closeThisTab = null
