import { MPyCManager } from "../mpyc";
import { chatInput, knownPeersEl, term } from ".";
import DOMPurify from "dompurify";

export function sendChatMessage(mpyc: MPyCManager) {
    let message = chatInput.value;
    chatInput.value = "";
    term.writeln(`Me: ${safe(message)}`);

    mpyc.broadcastMessage('chat', message)
}

export function processChatMessage(peerID: string, { data: message }: { data: string }) {
    console.log("received chat", message)
    term.writeln(`${safe(peerID)}: ${safe(message)}`);
}

export function safe(text: string) {
    return DOMPurify.sanitize(text);
}

export function onPeerConnectedHook(newPeerID: string, mpyc: MPyCManager) {
    term.writeln(`Connected to: ${newPeerID}`);
    updateKnownPeersDiv(mpyc);
}
export function onPeerConnectionErrorHook(peerID: string, err: Error, mpyc: MPyCManager) {
    term.writeln(`Failed to connect to: ${peerID}: ${err.message}`);
    updateKnownPeersDiv(mpyc);
}

export function onPeerDisconnectedHook(disconnectedPeerID: string, mpyc: MPyCManager) {
    term.writeln(`Disconnected from: ${disconnectedPeerID}`);
    updateKnownPeersDiv(mpyc);
}

export function updateKnownPeersDiv(mpyc: MPyCManager) {
    knownPeersEl.innerHTML = "";
    mpyc.getPeers(true).forEach((p, pid) => {
        knownPeersEl.innerHTML += `<li class="list-group-item ${p == mpyc.peer.id ? 'list-group-item-light' : ''}"> <span style="user-select:none">${pid}: </span><span>${safe(p)} </span></li>`;
    });
}
