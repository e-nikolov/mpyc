/*
 *  Copyright (c) 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree.
 */

'use strict';

import '../scss/style.scss';

import { MPyCManager } from './mpyc';

import * as ui from './ui';

var mpyc: MPyCManager = initMPyC()
ui.initUI(mpyc, initMPyC);

function initMPyC() {
    if (mpyc) {
        mpyc.close();
    }

    mpyc = new MPyCManager(localStorage.getItem("myPeerID"), "config.toml");
    mpyc.onPeerConnectedHook = ui.onPeerConnectedHook;
    mpyc.onPeerDisconnectedHook = ui.onPeerDisconnectedHook;
    mpyc.onPeerJSUserDataReceivedHook = ui.processChatMessage;
    mpyc.onPeerIDReadyHook = (peerID: string) => {
        ui.myPeerIDEl.value = ui.safe(peerID);
        localStorage.setItem("myPeerID", peerID);
        console.log('My peer ID is: ' + peerID);
    };
    ui.term.writeln("Loading PyScript runtime...");
    mpyc.onRuntimeReadyHook = () => {
        ui.term.writeln("PyScript runtime ready.");
    };
    mpyc.onPyScriptDisplayHook = (message: string) => {
        ui.term.writeln(message);
    };
    document.mpyc = mpyc;
    document.r = initMPyC;
    document.run = () => mpyc.runMPyCDemo(false);
    document.runa = () => mpyc.runMPyCDemo(true);

    return mpyc;
}

declare global {
    interface Document {
        r: any;
        run: any;
        runa: any;
        mpyc: MPyCManager;
    }
}