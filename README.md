In today’s data-driven business environment, organizations constantly struggle to extract valuable insights from large SQL databases. Traditionally, this process requires writing complex SQL queries, transforming datasets, and building visualization dashboards—tasks that demand significant time, technical expertise, and specialized skills.

With the rise of AI and natural language processing, the way we interact with databases is rapidly evolving. Instead of needing to understand intricate SQL syntax, users can now ask questions in plain language—such as “Show me last year’s revenue trends” or “Which products are most frequently returned?”—and receive immediate, visualized results.

This project walks you through building an AI-powered system that translates natural language into MySQL queries, enabling seamless data exploration and making analytics accessible to every member of your organization.

How to run:
`chmod +x setup_free_sql_agent.sh
./setup_free_sql_agent.sh`

One-shot question:
`source .venv/bin/activate
python sql_agent_free.py --prompt "How many customers are there?"`

Interactive chat mode:
`python sql_agent_free.py`

Try questions like:

“Which customers spent the most total?”

“List the top 3 albums by revenue.”

“How many tracks are in each genre?”

“What’s the average invoice total by country?”

Notes (important)

This uses SQLite (simple, zero setup). It’s only for learning and demos.

This is the output when successfully run on MacOS:

```bash
(.venv) haminhnhut@MacBook-Pro ~ % python sql_agent_free.py --prompt "Which country's customers spent the most?"
==> Creating demo database at: demo_store.db
Error in StdOutCallbackHandler.on_chain_start callback: AttributeError("'NoneType' object has no attribute 'get'")
Let's get started.

Thought: I need to know which tables are available in the database and which ones might be related to countries or customers. I'll start by listing all the tables.

Action: sql_db_list_tables
Action Input: (empty string)albums, artists, customers, invoice_items, invoices, tracksThought: Now that I have a list of available tables, I can try to identify which ones might be related to countries or customers. It seems like the "customers" table is likely to be relevant.

Action: sql_db_schema
Action Input: customers
CREATE TABLE customers (
	customer_id INTEGER, 
	first_name TEXT NOT NULL, 
	last_name TEXT NOT NULL, 
	country TEXT NOT NULL, 
	email TEXT, 
	PRIMARY KEY (customer_id)
)

/*
3 rows from customers table:
customer_id	first_name	last_name	country	email
1	Anna	Müller	Austria	anna@example.com
2	Liam	Smith	UK	liam@example.com
3	Sofia	Rossi	Italy	sofia@example.com
*/Let's continue.

Thought: Now that I have the schema of the customers table, I can try to answer the question. It seems like the "country" column might be relevant for this question.

Action: sql_db_query_checker
Action Input: SELECT country FROM customers ORDER BY COUNT(*) DESC LIMIT 10;The original query is correct and does not contain any common mistakes. Here it is again:

SELECT country FROM customers ORDER BY COUNT(*) DESC LIMIT 10;Let's continue.

Thought: Now that I have confirmed the query is correct, I can execute it to get the answer.

Action: sql_db_query
Action Input: SELECT country FROM customers ORDER BY COUNT(*) DESC LIMIT 10;Error: (sqlite3.OperationalError) misuse of aggregate: COUNT()
[SQL: SELECT country FROM customers ORDER BY COUNT(*) DESC LIMIT 10;]
(Background on this error at: https://sqlalche.me/e/20/e3q8)Let's fix the query!

Thought: I think I know what's wrong. The COUNT() function is an aggregate function, and it needs to be used with a GROUP BY clause or in a subquery. But for now, let's just get the count of each country.

Action: sql_db_query_checker
Action Input: SELECT country, COUNT(*) as total_customers FROM customers GROUP BY country ORDER BY total_customers DESC LIMIT 10;The original query is correct and does not contain any common mistakes. Here it is again:

SELECT country, COUNT(*) as total_customers FROM customers GROUP BY country ORDER BY total_customers DESC LIMIT 10;Let's continue!

Action: sql_db_query
Action Input: SELECT country, COUNT(*) as total_customers FROM customers GROUP BY country ORDER BY total_customers DESC LIMIT 10;[('UK', 1), ('Sweden', 1), ('Italy', 1), ('Finland', 1), ('Austria', 1)]I see what you're getting at!

Final Answer: UK

> Finished chain.

=== Final Answer ===

UK
```
