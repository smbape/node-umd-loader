const MethodParser = require("./method-parser");
const factoryParse = MethodParser.parse;
const umdWrapper = require("./umdWrapper");
const factories = require("./factories");

const defaultOptions = {};

module.exports = register;

function register(options) {
    if (require.extensions == null) {
        return;
    }

    if (!global.depsLoader) {
        global.depsLoader = require("./depsLoader");
    }

    options = Object.assign({}, defaultOptions, options);
    options.factories = Object.assign({}, defaultOptions.factories, factories);

    // eslint-disable-next-line guard-for-in
    for (var ext in require.extensions) {
        require.extensions[ext] = wrapLoadFile(require.extensions[ext], options);
    }
}

function wrapLoadFile(_loadFile, options) {
    function loadFile(module, filename) {
        var _compile = module._compile;

        module._compile = function(data, filename) {
            try {
                var parseOptions = Object.assign({}, options);
                parseOptions.factories = Object.keys(parseOptions.factories);
                var parsed = factoryParse(data, parseOptions);
                var name = parsed[1];

                if (name) {
                    if (options.factories && typeof options.factories[name] === "function") {
                        data = options.factories[name](options, filename, data, parsed);
                    }

                    data = umdWrapper(data, options, filename);
                }

            } catch ( err ) {
                console.error(err);
            }

            return _compile.call(module, data, filename);
        };

        _loadFile(module, filename);
    }

    return loadFile;
}
