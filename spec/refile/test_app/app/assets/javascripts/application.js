//= require jquery
//= require refile

"use strict";

if(document.addEventListener) {
  document.addEventListener("DOMContentLoaded", function() {
    var form = document.querySelector("form#direct");

    if(form) {
      var input = document.querySelector("#post_document");

      form.addEventListener("upload:start", function() {
        var p = document.createElement("p");
        p.textContent = "Upload started";
        form.appendChild(p);
      });

      form.addEventListener("upload:complete", function(e) {
        var p = document.createElement("p");
        p.textContent = "Upload complete " + e.detail;
        form.appendChild(p);
      });

      form.addEventListener("upload:progress", function(e) {
        var p = document.createElement("p");
        p.textContent = "Upload progress " + e.detail.loaded + " " + e.detail.total;
        form.appendChild(p);
      });

      form.addEventListener("upload:failure", function(e) {
        var p = document.createElement("p");
        p.textContent = "Upload failure " + e.detail
        form.appendChild(p);
      });
    }
  });

  $(document).on("upload:success", "form#direct", function(e) {
    $("<p></p>").text("Upload success " + e.originalEvent.detail).appendTo(this);
  });
}
