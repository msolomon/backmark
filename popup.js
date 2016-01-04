// Generated by CoffeeScript 1.8.0
var buildElements, placeElements, setUpDynamicLinks, setUpSettingHandlers, showDialogIfFirstRun;

buildElements = function() {
  return getBookmarksInfo().then(function(bookmarks) {
    return bookmarks.map(Handlebars.templates['popup-bookmark']);
  });
};

placeElements = function() {
  return buildElements().then(function(html) {
    $('#bookmarks-body').html(html);
    return setUpDynamicLinks();
  });
};

setUpDynamicLinks = function() {
  $('.downloadbackup').on('click', function(evt) {
    var url;
    evt.preventDefault();
    url = evt.target.dataset.url;
    return downloadPageWithAccept(url);
  });
  return $('.download').on('click', function(evt) {
    var url;
    evt.preventDefault();
    url = evt.target.dataset.url;
    return backupUrl(url).then(function() {
      return placeElements();
    });
  });
};

setUpSettingHandlers = function() {
  var checkedUrls, dialog;
  checkedUrls = function() {
    return ($('.check:checked').parent().parent().find('a.download').map(function(i, a) {
      return a.attributes['data-url'].value;
    })).toArray();
  };
  $('#checkall').on('change', function(evt) {
    var checked;
    checked = evt.target.checked;
    return $('.check').map(function(i, c) {
      return c.checked = checked;
    });
  });
  getConcurrency().then(function(c) {
    return $('#concurrency').val(c);
  });
  $('#concurrency').on('change', function(evt) {
    return setConcurrency(evt.target.valueAsNumber);
  });
  getRetryDays().then(function(d) {
    return $('#retry-days').val(d);
  });
  $('#retry-days').on('change', function(evt) {
    return setRetryDays(evt.target.valueAsNumber);
  });
  $('#start-missing').on('click', function(evt) {
    return chrome.runtime.sendMessage({
      msg: 'missingBackup'
    }, function(rep) {
      console.log('done with missing backup', rep);
      return placeElements();
    });
  });
  $('#start-backup').on('click', function(evt) {
    var urls;
    urls = checkedUrls();
    return chrome.runtime.sendMessage({
      msg: 'partialBackup',
      urls: urls
    }, function(rep) {
      console.log('done with selected backup', rep);
      return placeElements();
    });
  });
  $('#start-download').on('click', function(evt) {
    var urls;
    urls = checkedUrls();
    return chrome.runtime.sendMessage({
      msg: 'partialDownload',
      urls: urls
    }, function(rep) {
      return console.log('done with download', rep);
    });
  });
  dialog = $('#confirm-reset').get(0);
  $('#reset').on('click', function(evt) {
    $('#close').on('click', function(evt) {
      return dialog.close();
    });
    $('#erase').on('click', function(evt) {
      return eraseStorage().then(function() {
        dialog.close();
        return placeElements();
      });
    });
    return dialog.showModal();
  });
  $('#first-run-close').on('click', function(evt) {
    return $('#first-run').get(0).close();
  });
  return $('#tabify').on('click', function(evt) {
    return chrome.tabs.createAsync({
      url: 'popup.html'
    });
  });
};

showDialogIfFirstRun = function() {
  if (window.location.href.endsWith('firstrun')) {
    return $('#first-run').get(0).show();
  }
};

setUpSettingHandlers();

placeElements();

showDialogIfFirstRun();

//# sourceMappingURL=popup.js.map
