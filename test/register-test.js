var fs = require("fs");
var waterfall = require("async/waterfall");

describe("register", function() {
    var module1, module2, module3;
    require("../lib/register");

    it("should require with no dependencies", () => {
        module1 = require("./umd_modules/module1");
        expect(module1).to.deep.equal({
            key1: "value1"
        });
    });

    it("should require with local dependency", () => {
        module2 = require("./umd_modules/module2");
        expect(module2).to.deep.equal({
            key2: "value2",
            module1: module1
        });
        expect(module2.module1).to.equal(module1);
    });

    it("should require local umd as well as node modules and native modules", () => {
        global.var1  = "var1";
        global.var2  = "var2";

        module3 = require("./umd_modules/module3");
        expect(module3).to.deep.equal({
            key3: "value3",
            module2: module2,
            _undefined: undefined,
            var1: global.var1,
            var2: global.var2,
            waterfall: waterfall,
            fs: fs
        });
        expect(module3.module2).to.equal(module2);
    });
})