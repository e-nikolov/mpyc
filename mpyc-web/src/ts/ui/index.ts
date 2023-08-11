import { MPyCManager } from '../mpyc';
import * as ui from '.';
import { Tooltip } from 'bootstrap';
import { Terminal } from 'xterm';
import { EditorView } from '@codemirror/view';

import $ from 'jquery'
import 'jquery-resizable-dom'
import { FitAddon } from 'xterm-addon-fit';

export * from './copy-btn';
export * from './term';
export * from './elements';
export * from './chat';
export * from './qr';
export * from './peers';
export * from './codemirror';


export function ensureStorageSchema(gen: number) {
    console.log("Storage schema generation:", localStorage.gen)
    localStorage.gen ||= 0;
    if (localStorage.gen < gen) {
        console.log(`Clearing schema, latest generation: ${gen}`)
        localStorage.clear();
        sessionStorage.clear();
        localStorage.gen = gen;
    }
}
export var editor: EditorView;

export function init(mpyc: MPyCManager) {
    ui.term.writeln('Initializing PeerJS...');

    mpyc.on('peerjs:ready', (peerID: string) => {
        ui.myPeerIDEl.value = ui.safe(peerID);
        setTabState('myPeerID', peerID);

        console.log('My peer ID is: ' + peerID);
        ui.term.writeln('PeerJS ready with ID: ' + peerID);
        ui.updateKnownPeersDiv(mpyc);
    });
    mpyc.on('peerjs:closed', () => { ui.term.writeln('PeerJS closed.'); });
    mpyc.on('peerjs:error', (err: Error) => { ui.term.writeln('PeerJS failed: ' + err.message); });
    mpyc.on('peerjs:conn:ready', ui.onPeerConnectedHook);
    mpyc.on('peerjs:conn:disconnected', ui.onPeerDisconnectedHook);
    mpyc.on('peerjs:conn:error', ui.onPeerConnectionErrorHook);
    mpyc.on('peerjs:conn:data:user:chat', ui.processChatMessage);
    mpyc.on('worker:error', (err: Error) => { ui.term.writeln(err.message); });
    mpyc.on('worker:run', (mpyc: MPyCManager) => { ui.updateKnownPeersDiv(mpyc); });
    mpyc.on('worker:display', (message: string) => { ui.term.writeln(message); });
    mpyc.on('worker:display:raw', (message: string) => { ui.term.write(message); });
    ui.term.writeln('Initializing PyScript runtime...');
    mpyc.on('worker:ready', () => { ui.term.writeln('PyScript runtime ready.'); });
    mpyc.on('peerjs:conn:data:mpyc:ready', () => { ui.updateKnownPeersDiv(mpyc); });

    ui.resetPeerIDButton.addEventListener('click', () => { delete sessionStorage.myPeerID; ui.term.writeln("Restarting PeerJS..."); mpyc.resetPeer(""); });
    ui.stopMPyCButton.addEventListener('click', () => { ui.term.writeln("Restarting PyScript runtime..."); mpyc.resetWorker(); });
    ui.runMPyCButton.addEventListener('click', async () => { mpyc.runMPC(await getCodeFromEditor(), false); });
    ui.runMPyCAsyncButton.addEventListener('click', async () => mpyc.runMPC(await getCodeFromEditor(), true));
    ui.connectToPeerButton.addEventListener('click', () => { localStorage.hostPeerID = ui.hostPeerIDInput.value; mpyc.connectToPeer(ui.hostPeerIDInput.value) });
    ui.sendMessageButton.addEventListener('click', () => { ui.sendChatMessage(mpyc); });
    ui.clearTerminalButton.addEventListener('click', () => { ui.term.clear(); });

    const urlParams = new URLSearchParams(window.location.search);
    const peer = urlParams.get('peer');
    var hostPeerID = peer || localStorage.hostPeerID;
    if (hostPeerID) {
        ui.hostPeerIDInput.value = hostPeerID;
        localStorage.hostPeerID = hostPeerID;
    }

    ui.makeCopyButton('#myPeerID', 'button#copyPeerID');


    ui.chatInput.addEventListener('keypress', function (e: Event) {
        let ev = e as KeyboardEvent;

        if (ev.key === 'Enter' && !ev.shiftKey) {
            ev.preventDefault();
            return ui.sendChatMessage(mpyc);
        }
    });

    var myDefaultAllowList = Tooltip.Default.allowList;
    myDefaultAllowList.span = ['style'];
    myDefaultAllowList.canvas = [];


    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
    tooltipTriggerList.forEach(tooltipTriggerEl => new Tooltip(tooltipTriggerEl,));

    if (window.innerWidth < 800) {
        ui.demoSelector.size = 0;
    }
    ui.demoSelector.selectedIndex = parseInt(localStorage.demoSelectorSelectedIndex) || 1;

    ui.demoSelector.onchange = async () => {
        localStorage.demoSelectorSelectedIndex = ui.demoSelector.selectedIndex;
        let demoCode = await fetchSelectedDemo();
        updateEditor(demoCode);
        ui.editor.focus();
    }

    ui.fetchSelectedDemo().then((code) => {
        editor = ui.makeEditor(
            code,
            "#editor",
            mpyc,
        )

        document.editor = editor;
    });

    ui.initQRCodeUI();
    document.mpyc = mpyc;
    document.clearTabCount = () => { delete localStorage.tabCount }
    document.r = () => { mpyc.reset("") };
    document.run = async () => mpyc.runMPC(await getCodeFromEditor(), false);
    document.runa = async () => mpyc.runMPC(await getCodeFromEditor(), true);

    // debounce resize

    let resizeTimeout: NodeJS.Timeout;
    let ro = new ResizeObserver(() => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(() => {
            console.log("resized editor!")
            document.fitAddon.fit();
        }, 50);
    });

    ro.observe(document.querySelector(".xterm")!)
    // document.querySelector(".xterm")?.addEventListener('resize', () => {
    //     console.log("resized editor!")
    //     ui.editor.requestMeasure();
    //     document.fitAddon.fit();
    // })



    $(".panel-top").resizableSafe({
        handleSelector: ".splitter-horizontal",
        resizeWidth: false
    });
}

