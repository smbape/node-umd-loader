deps = [ "./module1" ];

const factory = function(module1) {
    return {
        key2: "value2",
        module1
    };
};
