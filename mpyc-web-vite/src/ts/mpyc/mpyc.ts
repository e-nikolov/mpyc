import { Peer, DataConnection } from "peerjs";
import * as polyscript from "polyscript";


type ConnMap = Map<string, DataConnection>;

export class MPyCManager {
    peer: Peer;
    conns: ConnMap = new Map<string, DataConnection>();
    worker: Worker;


    constructor(peerID: string | null, configFilePath: string) {
        this.peer = this.newPeerJS(peerID);
        this.worker = this.newWorker(this.conns, configFilePath)
    }

    public onPeerConnectedHook: (conn: string, conns: string[]) => void = () => { };
    public onPeerDisconnectedHook: (conn: string, conns: string[]) => void = () => { };
    public onPeerJSUserDataReceivedHook: (conn: string, data: any) => void = () => { };
    public onPeerIDReadyHook: (peerID: string) => void = () => { };
    public onPyScriptDisplayHook: (message: string) => void = () => { };
    public onRuntimeReadyHook: () => void = () => { };

    getPeers(includeSelf = false) {
        let peers = Array.from(this.conns, ([_, conn]) => conn.peer);

        if (includeSelf) {
            peers.push(this.peer.id);
        }

        return peers.sort();
    }

    broadcastMessage(message: any) {
        this.conns.forEach(conn => {
            conn.send(message);
        });
    }

    connectToPeer(peerID: string) {
        // data received does not work here
        let conn = this.peer.connect(peerID, {
            reliable: true
        });

        conn.on('open', () => {
            this.sendKnownPeers(conn);
            this.conns.set(conn.peer, conn);
            this.onPeerConnectedHook(conn.peer, this.getPeers(true));
        });
        // conn.on('connection', function (e:DataConnectionEvent) {
        //     sendKnownPeers(conn);
        //     addPeer(conn);
        // });
        this.ready(conn); //?????
    }

    runMPyCDemo(is_async = false) {
        let peers = this.getPeers(true)
        let pid = peers.findIndex((p) => p === this.peer.id)

        console.log("peers:", peers)
        console.log("my id:", this.peer.id)
        console.log("my pid:", pid)

        this.postWorkerMessage({
            init: {
                pid: pid,
                parties: peers,
                is_async: is_async,
                no_async: !is_async,
            }
        });
    }

    close() {
        this.peer.destroy();
        this.worker.terminate();
    }

    newPeerJS(peerID: string | null): Peer {
        var peer: Peer;

        if (peerID) {
            peer = new Peer(peerID);
        } else {
            peer = new Peer();
        }

        this.addPeerEvents(peer)

        return peer;
    }

    newWorker(conns: ConnMap, configFilePath: string) {
        let worker = polyscript.XWorker("./py/worker.py", { async: true, type: "pyodide", config: configFilePath });
        worker.sync.myFunc = function (x: any) {
            console.log("myFunc", x);
        }

        // Hook(pyodide);



        // Process messages from worker.py
        worker.onmessage = (event: any) => {
            console.log("(mpyc.js:worker:onmessage): --------------- data", event.data);
            let msg = JSON.parse(event.data);

            if (msg.display) {
                this.onPyScriptDisplayHook(msg.display);
            }
            if (msg.peerJS) {
                console.log("++++++++++++++ peerJS data")
                conns.get(msg.peerJS.peerID)?.send({
                    mpycMessage: msg.peerJS.message,
                })
            }
        };

        return worker;
    }

    private addPeerEvents(peer: Peer) {
        peer.on('open', (peerID) => {
            this.onPeerIDReadyHook(peerID);
        });

        // new incoming peer connection
        // data received works here
        peer.on('connection', (conn: DataConnection) => {
            conn.on('open', () => {
                this.sendKnownPeers(conn);
            });
            // data sending doesn't work?
            this.conns.set(conn.peer, conn);
            this.onPeerConnectedHook(conn.peer, this.getPeers(true));

            this.ready(conn);
        });
    }





    private sendKnownPeers(conn: DataConnection) {
        conn.send({
            knownPeers: this.getPeers()
        })
    }

    private ready(conn: DataConnection) {
        // Process messages from other peers received via peerJS
        conn.on('data', (data: any) => {
            console.log("Data received");
            console.log(data);
            this.processNewPeers(data?.knownPeers);

            // Need to somehow store those messages if we receive them before our user has clicked the start button
            this.processMPyCMessage(conn.peer, data?.mpycMessage);



            this.onPeerJSUserDataReceivedHook(conn.peer, data);
        });

        conn.on('close', () => {
            this.conns.delete(conn.peer);
            this.onPeerDisconnectedHook(conn.peer, this.getPeers(true));
        });
    }

    private processNewPeers(newPeers: string[]) {
        if (!newPeers) {
            return;
        }
        newPeers.forEach(peerID => {
            if (!this.conns.get(peerID) && peerID != this.peer.id) {
                this.connectToPeer(peerID);
            }
        });
    }

    private processMPyCMessage(peerID: string, message: any) {
        if (!message) {
            return;
        }

        this.postWorkerMessage({
            peerJS: {
                peerID,
                message,
            }
        });
    }

    private postWorkerMessage(message: any) {
        this.worker.postMessage(this.workMessage(message));
    }

    private workMessage(obj: any) {
        obj = { ...{ init: null, peerJS: null }, ...obj };

        if (obj.peerJS) {
            obj.peerJS.message = { ...{ runtime_message: null, ready_message: null }, ...obj.peerJS.message };
        }

        return obj;
    }

}
