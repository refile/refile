"use strict";

document.addEventListener("change", function(e) {
  if(e.target.tagName === "INPUT" && e.target.type === "file" && e.target.dataset.direct) {
    var input = e.target;
    var file = input.files[0];
    if(file) {
      var url = e.target.dataset.url;
      if(e.target.dataset.fields) {
        var fields = JSON.parse(e.target.dataset.fields);
      }

      var data = new FormData();

      if(fields) {
        Object.keys(fields).forEach(function(key) {
          data.append(key, fields[key]);
        });
      }
      data.append("file", file);

      var xhr = new XMLHttpRequest();
      xhr.addEventListener("load", function(e) {
        if(xhr.readyState === 4) {
          var id = JSON.parse(xhr.responseText).id;
          input.dispatchEvent(new CustomEvent("upload:end", { detail: { id: id }, bubbles: true }));
          input.previousSibling.value = id;
          input.removeAttribute("name");
        }
      });

      xhr.addEventListener("progress", function(e) {
        if (e.lengthComputable) {
          input.dispatchEvent(new CustomEvent("upload:progress", { detail: e, bubbles: true }));
        }
      });

      xhr.open("POST", url, true);
      xhr.send(data);

      input.dispatchEvent(new CustomEvent("upload:start", { bubbles: true }));
    }
  }
});

