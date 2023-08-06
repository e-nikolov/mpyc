/*
 *  Copyright (c) 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree.
 */

'use strict';

import { Terminal } from 'xterm';
import '../scss/style.scss';

import { MPyCManager } from './mpyc';

import * as ui from './ui';

var mpyc: MPyCManager = initMPyC()
ui.initUI(mpyc, initMPyC);


function initMPyC() {
    if (mpyc) {
        console.log("Closing previous MPyCManager instance...")
        mpyc.close();
        mpyc.init("", "./py/main.py", "config.toml");
        return mpyc;
    }
    mpyc = new MPyCManager(localStorage.getItem("myPeerID"), "./py/main.py", "config.toml");

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
        term: Terminal;
    }
}