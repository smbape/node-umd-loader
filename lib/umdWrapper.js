module.exports = umdWrapper;

function umdWrapper(data, options, filename) {
    var strict = "";

    if (options.strict) {
        data = removeStrictOptions(data);
        strict = "'use strict'";
    }

    return `
(function(require) {${strict}; var deps = [];${data};(function(factory, deps) {
    var g;
    if (typeof window !== "undefined") {
        g = window;
    } else if (typeof global !== "undefined") {
        g = global;
    } else if (typeof self !== "undefined") {
        g = self;
    } else {
        g = this;
    }

    if (typeof process === "object" && typeof process.platform !== "undefined") {
        // NodeJs
        module.exports = depsLoader.common(require, "node", deps, factory, g);
    } else if (typeof exports === "object" && typeof module !== "undefined") {
        // CommonJS
        module.exports = depsLoader.common(require, g.require && g.require.brunch ? ["brunch", "common"] : "common", deps, factory, g);
    } else if (typeof define === "function" && define.amd) {
        // AMD
        depsLoader.amd(deps, factory, g);
    }
})(factory, deps);
})(typeof require !== "undefined" ? require : undefined);
`.trim();
}

function removeStrictOptions(str) {
    return str.replace(/^\s*(['"])use strict\1;?[^\n]*$/m, "");
}