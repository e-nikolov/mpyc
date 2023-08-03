<script lang="ts">
	// import { onMount } from 'svelte';
	import { xterm } from './xterm.js';
	import { run } from './pyscript.js';

	import peerjs from 'peerjs';

	// import { onMount } from 'svelte';
	// let terminal: HTMLElement;

	// onMount(async () => {
	// 	let xterm = await import('xterm');
	// 	let peerjs = await import('peerjs');
	// 	var term = new xterm.Terminal();
	// 	let pyscript = await import('@pyscript/core');

	// 	term.open(terminal);
	// });
</script>

<svelte:head>
	<title>MPyC PyScript Demo</title>
	<meta name="description" content="About this app" />
</svelte:head>

<div class="text-column">
	<h1>MPyC in PyScript Core</h1>

	<div id="myPeerID" />

	<input type="text" id="hostPeerID" />
	<button id="connect">Connect</button>

	<div id="sendReceive">
		<div id="send">
			<h2>Send</h2>
			<textarea
				id="dataChannelSend"
				disabled
				placeholder="Press Start, enter some text, then press Send."
			/>
		</div>
		<div id="receive">
			<h2>Receive</h2>
			<textarea id="dataChannelReceive" disabled />
		</div>
	</div>
	<div id="buttons">
		<button id="startButton">Run</button>
		<button id="startAsyncButton">Run Async</button>
		<button id="stopButton" disabled>Stop</button>
	</div>

	<div>
		All output to stdout (and stderr) is displayed on this "terminal":
		<link rel="stylesheet" href="node_modules/xterm/css/xterm.css" />
		<div id="terminal" use:xterm={'hello term'} />

		<!-- <script type="pyodide" async config="config.toml" src="secretsanta.py"></script> -->
	</div>
</div>
