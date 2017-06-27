module.exports = umdWrapper;

function umdWrapper(data, options, filename) {
    var strict = "";

    if (options.strict) {
        data = removeStrictOptions(data);
        strict = "'use strict'";
    }

    return `(function(require, global) {${strict}; var deps = [];${data}

        if (typeof process === 'object' && typeof process.platform !== 'undefined') {
            // NodeJs
            module.exports = depsLoader.common(require, 'node', deps, factory, global);
        } else if (typeof exports !== 'undefined') {
            // CommonJS
            module.exports = depsLoader.common(require, global.require && global.require.brunch ? ['brunch', 'common'] : 'common', deps, factory, global);
        } else if (typeof define === 'function' && define.amd) {
            // AMD
            depsLoader.amd(deps, factory, global);
        }
        }(require, typeof window !== 'undefined' && window === window.window ? window : typeof global !== 'undefined' ? global : null));`;
}

function removeStrictOptions(str) {
    return str.replace(/^\s*(['"])use strict\1;?[^\n]*$/m, "");
}