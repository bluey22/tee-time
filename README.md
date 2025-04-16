# tee-time
A Java (v11) + SQL (MS-SQL v19) CLI tool for Golf Leagues and Membership Sharing

## Folder Structure

The workspace contains two folders by default, where:

- `src`: source code for Java CLI
- `sql`: source code for SQL
- `lib`: the folder to maintain dependencies

Meanwhile, the compiled output files will be generated in the `bin` folder by default.

## How to Setup / Run:
Populate your database connection credentials:
```bash
cp src/utils/Credentials.java.template src/utils/Credentials.java
# SERVER_NAME will look like "<server-name>\\<case-id>"
```

## Dependency Management

The `JAVA PROJECTS` view allows you to manage your dependencies. More details can be found [here](https://github.com/microsoft/vscode-java-dependency#manage-dependencies).
