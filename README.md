In today’s data-driven business environment, organizations constantly struggle to extract valuable insights from large SQL databases. Traditionally, this process requires writing complex SQL queries, transforming datasets, and building visualization dashboards—tasks that demand significant time, technical expertise, and specialized skills.

With the rise of AI and natural language processing, the way we interact with databases is rapidly evolving. Instead of needing to understand intricate SQL syntax, users can now ask questions in plain language—such as “Show me last year’s revenue trends” or “Which products are most frequently returned?”—and receive immediate, visualized results.

This project walks you through building an AI-powered system that translates natural language into MySQL queries, enabling seamless data exploration and making analytics accessible to every member of your organization.

How to run:
chmod +x setup_free_sql_agent.sh
./setup_free_sql_agent.sh

One-shot question:
source .venv/bin/activate
python sql_agent_free.py --prompt "How many customers are there?"

Interactive chat mode:
python sql_agent_free.py

Try questions like:

“Which customers spent the most total?”

“List the top 3 albums by revenue.”

“How many tracks are in each genre?”

“What’s the average invoice total by country?”

Notes (important)

This uses SQLite (simple, zero setup). It’s only for learning and demos.

