(function() {
  "use strict";

  if(!document.addEventListener) { return }; // IE8

  document.addEventListener("change", function(e) {
    if(e.target.tagName === "INPUT" && e.target.type === "file" && e.target.getAttribute("data-direct")) {
      var input = e.target;
      if(!input.files) { return; } // IE9, bail out if file API is not supported.
      var file = input.files[0];

      var dispatchEvent = function(name, detail) {
        var ev = document.createEvent('CustomEvent');
        ev.initCustomEvent(name, true, false, detail);
        input.dispatchEvent(ev);
      }

      if(file) {
        var url = e.target.getAttribute("data-url");
        if(e.target.getAttribute("data-fields")) {
          var fields = JSON.parse(e.target.getAttribute("data-fields"));
        }

        var data = new FormData();

        if(fields) {
          Object.keys(fields).forEach(function(key) {
            data.append(key, fields[key]);
          });
        }
        data.append(input.getAttribute("data-as"), file);

        var xhr = new XMLHttpRequest();
        xhr.addEventListener("load", function(e) {
          input.classList.remove("uploading")
          dispatchEvent("upload:complete", xhr.responseText);
          if((xhr.status >= 200 && xhr.status < 300) || xhr.status === 304) {
            var id = input.getAttribute("data-id") || JSON.parse(xhr.responseText).id;
            input.previousSibling.value = id;
            input.removeAttribute("name");
            dispatchEvent("upload:success", xhr.responseText);
          } else {
            dispatchEvent("upload:failure", xhr.responseText);
          }
        });

        xhr.upload.addEventListener("progress", function(e) {
          if (e.lengthComputable) {
            dispatchEvent("upload:progress", e);
          }
        });

        xhr.open("POST", url, true);
        xhr.send(data);

        input.classList.add("uploading")
        dispatchEvent("upload:start");
      }
    }
  });
})();
