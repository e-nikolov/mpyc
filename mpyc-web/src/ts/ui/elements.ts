import * as ui from '.';

export const hostPeerIDInput = document.querySelector<HTMLInputElement>('input#hostPeerID')!;
export const chatInput = document.querySelector<HTMLInputElement>('#chatInput')!;

export const myPeerIDEl = document.querySelector<HTMLInputElement>('#myPeerID')!;
export const knownPeersEl = document.querySelector('#knownPeers')!;
export const resetPeerIDButton = document.querySelector<HTMLButtonElement>('button#resetPeerID')!;
export const runMPyCButton = document.querySelector<HTMLButtonElement>('button#startButton')!;
export const runMPyCAsyncButton = document.querySelector<HTMLButtonElement>('button#startAsyncButton')!;
export const stopMPyCButton = document.querySelector<HTMLButtonElement>('button#stopButton')!;
export const connectToPeerButton = document.querySelector<HTMLButtonElement>('button#connect')!;
export const sendMessageButton = document.querySelector<HTMLButtonElement>('#sendMessageButton')!;
export const showQRCodeButton = document.querySelector<HTMLButtonElement>('#show-qr')!;
export const scanQRInput = document.querySelector<HTMLInputElement>('#scan-qr')!;
export const qrCanvas = document.querySelector<HTMLCanvasElement>('#qrr')!;
export const qrCanvas2 = document.querySelector<HTMLCanvasElement>('#canvas')!;
export const testDiv = document.querySelector<HTMLCanvasElement>('div#test')!;
export var term = ui.makeTerminal('#terminal');
