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
    worker: Worker & { sync: any };
    mainFilePath: string;
    configFilePath: string;


    constructor(peerID: string | null, mainFilePath: string, configFilePath: string) {
        super();
        this.peer = this.newPeerJS(peerID);
        this.worker = this.newWorker(mainFilePath, configFilePath)
        this.mainFilePath = mainFilePath;
        this.configFilePath = configFilePath;

        this.on('peerjs:conn:data:peers', this.processNewPeers);
        this.on('peerjs:conn:data:mpyc', this.processMPyCMessage);
    }

    public init(peerID: string | null, mainFilePath: string, configFilePath: string): [Peer, Worker & { sync: any }] {
        this.peer = this.newPeerJS(peerID);
        this.worker = this.newWorker(mainFilePath, configFilePath)
        this.mainFilePath = mainFilePath;
        this.configFilePath = configFilePath;

        this.on('peerjs:conn:data:peers', this.processNewPeers);
        this.on('peerjs:conn:data:mpyc', this.processMPyCMessage);

        return [this.peer, this.worker];
    }

    on(type: string, handler: (...args: any[]) => void) {
        this.addEventListener(type, (e: Event) => {
            // console.log("on", type, e)
            handler(...((e as Ev).detail.args))
        });
    }

    async emit(type: string, ...args: any[]) {
        this.dispatchEvent(new Ev(type, { detail: { args } }));
    }

    getPeers(includeSelf = false) {
        console.log("getPeers")
        console.log(this.conns)
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

    async runMPyCDemo(is_async = false) {
        let peers = this.getPeers(true)
        let pid = peers.findIndex((p) => p === this.peer.id)

        console.log("peers:", peers)
        console.log("my id:", this.peer.id)
        console.log("my pid:", pid)

        for (let i = 0; i < peers.length; i++) {
            this.peerIDToPID.set(peers[i], i)
            this.pidToPeerID.set(i, peers[i])
        }

        let contents = await fetch(this.mainFilePath)
        let pyCode = await contents.text()
        // console.log(pyCode)
        // ui.term.write(pyCode)


        this.worker.sync.run_mpc({
            pid: pid,
            parties: peers,
            is_async: is_async,
            no_async: !is_async,
            exec: pyCode,
            // exec: "import mpycweb.redirect_stdout",
        })
    }

    close() {
        console.log("destroying peer and worker");
        this.peer.destroy();
        this.worker.terminate();
    }

    newPeerJS(peerID: string | null): Peer {
        var peer: Peer;

        console.log("trying to create peer with peerID:", peerID)
        if (peerID) {
            console.log(peerID)
            console.log(`calling new Peer(${peerID})`)
            peer = new Peer(peerID);
        } else {
            console.log(`calling new Peer()`);
            peer = new Peer();
        }


        this.addPeerEventHandlers(peer)

        return peer;
    }

    newWorker(mainFilePath: string, configFilePath: string) {
        let worker = polyscript.XWorker(mainFilePath, { async: true, type: "pyodide", config: configFilePath });
        worker.sync.myFunc = function (x: any) {
            console.log("myFunc", x);
        }

        worker.sync.console = console;
        worker.sync.log = console.log;

        worker.sync.display = (message: string) => {
            this.emit('worker:display', message, this);
        }

        worker.sync.displayRaw = (message: string) => {
            this.emit('worker:display:raw', message, this);
        }

        worker.sync.sendRuntimeMessage = (pid: number, message: string) => {
            let peerID = this.pidToPeerID.get(pid);
            this.conns.get(peerID!)?.send({
                runtime_message: message,
            })
        };

        worker.sync.sendReadyMessage = (pid: number, message: string) => {
            let peerID = this.pidToPeerID.get(pid);
            this.conns.get(peerID!)?.send({
                ready_message: message,
            })
        };

        worker.onerror = (err: ErrorEvent) => { console.error(err.error); this.emit('worker:error', err, this) };

        return worker;
    }

    private addPeerEventHandlers(peer: Peer) {
        peer.on('open', (peerID) => {
            this.emit('peerjs:ready', peerID, this);
        });

        peer.on('error', (err) => {
            this.emit('peerjs:error', err, this);
        });

        peer.on('close', () => {
            this.emit('peerjs:closed', this);
        });

        // new incoming peer connection
        // data received works here
        peer.on('connection', (conn: DataConnection) => {
            this.addConnEventHandlers(conn);
        });
    }





    private sendKnownPeers(conn: DataConnection) {
        conn.send({
            knownPeers: this.getPeers()
        })
    }

    private addConnEventHandlers(conn: DataConnection) {
        console.log("________________ new peer connection", conn.peer)
        console.log("________________ peer", this.peer, this.peer.id)
        conn.on('open', () => {
            console.log("peer connection is now open", conn.peer)
            this.sendKnownPeers(conn);

            this.conns.set(conn.peer, conn);
            this.emit("peerjs:conn:ready", conn.peer, this);
        });

        conn.on('error', (err) => {
            this.emit("peerjs:conn:error", conn.peer, err, this)
            console.log(err)
        });
        // Process messages from other peers received via peerJS
        conn.on('data', (data: any) => {
            console.log("Data received");
            console.log(data);

            this.emit(`peerjs:conn:data:${data.type}`, conn.peer, data.data)
        });


        conn.on('close', () => {
            this.conns.delete(conn.peer);
            this.emit('peerjs:conn:disconnected', conn.peer, this);
        });
    }

    private async processNewPeers(peerID: string, newPeers: string[]) {
        if (!newPeers) {
            return;
        }
        newPeers.forEach(peerID => {
            if (!this.conns.get(peerID) && peerID != this.peer.id) {
                this.connectToPeer(peerID);
            }
        });
    }

    private async processMPyCMessage(peerID: string, data: any) {
        let pid = this.peerIDToPID.get(peerID);

        if (data?.ready_message) {
            this.worker.sync.on_ready_message(pid, data.ready_message)
        }

        if (data?.runtime_message) {
            this.worker.sync.on_runtime_message(pid, data.runtime_message)
        }
    }
}
