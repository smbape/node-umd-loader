deps = [ "./module1" ];

var factory = function(module1) {
    return {
        key2: "value2",
        module1: module1
    };
}