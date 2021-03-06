// Generated by CoffeeScript 1.8.0
var embed;

embed = _.filter($('embed#plugin, embed[name="plugin"]'), function(ele) {
  return /pdf/.test(ele.type) || _.contains(_.mapValues(ele.attributes, v(function() {
    return v.name;
  })), "internalinstanceid");
})[0];

if (!embed) {
  console.log("no plugin embed found, saving as MHTML");
  ({
    msg: 'saveMHTML'
  });
} else {
  console.log('found plugin embed, saving:', embed);
  $.get(embed.src);
  ({
    msg: 'saveEmbed',
    url: embed.src,
    mime: embed.type
  });
}

//# sourceMappingURL=detect.js.map
