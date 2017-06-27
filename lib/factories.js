module.exports = {
    factory(plugin, modulePath, data, parsed) {
        const args = parsed[2];
        const head = parsed[3];
        const declaration = parsed[4];
        const body = parsed[5];
        let index;

        if ("require" !== args[0]) {
            while (index = args.indexOf("require") !== -1) {
                args[index] = "undefined";
            }

            args.unshift("require");
            data = String(head) + declaration + args.join(", ") + body;
        }

        return data;
    }
};