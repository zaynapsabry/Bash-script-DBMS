# Bash Shell Script Database Management System (DBMS)

## Overview

This project aims to develop a simple yet effective Database Management System (DBMS) using Bash Shell Scripting. The DBMS allows users to store, retrieve, and manage data on their hard disk through a Command Line Interface (CLI) menu.

---

## Usage ⬇️

1. **Clone the repository:**

    ```bash
    git clone https://github.com/zaynapsabry/Bash-script-DBMS.git
    ```

2. **Navigate to the project directory:**

    ```bash
    cd bin
    ```

3. **Run the script:**

    ```bash
    ./dbms.sh
    ```

4. **Follow the on-screen instructions to interact with the DBMS.**

---

## Features ✔️

### Main Menu

- **Create Database:** Create a new database to store tables.
- **List Databases:** View a list of available databases.
- **Rename Database:** Change current database name to another name.
- **Drop Database:** Delete a database and its associated tables.
- **Connect To Database:** Connect to a specific database for further operations.

### Database Menu

After connecting to a specific database, the user is presented with additional options:

- **Create Table:** Define the structure of a new table, specifying column names, data types and column constraints.
- **List Tables:** View a list of tables in the connected database.
- **Drop Table:** Remove a table from the database.
- **Insert Into Table:** Add new records to a table.
- **Select From Table:** Retrieve and display data from a table.
- **Delete From Table:** Remove records from a table based on specified conditions.
- **Update Table:** Modify existing records or columns in a table.

### Hints

- Databases are stored as directories in the databases directory.
- Displayed rows from SELECT operations are formatted for easy readability.
- User input for column data types is validated during table creation, insertion, and updating.
- Primary keys can be defined during table creation and are enforced during data insertion.

---

## Contributors <img src="https://emojipedia-us.s3.amazonaws.com/source/skype/295/hot-beverage_2615.png" height = "30px" width = "30px"/>

- **[Zeinab Sabry](https://github.com/zaynapsabry)**
- **[Sherry Osama](https://github.com/sh-osama-sami)**

<p align="center">
    <img src="https://c.tenor.com/S61VCO73mOAAAAAC/linux-tux.gif" alt="Interface" height = "100px" width = "100px" />
</p>

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please create an issue or submit a pull request.
