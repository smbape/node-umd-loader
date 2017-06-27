var fs = require("fs");
var sysPath = require("path");
var anyspawn = require("anyspawn");

var bowerFile = sysPath.resolve(__dirname, "../bower.json");

anyspawn.spawnSeries([
    function(next) {
        fs.readFile(bowerFile, function(err, data) {
            if (err) {
                next(err);
                return;
            }

            var version = require("../package").version;
            var content = data.toString();
            content = content.replace(/^(\s*"version":\s*)"([^"]+)"/mg, "$1\"" + version + "\"");
            fs.writeFile(bowerFile, content, next);
        });
    },

    ["git", ["add", bowerFile]]
], function(err) {
    if (err) {
        throw err;
    }
});
