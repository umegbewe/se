# SE

File-based storage engine implemented entirely in Bash. This project demonstrates how to store data in files, build indexes, run queries, manage transactions, and create backups


- [Features](#features)
- [Getting Started](#getting-started)
- [Directory Structure](#directory-structure)
- [Usage](#usage)
  - [Create a New Record](#create-a-new-record)
  - [Query Data](#query-data)
  - [Async Query](#async-query)
  - [Check and Retrieve Async Results](#check-and-retrieve-async-results)
  - [Backup and Restore](#backup-and-restore)
  - [Transactions](#transactions)
- [Data Types](#data-types)
- [Known Limitations](#known-limitations)

## Features
* Stores data in plain text files, one file per record, in a `data/<collection_name>/record_<record_id>` format.
* Maintains simple indexes to speed lookups by record ID or data type.  
* Provides both synchronous and asynchronous query modes.  
* Backup and restore of data directories.  
* Includes a minimal `transaction manager`, letting you stage changes and commit/rollback if desired.  
* Validates data types (e.g., string, integer, email, booleans).

## Getting Started

1. Clone `git clone https://github.com/umegbewe/se.git`  
2. Ensure that you have `Bash ≥4.0` installed and `sed`, `awk`, `grep`, `find` are on your PATH. 
---

## Directory Structure

• <strong>storage-engine.sh</strong>:  
  Main entry point. Parses CLI arguments (e.g., --create-record, --backup, --restore, etc.) and calls the appropriate functions. Also loads all sub-scripts.

• <strong>record_operations.sh</strong>:  
  Create, read, update, and delete (CRUD) functions. Each record is a file `record_<id>` in `data/<collection>/`.

• <strong>query-engine.sh</strong> & <strong>query_parser.sh</strong>:  
  Parse queries (“SELECT * FROM … WHERE … ORDER BY … LIMIT …”) and evaluate them.  

• <strong>index_operations.sh</strong>:  
  Functions to maintain the “index” files under `data/<collection>/indexes/`.  

• <strong>backup_restore.sh</strong>:  
  Backs up or restores the “data” directory.  

• <strong>transaction_manager.sh</strong>:  
  Minimal staging for commits/rollbacks.  

• <strong>type-system/</strong>:  
  Type definitions, regex validation, and utility functions.

---

## Usage

The storage engine is invoked via `storage-engine.sh` with various flags. For example:

```bash
bash storage-engine.sh --create-record <collection> <data> <data_type> [transaction_id]
```

### Create a New Record

Use `--create-record` to insert data:

• `collection`:  The name of the collection (directory) to store the record.  
• `data`:        The actual string data you want to store.  
• `data_type`:   A recognized type (e.g., string, integer, boolean, email, etc.).  
• `transaction_id`: (optional) if you want to include this in a transaction.

Example:  

```bash
bash storage-engine.sh --create-record users "John Doe" string
```

Output:

```bash
New record created with ID: 1734946832N_5678
```

You can confirm that something that looks like `data/users/record_1734946832N_5678` file is created with contents `John Doe|string`.

### Query Data

Use `--query` to perform a simple query.  
• You can pass a `WHERE field = value`, `ORDER BY field ASC`, `LIMIT n`, etc. in your actual query string, which the query parser can interpret.  
• By default, if the query matches multiple records, results will be printed line by line.  

Example:

```bash
bash storage-engine.sh --query "SELECT FROM users WHERE name = 'John Doe'"
```

Output:

```bash
John Doe|string
```

You can optionally provide a page number (second argument) and limit (third argument). For instance:

```bash
bash storage-engine.sh --query "SELECT FROM users WHERE type = 'string'" 1 2
```

Output:

```bash
John Doe|string
Jane Doe|string
```
That will fetch the first page of up to 2 matching records.

### Async Query

Useful for longer-running queries.  

```bash
bash storage-engine.sh --async-query "SELECT FROM users WHERE age >= 21"
```

Output:

```bash
Async query submitted successfully: <query_id>
```
where query_id is an internal identifier tracking the background job

### Check and Retrieve Async Results

```bash
bash storage-engine.sh --check-async-query <query_id>
```

Output:

```bash
Async query status: RUNNING

Or

Async query status: COMPLETE
```

Once it’s complete, fetch the results:

```
Async query result:
John Doe|string
Alice Johnson|string
```

### Backup and Restore
Backup the entire data directory:

```bash
bash storage-engine.sh --backup my_backup
```
Creates a “backup/my_backup.tar.gz” (or similar)

Restore from a backup:

```bash
bash storage-engine.sh --restore my_backup
```

### Transactions
Some record operations can be rolled into transactions. For instance, the “create_record” function can take a “transaction_id” param. If provided, the engine will stage the change in `data/transactions/<transaction_id>`. 

You can then commit or rollback the transaction:

```bash
# create a transaction ID
TXN_ID="abc123"

# insert a record into “users”
bash storage-engine.sh --create-record users "Alice" string "$TXN_ID"

# Then at some point, commit or rollback.
bash storage-engine.sh --commit-transaction "$TXN_ID"

bash storage-engine.sh --rollback-transaction "$TXN_ID"
```

By default, if no transaction_id is given, the record is created immediately.

### Data Types
Within `type-system/type_definitions.sh`, you’ll find definitions like:

* string: ^.$
* integer: ^[0-9]+$
* boolean: ^(true|false)$
* email: ^[a-zA-Z0-9.%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
* url: ^(https?://)?... etc.

When you do `create_record users 'great@linux.com' email`, the engine checks if `great@linux.com` matches the `email` regex. If not, you are in error.



### Limitations
* This is not optimized for high performance. Looping over files in Bash can be slow with large data sets.
* The query syntax is minimal and does not fully support complex joins or subqueries.
* Transaction support is rudimentary; concurrent edits can lead to partial conflicts.
* Because it’s file-based, you may want to migrate to a real database if your data grows large or concurrency becomes an issue.


Do not use this for anything serious. It's a learning exercise and a proof of concept.
