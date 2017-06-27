# Universal module loader

A module that intend to have a control of dependencies per environment. Ex: node, commonjs, amd, brunch

The motive was: I had scripts that could be exactly the same on the client and server as long as there are libraries which exposes the same API.  
It is annoying to have to duplicate because you now have to maintain 2 differents but very similar code. From my experience that gives unecessary headaches.

```javascript
// multiple-depencies.js
deps = [
    {
        amd: "lodash", // require lodash when on an amd environment like requirejs
        common: "lodash", // require lodash when on an environment like commonjs
        brunch: "!_", // use global variable "_" when build with brunch
        node: "lodash" // use lodash in node
    },
    {
        // I hope you guessed
        amd: "jquery",
        common: "jquery",
        brunch: "!jQuery",
        node: "cheerio"
    },
    {
        node: "fs"
        // ignore other environments
    }
];

function factory(_, $, fs) {
    var exposed = {
        key: "value",
        _: _,
        $: $,
        fs: fs
    };
    return exposed;
}
```

```javascript
require("umd-loader").register();
var multiple = require("./multiple-depencies");
if (multiple.fs) {
    // multiple.fs
}

var html = "<html><head></head><body><p>some text</p></body></html>";
var $html = multiple.$.load ? multiple.$.load(html) : multiple.$(html);
var text = $html.find("p").text();
console.log(text);
```

TODO: 
  document usage with node
  document usage with brunch
  document usage with webpack
