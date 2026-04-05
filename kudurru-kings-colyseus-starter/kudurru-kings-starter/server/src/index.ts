import "./kk-hooks";
import "dotenv/config";
import express from "express";
import { createServer } from "http";
import { Server } from "colyseus";
import { monitor } from "@colyseus/monitor";
import { KudurruRoom } from "./rooms/KudurruRoom";

const PORT = Number(process.env.PORT || 2567);
const app = express();
const server = createServer(app);
const gameServer = new Server({ server });
gameServer.define("my_room", KudurruRoom);

gameServer.define("kudurru", KudurruRoom);

// Dev-only monitor
app.use("/colyseus", monitor());

server.listen(PORT, () => {
  console.log(`[Kudurru] Colyseus listening on ws://localhost:${PORT}`);
});
