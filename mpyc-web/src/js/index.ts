/*
 *  Copyright (c) 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree.
 */

'use strict';


import { Terminal } from 'xterm';
import $ from 'jquery';

import { MPyCManager } from './mpyc/mpyc';
import bootstrap from 'bootstrap';
import DOMPurify from 'dompurify';

declare global {
    interface Document {
        term: Terminal;
        r: any;
        run: any;
        runa: any;
        mpyc: MPyCManager;
    }
}

const hostPeerIDInput = document.querySelector<HTMLInputElement>('input#hostPeerID')!;
const chatInput = document.querySelector<HTMLInputElement>('#chatInput')!;

const myPeerIDEl = document.querySelector<HTMLInputElement>('#myPeerID')!;
const knownPeersEl = document.querySelector('#knownPeers')!;

var term: Terminal = initTermJS('#terminal');
var mpyc: MPyCManager;

initMPyC()
initUI();

function initTermJS(sel: string): Terminal {
    let term = new Terminal();
    term.open(document.querySelector(sel)!);
    document.term = term;
    return term
}

function initMPyC() {
    if (mpyc) {
        mpyc.close();
    }

    mpyc = new MPyCManager(localStorage.getItem("myPeerID"), "config.toml");
    mpyc.onPeerConnectedHook = onPeerConnectedHook;
    mpyc.onPeerDisconnectedHook = onPeerDisconnectedHook;
    mpyc.onUserDataReceivedHook = processChatMessage;
    mpyc.onPeerIDReadyHook = (peerID: string) => {
        myPeerIDEl.value = safe(peerID);
        localStorage.setItem("myPeerID", peerID);
        console.log('My peer ID is: ' + peerID);
    };
    term.writeln("Loading PyScript runtime...");
    mpyc.onRuntimeReadyHook = () => {
        term.writeln("PyScript runtime ready.");
    };

    document.mpyc = mpyc;
    document.r = initMPyC;
    document.run = () => mpyc.runMPyCDemo(false);
    document.runa = () => mpyc.runMPyCDemo(true);
}

function initUI() {
    document.querySelector<HTMLButtonElement>('button#resetPeerID')!.onclick = () => { localStorage.removeItem("myPeerID"); mpyc.close(); initMPyC() };
    document.querySelector<HTMLButtonElement>('button#startButton')!.onclick = () => { mpyc.runMPyCDemo(false); }
    document.querySelector<HTMLButtonElement>('button#startAsyncButton')!.onclick = () => mpyc.runMPyCDemo(true);
    document.querySelector<HTMLButtonElement>('button#stopButton')!.onclick = initMPyC;
    document.querySelector<HTMLButtonElement>('button#connect')!.onclick = () => { localStorage.setItem("hostPeerID", hostPeerIDInput.value); mpyc.connectToPeer(hostPeerIDInput.value) };

    var hostPeerID = localStorage.getItem("hostPeerID");
    if (hostPeerID) {
        hostPeerIDInput.value = hostPeerID;
    }

    $('button#copyPeerID').on("click", function () {
        let $this = $(this as HTMLButtonElement);

        navigator.clipboard.writeText(myPeerIDEl.value).then(function () {
            $this.find("i").switchClass("bi-clipboard", "bi-check2");
            $this.switchClass("btn-primary", "btn-success");
            bootstrap.Tooltip.getInstance('button#copyPeerID')!.setContent({ '.tooltip-inner': "Copied!" })

            setTimeout(() => {
                $this.switchClass("btn-success", "btn-primary");
                $this.find("i").switchClass("bi-check2", "bi-clipboard");
                bootstrap.Tooltip.getInstance('button#copyPeerID')!.setContent({ '.tooltip-inner': "Copy to clipboard" })
                $this.attr("data-bs-title", "Copy to clipboard")
            }, 3000);

            console.log('Async: Copying to clipboard was successful!');
        }, function (err) {
            console.error('Async: Could not copy text: ', err);
        });
    });
    document.querySelector<HTMLButtonElement>('#sendMessageButton')!.onclick = () => {
        sendChatMessage(mpyc);
    };

    chatInput.addEventListener('keypress', function (e: Event) {
        let ev = e as KeyboardEvent;

        if (ev.key === 'Enter' && !ev.shiftKey) {
            return sendChatMessage(mpyc);
        }
    });
    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
    tooltipTriggerList.forEach(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))
}


// function knownPeers(conns: ConnMap, includeSelf = false) {
//     let peers = Object.values(conns).map(conn => conn.peer);

//     if (includeSelf) {
//         peers.push(peer.id);
//     }

