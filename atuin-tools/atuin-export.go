package main

import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
	"strconv"

	_ "github.com/mattn/go-sqlite3"
)

func runExport(args []string) {
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintln(os.Stderr, "cannot determine home directory:", err)
		os.Exit(1)
	}

	dbPath := filepath.Join(home, ".local", "share", "atuin", "history.db")
	outPath := "history.csv"
	if len(args) > 0 {
		outPath = args[0]
	}

	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, "open db:", err)
		os.Exit(1)
	}
	defer db.Close()

	rows, err := db.Query("SELECT id, timestamp, duration, exit, command, cwd, session, hostname, deleted_at FROM history ORDER BY timestamp ASC")
	if err != nil {
		fmt.Fprintln(os.Stderr, "query:", err)
		os.Exit(1)
	}
	defer rows.Close()

	file, err := os.Create(outPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, "create output:", err)
		os.Exit(1)
	}
	defer file.Close()

	w := csv.NewWriter(file)
	defer w.Flush()

	// Header
	w.Write([]string{"id", "timestamp", "duration", "exit", "command", "cwd", "session", "hostname", "deleted_at"})

	var count int
	for rows.Next() {
		var id, command, cwd, session, hostname string
		var timestamp, duration, exit int
		var deletedAt sql.NullInt64

		err = rows.Scan(&id, &timestamp, &duration, &exit, &command, &cwd, &session, &hostname, &deletedAt)
		if err != nil {
			fmt.Fprintln(os.Stderr, "scan:", err)
			continue
		}

		deletedAtStr := ""
		if deletedAt.Valid {
			deletedAtStr = strconv.FormatInt(deletedAt.Int64, 10)
		}

		w.Write([]string{
			id,
			strconv.Itoa(timestamp),
			strconv.Itoa(duration),
			strconv.Itoa(exit),
			command,
			cwd,
			session,
			hostname,
			deletedAtStr,
		})
		count++
	}

	if err = rows.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "rows:", err)
		os.Exit(1)
	}

	fmt.Printf("Exported %d entries to %s\n", count, outPath)
}
