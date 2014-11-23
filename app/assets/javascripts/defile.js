"use strict";

document.addEventListener("change", function(e) {
  if(e.target.tagName === "INPUT" && e.target.type === "file" && e.target.dataset.presigned) {
    var input = e.target;
    var file = input.files[0];
    if(file) {
      var url = e.target.dataset.url;
      var fields = JSON.parse(e.target.dataset.fields);

      var id = fields["key"].split("/")[1];

      var data = new FormData();

      Object.keys(fields).forEach(function(key) {
        data.append(key, fields[key]);
      });
      data.append("file", file);

      var xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function() {
        if(xhr.readyState === 4) {
          console.log("Done!", id);
          input.previousSibling.value = id;
          input.removeAttribute("name");
        }
      }
      xhr.open("POST", url, true);
      xhr.send(data);
    }
  }
});

