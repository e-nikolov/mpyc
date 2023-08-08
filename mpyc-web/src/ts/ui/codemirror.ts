import { basicSetup, EditorView } from 'codemirror';
import { python } from '@codemirror/lang-python';
import { indentUnit } from '@codemirror/language';
import { Compartment, Extension, Prec } from '@codemirror/state';
import { keymap, Command, DOMEventHandlers, ViewUpdate } from '@codemirror/view';
import { defaultKeymap } from '@codemirror/commands';
import { oneDarkTheme } from '@codemirror/theme-one-dark';
import { birdsOfParadise } from 'thememirror';
import { ui } from 'jquery';
import { indentWithTab } from "@codemirror/commands"

export function makeEditor(pySrc: string, selector: string, exec: Command, save: Command): EditorView {
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
                { key: 'Ctrl-Enter', run: exec, preventDefault: true },
                { key: 'Shift-Enter', run: exec, preventDefault: true },
                { key: 'Ctrl-s', run: save, preventDefault: true },
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