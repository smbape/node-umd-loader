deps = [{
    node: "./module2"
}, {
    amd: "!undefined"
}, "!var1", {
    node: "!var2"
}, {
    node: "async/waterfall"
}, "fs"];

function factory(module2, amd, var1, var2, waterfall, fs) {
    return {
        key3: "value3",
        module2,
        amd,
        var1,
        var2,
        waterfall,
        fs
    };
}
