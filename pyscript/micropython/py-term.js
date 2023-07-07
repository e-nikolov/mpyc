// src/plugins/pyterminal.ts
var knownPyTerminalTags = /* @__PURE__ */ new WeakSet();
var logger7 = getLogger("py-terminal");
var PyTerminalPlugin = class extends Plugin {
    constructor(app) {
        super();
        this.app = app;
    }
    configure(config2) {
        validateConfigParameterFromArray({
            config: config2,
            name: "terminal",
            possibleValues: [true, false, "auto"],
            defaultValue: "auto"
        });
        validateConfigParameterFromArray({
            config: config2,
            name: "docked",
            possibleValues: [true, false, "docked"],
            defaultValue: "docked"
        });
        validateConfigParameterFromArray({
            config: config2,
            name: "xterm",
            possibleValues: [true, false, "xterm"],
            defaultValue: false
        });
    }
    beforeLaunch(config2) {
        const { terminal: t2, docked: d, xterm: x } = config2;
        const auto = t2 === true || t2 === "auto";
        const docked = d === true || d === "docked";
        const xterm = x === true || x === "xterm";
        if (auto && $("py-terminal", document) === null) {
            logger7.info("No <py-terminal> found, adding one");
            const termElem = document.createElement("py-terminal");
            if (auto)
                termElem.setAttribute("auto", "");
            if (docked)
                termElem.setAttribute("docked", "");
            if (xterm)
                termElem.setAttribute("xterm", "");
            document.body.appendChild(termElem);
        }
    }
    afterSetup(_interpreter) {
        const PyTerminal = _interpreter.config.xterm ? make_PyTerminal_xterm(this.app) : make_PyTerminal_pre(this.app);
        customElements.define("py-terminal", PyTerminal);
    }
};
var PyTerminalBaseClass = class extends HTMLElement {
    isAuto() {
        return this.hasAttribute("auto");
    }
    isDocked() {
        return this.hasAttribute("docked");
    }
    setupPosition(app) {
        if (this.isAuto()) {
            this.classList.add("py-terminal-hidden");
            this.autoShowOnNextLine = true;
        } else {
            this.autoShowOnNextLine = false;
        }
        if (this.isDocked()) {
            this.classList.add("py-terminal-docked");
        }
        logger7.info("Registering stdio listener");
        app.registerStdioListener(this);
    }
};
function make_PyTerminal_pre(app) {
    class PyTerminalPre extends PyTerminalBaseClass {
        connectedCallback() {
            this.outElem = document.createElement("pre");
            this.outElem.classList.add("py-terminal");
            this.appendChild(this.outElem);
            this.setupPosition(app);
        }
        // implementation of the Stdio interface
        stdout_writeline(msg) {
            this.outElem.innerText += msg + "\n";
            if (this.isDocked()) {
                this.scrollTop = this.scrollHeight;
            }
            if (this.autoShowOnNextLine) {
                this.classList.remove("py-terminal-hidden");
                this.autoShowOnNextLine = false;
            }
        }
        stderr_writeline(msg) {
            this.stdout_writeline(msg);
        }
        // end of the Stdio interface
    }
    return PyTerminalPre;
}
function make_PyTerminal_xterm(app) {
    class PyTerminalXterm extends PyTerminalBaseClass {
        constructor() {
            super();
            this._xterm_cdn_base_url = "https://cdn.jsdelivr.net/npm/xterm@5.1.0";
            this.cachedStdOut = [];
            this.cachedStdErr = [];
            this._moduleResolved = false;
            this.style.width = "100%";
            this.style.height = "100%";
        }
        async connectedCallback() {
            if (knownPyTerminalTags.has(this))
                return;
            knownPyTerminalTags.add(this);
            this.outElem = document.createElement("div");
            this.appendChild(this.outElem);
            this.setupPosition(app);
            this.xtermReady = this._setupXterm();
            await this.xtermReady;
        }
        /**
         * Fetch the xtermjs library from CDN an initialize it.
         * @private
         * @returns the associated xterm.js Terminal
         */
        async _setupXterm() {
            if (this.xterm == void 0) {
                if (globalThis.Terminal == void 0) {
                    await import(this._xterm_cdn_base_url + "/lib/xterm.js");
                    const cssTag = document.createElement("link");
                    cssTag.type = "text/css";
                    cssTag.rel = "stylesheet";
                    cssTag.href = this._xterm_cdn_base_url + "/css/xterm.css";
                    document.head.appendChild(cssTag);
                }
                this.xterm = new Terminal({ screenReaderMode: true, cols: 80 });
                if (!this.autoShowOnNextLine)
                    this.xterm.open(this);
                this._moduleResolved = true;
                this.cachedStdOut.forEach((value) => this.stdout_writeline(value));
                this.cachedStdErr.forEach((value) => this.stderr_writeline(value));
            } else {
                this._moduleResolved = true;
            }
            return this.xterm;
        }
        // implementation of the Stdio interface
        stdout_writeline(msg) {
            if (this._moduleResolved) {
                this.xterm.writeln(msg);
                if (this.isDocked()) {
                    this.scrollTop = this.scrollHeight;
                }
                if (this.autoShowOnNextLine) {
                    this.classList.remove("py-terminal-hidden");
                    this.autoShowOnNextLine = false;
                    this.xterm.open(this);
                }
            } else {
                this.cachedStdOut.push(msg);
            }
        }
        stderr_writeline(msg) {
            this.stdout_writeline(msg);
        }
        // end of the Stdio interface
    }
    return PyTerminalXterm;
}