buildElements = () ->
  getBookmarksInfo()
  .then (bookmarks) ->
    bookmarks.map(Handlebars.templates['popup-bookmark'])

placeElements = () ->
  buildElements().then (html) ->
    $('#bookmarks-body').html(html)
    setUpDynamicLinks()

setUpDynamicLinks = () ->
  $('.downloadbackup').on('click', (evt) ->
    evt.preventDefault()
    url = evt.target.dataset.url
    getPage(url).then (dataUri) -> downloadPage(dataUri, url)
  )

  $('.download').on('click', (evt) ->
    evt.preventDefault()
    url = evt.target.dataset.url
    backupUrl(url).then () -> placeElements()
  )

setUpSettingHandlers = () ->
  checkedUrls = () -> ($('.check:checked').parent().parent().find('a.download').map (i, a) -> a.attributes['data-url'].value).toArray()
  # select all/none checkbox
  $('#checkall').on('change', (evt) ->
    checked = evt.target.checked
    $('.check').map (i, c) -> c.checked = checked
  )

  # concurrency
  getConcurrency().then (c) -> $('#concurrency').val(c)
  $('#concurrency').on('change', (evt) -> setConcurrency(evt.target.valueAsNumber))

  # retry after X days
  getRetryDays().then (d) -> $('#retry-days').val(d)
  $('#retry-days').on('change', (evt) -> setRetryDays(evt.target.valueAsNumber))

  # regular backup selected
  $('#start-missing').on('click', (evt) ->
    chrome.runtime.sendMessage(
      {msg: 'missingBackup'},
      (rep) ->
        console.log('done with missing backup', rep)
        placeElements()
    )
  )

  # multi-backup selected
  $('#start-backup').on('click', (evt) ->
    urls = checkedUrls()
    chrome.runtime.sendMessage(
      {msg: 'partialBackup', urls: urls},
      (rep) ->
        console.log('done with selected backup', rep)
        placeElements()
    )
  )

  # multi-download selected
  $('#start-download').on('click', (evt) ->
    urls = checkedUrls()
    chrome.runtime.sendMessage(
      {msg: 'partialDownload', urls: urls},
      (rep) ->
        console.log('done with download', rep)
    )
  )

  # reset dialog
  dialog = $('#confirm-reset').get(0)
  $('#reset').on('click', (evt) ->
    $('#close').on('click', (evt) -> dialog.close())
    $('#erase').on('click', (evt) ->
      eraseStorage()
      .then () ->
        dialog.close()
        placeElements()
    )

    dialog.showModal()
  )

setUpSettingHandlers()
placeElements()

