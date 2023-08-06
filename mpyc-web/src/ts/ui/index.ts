import { MPyCManager } from '../mpyc';
import * as ui from '.';
import { Tooltip } from 'bootstrap';

export * from './copy-btn';
export * from './term';
export * from './elements';
export * from './chat';
export * from './qr';

export function initUI(mpyc: MPyCManager, initMPyC: () => void) {
    ui.term.writeln('Initializing PeerJS...');
    mpyc.on('peerjs:ready', (peerID: string) => {
        console.log(peerID)
        ui.myPeerIDEl.value = ui.safe(peerID);
        localStorage.setItem('myPeerID', peerID);
        console.log('My peer ID is: ' + peerID);
        ui.term.writeln('PeerJS ready with ID: ' + peerID);
    });
    mpyc.on('peerjs:closed', (e) => {
        console.log(e);
        ui.term.writeln('PeerJS closed.');
    });
    mpyc.on('peerjs:error', (err: Error) => {
        ui.term.writeln('PeerJS failed: ' + err.message);
    });
    mpyc.on('peerjs:conn:ready', ui.onPeerConnectedHook);
    mpyc.on('peerjs:conn:disconnected', ui.onPeerDisconnectedHook);
    mpyc.on('peerjs:conn:error', ui.onPeerConnectionErrorHook);
    mpyc.on('peerjs:conn:data:user:chat', ui.processChatMessage);
    mpyc.on('worker:error', (err: Error) => {
        ui.term.writeln(err.message);
    });
    mpyc.on('worker:display', (message: string) => {
        ui.term.writeln(message);
    });
    mpyc.on('worker:display:raw', (message: string) => {
        ui.term.write(message);
    });
    ui.term.writeln('Initializing PyScript runtime...');
    mpyc.on('worker:ready', () => {
        ui.term.writeln('PyScript runtime ready.');
    });

    ui.resetPeerIDButton.addEventListener('click', () => { localStorage.removeItem('myPeerID'); console.log('resetPeerID'); initMPyC() });
    ui.runMPyCButton.addEventListener('click', () => { mpyc.runMPyCDemo(false); });
    ui.runMPyCAsyncButton.addEventListener('click', () => mpyc.runMPyCDemo(true));
    ui.stopMPyCButton.addEventListener('click', () => { console.log('resetPeerID2'); initMPyC() });
    ui.connectToPeerButton.addEventListener('click', () => { localStorage.setItem('hostPeerID', ui.hostPeerIDInput.value); mpyc.connectToPeer(ui.hostPeerIDInput.value) });
    ui.sendMessageButton.addEventListener('click', () => { ui.sendChatMessage(mpyc); });

    if (localStorage.getItem('myPeerID')) {
        ui.myPeerIDEl.value = localStorage.getItem('myPeerID')!;
    }

    const urlParams = new URLSearchParams(window.location.search);
    const peer = urlParams.get('peer');
    var hostPeerID = peer || localStorage.getItem('hostPeerID');
    if (hostPeerID) {
        ui.hostPeerIDInput.value = hostPeerID;
        localStorage.setItem('hostPeerID', hostPeerID);
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

    ui.initQRCodeUI();
}