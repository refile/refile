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

  function resizeParams(file, input) {
    var info, srcRatio, trgRatio;

    info = {
      srcX: 0,
      srcY: 0,
      srcWidth: file.width,
      srcHeight: file.height
    };
    srcRatio = file.width / file.height;

    info.maxWidth = parseInt(input.dataset.maxWidth);
    info.maxHeight = parseInt(input.dataset.maxHeight);

    // Make sure it still works even if only one max size is defined
    if(isNaN(info.maxWidth)) info.maxWidth = info.maxHeight
    if(isNaN(info.maxHeight)) info.maxHeight = info.maxWidth

    trgRatio = info.maxWidth / info.maxHeight;

    if (file.width > info.maxWidth || file.height > info.maxHeight) {
      if (file.width > file.height) {
        info.trgWidth = info.maxWidth
        info.trgHeight = file.height * (info.maxWidth / file.width)
      } else {
        info.trgHeight = info.maxHeight
        info.trgWidth = file.width * (info.maxHeight / file.height)
      }
    } else {
      info.trgHeight = info.srcHeight;
      info.trgWidth = info.srcWidth;
    }

    info.srcX = (file.width - info.srcWidth) / 2;
    info.srcY = (file.height - info.srcHeight) / 2;

    return info;
  }

  function detectVerticalSquash(img) {
    var alpha, canvas, ctx, data, ey, ih, iw, py, ratio, sy;
    iw = img.naturalWidth;
    ih = img.naturalHeight;
    canvas = document.createElement("canvas");
    canvas.width = 1;
    canvas.height = ih;
    ctx = canvas.getContext("2d");
    ctx.drawImage(img, 0, 0);
    data = ctx.getImageData(0, 0, 1, ih).data;
    sy = 0;
    ey = ih;
    py = ih;
    while (py > sy) {
      alpha = data[(py - 1) * 4 + 3];
      if (alpha === 0) {
        ey = py;
      } else {
        sy = py;
      }
      py = (ey + sy) >> 1;
    }
    ratio = py / ih;
    if (ratio === 0) {
      return 1;
    } else {
      return ratio;
    }
  }

  function drawImageIOSFix(ctx, img, sx, sy, sw, sh, dx, dy, dw, dh) {
    var vertSquashRatio;
    vertSquashRatio = detectVerticalSquash(img);
    return ctx.drawImage(img, sx, sy, sw, sh, dx, dy, dw, dh / vertSquashRatio);
  };

  function dataURLToBlob(dataURL) {
    var BASE64_MARKER, contentType, i, parts, raw, rawLength, uInt8Array;
    BASE64_MARKER = ";base64,";
    if (dataURL.indexOf(BASE64_MARKER) === -1) {
      parts = dataURL.split(",");
      contentType = parts[0].split(":")[1];
      raw = decodeURIComponent(parts[1]);
      return new Blob([raw], {
        type: contentType
      });
    }
    parts = dataURL.split(BASE64_MARKER);
    contentType = parts[0].split(":")[1];
    raw = window.atob(parts[1]);
    rawLength = raw.length;
    uInt8Array = new Uint8Array(rawLength);
    i = 0;
    while (i < rawLength) {
      uInt8Array[i] = raw.charCodeAt(i);
      ++i;
    }
    return new Blob([uInt8Array], {
      type: contentType
    });
  };

  function resizeImage(file, input, index, callback) {
    var fileReader = new FileReader;

    fileReader.onload = (function(_this) {
      return function() {
        if (file.type === "image/svg+xml") return;

        var img = document.createElement("img");

        img.onload = function() {
          var canvas, ctx, resizeInfo, resizedImage, _ref, _ref1, _ref2, _ref3;
          file.width = img.width;
          file.height = img.height;
          resizeInfo = resizeParams(file, input);
          if (resizeInfo.trgWidth == null) {
            resizeInfo.trgWidth = resizeInfo.maxWidth;
          }
          if (resizeInfo.trgHeight == null) {
            resizeInfo.trgHeight = resizeInfo.maxHeight;
          }
          canvas = document.createElement("canvas");
          ctx = canvas.getContext("2d");
          canvas.width = resizeInfo.trgWidth;
          canvas.height = resizeInfo.trgHeight;
          drawImageIOSFix(
            ctx,
            img,
            (_ref = resizeInfo.srcX) != null ? _ref : 0,
            (_ref1 = resizeInfo.srcY) != null ? _ref1 : 0,
            resizeInfo.srcWidth,
            resizeInfo.srcHeight,
            (_ref2 = resizeInfo.trgX) != null ? _ref2 : 0,
            (_ref3 = resizeInfo.trgY) != null ? _ref3 : 0,
            resizeInfo.trgWidth,
            resizeInfo.trgHeight
          );
          resizedImage = canvas.toDataURL("image/png");
          input.files[index].resized = resizedImage;
          requests.push(callback(file, index));
        };
        img.src = fileReader.result;
      };
    })(this);

    fileReader.readAsDataURL(file);
  }

  if(!document.addEventListener) { return; } // IE8

  var requests = []

  document.addEventListener("change", function(changeEvent) {
    var input = changeEvent.target;
    if(input.tagName === "INPUT" && input.type === "file" && input.getAttribute("data-direct")) {
      if(!input.files) { return; } // IE9, bail out if file API is not supported.

      var reference = input.getAttribute("data-reference");
      var metadataField = document.querySelector("input[type=hidden][data-reference='" + reference + "']");

      var url = input.getAttribute("data-url");
      var fields = JSON.parse(input.getAttribute("data-fields") || "null");

      for(var i = 0; i < input.files.length; i++) {
        if(input.getAttribute("data-max-width") || input.getAttribute("data-max-height"))
          resizeImage(input.files[i], input, i, createRequest);
        else
          requests.push(createRequest(file, index));
      }

      function createRequest(file, index) {
        function dispatchEvent(element, name, progress) {
          var ev = document.createEvent('CustomEvent');
          ev.initCustomEvent(name, true, false, { xhr: xhr, file: file, index: index, progress: progress });
          element.dispatchEvent(ev);
        }

        var xhr = new XMLHttpRequest();

        xhr.file = file;

        xhr.addEventListener("load", function() {
          xhr.complete = true;
          if(requests.every(function(xhr) { return xhr.complete })) {
            finalizeUpload();
          }
          if(isSuccess(xhr)) {
            dispatchEvent(input, "upload:success");
          } else {
            dispatchEvent(input, "upload:failure");
          }
          dispatchEvent(input, "upload:complete");
        });

        xhr.upload.addEventListener("progress", function(progressEvent) {
          dispatchEvent(input, "upload:progress", progressEvent);
        });

        var fileData = file.resized ? dataURLToBlob(file.resized) : file;

        if(input.getAttribute("data-presigned")) {
          dispatchEvent(input, "presign:start");
          var presignXhr = new XMLHttpRequest();
          var presignUrl = url + "?t=" + Date.now() + "." + index;
          presignXhr.addEventListener("load", function() {
            dispatchEvent(input, "presign:complete");
            if(isSuccess(presignXhr)) {
              dispatchEvent(input, "presign:success");
              var data = JSON.parse(presignXhr.responseText)
              xhr.id = data.id;
              xhr.open("POST", data.url, true);
              xhr.send(formData(data.as, file, data.fields));
              dispatchEvent(input, "upload:start");
            } else {
              dispatchEvent(input, "presign:failure");
              xhr.complete = true;
            };
          });
          presignXhr.open("GET", presignUrl, true);
          presignXhr.send();
        } else {
          xhr.open("POST", url, true);
          xhr.send(formData(input.getAttribute("data-as"), file, fields));
          dispatchEvent(input, "upload:start");
        }

        return xhr;
      };

      if(input.files.length) {
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
