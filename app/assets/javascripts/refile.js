(function() {
  "use strict";

  if(!document.addEventListener) { return; } // IE8

  document.addEventListener("change", function(changeEvent) {
    var input = changeEvent.target;
    if(input.tagName === "INPUT" && input.type === "file" && input.getAttribute("data-direct")) {
      if(!input.files) { return; } // IE9, bail out if file API is not supported.

      var file = input.files[0];
      var metadataField = input.previousSibling;

      var dispatchEvent = function(name, detail) {
        var ev = document.createEvent('CustomEvent');
        ev.initCustomEvent(name, true, false, detail);
        input.dispatchEvent(ev);
      };

      if(file) {
        var url = input.getAttribute("data-url");
        var fields = JSON.parse(input.getAttribute("data-fields") || "null");

        var data = new FormData();

        if(fields) {
          Object.keys(fields).forEach(function(key) {
            data.append(key, fields[key]);
          });
        }
        data.append(input.getAttribute("data-as"), file);

        var xhr = new XMLHttpRequest();
        xhr.addEventListener("load", function() {
          input.classList.remove("uploading");
          dispatchEvent("upload:complete", xhr.responseText);
          if((xhr.status >= 200 && xhr.status < 300) || xhr.status === 304) {
            var id = input.getAttribute("data-id") || JSON.parse(xhr.responseText).id;
            if(metadataField) {
              metadataField.value = JSON.stringify({ id: id, filename: file.name, content_type: file.type, size: file.size });
            }
            input.removeAttribute("name");
            dispatchEvent("upload:success", xhr.responseText);
          } else {
            dispatchEvent("upload:failure", xhr.responseText);
          }
        });

        xhr.upload.addEventListener("progress", function(progressEvent) {
          if (progressEvent.lengthComputable) {
            dispatchEvent("upload:progress", progressEvent);
          }
        });

        xhr.open("POST", url, true);
        xhr.send(data);

        input.classList.add("uploading");
        dispatchEvent("upload:start", xhr);
      }
    }
  });
})();
