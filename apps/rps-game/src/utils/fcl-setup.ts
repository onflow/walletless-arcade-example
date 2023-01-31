import * as fcl from "@onflow/fcl";

fcl
  .config()
  .put("accessNode.api", "http://localhost:8888")
  .put("flow.network", "emulator");
