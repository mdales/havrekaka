package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"sort"
	"unicode/utf8"
)

type PSFHeader struct {
	Magic          uint32
	Version        uint32
	HeaderSize     uint32
	Flags          uint32
	NumberOfGlyphs uint32
	BytesPerGlyph  uint32
	Height         uint32
	Width          uint32
}

type TypsnittHeader struct {
	PSFHeader
	LookUpTableSize uint32
}

func (h PSFHeader) String() string {
	return fmt.Sprintf("<Magic: 0x%08x, Version: %d, PSFHeader: %d, Flags: 0x%08x, Glyphs: %d, Bytes per glyph: %d, Size: %dx%d >",
		h.Magic, h.Version, h.HeaderSize, h.Flags, h.NumberOfGlyphs, h.BytesPerGlyph, h.Width, h.Height)
}

func main() {

	if len(os.Args) != 3 {
		fmt.Printf("Usage: %s [path to PSF file] [path for typsnitt file]", os.Args[0])
		return
	}

	f, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Printf("Failed to open %s: %v\n", os.Args[1], err)
		return
	}
	defer f.Close()

	header := PSFHeader{}
	err = binary.Read(f, binary.LittleEndian, &header)
	if err != nil {
		fmt.Printf("Failed to read header: %v\n", err)
		return
	}

	if header.BytesPerGlyph < ((header.Width * header.Height) / 8) {
		fmt.Printf("Glyph data seems to be too small\n")
		return
	}

	g, err := os.Create(os.Args[2])
	if err != nil {
		fmt.Printf("Failed to create %s: %v", os.Args[2], err)
		return
	}
	defer g.Close()

	glyphmap := make([][]rune, header.NumberOfGlyphs)
	runemap := make(map[uint32]uint32, 0)

	if header.Flags == 0x1 {
		f.Seek(int64(header.HeaderSize)+(int64(header.BytesPerGlyph)*int64(header.NumberOfGlyphs)), 0)
		for i := uint32(0); i < header.NumberOfGlyphs; i++ {
			runelist := glyphmap[i]

			bytes := make([]byte, 0)
			b := make([]byte, 1)
			for true {
				count, err := f.Read(b)
				if b[0] == 0xFF {
					break
				}
				if err != nil {
					fmt.Printf("Failed to read glyth table: %v", err)
					return
				}
				if count == 0 {
					fmt.Printf("Data undeflow reading glyph table")
					return
				}
				bytes = append(bytes, b[0])
			}

			for len(bytes) > 0 {
				rune, size := utf8.DecodeRune(bytes)
				if rune == utf8.RuneError {
					fmt.Printf("Failed to decode UTF8 rune in table (%d): %v", size, bytes)
					return
				}
				runemap[uint32(rune)] = i
				runelist = append(runelist, rune)
				bytes = bytes[size:]
			}

			glyphmap[i] = runelist
		}
	} else {
		for i := uint32(0); i < header.NumberOfGlyphs; i++ {
			runelist := make([]rune, 1)
			runelist[0] = rune(i)
			glyphmap[i] = runelist
		}
	}

	newHeader := TypsnittHeader{
		header,
		uint32(len(runemap)),
	}
	binary.Write(g, binary.LittleEndian, newHeader)

	// Now generate a rune lookup table
	runes := make([]uint32, 0, len(runemap))
	for k := range runemap {
		runes = append(runes, k)
	}
	sort.Slice(runes, func(i, j int) bool {
		return runes[i] < runes[j]
	})
	for _, rune := range runes {
		err = binary.Write(g, binary.LittleEndian, rune)
		if err != nil {
			fmt.Printf("Failed to write rune number: %v", err)
			return
		}
		err = binary.Write(g, binary.LittleEndian, runemap[rune])
		if err != nil {
			fmt.Printf("Failed to write rune value: %v", err)
			return
		}
	}

	// go to start of glyph data in case we read the mapping table
	f.Seek(int64(header.HeaderSize), 0)

	for i := uint32(0); i < header.NumberOfGlyphs; i++ {

		// glyphs := glyphmap[i]
		// if len(glyphs) == 0 {
		// 	continue
		// }

		bits := make([]byte, header.BytesPerGlyph)
		count, err := f.Read(bits)
		if err != nil {
			fmt.Printf("Failed to read glyph %d: %v\n", i, err)
			return
		}
		if count != int(header.BytesPerGlyph) {
			fmt.Printf("Author needs to be less lazy\n")
			return
		}
		out, err := g.Write(bits)
		if err != nil {
			fmt.Printf("Failed to write glyph %d: %v\n", i, err)
			return
		}
		if out != count {
			fmt.Printf("Failed to write entire glyph %d not %d\n", count, out)
			return
		}
	}
}
