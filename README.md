
# Research Paper Repository (MySQL-Based)

This project implements a complete **Research Paper Repository** using only **MySQL**. It is designed to manage paper submissions, reviews, versioning, user roles, citations, and statistics, all via SQL without requiring frontend/backend code.

---

## 📘 ER Diagram

![ER Diagram](/er-diagram.png)

---
## 📚 Features Overview

### 🔐 1. User Management
- **Tables:** `users`, `roles`, `user_roles`
- Tracks authors, reviewers, and admins with login details.
- Supports role-based access control (RBAC).

> ✅ *Ensures only authorized users can perform certain actions (e.g., only reviewers can review papers).*

---

### 📄 2. Paper Management
- **Tables:** `papers`, `paper_versions`
- Supports multiple versions per paper with metadata and file paths.
- Tracks status like `DRAFT`, `SUBMITTED`, `ACCEPTED`, etc.

> ✅ *Keeps track of paper versions and submission history.*

---

### 🔗 3. Citation Management
- **Table:** `citations`
- Stores which papers cite others.

> ✅ *Helps measure research influence via citation count.*

---

### 📝 4. Review System
- **Table:** `reviews`
- Assigns reviewers to specific versions of papers.
- Supports scoring (1-5) and comment tracking.

> ✅ *Facilitates peer review with version-specific feedback.*

---

### 🏷️ 5. Tagging System
- **Tables:** `tags`, `paper_tags`
- Assigns subject tags (e.g., AI, Quantum Physics) to papers.

> ✅ *Improves searchability and categorization of research.*

---

### 📊 6. Audit Logs
- **Table:** `audit_logs`
- Logs insert/update/delete actions for key tables like `papers`.

> ✅ *Adds traceability for changes, aiding in transparency and compliance.*

---

## ⚙️ Optimization Features

- **Indexes:** Full-text on `title`, `abstract` for fast search.
- **Additional Indexes:** On `status`, `reviewer`, and `user_roles`.

> ✅ *Significantly improves query performance on large datasets.*

---

## 🔁 Triggers
- **Triggers:** `papers_audit`, `paper_versions_audit`
- Automatically logs changes on inserts into key tables.

> ✅ *Maintains a history of who added what and when.*

---

## 🧠 Stored Procedures

### `submit_paper_version`
> Submits a new version of a paper by an author. Auto-increments version and updates status.

### `assign_reviewer`
> Assigns a reviewer to a paper version. Only an admin can do this.

### `bulk_import_papers`
> Imports papers from a JSON structure (simplified for demonstration).

### `search_papers`
> Searches papers by keywords in title, abstract, or tag names using full-text search and tag matching.

> ✅ *Encapsulates business logic and enforces role-based access rules.*

---

## 📈 Views for Statistics

### `most_cited_papers`
> Shows the most cited papers along with citation counts.

### `active_reviewers`
> Lists reviewers who have completed the most reviews.

> ✅ *Provides quick insights into system activity and paper impact.*

---



## 🧪 Sample Queries Explained

### 1. **Get all papers with latest version**
```sql
SELECT p.paper_id, v.title, v.abstract, p.status 
FROM papers p
JOIN paper_versions v ON p.current_version = v.version AND p.paper_id = v.paper_id;
```
> 🎯 Fetches latest version details for each paper.

---

### 2. **Get all citations for a paper**
```sql
SELECT cited_paper_id 
FROM citations 
WHERE citing_paper_id = 1;
```
> 🔗 Lists all papers cited by a specific paper.

---

### 3. **Get pending reviews for a reviewer**
```sql
SELECT * FROM reviews 
WHERE reviewer_id = 2 AND status = 'PENDING';
```
> 🕒 Helps reviewers see what’s pending in their queue.

---

### 4. **Update paper status**
```sql
UPDATE papers SET status = 'ACCEPTED' WHERE paper_id = 1;
```
> ✅ Used by editors/admins to update review outcomes.

---

### 5. **Get papers by tag**
```sql
SELECT p.paper_id, v.title 
FROM papers p
JOIN paper_versions v ON p.current_version = v.version AND p.paper_id = v.paper_id
JOIN paper_tags pt ON p.paper_id = pt.paper_id
JOIN tags t ON pt.tag_id = t.tag_id
WHERE t.tag_name = 'Artificial Intelligence';
```
> 🔍 Useful for subject-wise filtering of research work.

---

## 📌 Notes
- **Password storage** uses `bcrypt` hash format (`CHAR(60)`).
- Follows **normalization** and **referential integrity** using `FOREIGN KEY`s.
- Can be extended with more roles, detailed audit triggers, and file storage integrations.

---

## ✅ Getting Started

To use this schema:

1. Import `research_repository.sql` into your MySQL server.
2. Run the queries/procedures directly via MySQL CLI or any client (e.g., MySQL Workbench).
3. Extend or integrate as needed.

---

> Built with 💡 to simplify research paper workflow management using just SQL.
