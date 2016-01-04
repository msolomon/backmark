## injected into page to support e.g. pdfs as well as html bookmarks

# try to find plugin embeds, such as used to display PDFs in chrome
embed = _.filter($('embed#plugin, embed[name="plugin"]'), (ele) ->
  /pdf/.test(ele.type) ||
    _.contains(_.mapValues(ele.attributes, v -> v.name), "internalinstanceid"))[0]

# this last expression is the result that gets communicated back to the injector of this js
if !embed
  console.log("no plugin embed found, saving as MHTML")
  {msg: 'saveMHTML'}
else
  console.log('found plugin embed, saving:', embed)
  $.get(embed.src)
  {msg: 'saveEmbed', url: embed.src, mime: embed.type}
