/** @eumd */

import module2 from "./module2-es6";
import amd from "%{ amd: \"!undefined\" }";
import var1 from "!var1";
import var2 from "%{ node: \"!var2\" }";
import waterfall from "%{ node: \"async/waterfall\" }";

const fs = require({ node: "fs" });

export default {
    key3: "value3",
    module2,
    amd,
    var1,
    var2,
    waterfall,
    fs
};
