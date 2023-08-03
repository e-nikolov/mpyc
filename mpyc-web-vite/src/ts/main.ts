/*
 *  Copyright (c) 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree.
 */

'use strict';

import '../scss/style.scss';
// import workerURL from "../py/worker.py"

import { MPyCManager } from './mpyc/mpyc';
import { Terminal } from 'xterm';

import { Tooltip } from 'bootstrap';
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

    mpyc = new MPyCManager(localStorage.getItem("myPeerID"), "../config.toml");
    mpyc.onPeerConnectedHook = onPeerConnectedHook;
    mpyc.onPeerDisconnectedHook = onPeerDisconnectedHook;
    mpyc.onPeerJSUserDataReceivedHook = processChatMessage;
    mpyc.onPeerIDReadyHook = (peerID: string) => {
        myPeerIDEl.value = safe(peerID);
        localStorage.setItem("myPeerID", peerID);
        console.log('My peer ID is: ' + peerID);
    };
    term.writeln("Loading PyScript runtime...");
    mpyc.onRuntimeReadyHook = () => {
        term.writeln("PyScript runtime ready.");
    };
    mpyc.onPyScriptDisplayHook = (message: string) => {
        term.writeln(message);
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
            Tooltip.getInstance('button#copyPeerID')!.setContent({ '.tooltip-inner': "Copied!" })

            setTimeout(() => {
                $this.switchClass("btn-success", "btn-primary");
                $this.find("i").switchClass("bi-check2", "bi-clipboard");
                Tooltip.getInstance('button#copyPeerID')!.setContent({ '.tooltip-inner': "Copy to clipboard" })
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
    tooltipTriggerList.forEach(tooltipTriggerEl => new Tooltip(tooltipTriggerEl))
}

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
