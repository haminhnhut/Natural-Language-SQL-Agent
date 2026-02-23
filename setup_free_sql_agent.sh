#!/usr/bin/env bash
set -euo pipefail

# ====== Config you can change ======
MODEL_NAME="${MODEL_NAME:-llama3}"
VENV_DIR="${VENV_DIR:-.venv}"
DB_FILE="${DB_FILE:-demo_store.db}"
PY_FILE="${PY_FILE:-sql_agent_free.py}"
# ===================================

echo "==> Checking prerequisites..."

# Basic check for python
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 not found. Install Python 3.10+ and retry."
  exit 1
fi

# Install Ollama if missing (macOS: brew, Linux: official install script)
if ! command -v ollama >/dev/null 2>&1; then
  echo "==> Ollama not found. Installing..."
  if command -v brew >/dev/null 2>&1; then
    brew install ollama
  else
    # Linux install (official)
    curl -fsSL https://ollama.com/install.sh | sh
  fi
else
  echo "==> Ollama already installed."
fi

# Start Ollama server if not running
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
  echo "==> Starting Ollama server..."
  # macOS: "ollama serve" in background
  # Linux: may already be managed by systemd, but this is safe
  (nohup ollama serve >/dev/null 2>&1 &) || true
  sleep 2
fi

echo "==> Pulling model: ${MODEL_NAME}"
ollama pull "${MODEL_NAME}"

echo "==> Creating virtual environment: ${VENV_DIR}"
python3 -m venv "${VENV_DIR}"

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

echo "==> Upgrading pip..."
python -m pip install --upgrade pip

echo "==> Installing Python dependencies..."
python -m pip install \
  langchain==0.2.* \
  langchain-community==0.2.* \
  langchain-experimental==0.0.* \
  sqlalchemy==2.* \
  pandas==2.* \
  tabulate==0.9.*

echo "==> Writing Python agent script: ${PY_FILE}"
cat > "${PY_FILE}" <<'PY'
import argparse
import os
import sqlite3
from typing import Optional

from sqlalchemy import create_engine, text
from langchain_community.utilities.sql_database import SQLDatabase
from langchain_community.llms import Ollama
from langchain_community.agent_toolkits import create_sql_agent
from langchain.agents import AgentType


def create_demo_db(db_path: str) -> None:
    """
    Creates a small demo 'music store' DB (SQLite) with realistic-ish tables + data.
    Safe to re-run: drops and recreates tables for a clean state.
    """
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.executescript(
        """
        PRAGMA foreign_keys = ON;

        DROP TABLE IF EXISTS invoice_items;
        DROP TABLE IF EXISTS invoices;
        DROP TABLE IF EXISTS tracks;
        DROP TABLE IF EXISTS albums;
        DROP TABLE IF EXISTS artists;
        DROP TABLE IF EXISTS customers;

        CREATE TABLE customers (
            customer_id INTEGER PRIMARY KEY,
            first_name TEXT NOT NULL,
            last_name  TEXT NOT NULL,
            country    TEXT NOT NULL,
            email      TEXT
        );

        CREATE TABLE artists (
            artist_id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
        );

        CREATE TABLE albums (
            album_id  INTEGER PRIMARY KEY,
            title     TEXT NOT NULL,
            artist_id INTEGER NOT NULL,
            FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
        );

        CREATE TABLE tracks (
            track_id   INTEGER PRIMARY KEY,
            name       TEXT NOT NULL,
            album_id   INTEGER NOT NULL,
            genre      TEXT NOT NULL,
            unit_price REAL NOT NULL,
            milliseconds INTEGER NOT NULL,
            FOREIGN KEY (album_id) REFERENCES albums(album_id)
        );

        CREATE TABLE invoices (
            invoice_id  INTEGER PRIMARY KEY,
            customer_id INTEGER NOT NULL,
            invoice_date TEXT NOT NULL,
            billing_country TEXT NOT NULL,
            total REAL NOT NULL,
            FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        );

        CREATE TABLE invoice_items (
            invoice_item_id INTEGER PRIMARY KEY,
            invoice_id INTEGER NOT NULL,
            track_id INTEGER NOT NULL,
            unit_price REAL NOT NULL,
            quantity INTEGER NOT NULL,
            FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),
            FOREIGN KEY (track_id) REFERENCES tracks(track_id)
        );
        """
    )

    customers = [
        (1, "Anna", "Müller", "Austria", "anna@example.com"),
        (2, "Liam", "Smith", "UK", "liam@example.com"),
        (3, "Sofia", "Rossi", "Italy", "sofia@example.com"),
        (4, "Noah", "Johansson", "Sweden", "noah@example.com"),
        (5, "Mia", "Nguyen", "Finland", "mia@example.com"),
    ]
    cur.executemany("INSERT INTO customers VALUES (?, ?, ?, ?, ?);", customers)

    artists = [
        (1, "Daft Punk"),
        (2, "Radiohead"),
        (3, "Björk"),
    ]
    cur.executemany("INSERT INTO artists VALUES (?, ?);", artists)

    albums = [
        (1, "Discovery", 1),
        (2, "OK Computer", 2),
        (3, "Homogenic", 3),
    ]
    cur.executemany("INSERT INTO albums VALUES (?, ?, ?);", albums)

    tracks = [
        (1, "One More Time", 1, "Electronic", 0.99, 320000),
        (2, "Harder Better Faster Stronger", 1, "Electronic", 0.99, 224000),
        (3, "Paranoid Android", 2, "Alternative", 1.29, 385000),
        (4, "Karma Police", 2, "Alternative", 1.29, 260000),
        (5, "Jóga", 3, "Art Pop", 1.19, 315000),
        (6, "Bachelorette", 3, "Art Pop", 1.19, 330000),
    ]
    cur.executemany("INSERT INTO tracks VALUES (?, ?, ?, ?, ?, ?);", tracks)

    invoices = [
        (1, 1, "2025-12-01", "Austria", 3.27),
        (2, 2, "2025-12-03", "UK", 2.58),
        (3, 3, "2025-12-05", "Italy", 4.76),
        (4, 4, "2025-12-08", "Sweden", 1.98),
        (5, 5, "2025-12-10", "Finland", 5.15),
    ]
    cur.executemany("INSERT INTO invoices VALUES (?, ?, ?, ?, ?);", invoices)

    invoice_items = [
        (1, 1, 1, 0.99, 1),
        (2, 1, 3, 1.29, 1),
        (3, 1, 5, 1.19, 1),

        (4, 2, 4, 1.29, 2),

        (5, 3, 2, 0.99, 2),
        (6, 3, 6, 1.19, 2),

        (7, 4, 1, 0.99, 2),

        (8, 5, 3, 1.29, 1),
        (9, 5, 4, 1.29, 1),
        (10, 5, 5, 1.19, 1),
        (11, 5, 6, 1.19, 1),
    ]
    cur.executemany("INSERT INTO invoice_items VALUES (?, ?, ?, ?, ?);", invoice_items)

    conn.commit()
    conn.close()


