/*
 *  Copyright (c) 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree.
 */

'use strict';

import '../scss/style.scss';
import '@fontsource/fira-code';
// import '@fontsource/inter';
// import '@fontsource/roboto';
// import '@fontsource/roboto-mono';
import 'hack-font/build/web/hack.css';

import { MPyCManager } from './mpyc';

import * as ui from './ui';

ui.ensureStorageSchema(18);
let peerID = ui.loadPeerID();

var mpyc: MPyCManager = new MPyCManager(peerID, "./py/shim.py", "config.toml");
ui.init(mpyc);
