package main

import (
	"encoding/json"
	"fmt"
	"os"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Printf("Avändande: %s [strings JSON file] [dest asm file]\n", os.Args[0])
		return
	}

	f, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Printf("Misslyckades med att öppna JSON fil: %v\n", err)
		return
	}
	defer f.Close()

	var strings map[string]string
	err = json.NewDecoder(f).Decode(&strings)
	if err != nil {
		fmt.Printf("Misslyckades läsa fil: %v\n", err)
		return
	}

	g, err := os.Create(os.Args[2])
	if err != nil {
		fmt.Printf("Misslyckades med att öppna asm fil: %v\n", err)
		return
	}
	defer g.Close()

	header := "[bits 32]\n\n"
	_, err = g.WriteString(header)
	if err != nil {
		fmt.Printf("Misslyckades skriver rubrik: %v", err)
		return
	}

	for key, value := range strings {
		plate := fmt.Sprintf("%s:\n\tdd 0x%04x,\n\tdb \"%s\"\n", key, len(value), value)
		_, err := g.WriteString(plate)
		if err != nil {
			fmt.Printf("Misslyckades skriver rubrik: %v", err)
			return
		}
	}
}
