import { MPyCManager } from "../mpyc";
import { knownPeersEl, term } from ".";
import DOMPurify from "dompurify";

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
        let icon = `
        <span class="position-relative end-0">
            <i class='bi ${mpyc.peersReady.get(p) ? 'bi-play-fill' : 'bi-pause-fill'}'></i>
        </span>`
        knownPeersEl.innerHTML += `
        <li class="list-group-item ${p == mpyc.peer.id ? '' : 'list-group-item-light'}"> 
            <span class="" style="user-select:none">${pid}: </span>
            <span class="d-inline-block text-truncate" style="vertical-align:top;max-width:200px;">${safe(p)}</span> 
            ${icon}
        </li>`;
    });
}

// export function updateKnownPeersDiv(mpyc: MPyCManager) {
//     knownPeersEl.innerHTML = "";
//     mpyc.getPeers(true).forEach((p, pid) => {
//         let icon = `
//         <span class="position-relative end-0">
//             <i class='bi ${mpyc.peersReady.get(p) ? 'bi-play-fill' : 'bi-pause-fill'}'></i>
//         </span>`
//         knownPeersEl.innerHTML += `
//         <div class="input-group">
//             <span class="input-group-text" style="user-select:none">${pid}: </span>
//             z
//             <span class="input-group-text " style="vertical-align:top;max-width:200px;">${safe(p)}</span> 
//         </div>
//             ${icon}
//         `;
//     });
// }
