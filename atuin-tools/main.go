package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: atuin-tools <command> [args...]")
		fmt.Fprintln(os.Stderr, "commands: export, import")
		os.Exit(1)
	}

	cmd := os.Args[1]
	args := os.Args[2:]

	switch cmd {
	case "export":
		runExport(args)
	case "import":
		runImport(args)
	default:
		fmt.Fprintf(os.Stderr, "unknown command: %s\n", cmd)
		fmt.Fprintln(os.Stderr, "commands: export, import")
		os.Exit(1)
	}
}
