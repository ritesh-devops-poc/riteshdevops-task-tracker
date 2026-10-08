const express = require("express");
const { Pool } = require("pg");
require("dotenv").config();

const app = express();
const port = process.env.PORT || 3000;

// PostgreSQL connection pool
const db = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// Middleware
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static("public"));

app.set("view engine", "ejs");

// Home - show all tasks
app.get("/", async (req, res) => {
  try {
    const result = await db.query(
      "SELECT * FROM tasks ORDER BY created_at DESC"
    );

    res.render("index", {
      tasks: result.rows,
    });
  } catch (error) {
    console.error(error);
    res.status(500).send("Database error");
  }
});

// Create task
app.post("/tasks", async (req, res) => {
  try {
    const { title, description } = req.body;

    await db.query(
      "INSERT INTO tasks (title, description) VALUES ($1, $2)",
      [title, description]
    );

    res.redirect("/");
  } catch (error) {
    console.error(error);
    res.status(500).send("Unable to create task");
  }
});

// Mark task as completed
app.post("/tasks/:id/complete", async (req, res) => {
  try {
    await db.query(
      "UPDATE tasks SET status = 'completed' WHERE id = $1",
      [req.params.id]
    );

    res.redirect("/");
  } catch (error) {
    console.error(error);
    res.status(500).send("Unable to update task");
  }
});

// Delete task
app.post("/tasks/:id/delete", async (req, res) => {
  try {
    await db.query(
      "DELETE FROM tasks WHERE id = $1",
      [req.params.id]
    );

    res.redirect("/");
  } catch (error) {
    console.error(error);
    res.status(500).send("Unable to delete task");
  }
});

// Start server
app.listen(port, () => {
  console.log(`Ritesh DevOps Task Tracker running on port ${port}`);
});