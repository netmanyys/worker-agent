import os, asyncio
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse, PlainTextResponse

INV = os.environ.get("ANSIBLE_INVENTORY", "/opt/ansible/inventories/hosts.ini")
KEY = os.environ.get("ANSIBLE_PRIVATE_KEY", "/home/agent/.ssh/id_ed25519")
app = FastAPI()

HTML = """<!doctype html>
<title>Ansible Live</title>
<body>
<h3>Run: ansible web -m ping</h3>
<button onclick="run()">Run</button>
<pre id="out" style="white-space:pre-wrap"></pre>
<script>
async function run(){
  const ws = new WebSocket(`ws://${location.host}/ws/run`);
  const out = document.getElementById('out');
  ws.onopen = () => ws.send(JSON.stringify({group:"web", module:"ping", args:""}));
  ws.onmessage = (e) => out.textContent += e.data;
  ws.onclose = () => out.textContent += "\\n[CLOSED]\\n";
}
</script>
</body>"""

@app.get("/", response_class=HTMLResponse)
async def index():
    return HTML

@app.get("/health", response_class=PlainTextResponse)
async def health():
    return "ok"

@app.websocket("/ws/run")
async def ws_run(ws: WebSocket):
    await ws.accept()
    try:
        params = await ws.receive_json()
        group  = params.get("group", "web")
        module = params.get("module", "ping")
        args   = params.get("args", "")

        cmd = ["ansible", group, "-m", module, "-i", INV, "--private-key", KEY]
        if args:
            cmd.extend(["-a", args])

        proc = await asyncio.create_subprocess_exec(
            *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT
        )
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
            await ws.send_text(line.decode(errors="ignore"))
        await proc.wait()
    except WebSocketDisconnect:
        pass
    finally:
        await ws.close()
