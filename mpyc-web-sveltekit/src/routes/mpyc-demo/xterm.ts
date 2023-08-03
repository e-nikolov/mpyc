import { Terminal } from 'xterm'; // Breaks in REPL, but should work in prod.
// import xTerm from 'xterm';

export function xterm(node: HTMLElement, data: string) {
    let term = new Terminal();

    term.open(node);
    term.write(data);
}