//     return peers.sort();
// }

// function sendKnownPeers(conn: DataConnection, conns: ConnMap) {
//     conn.send({
//         knownPeers: knownPeers(conns)
//     })
// }

// function ready(conn: DataConnection, conns: ConnMap) {

//     // Process messages from other peers received via peerJS
//     conn.on('data', function (data) {
//         console.log("Data received");
//         console.log(data);
//         processNewPeers(data?.knownPeers);
//         processChatMessage(conn.peer, data?.chatMessage);

//         // Need to somehow store those messages if we receive them before our user has clicked the start button
//         processMPyCMessage(conn.peer, data?.mpycMessage);
//     });
//     conn.on('close', function () {
//         conns.delete(conn.peer);
//         removePeer(conns, conn);
//     });
// }

// function processNewPeers(newPeers: string[]) {
//     if (!newPeers) {
//         return;
//     }
//     newPeers.forEach(peerID => {
//         if (!conns[peerID] && peerID != peer.id) {
//             connectToPeer(peerID);
//         }
//     });
// }

function sendChatMessage(mpyc: MPyCManager) {
    let message = chatInput.value;
    chatInput.value = "";
    term.writeln(`Me: ${safe(message)}`);

    mpyc.broadcastMessage({
        chatMessage: message
    })
}

function processChatMessage(peerID: string, data: any) {
    if (!data) {
        return;
    }

    term.writeln(`${safe(peerID)}: ${safe(data?.chatMessage)}`);
}

function safe(text: string) {
    return DOMPurify.sanitize(text);
}

// function connectToPeer(conns: ConnMap, peerID: string) {
//     // data received does not work here
//     let conn = peer.connect(peerID, {
//         reliable: true
//     });

//     conn.on('open', function () {
//         sendKnownPeers(conn, conns);
//         addPeer(conns, conn);
//     });
//     // conn.on('connection', function (e:DataConnectionEvent) {
//     //     sendKnownPeers(conn);
//     //     addPeer(conn);
//     // });
//     ready(conn, conns);
// }

function onPeerConnectedHook(newPeerID: string, peerIDs: string[]) {
    console.log(`Connected to: ${newPeerID}`)
    term.writeln(`Connected to: ${newPeerID}`);
    updateKnownPeersDiv(peerIDs);
}

function onPeerDisconnectedHook(peerID: string, peerIDs: string[]) {
    console.log(`Disconnected from: ${peerID}`)
    term.writeln(`Disconnected from: ${peerID}`);
    updateKnownPeersDiv(peerIDs);
}

function updateKnownPeersDiv(peerIDs: string[]) {
    knownPeersEl.innerHTML = "";
    peerIDs.forEach((p, pid) => {
        knownPeersEl.innerHTML += `<li class="list-group-item ${p == mpyc.peer.id ? 'list-group-item-light' : ''}"> <span style="user-select:none">${pid}: </span><span>${safe(p)} </span></li>`;
    });
}

// function workMessage(obj) {
//     obj = { ...{ init: null, peerJS: null }, ...obj };

//     if (obj.peerJS) {
//         obj.peerJS.message = { ...{ runtime_message: null, ready_message: null }, ...obj.peerJS.message };
//     }

//     return obj;
// }


// function initPyScript() {
//     if (worker) {
//         worker.terminate();
//     }
//     worker = newWorker();
// }

// function initPyScript() {
//     if (worker) {
//         worker.terminate();
//     }

//     if (workerNext) {
//         worker = workerNext;
//     } else {
//         worker = new newWorker();
//     }

//     workerNext = newWorker();
// }

// function processMPyCMessage(peerID, message) {
//     if (!message) {
//         return;
//     }

//     postWorkerMessage(worker, {
//         peerJS: {
//             peerID,
//             message,
//         }
//     });
// }

// function postWorkerMessage(w, message) {
//     w.postMessage(workMessage(message));
// }

// function newWorker() {
//     let www = new XWorker("./worker.py", { async: true, type: "pyodide", config: "config.toml" });
//     www.sync.myFunc = function (x) {
//         console.log("myFunc", x);
//     }

//     // Process messages from worker.py
//     www.onmessage = (event) => {
//         console.log("(mpyc.js:worker:onmessage): --------------- data", event.data);
//         let msg = JSON.parse(event.data);

//         if (msg.display) {
//             document.term.writeln(msg.display);
//         }
//         if (msg.peerJS) {
//             console.log("++++++++++++++ peerJS data")
//             conns[msg.peerJS.peerID].send({
//                 mpycMessage: msg.peerJS.message,
//             })
//         }
//     };
//     return www;
// }
