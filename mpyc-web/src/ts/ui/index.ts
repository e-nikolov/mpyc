import { MPyCManager } from '../mpyc';
import * as ui from ".";
import { Tooltip } from 'bootstrap';

export * from './copy-btn';
export * from './term';
export * from './elements';
export * from './chat';

export function initUI(mpyc: MPyCManager, initMPyC: () => void) {
    ui.resetPeerIDButton.addEventListener('click', () => { localStorage.removeItem("myPeerID"); mpyc.close(); initMPyC() });
    ui.runMPyCButton.addEventListener('click', () => { mpyc.runMPyCDemo(false); });
    ui.runMPyCAsyncButton.addEventListener('click', () => mpyc.runMPyCDemo(true));
    ui.stopMPyCButton.addEventListener('click', initMPyC);
    ui.connectToPeerButton.addEventListener('click', () => { localStorage.setItem("hostPeerID", ui.hostPeerIDInput.value); mpyc.connectToPeer(ui.hostPeerIDInput.value) });
    ui.sendMessageButton.addEventListener('click', () => { ui.sendChatMessage(mpyc); });

    var hostPeerID = localStorage.getItem("hostPeerID");
    if (hostPeerID) {
        ui.hostPeerIDInput.value = hostPeerID;
    }

    ui.makeCopyButton("#myPeerID", "button#copyPeerID");


    ui.chatInput.addEventListener('keypress', function (e: Event) {
        let ev = e as KeyboardEvent;

        if (ev.key === 'Enter' && !ev.shiftKey) {
            ev.preventDefault();
            return ui.sendChatMessage(mpyc);
        }
    });
    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
    tooltipTriggerList.forEach(tooltipTriggerEl => new Tooltip(tooltipTriggerEl));
}