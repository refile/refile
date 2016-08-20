Refile = function(files, options) {
  var handlers = [];
  var obj = this;

  var isSuccess = function(xhr) {
    return (xhr.status >= 200 && xhr.status < 300) || xhr.status === 304;
  };

  var formData = function(as, file, fields) {
    var data = new FormData();

    if (fields) {
      Object.keys(fields).forEach(function(key) {
        data.append(key, fields[key]);
      });
    }

    data.append(as, file);

    return data;
  };

  var emit = function(eventName) {
    for(var list = handlers[eventName], i = 0; list && list[i];) {
        list[i++].apply(obj, list.slice.call(arguments, 1));
    };

    return obj;
  };

  // Event Emitter functions
  this.on = function(eventName, handler) {
    (handlers[eventName] = handlers[eventName] || []).push(handler);

    return obj;
  };

  this.upload = function(files, options) {
    if (files.length == 0)
      return;

    var requests = [].map.call(files, function(file, index) {
      var xhr = new XMLHttpRequest();
      xhr.complete = false;
      xhr.file = file;

      var eventOptions = {
        xhr:    xhr,
        file:   file,
        index:  index
      };

      xhr.addEventListener('load', function() {
        if (isSuccess(xhr)) {
          emit('upload:success', eventOptions);
        } else {
          emit('upload:failure', eventOptions);
        };

        xhr.complete = true;

        // The order of 'uploads:finished' and 'upload:complete' will trigger in the
        // wrong order. This is required for existing tests to pass.
        // It is likely a bug
        if (requests.every(function(thisXhr) { return thisXhr.complete })) {
          emit('uploads:finished', requests);
        };

        emit('upload:complete', eventOptions);
      });

      xhr.upload.addEventListener('progress', function(progressEvent) {
        eventOptions['progress'] = progressEvent;
        emit('upload:progress', eventOptions);
      });

      if (options['presigned']) {
        emit('presign:start', eventOptions);

        var presignXhr = new XMLHttpRequest();
        var presignUrl = options['url'] + '?t=' + Date.now() + '.' + index;

        presignXhr.addEventListener('load', function() {
          emit('presign:complete', eventOptions);

          if (isSuccess(presignXhr)) {
            emit('presign:success', eventOptions);

            var presignReqData = JSON.parse(presignXhr.responseText)
            xhr.id = presignReqData.id;
            xhr.open('POST', presignReqData.url, true);
            xhr.send(formData(presignReqData.as, file, presignReqData.fields));

            emit('upload:start', eventOptions);
          } else {
            emit('presign:failure', eventOptions);
            xhr.complete = true;
          };
        });

        presignXhr.open('GET', presignUrl, true);
        presignXhr.send();
      } else {
        xhr.open('POST', options['url'], true);
        xhr.send(formData(options['as'], file, options['fields']));
        emit('upload:start', eventOptions);
      };

      return xhr;
    });

    return requests;
  };
};

// Add backwards compatability support
!(function(Refile) {
  "use strict";

  var dispatchEvent = function(element, name, eventOptions) {
    var ev = document.createEvent('CustomEvent');
    ev.initCustomEvent(name, true, false, eventOptions);
    element.dispatchEvent(ev);
  };

  var isSuccess = function(xhr) {
    return (xhr.status >= 200 && xhr.status < 300) || xhr.status === 304;
  };

  if(!document.addEventListener) { return; } // IE8

  document.addEventListener('change', function(changeEvent) {
    var input = changeEvent.target;

    if (input.tagName === 'INPUT' && input.type === 'file' && input.getAttribute('data-direct')) {
      var options = {
        direct:     input.getAttribute('data-direct'),
        presigned:  input.getAttribute('data-presigned'),
        fields:     JSON.parse(input.getAttribute('data-fields')),
        url:        input.getAttribute('data-url'),
        as:         input.getAttribute("data-as")
      };

      var refile = new Refile();

      ['start', 'success', 'failure', 'complete', 'progress'].forEach(function(eventName) {
        var fullEventName = 'upload:' + eventName;
        refile.on(fullEventName, function(eventOptions) {
          dispatchEvent(input, fullEventName, eventOptions)
        });
      });

      ['start', 'complete', 'success', 'failure'].forEach(function(eventName) {
        var fullEventName = 'presign:' + eventName;
        refile.on(fullEventName, function(eventOptions){
          dispatchEvent(input, fullEventName, eventOptions)
        });
      });

      refile.on('uploads:finished', function(requests) {
        if (requests.every(isSuccess)) {
          input.classList.remove("uploading");

          var data = requests.map(function(xhr) {
            var id = xhr.id || JSON.parse(xhr.responseText).id;
            return { id: id, filename: xhr.file.name, content_type: xhr.file.type, size: xhr.file.size };
          });

          var reference = input.getAttribute("data-reference");
          var metadataField = document.querySelector("input[type=hidden][data-reference='" + reference + "']");

          if (!input.multiple) data = data[0];
          if (metadataField) metadataField.value = JSON.stringify(data);

          input.removeAttribute("name");
          dispatchEvent(input, 'uploads:finished')
        };
      });

      var requests = refile.upload(input.files, options);

      if (requests.length > 0) {
        input.classList.add("uploading");
      };
    };
  });
})(Refile)
