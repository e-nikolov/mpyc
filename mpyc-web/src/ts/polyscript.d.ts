declare module 'polyscript' {
    export type WorkerOptions = {
        /**
         * the interpreter type to use
         */
        type: string;
        /**
         * the optional interpreter version to use
         */
        version?: string;
        /**
         * the optional config to use within such interpreter
         */
        config?: string;

        async?: boolean;

    };
    // export const XWorker: typeof XWorker & { sync: any };
    export const XWorker: (url: string, options?: WorkerOptions) => Worker & { sync: any };
}
