import { MPyCManager } from "../mpyc";
import { chatInput, knownPeersEl, term } from ".";
import DOMPurify from "dompurify";

export function sendChatMessage(mpyc: MPyCManager) {
    let message = chatInput.value;
    chatInput.value = "";
    term.writeln(`Me: ${safe(message)}`);

    mpyc.broadcastMessage({
        chatMessage: message
    })
}

export function processChatMessage(peerID: string, data: any) {
    if (!data) {
        return;
    }

    term.writeln(`${safe(peerID)}: ${safe(data?.chatMessage)}`);
}

export function safe(text: string) {
    return DOMPurify.sanitize(text);
}

export function onPeerConnectedHook(newPeerID: string, mpyc: MPyCManager) {
    console.log(`Connected to: ${newPeerID}`)
    term.writeln(`Connected to: ${newPeerID}`);
    updateKnownPeersDiv(mpyc);
}

export function onPeerDisconnectedHook(disconnectedPeerID: string, mpyc: MPyCManager) {
    console.log(`Disconnected from: ${disconnectedPeerID}`)
    term.writeln(`Disconnected from: ${disconnectedPeerID}`);
    updateKnownPeersDiv(mpyc);
}

export function updateKnownPeersDiv(mpyc: MPyCManager) {
    knownPeersEl.innerHTML = "";
    mpyc.getPeers(true).forEach((p, pid) => {
        knownPeersEl.innerHTML += `<li class="list-group-item ${p == mpyc.peer.id ? 'list-group-item-light' : ''}"> <span style="user-select:none">${pid}: </span><span>${safe(p)} </span></li>`;
    });
}
