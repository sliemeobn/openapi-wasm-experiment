import { defineConfig } from "vite";
import swiftWasm from "@elementary-swift/vite-plugin-swift-wasm";

export default defineConfig({
  plugins: [
    swiftWasm({
      extraBuildArgs: [
        "-Xcc",
        "-D_WASI_EMULATED_MMAN",
        "-Xcc",
        "-D_WASI_EMULATED_SIGNAL",
      ],
    }),
  ],
});
