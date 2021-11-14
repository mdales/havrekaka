package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strconv"
)

type PaletteEntry struct {
	Name   string   `json:"name"`
	Author string   `json:"author"`
	URL    string   `json:"url"`
	Hex    []string `json:"hex"`
}

func main() {
	if len(os.Args) != 3 {
		fmt.Printf("Avändande: %s [färger JSON fil] [dest asm file]\n", os.Args[0])
		return
	}

	f, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Printf("Misslyckades med att öppna JSON fil: %v\n", err)
		return
	}
	defer f.Close()

	var palettes map[string]PaletteEntry
	err = json.NewDecoder(f).Decode(&palettes)
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

	header := "[bits 32]\n"
	_, err = g.WriteString(header)
	if err != nil {
		fmt.Printf("Misslyckades skriver rubrik: %v", err)
		return
	}

	for symbol, palette := range palettes {
		header := fmt.Sprintf("\n; %s by %s\n%s:\n\tdw 0x%04x  ; length\n",
			palette.Name, palette.Author, symbol, len(palette.Hex))
		_, err := g.WriteString(header)
		if err != nil {
			fmt.Printf("Misslyckades skriver rubrik: %v", err)
			return
		}
		for _, hex := range palette.Hex {
			value, err := strconv.ParseInt(hex, 16, 32)
			if err != nil {
				fmt.Printf("Misslyckades läser färg '%s': %v", hex, err)
				return
			}
			röd := (value >> 16) & 0xFF
			grön := (value >> 8) & 0xFF
			blå := (value >> 0) & 0xFF
			// VESA seems to be BGRA? At least on Hyper-V. The spec I was reading said:
			// "Format of Palette Values:Alignment byte, Red byte, Green byte, Blue byte"
			// But in practice for 8bpp I'm seeing BGRA with 6 bits per channel
			line := fmt.Sprintf("\tdb 0x%02x, 0x%02x, 0x%02x, 0x0,\n", blå>>2, grön>>2, röd>>2)
			_, err = g.WriteString(line)
			if err != nil {
				fmt.Printf("Misslyckades skriver dd: %v", err)
				return
			}
		}
	}
}