def run_agent(db_path: str, model_name: str, prompt: str) -> None:
    # SQLAlchemy engine for SQLite file
    engine = create_engine(f"sqlite:///{db_path}")

    # LangChain SQLDatabase wrapper
    db = SQLDatabase(engine)

    # Local LLM via Ollama
    llm = Ollama(model=model_name, temperature=0.2)

    # SQL Agent
    agent = create_sql_agent(
        llm=llm,
        db=db,
        verbose=True,
        handle_parsing_errors=True,
        agent_type=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
    )

    result = agent.invoke(prompt)

    # LangChain may return dict; print cleanly
    if isinstance(result, dict) and "output" in result:
        print("\n=== Final Answer ===\n")
        print(result["output"])
    else:
        print("\n=== Final Answer ===\n")
        print(result)


def repl(db_path: str, model_name: str) -> None:
    print("\nFree NLQ → SQL Agent (local Ollama)")
    print("Type a question, or 'exit' to quit.\n")
    while True:
        q = input("NLQ> ").strip()
        if not q:
            continue
        if q.lower() in ("exit", "quit"):
            break
        run_agent(db_path, model_name, q)
        print()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default="demo_store.db", help="SQLite DB file path")
    parser.add_argument("--model", default="llama3", help="Ollama model name (e.g., llama3, mistral)")
    parser.add_argument("--prompt", type=str, help="One-shot question to ask the agent")
    parser.add_argument("--rebuild-db", action="store_true", help="Drop & recreate the demo DB")
    args = parser.parse_args()

    if args.rebuild_db or not os.path.exists(args.db):
        print(f"==> Creating demo database at: {args.db}")
        create_demo_db(args.db)

    if args.prompt:
        run_agent(args.db, args.model, args.prompt)
    else:
        repl(args.db, args.model)


if __name__ == "__main__":
    main()
PY

echo "==> Done."
echo ""
echo "Next:"
echo "  1) Activate venv:  source ${VENV_DIR}/bin/activate"
echo "  2) Run one question:"
echo "     python ${PY_FILE} --prompt \"Which country's customers spent the most?\""
echo "  3) Or run interactive mode:"
echo "     python ${PY_FILE}"
echo ""
echo "Tip: rebuild DB anytime with:"
echo "     python ${PY_FILE} --rebuild-db"
