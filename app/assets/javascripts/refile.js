(function() {
  "use strict";

  function isSuccess(xhr) {
    return (xhr.status >= 200 && xhr.status < 300) || xhr.status === 304
  }

  function formData(as, file, fields) {
    var data = new FormData();

    if(fields) {
      Object.keys(fields).forEach(function(key) {
        data.append(key, fields[key]);
      });
    }

    data.append(as, file);

    return data;
  }

  function dispatchEvent(element, name, detail) {
    var ev = document.createEvent('CustomEvent');
    ev.initCustomEvent(name, true, false, detail);
    element.dispatchEvent(ev);
  }

  if(!document.addEventListener) { return; } // IE8

  document.addEventListener("change", function(changeEvent) {
    var input = changeEvent.target;
    if(input.tagName === "INPUT" && input.type === "file" && input.getAttribute("data-direct")) {
      if(!input.files) { return; } // IE9, bail out if file API is not supported.

      var metadataField = input.previousSibling;

      var url = input.getAttribute("data-url");
      var fields = JSON.parse(input.getAttribute("data-fields") || "null");

      var requests = [].map.call(input.files, function(file, index) {
        var xhr = new XMLHttpRequest();

        xhr.file = file;

        xhr.addEventListener("load", function() {
          xhr.complete = true;
          dispatchEvent(input, "upload:complete", xhr.responseText);
          if(isSuccess(xhr)) {
            dispatchEvent(input, "upload:success", xhr.responseText);
          } else {
            dispatchEvent(input, "upload:failure", xhr.responseText);
          }
          if(requests.every(function(xhr) { return xhr.complete })) {
            finalizeUpload();
          }
        });

        xhr.upload.addEventListener("progress", function(progressEvent) {
          dispatchEvent(input, "upload:progress", progressEvent);
        });

        if(input.getAttribute("data-presigned")) {
          dispatchEvent(input, "presign:start", xhr);
          var presignXhr = new XMLHttpRequest();
          presignXhr.addEventListener("load", function() {
            dispatchEvent(input, "presign:complete", xhr);
            if(isSuccess(presignXhr)) {
              dispatchEvent(input, "presign:success", xhr);
              var data = JSON.parse(presignXhr.responseText)
              xhr.id = data.id;
              xhr.open("POST", data.url, true);
              xhr.send(formData(data.as, file, data.fields));
              dispatchEvent(input, "upload:start", xhr);
            } else {
              dispatchEvent(input, "presign:failure", xhr);
              xhr.complete = true;
            };
          });
          presignXhr.open("GET", url, true);
          presignXhr.send();
        } else {
          xhr.open("POST", url, true);
          xhr.send(formData(input.getAttribute("data-as"), file, fields));
          dispatchEvent(input, "upload:start", xhr);
        }

        return xhr;
      });

      if(requests.length) {
        input.classList.add("uploading");
      }

      var finalizeUpload = function() {
        input.classList.remove("uploading");

        if(requests.every(isSuccess)) {
          var data = requests.map(function(xhr) {
            var id = xhr.id || JSON.parse(xhr.responseText).id;
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
