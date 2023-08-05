import { MPyCManager } from '../mpyc';
import * as ui from ".";
import { Tooltip } from 'bootstrap';

export * from './copy-btn';
export * from './term';
export * from './elements';
export * from './chat';
export * from './qr';

export function initUI(mpyc: MPyCManager, initMPyC: () => void) {
    ui.resetPeerIDButton.addEventListener('click', () => { localStorage.removeItem("myPeerID"); mpyc.close(); initMPyC() });
    ui.runMPyCButton.addEventListener('click', () => { mpyc.runMPyCDemo(false); });
    ui.runMPyCAsyncButton.addEventListener('click', () => mpyc.runMPyCDemo(true));
    ui.stopMPyCButton.addEventListener('click', initMPyC);
    ui.connectToPeerButton.addEventListener('click', () => { localStorage.setItem("hostPeerID", ui.hostPeerIDInput.value); mpyc.connectToPeer(ui.hostPeerIDInput.value) });
    ui.sendMessageButton.addEventListener('click', () => { ui.sendChatMessage(mpyc); });

    const urlParams = new URLSearchParams(window.location.search);
    const peer = urlParams.get('peer');
    var hostPeerID = peer || localStorage.getItem("hostPeerID");
    if (hostPeerID) {
        ui.hostPeerIDInput.value = hostPeerID;
        localStorage.setItem("hostPeerID", hostPeerID);
    }

    ui.makeCopyButton("#myPeerID", "button#copyPeerID");


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