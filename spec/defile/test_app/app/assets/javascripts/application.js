//= require defile

"use strict";

document.addEventListener("DOMContentLoaded", function() {
  var form = document.querySelector("form#direct");

  if(form) {
    var input = document.querySelector("#post_document");

    input.addEventListener("upload:start", function() {
      var p = document.createElement("p");
      p.textContent = "Upload started";
      form.appendChild(p);
    });
  }
});
