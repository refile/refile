//= require jquery
//= require refile

"use strict";

if(document.addEventListener) {
  document.addEventListener("DOMContentLoaded", function() {
    var form = document.querySelector("form#direct");

    if(form) {
      var input = document.querySelector("#post_document");

      ["start", "complete", "failure", "success"].forEach(function(ev) {
        form.addEventListener("presign:" + ev, function() {
          var p = document.createElement("p");
          p.textContent = "Presign " + ev;
          form.appendChild(p);
        });
      });

      form.addEventListener("upload:start", function() {
        var p = document.createElement("p");
        p.textContent = "Upload started";
        form.appendChild(p);
      });

      form.addEventListener("upload:complete", function(e) {
        var p = document.createElement("p");
        p.textContent = "Upload complete " + e.detail.xhr.responseText;
        form.appendChild(p);
      });

      form.addEventListener("upload:progress", function(e) {
        var p = document.createElement("p");
        p.textContent = "Upload progress " + e.detail.progress.loaded + " " + e.detail.progress.total;
        form.appendChild(p);
      });

      form.addEventListener("upload:failure", function(e) {
        var p = document.createElement("p");
        p.textContent = "Upload failure " + e.detail.xhr.responseText
        form.appendChild(p);
      });
    }
  });

  $(document).on("upload:success", "form#direct", function(e) {
    $("<p></p>").text("Upload success " + e.originalEvent.detail.xhr.responseText).appendTo(this);
  });

  $(document).on("upload:complete", "form", function(e) {
    if(!$(this).find("input.uploading").length) {
      $(this).find("input[type=submit]").removeAttr("disabled")
      $(this).append("<p>All uploads complete</p>")
    }
  });
}