function updateEditor(code: string) {
    editor.dispatch({
        changes: { from: 0, to: editor.state.doc.length, insert: code },
        selection: { anchor: 0, head: 0 }
    });
}

export async function fetchSelectedDemo(): Promise<string> {
    var demoCode: string;
    if (ui.demoSelector.selectedIndex == 0) {
        demoCode = localStorage.customCode || "";
    } else {
        demoCode = await ui.fetchDemoCode(ui.demoSelector.value);
    }
    return demoCode;
}

export async function fetchDemoCode(src = "./py/main.py"): Promise<string> {
    let contents = await fetch(src)
    let pyCode = await contents.text()
    return pyCode;
}

export async function getCodeFromEditor(): Promise<string> {
    return ui.editor.state.doc.toString();
}

// TODO: not thread safe, breaks if tabs open too quickly
export function loadPeerID(): string {
    localStorage.tabCount ||= 0;
    let tabCount = parseInt(localStorage.tabCount);
    localStorage.tabCount = tabCount + 1;

    addEventListener('beforeunload', function () {
        let tabCount = parseInt(localStorage.tabCount);
        if (tabCount > 0) {
            localStorage.tabCount = tabCount - 1;
        }
    });

    // Duplicated Tabs will have the same tabID and peerID as their parent Tab; we must force reset those values
    if (!sessionStorage.tabID || window.performance.getEntriesByType("navigation")[0].type == 'back_forward') {
        sessionStorage.tabID = localStorage.tabCount;
        sessionStorage.myPeerID = ui.getTabState("myPeerID");
    }

    console.log("tab id: " + sessionStorage.tabID);
    return sessionStorage.myPeerID;
}


export function getTabState(key: string) {
    let tabID = sessionStorage.tabID;
    return localStorage[`tabState:${tabID}:` + key] || "";
}

export function setTabState(key: string, value: any) {
    let tabID = sessionStorage.tabID;
    sessionStorage[key] = value;
    localStorage[`tabState:${tabID}:` + key] = value;
}

declare global {
    interface JQuery {
        resizableSafe: (obj: any) => void;
    }
    interface Document {
        clearTabCount: any;
        r: any;
        run: any;
        runa: any;
        mpyc: MPyCManager;
        term: Terminal;
        editor: EditorView;
        fitAddon: FitAddon;
    }
    interface PerformanceEntry {
        type: string;
    }
}