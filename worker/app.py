from flask import Flask, jsonify
from pathlib import Path
from datetime import datetime

app = Flask(__name__)
LOG_FILE = Path(__file__).resolve().parent / "worker.log"

@app.post("/run-task")
def run_task():
    """Handle task execution requests from Airflow."""
    msg = f"Task executed at {datetime.utcnow().isoformat()}\n"
    with LOG_FILE.open("a") as fh:
        fh.write(msg)
    return jsonify({"status": "ok", "message": msg})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
