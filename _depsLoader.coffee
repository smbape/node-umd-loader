((root, factory) ->
    'use strict'
    if typeof exports isnt 'undefined'
        # Node/CommonJS
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        # AMD
        define [], factory
    else
        root.depsLoader = factory()
    return
) this, ->
    'use strict'

    objectToString = Object::toString
    objectTag = '[object Object]'
    hasProp = Object::hasOwnProperty
    funcToString = Function::toString
    objectCtorString = funcToString.call(Object)

    isObjectLike = (value)->
        return typeof value is 'object' and value isnt null

    isPlainObject = (value)->
        if not isObjectLike(value) or objectToString.call(value) isnt objectTag
            return false

        proto = Object.getPrototypeOf(value)
        if proto is null
            return true

        Ctor = hasProp.call(proto, "constructor") && proto.constructor
        return "function" is typeof Ctor and Ctor instanceof Ctor and funcToString.call(Ctor) is objectCtorString

    resolveName = (dep)->
        dep.replace /(?:(?:\\(.))|(\/\*{1,2})$)/g, (match, escape, pack)->
            return escape if escape
            return "/package" if pack is "/*"
            return "/deepack"

    _processCommonDep = (require, type, dep, global, libs, errors)->
        if dep in [null, undefined]
            libs.push null
            return

        switch dep[0]
            when '!'
                # global depency requested
                throw 'global scope is not defined' if not global
                libs.push global[dep.slice(1)]
            when '$'
                # Ignore dependency. To use with angular as an example
                libs.push null
            else
                dep = resolveName(dep)
                if errors
                    try
                        libs.push require dep
                    catch ex
                        throw ex if typeof errback isnt 'function'
                        errors.push ex
                else
                    libs.push require dep

        return

    _commonRequireDeps = (require, type, deps, global, libs, errors)->
        for dep in deps
            if isPlainObject(dep)
                if Array.isArray type
                    found = null
                    for name in type
                        if hasProp.call(dep, name)
                            found = dep[name]
                            break
                    dep = found
                else
                    dep = dep[type]

            _processCommonDep require, type, dep, global, libs, errors

        return libs

    # Module definition for Common Specification
    commonSpecDefine = (require, type, deps, factory, global)->
        deps = [] if typeof deps is 'undefined'

        # a call for require within the module, will call commonSpecRequire
        localRequire = (deps, callback, errback, options)->
            commonSpecRequire require, type, deps, callback, errback, options, global

        libs = [localRequire]

        _commonRequireDeps(require, type, deps, global, libs)

        factory.apply global, libs

    commonSpecRequire = (require, type, deps, callback, errback, options, global)->

        if typeof deps is 'string'
            deps = [deps]
        else if typeof deps is 'undefined'
            deps = []
        libs = []
        errors = []

        _commonRequireDeps(require, type, deps, global, libs, errors)

        if errors.length isnt 0
            errback.apply global, errors
        else if typeof callback is 'function'
            callback.apply global, libs
        else if deps.length is 1
            libs[0]

    _processAmdDep = (global, libs, availables, map, dep, index)->
        if dep in [null, undefined]
            availables[index] = null
            return

        switch dep[0]
            when '!'
                # global depency requested
                throw 'global scope is not defined' if not global
                availables[index] = global[dep.slice(1)]
            when '$'
                # Ignore dependency. To use with angular as an example
                availables[index] = null
            else
                map[libs.length] = index
                dep = resolveName(dep)
                libs.push dep

        return

    amdDefine = (name, deps, factory, global)->
        if arguments.length is 3
            global = factory
            factory = deps
            deps = name
            name = null

        deps = [] if typeof deps is 'undefined'
        libs = ['require']
        availables = []
        map = {}

        for dependency, index in deps
            if typeof dependency is 'string'
                _processAmdDep(global, libs, availables, map, dependency, index + 1)
            else if isPlainObject(dependency)
                _processAmdDep(global, libs, availables, map, dependency.amd, index + 1)

        callback = (require)->
            for index in [1...arguments.length] by 1
                availables[map[index]] = arguments[index]

            localRequire = (deps, callback, errback, options)->
                amdRequire require, deps, callback, errback, options, global
            availables[0] = localRequire

            factory.apply global, availables

        if name
            define name, libs, callback
        else
            define libs, callback

    amdRequire = (require, deps, callback, errback, options, global)->

        if typeof deps is 'string'
            deps = [deps]
        else if typeof deps is 'undefined'
            deps = []
        libs = []
        availables = []
        map = {}

        for dependency, index in deps
            if typeof dependency is 'string'
                _processAmdDep(global, libs, availables, map, dependency, index)
            else if isPlainObject(dependency)
                _processAmdDep(global, libs, availables, map, dependency.amd, index)

        if typeof callback isnt 'function' and deps.length is 1
            return availables[0]

        if libs.length is 0
            return callback.apply global, availables

        require libs, ->
            for lib, index in arguments
                availables[map[index]] = lib
            callback.apply global, availables
        , errback
        return

    exports =
        common: commonSpecDefine
        amd: amdDefine

    exports.createNgModule = (angular, name, ngdeps, ngmap, resolvedDeps)->
        toRegister = []
        for dusable, index in resolvedDeps
            if dusable.$ng
                # this is not a module injectable dependency
                toRegister.unshift index

        # remove non injectable dependencies
        for index in toRegister
            ngdeps.splice ngmap[index], 1

        app = angular.module(name, ngdeps)
        app.name = name

        # register usables
        for index in toRegister
            resolvedDeps[index] app

        app

    exports.createNgUsable = (ctor, ngmethod, $name, $path, $dirname, $shortName, ngdeps, resolvedDeps, ngmap)->

        switch ngmethod
            when 'controller'
                name = ctor::$name or (ctor::$name = $name)
                ctor::$path = $path
                ctor::$dirname = $dirname
            when 'directive', 'filter'
                name = $shortName.replace /\-([a-z])/g, (match) ->
                    match[1].toUpperCase()
            else
                name = $name

        usable = (app)->
            toRemove = []
            app.dependencies or (app.dependencies = {})
            app.dependencies[ngmethod] or (app.dependencies[ngmethod] = {})

            if !hasProp.call(app.dependencies[ngmethod], name)
                # first instruction to prevent infinite loop with recursion
                app.dependencies[ngmethod][name] = true

                # recursively register usable dependencies
                for dusable, i in resolvedDeps
                    if dusable.$ng
                        switch dusable.$ng
                            when 'usable', 'config', 'run', 'controller', 'directive', 'filter'
                                # this is not an injectable dependency
                                # unshift to loop from higher to lower
                                # this ensure slice is done on the correct element
                                toRemove.unshift ngmap[i]
                            else
                                ngdeps[ngmap[i]] = dusable.$name

                        dusable.apply null, arguments

                # remove non injectable dependencies
                for index in toRemove
                    ngdeps.splice index, 1

                if ngmethod is 'usable'
                    ctor.apply null, arguments
                    return

                withoutName = ngmethod in ['config', 'run']

                # register this usable
                if withoutName
                    app[ngmethod] ctor
                else
                    app[ngmethod] name, ctor
            return

        ctor.$inject = ngdeps
        usable.$name = name
        usable.$path = $path
        usable.$dirname = $dirname
        usable.ctor = ctor
        usable.$ng = ngmethod

        usable

    isValidContainer = (value)->
        # ELEMENT_NODE, DOCUMENT_NODE, DOCUMENT_FRAGMENT_NODE
        return isObjectLike(value) and value.nodeType in [1, 9, 11] and !isPlainObject(value)

    extend = (target, src)->
        if isObjectLike(src) and isObjectLike(target)
            for prop of src
                target[prop] = src[prop]
        target

    browserExtend = (exports)->
        if typeof window is 'undefined' or typeof window.window isnt 'object' or window.window.window isnt window.window
            return

        head = document.getElementsByTagName('head')[0]

        # Oh the tragedy, detecting opera. See the usage of isOpera for reason.
        isOpera = typeof opera isnt 'undefined' and opera.toString() is '[object Opera]'

        load = (attributes, container, callback, errback, completeback)->
            if ("function" is typeof container or !isValidContainer(container)) and arguments.length is 4
                [ _null, _null, callback, errback, completeback ] = arguments
                container = null

            if container in [ null, undefined ]
                container = head

            node = document.createElement attributes.tag
            node.charset = 'utf-8'
            node.async = true
            for attr, value of attributes
                if attr isnt 'tag' and node[attr] isnt value
                    node.setAttribute attr, value

            context = getContext callback, errback, completeback

            # ===========================
            # Taken from requirejs 2.1.11
            # ===========================

            # Set up load listener. Test attachEvent first because IE9 has
            # a subtle issue in its addEventListener and script onload firings
            # that do not match the behavior of all other browsers with
            # addEventListener support, which fire the onload event for a
            # script right after the script execution. See:
            # https://connect.microsoft.com/IE/feedback/details/648057/script-onload-event-is-not-fired-immediately-after-script-execution
            # UNFORTUNATELY Opera implements attachEvent but does not follow the script
            # script execution mode.

            # Check if node.attachEvent is artificially added by custom script or
            # natively supported by browser
            # read https://github.com/jrburke/requirejs/issues/187
            # if we can NOT find [native code] then it must NOT natively supported.
            # in IE8, node.attachEvent does not have toString()
            # Note the test for '[native code' with no closing brace, see:
            # https://github.com/jrburke/requirejs/issues/273
            if node.attachEvent and
            not (node.attachEvent.toString and node.attachEvent.toString().indexOf('[native code') < 0) and
            not isOpera

                # Probably IE. IE (at least 6-8) do not fire
                # script onload right after executing the script, so
                # we cannot tie the anonymous define call to a name.
                # However, IE reports the script as being in 'interactive'
                # readyState at the time of the define call.
                useInteractive = true
                node.attachEvent 'onreadystatechange', context.onScriptLoad

            # It would be great to add an error handler here to catch
            # 404s in IE9+. However, onreadystatechange will fire before
            # the error handler, so that does not help. If addEventListener
            # is used, then IE will fire error before load, but we cannot
            # use that pathway given the connect.microsoft.com issue
            # mentioned above about not doing the 'script execute,
            # then fire the script load event listener before execute
            # next script' that other browsers do.
            # Best hope: IE10 fixes the issues,
            # and then destroys all installs of IE 6-9.
            # node.attachEvent('onerror', context.onScriptError);
            else
                node.addEventListener 'load', context.onScriptLoad, false
                node.addEventListener 'error', context.onScriptError, false

            container.appendChild node
            return node

        readyRegExp = /^(?:complete|loaded)$/

        removeListener = (node, func, name, ieName) ->

            # Favor detachEvent because of IE9
            # issue, see attachEvent/addEventListener comment elsewhere
            # in this file.
            if node.detachEvent and not isOpera

                # Probably IE. If not it will throw an error, which will be
                # useful to know.
                node.detachEvent ieName, func if ieName
            else
                node.removeEventListener name, func, false
            return

        ###
        Given an event from a script node, get the requirejs info from it,
        and then removes the event listeners on the node.
        @param {Event} evt
        @returns {Object}
        ###
        onScriptComplete = (context, evt, completeback) ->

            # Using currentTarget instead of target for Firefox 2.0's sake. Not
            # all old browsers will be supported, but this one was easy enough
            # to support and still makes sense.
            node = evt.currentTarget or evt.srcElement

            # Remove the listeners once here.
            removeListener node, context.onScriptLoad, 'load', 'onreadystatechange'
            removeListener node, context.onScriptError, 'error'
            completeback() if typeof completeback is 'function'
            return

        getContext = (callback, errback, completeback)->
            context =
                ###
                callback for script loads, used to check status of loading.

                @param {Event} evt the event from the browser for the script
                that was loaded.
                ###
                onScriptLoad: (evt) ->
                    # Using currentTarget instead of target for Firefox 2.0's sake. Not
                    # all old browsers will be supported, but this one was easy enough
                    # to support and still makes sense.
                    if evt.type is 'load' or readyRegExp.test((evt.currentTarget or evt.srcElement).readyState)
                        callback() if typeof callback is 'function'
                        onScriptComplete context, evt, completeback
                    return

                ###
                Callback for script errors.
                ###
                onScriptError: (evt) ->
                    errback() if typeof errback is 'function'
                    onScriptComplete context, evt, completeback
                    return

        exports.load = load

        exports.getScript = getScript = (src, container = head)->
            scripts = container.getElementsByTagName 'script'
            a = document.createElement 'a'
            a.setAttribute 'href', src
            for script in scripts
                if script.src is a.href
                    found = script
                    break
            a = null

            return found

        exports.loadScript = loadScript = (src, attributes, container, callback, errback, completeback)->
            if ("function" is typeof container or !isValidContainer(container)) and arguments.length is 5
                [ _null, _null, callback, errback, completeback ] = arguments
                container = null

            if getScript src, container
                # console.log 'script already loaded', src
                callback() if typeof callback is 'function'
                completeback() if typeof completeback is 'function'
                return

            attributes = extend
                tag: 'script'
                type: 'text/javascript'
                src: src
            , attributes

            return load attributes, container, callback, errback, completeback

    browserExtend exports
    return exports
