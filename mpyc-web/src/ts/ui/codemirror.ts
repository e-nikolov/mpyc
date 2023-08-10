import { basicSetup, EditorView } from 'codemirror';
import { python } from '@codemirror/lang-python';
import { indentUnit } from '@codemirror/language';
import { Compartment, Prec } from '@codemirror/state';
import { keymap } from '@codemirror/view';
import { copyLineDown, defaultKeymap, deleteLine, moveLineDown, moveLineUp, redo } from '@codemirror/commands';
import { birdsOfParadise } from 'thememirror';
import { indentWithTab, } from "@codemirror/commands"
import { MPyCManager } from '../mpyc';

import * as ui from '.';

export function makeEditor(pySrc: string, selector: string, mpyc: MPyCManager): EditorView {
    // let parent = document.querySelector(selector)?.attachShadow({ mode: 'open' });

    const languageConf = new Compartment();
    let extensions = [
        indentUnit.of('    '),
        basicSetup,
        languageConf.of(python()),

        keymap.of([
            ...defaultKeymap,
            indentWithTab,
        ]),
        Prec.highest(
            keymap.of([
                {
                    key: 'Ctrl-Enter', run: () => {
                        ui.getCodeFromEditor().then((code: string) => { mpyc.runMPC(code, false) });
                        return true;
                    }, preventDefault: true
                },
                {
                    key: 'Shift-Enter', run: () => {
                        ui.getCodeFromEditor().then((code: string) => { mpyc.runMPC(code, true) });
                        return true;
                    }, preventDefault: true
                },
                {
                    key: 'Ctrl-s', run: () => {
                        localStorage.customCode = ui.editor.state.doc.toString();
                        if (ui.demoSelector.selectedIndex != 0) {
                            ui.demoSelector.selectedIndex = 0;
                        }
                        return true;
                    }, preventDefault: true
                },
                { key: 'Ctrl-Shift-z', run: redo, preventDefault: true },
                { key: 'Ctrl-d', run: copyLineDown, preventDefault: true },
                { key: 'Ctrl-Shift-ArrowUp', run: moveLineUp, preventDefault: true },
                { key: 'Ctrl-Shift-ArrowDown', run: moveLineDown, preventDefault: true },
                { key: 'Ctrl-y', run: deleteLine, preventDefault: true },
            ])
        ),
    ];

    extensions.push(birdsOfParadise);

    return new EditorView({
        doc: pySrc,
        extensions,
        parent: document.querySelector(selector)!,
    });
}