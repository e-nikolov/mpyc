import { MPyCManager } from "../mpyc";
import { chatInput, term } from ".";
import * as ui from ".";

export function sendChatMessage(mpyc: MPyCManager) {
    let message = chatInput.value;
    chatInput.value = "";
    term.writeln(`Me: ${ui.safe(message)}`);

    mpyc.broadcastMessage('chat', message)
}

export function processChatMessage(peerID: string, { data: message }: { data: string }) {
    term.writeln(`${ui.safe(peerID)}: ${ui.safe(message)}`);
}
