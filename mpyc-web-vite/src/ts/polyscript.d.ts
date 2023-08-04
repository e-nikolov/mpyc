declare module 'polyscript' {
    export const env: typeof import("./polyscript/index").env;
    export const XWorker: typeof import("./polyscript/index").XWorker;
    export const define: typeof import("./polyscript/index").define;
    export const whenDefined: typeof import("./polyscript/index").whenDefined;
}
