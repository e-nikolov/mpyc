import { defineConfig } from 'vite'

// https://vitejs.dev/config/
export default defineConfig({
  // root: "../",
  base: "/mpyc/",
  server: {
    headers: {
      "Cross-Origin-Embedder-Policy": "require-corp",
      "Cross-Origin-Opener-Policy": "same-origin",
      "Accept-Ranges": "bytes"
    },
    fs: {
      allow: ["../../"]
    }
  }
})
