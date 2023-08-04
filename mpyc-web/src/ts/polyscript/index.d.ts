export { env } from "./listeners.js";
export const XWorker: (url: string, options?: import("./worker/class.js").WorkerOptions & { async: boolean }) => Worker & { sync: any };
export { define, whenDefined } from "./custom.js";
// export { registry, interpreter, configs } from "./interpreters.js";
// export { default } from "./interpreter/pyodide.js";
// export { runAsync, run, registerJSModule } from "./interpreter/_python.js";
