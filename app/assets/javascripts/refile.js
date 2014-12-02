(function() {
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
        data.append(input.dataset.as, file);

        var xhr = new XMLHttpRequest();
        xhr.addEventListener("load", function(e) {
          input.classList.remove("uploading")
          input.dispatchEvent(new CustomEvent("upload:complete", { detail: xhr.responseText, bubbles: true }));
          if((xhr.status >= 200 && xhr.status < 300) || xhr.status === 304) {
            var id = input.dataset.id || JSON.parse(xhr.responseText).id;
            input.dispatchEvent(new CustomEvent("upload:success", { detail: xhr.responseText, bubbles: true }));
            input.previousSibling.value = id;
            input.removeAttribute("name");
          } else {
            input.dispatchEvent(new CustomEvent("upload:failure", { detail: xhr.responseText, bubbles: true }));
          }
        });

        xhr.addEventListener("progress", function(e) {
          if (e.lengthComputable) {
            input.dispatchEvent(new CustomEvent("upload:progress", { detail: e, bubbles: true }));
          }
        });

        xhr.open("POST", url, true);
        xhr.send(data);

        input.classList.add("uploading")
        input.dispatchEvent(new CustomEvent("upload:start", { bubbles: true }));
      }
    }
  });
})();
