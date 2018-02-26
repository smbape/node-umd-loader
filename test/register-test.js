const fs = require("fs");
const waterfall = require("async/waterfall");

describe("register", () => {
    let module1, module2, module3;
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
            module1
        });
        expect(module2.module1).to.equal(module1);
    });

    it("should require local umd as well as node modules and native modules", () => {
        global.var1 = "var1";
        global.var2 = "var2";

        module3 = require("./umd_modules/module3");
        expect(module3).to.deep.equal({
            key3: "value3",
            module2,
            amd: undefined,
            var1: global.var1,
            var2: global.var2,
            waterfall,
            fs
        });
        expect(module3.module2).to.equal(module2);
    });

    it("should require with no dependencies es6", () => {
        module1 = require("./umd_modules/module1-es6");
        expect(module1).to.deep.equal({
            key1: "value1"
        });
    });

    it("should require with local dependency es6", () => {
        module2 = require("./umd_modules/module2-es6");
        expect(module2).to.deep.equal({
            key2: "value2",
            module1
        });
        expect(module2.module1).to.equal(module1);
    });

    it("should require local umd as well as node modules and native modules es6", () => {
        global.var1 = "var11";
        global.var2 = "var21";

        module3 = require("./umd_modules/module3-es6");
        expect(module3).to.deep.equal({
            key3: "value3",
            module2,
            amd: undefined,
            var1: global.var1,
            var2: global.var2,
            waterfall,
            fs
        });
        expect(module3.module2).to.equal(module2);
    });
});
