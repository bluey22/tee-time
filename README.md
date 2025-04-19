# tee-time
A Java (v11) + SQL (MS-SQL v19) CLI tool for Golf Leagues and Membership Sharing

## Folder Structure

The workspace contains two folders by default, where:

- `src`: source code for Java CLI
- `sql`: source code for SQL

Meanwhile, the compiled output files will be generated in the `bin` folder by default.

## How to Setup / Run:
Populate your database connection credentials:
```bash
cp src/utils/Credentials.java.template src/utils/Credentials.java
# SERVER_NAME will look like "<server-name>\\<case-id>"
```

Setup the SQL database for testing:
- Relations are defined in `DDL.sql`
- Procedures / Use Cases are defined in `DML.sql`
- Mock data for testing is defined in `dev_data.sql`
