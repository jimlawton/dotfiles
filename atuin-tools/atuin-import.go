package main

import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"

	_ "github.com/mattn/go-sqlite3"
)

func runImport(args []string) {
	dryRun := false
	var positional []string
	for _, a := range args {
		if a == "--dry-run" {
			dryRun = true
		} else {
			positional = append(positional, a)
		}
	}

	inPath := "history.csv"
	if len(positional) > 0 {
		inPath = positional[0]
	}

	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintln(os.Stderr, "cannot determine home directory:", err)
		os.Exit(1)
	}

	dbPath := filepath.Join(home, ".local", "share", "atuin", "history.db")

	file, err := os.Open(inPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, "open csv:", err)
		os.Exit(1)
	}
	defer file.Close()

	r := csv.NewReader(file)
	r.LazyQuotes = true

	// Read and validate header
	header, err := r.Read()
	if err != nil {
		fmt.Fprintln(os.Stderr, "read header:", err)
		os.Exit(1)
	}
	expectedHeader := []string{"id", "timestamp", "duration", "exit", "command", "cwd", "session", "hostname", "deleted_at"}
	if len(header) != len(expectedHeader) {
		fmt.Fprintf(os.Stderr, "expected %d columns, got %d\n", len(expectedHeader), len(header))
		os.Exit(1)
	}
	for i, h := range expectedHeader {
		if header[i] != h {
			fmt.Fprintf(os.Stderr, "unexpected column %d: got %q, want %q\n", i, header[i], h)
			os.Exit(1)
		}
	}

	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, "open db:", err)
		os.Exit(1)
	}
	defer db.Close()

	tx, err := db.Begin()
	if err != nil {
		fmt.Fprintln(os.Stderr, "begin tx:", err)
		os.Exit(1)
	}

	stmt, err := tx.Prepare(`INSERT OR IGNORE INTO history (id, timestamp, duration, exit, command, cwd, session, hostname, deleted_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		fmt.Fprintln(os.Stderr, "prepare:", err)
		os.Exit(1)
	}
	defer stmt.Close()

	var imported, skipped int
	var lineNum int
	for {
		record, err := r.Read()
		if err == io.EOF {
			break
		}
		lineNum++
		if err != nil {
			fmt.Fprintf(os.Stderr, "line %d: read: %v\n", lineNum+1, err)
			skipped++
			continue
		}

		if len(record) != 9 {
			fmt.Fprintf(os.Stderr, "line %d: expected 9 fields, got %d\n", lineNum+1, len(record))
			skipped++
			continue
		}

		id := record[0]
		timestamp, err := strconv.ParseInt(record[1], 10, 64)
		if err != nil {
			fmt.Fprintf(os.Stderr, "line %d: bad timestamp %q: %v\n", lineNum+1, record[1], err)
			skipped++
			continue
		}
		duration, err := strconv.ParseInt(record[2], 10, 64)
		if err != nil {
			fmt.Fprintf(os.Stderr, "line %d: bad duration %q: %v\n", lineNum+1, record[2], err)
			skipped++
			continue
		}
		exit, err := strconv.ParseInt(record[3], 10, 64)
		if err != nil {
			fmt.Fprintf(os.Stderr, "line %d: bad exit %q: %v\n", lineNum+1, record[3], err)
			skipped++
			continue
		}
		command := record[4]
		cwd := record[5]
		session := record[6]
		hostname := record[7]

		var deletedAt *int64
		if record[8] != "" {
			v, err := strconv.ParseInt(record[8], 10, 64)
			if err != nil {
				fmt.Fprintf(os.Stderr, "line %d: bad deleted_at %q: %v\n", lineNum+1, record[8], err)
				skipped++
				continue
			}
			deletedAt = &v
		}

		result, err := stmt.Exec(id, timestamp, duration, exit, command, cwd, session, hostname, deletedAt)
		if err != nil {
			fmt.Fprintf(os.Stderr, "line %d: insert: %v\n", lineNum+1, err)
			skipped++
			continue
		}

		affected, _ := result.RowsAffected()
		if affected > 0 {
			imported++
		} else {
			skipped++
		}
	}

	if dryRun {
		if err := tx.Rollback(); err != nil {
			fmt.Fprintln(os.Stderr, "rollback:", err)
			os.Exit(1)
		}
		fmt.Printf("[dry-run] Would import %d entries from %s (%d skipped/duplicate)\n", imported, inPath, skipped)
	} else {
		if err := tx.Commit(); err != nil {
			fmt.Fprintln(os.Stderr, "commit:", err)
			os.Exit(1)
		}
		fmt.Printf("Imported %d entries from %s (%d skipped/duplicate)\n", imported, inPath, skipped)
	}
}
