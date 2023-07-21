/*
 *  Copyright (c) 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree.
 */

'use strict';

// console.log("pyscript.interpreter", PyScript.interpreter)

import { XWorker } from "./../core.js";

const hostPeerIDInput = document.querySelector('input#hostPeerID');

const myPeerIDDiv = document.querySelector('div#myPeerID');
const knownPeersDiv = document.querySelector('div#knownPeers');
const statusDiv = document.querySelector('div#status');

var peer;
var conns = {};
var worker;
var workerNext;
var term;

initTermJS();
initPeerJS()
initPyScript();
initUI();
initConsoleShortcuts();

function initConsoleShortcuts() {
    window.rr = initPyScript;
    window.cc = runMPyCDemo(true);
    window.ccna = runMPyCDemo();
    window.ww = worker;
    window.peer = peer;
}

function initTermJS() {
    term = new Terminal();
    term.open(document.getElementById('terminal'));
    document.term = term;
}

function initUI() {
    document.querySelector('button#resetPeerID').onclick = () => { localStorage.removeItem("myPeerID"); peer.destroy(); initPeerJS() };
    document.querySelector('button#startButton').onclick = runMPyCDemo();
    document.querySelector('button#startAsyncButton').onclick = runMPyCDemo(true);
    document.querySelector('button#stopButton').onclick = initPyScript;
    document.querySelector('button#connect').onclick = () => { localStorage.setItem("hostPeerID", hostPeerIDInput.value); connectToPeer(hostPeerIDInput.value) };
    document.querySelector('button#copyPeerID').onclick = function () {
        var copyText = myPeerIDDiv.innerText;
        navigator.clipboard.writeText(copyText).then(function () {
            console.log('Async: Copying to clipboard was successful!');
        }, function (err) {
            console.error('Async: Could not copy text: ', err);
        });
    };
    document.querySelector('button#sendMessage').onclick = () => {
        sendMessage(conns);
    };
}

function sendMessage(conns) {
    let message = document.querySelector('textarea#chatInput').value;
    document.querySelector('textarea#chatInput').value = "";
    term.writeln(`Me: ${safe(message)}`);

    Object.values(conns).forEach(conn => {
        conn.send({
            chatMessage: message
        })
    });
}

function initPeerJS() {
    var myPeerID = localStorage.getItem("myPeerID");
    if (myPeerID) {
        peer = new Peer(myPeerID)
    } else {
        peer = new Peer()
    }

    var hostPeerID = localStorage.getItem("hostPeerID");
    if (hostPeerID) {
        hostPeerIDInput.value = hostPeerID;
    }

    peer.on('open', function (id) {
        myPeerIDDiv.innerHTML = safe(id);
        localStorage.setItem("myPeerID", id);
        console.log('My peer ID is: ' + id);
    });

    // new incoming peer connection
    // data received works here
    peer.on('connection', function (conn) {
        conn.on('open', function () {
            sendKnownPeers(conn);
        });
        // data sending doesn't work?
        addPeer(conn);
        ready(conn);
    });
}


function sendKnownPeers(conn) {
    conn.send({
        knownPeers: Object.values(conns).map(conn => conn.peer)
    })
}

function ready(conn) {
    conn.on('data', function (data) {
        console.log("Data recieved");
        console.log(data);
        processNewPeers(data?.knownPeers);
        processChatMessage(conn.peer, data?.chatMessage);
    });
    conn.on('close', function () {
        removePeer(conn);
    });
}

function processNewPeers(newPeers) {
    if (!newPeers) {
        return;
    }
    newPeers.forEach(peerID => {
        if (!conns[peerID] && peerID != peer.id) {
            connectToPeer(peerID);
        }
    });
}

function processChatMessage(peerID, chatMessage) {
    term.writeln(`${safe(peerID)}: ${safe(chatMessage)}`);
}

function safeWriteTerm(text) {
    term.write(safe(text));
}

function safe(text) {
    return DOMPurify.sanitize(text);
}

function connectToPeer(peerID) {
    // data received does not work here
    let conn = peer.connect(peerID, {
        reliable: true
    });

    conn.on('open', function () {
        sendKnownPeers(conn);
        addPeer(conn);
    });
    conn.on('connection', function () {
        sendKnownPeers(conn);
        addPeer(conn);
    });
    ready(conn);
}

function addPeer(conn) {
    console.log("Connected to: ")
    console.log(conn.peer)
    term.writeln("Connected to: " + conn.peer);
    conns[conn.peer] = conn;
    updateKnownPeersDiv(conns);
}

function removePeer(conn) {
    term.writeln("Disconnected from: " + conn.peer);
    delete conns[conn.peer];
    updateKnownPeersDiv(conns);
}

function updateKnownPeersDiv(conns) {
    knownPeersDiv.innerHTML = "";
    Object.values(conns).forEach(conn => {
        knownPeersDiv.innerHTML += `<li>${safe(conn.peer)}</li>`;
    });
}




// peer.on('connection', function (c) {
//     // Allow only a single connection
//     c.on('open', function () {
//         c.send("Already connected to another client");
//         setTimeout(function () { c.close(); }, 500);
//     });
//     return;


//     conn = c;
//     console.log("Connected to: " + conn.peer);
//     status.innerHTML = "Connected";
//     ready();
// });


export function runMPyCDemo(is_async = false) {
    return function () {
        initPyScript()
        document.term.clear();

        worker.postMessage({
            is_async: is_async,
            no_async: !is_async,
            async: is_async
        });
    };
}



function initPyScript() {
    if (worker) {
        worker.terminate();
    }

    if (workerNext) {
        worker = workerNext;
    } else {
        worker = new newWorker();
    }

    workerNext = newWorker();
}

function newWorker() {
    let www = new XWorker("./worker.py", { async: true, type: "pyodide", config: "config.toml" });
    www.onmessage = (event) => {
        document.term.writeln(event.data);
    };
    return www;
}
