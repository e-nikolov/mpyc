import { Peer, DataConnection } from "peerjs";
import * as polyscript from "polyscript";


type ConnMap = Map<string, DataConnection>;

class Ev extends CustomEvent<{ args: any[] }> {
}

export class MPyCManager extends EventTarget {
    peer: Peer;
    conns: ConnMap = new Map<string, DataConnection>();
    peerIDToPID: Map<string, number> = new Map<string, number>();
    pidToPeerID: Map<number, string> = new Map<number, string>();
    peersReady: Map<string, boolean> = new Map<string, boolean>();
    worker: Worker & { sync: any };
    shimFilePath: string;
    configFilePath: string;
    running = false;


    constructor(peerID: string | null, shimFilePath: string, configFilePath: string) {
        super();
        this.peer = this.newPeerJS(peerID);
        this.worker = this.newWorker(shimFilePath, configFilePath)
        this.shimFilePath = shimFilePath;
        this.configFilePath = configFilePath;

        this.on('peerjs:conn:data:peers', this.processNewPeers);
        this.on('peerjs:conn:data:mpyc:ready', this.processMPyCReadyMessage);
        this.on('peerjs:conn:data:mpyc:runtime', this.processMPyCRuntimeMessage);
    }

    public reset(peerID: string | null) {
        this.resetPeer(peerID);
        this.resetWorker();
    }

    resetPeer(peerID: string | null) {
        console.log("resetting peer");
        this.peerIDToPID = new Map<string, number>();
        this.peersReady = new Map<string, boolean>();
        this.pidToPeerID = new Map<number, string>();
        this.peer.destroy();
        this.peer = this.newPeerJS(peerID);
    }
    resetWorker() {
        console.log("resetting worker");
        this.worker.terminate();
        this.worker = this.newWorker(this.shimFilePath, this.configFilePath)
        this.running = false;
    }

    close() {
        console.log("destroying peer and worker");
        this.peer.destroy();
        this.worker.terminate();
        this.running = false;
    }

    on(type: string, handler: (...args: any[]) => void) {
        this.addEventListener(type, (e: Event) => {
            // console.log("on", type, e)
            handler(...((e as Ev).detail.args))
        });
    }

    async emit(type: string, ...args: any[]) {
        console.log("emit", type, ...[...args].filter(a => !(a instanceof MPyCManager)))
        this.dispatchEvent(new Ev(type, { detail: { args } }));
    }

    getPeers(includeSelf = false) {
        let peers = Array.from(this.conns, ([_, conn]) => conn.peer);

        if (includeSelf) {
            peers.push(this.peer.id);
        }

        return peers.sort();
    }

    broadcastMessage(type: string, data: any) {
        this.conns.forEach(conn => {
            conn.send({ type: `user:${type}`, data });
        });
    }

    connectToPeer(peerID: string) {
        // data received does not work here
        let conn = this.peer.connect(peerID, {
            reliable: true
        });

        this.addConnEventHandlers(conn); //?????
    }

    runMPyCDemo = async (code: string, is_async = false) => {
        this.running = true;
        let peers = this.getPeers(true)
        let pid = peers.findIndex((p) => p === this.peer.id)

        console.log("peers:", peers)
        console.log("my id:", this.peer.id)
        console.log("my pid:", pid)

        for (let i = 0; i < peers.length; i++) {
            this.peerIDToPID.set(peers[i], i)
            this.pidToPeerID.set(i, peers[i])
        }

        this.peersReady.set(this.peer.id, true);

        this.worker.sync.run_mpc({
            pid: pid,
            parties: peers,
            is_async: is_async,
            no_async: !is_async,
            exec: code,
        })
        this.emit('worker:run', this);
    }

    newPeerJS(peerID: string | null): Peer {
        var peer: Peer;

        if (peerID) {
            peer = new Peer(peerID);
        } else {
            peer = new Peer();
        }

        this.addPeerEventHandlers(peer)

        return peer;
    }

    newWorker(shimFilePath: string, configFilePath: string) {
        let worker = polyscript.XWorker(shimFilePath, { async: true, type: "pyodide", config: configFilePath });

        // allow the python worker to send PeerJS messages via the main thread
        worker.sync.sendReadyMessage = this.sendReadyMessage;
        worker.sync.sendRuntimeMessage = this.sendRuntimeMessage;

        // UI callbacks
        worker.sync.log = console.log;
        worker.sync.display = (message: string) => { this.emit('worker:display', message, this); }
        worker.sync.displayRaw = (message: string) => { this.emit('worker:display:raw', message, this); }
        worker.onerror = (err: ErrorEvent) => { console.error(err.error); this.emit('worker:error', err, this) };
        worker.sync.mpcDone = () => { this.running = false; }

        return worker;
    }

    private addPeerEventHandlers(peer: Peer) {
        peer.on('open', (peerID) => { this.emit('peerjs:ready', peerID, this); });
        peer.on('error', (err) => { this.emit('peerjs:error', err, this); });
        peer.on('close', () => { this.emit('peerjs:closed', this); });
        peer.on('connection', (conn: DataConnection) => { this.addConnEventHandlers(conn); });
    }

    private addConnEventHandlers(conn: DataConnection) {
        console.log("new peer connection from", conn.peer)
        conn.on('open', () => {
            this.sendKnownPeers(conn);
            this.conns.set(conn.peer, conn);
            this.emit("peerjs:conn:ready", conn.peer, this);
        });
        conn.on('error', (err) => { this.emit("peerjs:conn:error", conn.peer, err, this) });
        conn.on('close', () => {
            this.conns.delete(conn.peer);
            this.emit('peerjs:conn:disconnected', conn.peer, this);
        });

        conn.on('data', (data: any) => { this.emit(`peerjs:conn:data:${data.type}`, conn.peer, data.payload) });
    }

    private sendKnownPeers(conn: DataConnection) {
        conn.send({
            type: 'peers',
            payload: this.getPeers()
        })
    }

    private processNewPeers = (_: string, newPeers: string[]) => {
        newPeers.forEach(peerID => {
            if (!this.conns.get(peerID) && peerID != this.peer.id) {
                this.connectToPeer(peerID);
            }
        });
    }

    // Called from the Python worker
    sendReadyMessage = (pid: number, message: string) => {
        let peerID = this.pidToPeerID.get(pid);
        this.conns.get(peerID!)?.send({
            type: 'mpyc:ready',
            payload: message,
        })
    };

    // Called from the PeerJS connection
    processMPyCReadyMessage = (peerID: string, message: string) => {
        this.peersReady.set(peerID, true);

        if (!this.running) {
            console.log("ignoring mpc ready message because we are not running")
            return;
        }
        let pid = this.peerIDToPID.get(peerID)!;
        this.worker.sync.on_ready_message(pid, message)
    }

    // Called from the Python worker
    sendRuntimeMessage = (pid: number, message: string) => {
        let peerID = this.pidToPeerID.get(pid)!;
        this.conns.get(peerID)?.send({
            type: 'mpyc:runtime',
            payload: message,
        })
    };

    // Called from the PeerJS connection
    processMPyCRuntimeMessage = (peerID: string, message: string) => {
        if (!this.running) {
            // ignore mpc messages if we're not running
            console.log("ignoring mpc runtime message because we are not running")
            return;
        }
        let pid = this.peerIDToPID.get(peerID)!;
        this.worker.sync.on_runtime_message(pid, message)
    }
}
