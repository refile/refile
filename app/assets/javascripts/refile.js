(function() {
  "use strict";

  if(!document.addEventListener) { return; } // IE8

  document.addEventListener("change", function(changeEvent) {
    var input = changeEvent.target;
    if(input.tagName === "INPUT" && input.type === "file" && input.getAttribute("data-direct")) {
      if(!input.files) { return; } // IE9, bail out if file API is not supported.

      var metadataField = input.previousSibling;

      var dispatchEvent = function(name, detail) {
        var ev = document.createEvent('CustomEvent');
        ev.initCustomEvent(name, true, false, detail);
        input.dispatchEvent(ev);
      };

      var isSuccess = function(xhr) {
        return (xhr.status >= 200 && xhr.status < 300) || xhr.status === 304
      }

      var url = input.getAttribute("data-url");
      var fields = JSON.parse(input.getAttribute("data-fields") || "null");

      var requests = [].map.call(input.files, function(file) {

        var data = new FormData();

        if(fields) {
          Object.keys(fields).forEach(function(key) {
            data.append(key, fields[key]);
          });
        }
        data.append(input.getAttribute("data-as"), file);

        var xhr = new XMLHttpRequest();

        xhr.file = file;

        xhr.addEventListener("load", function() {
          dispatchEvent("upload:complete", xhr.responseText);
          if(isSuccess(xhr)) {
            dispatchEvent("upload:success", xhr.responseText);
          } else {
            dispatchEvent("upload:failure", xhr.responseText);
          }
          if(requests.every(function(xhr) { return xhr.readyState === 4 })) {
            finalizeUpload();
          }
        });

        xhr.upload.addEventListener("progress", function(progressEvent) {
          if (progressEvent.lengthComputable) {
            dispatchEvent("upload:progress", progressEvent);
          }
        });

        xhr.open("POST", url, true);
        xhr.send(data);

        dispatchEvent("upload:start", xhr);

        return xhr;
      });

      if(requests.length) {
        input.classList.add("uploading");
      }

      var finalizeUpload = function() {
        input.classList.remove("uploading");

        if(requests.every(isSuccess)) {
          var data = requests.map(function(xhr) {
            var id = input.getAttribute("data-id") || JSON.parse(xhr.responseText).id;
            return { id: id, filename: xhr.file.name, content_type: xhr.file.type, size: xhr.file.size };
          });
          if(!input.multiple) data = data[0];
          if(metadataField) metadataField.value = JSON.stringify(data);

          input.removeAttribute("name");
        }
      }
    }
  });
})();
