deps = [{
    node: "./module2"
}, {}, "!var1", {
    node: "!var2"
}, {
    "node": "async/waterfall"
}, "fs"];

function factory(module2, _undefined, var1, var2, waterfall, fs) {
    return {
        key3: "value3",
        module2: module2,
        _undefined: _undefined,
        var1: var1,
        var2: var2,
        waterfall: waterfall,
        fs: fs
    };
}
