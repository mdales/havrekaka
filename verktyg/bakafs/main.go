// Simple tool to generate a simple haverkaka FDD image
// The format is very simple for now: in sectors we have:
//
// 0: MBR
// 1..n: catalogue
// n+1..end: data
//
// The catalogue has th

package main

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"unsafe"
)

const SectorSize = 512

type FSDescription struct {
	MBR   string   `json:"MBR"`
	Files []string `json:"Files"`
}

type EntryData struct {
	EntrySize uint16
	Flags     uint16
	Offset    uint64
	Length    uint64
}

type CatalogueEntry struct {
	EntryData
	Name string
}

type Catalogue struct {
	Version                  uint32
	CatalogueLengthInSectors uint32
	CatalogueEntryCount      uint32
}

// We encode strings in Haverkake in Pascal style
// uint32 bytes, UTF8 data
func StringToHaverkaka(s string) []byte {

	buffer := make([]byte, 4+len(s))

	binary.LittleEndian.PutUint32(buffer[:4], uint32(len(s)))
	for i := 0; i < len(s); i++ {
		buffer[4+i] = s[i]
	}

	return buffer
}

func WriteBytes(f io.Writer, b []byte) error {
	count, err := f.Write(b)
	if err != nil {
		return err
	}
	if count != len(b) {
		return fmt.Errorf("%d inte %d", count, len(b))
	}
	return nil
}

func main() {

	if len(os.Args) != 3 {
		fmt.Printf("Avändande: %s [JSON fil] [FS fil]\n", os.Args[0])
		return
	}

	f, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Printf("Misslyckades med att öppna JSON fil: %v\n", err)
		return
	}
	defer f.Close()

	var description FSDescription
	err = json.NewDecoder(f).Decode(&description)
	if err != nil {
		fmt.Printf("Misslyckades läsa fil: %v\n", err)
		return
	}

	g, err := os.Create(os.Args[2])
	if err != nil {
		fmt.Printf("Misslyckades med att öppna FS fil: %v\n", err)
		return
	}
	defer g.Close()
	mbr, err := os.Open(description.MBR)
	if err != nil {
		fmt.Printf("Misslyckades med att öppna MBR: %v\n", err)
		return
	}
	defer mbr.Close()
	buffer, err := ioutil.ReadAll(mbr)
	if err != nil {
		fmt.Printf("Misslyckade läda MBR: %v\n", err)
		return
	}
	if len(buffer) != SectorSize {
		fmt.Printf("MBR inte rätt storlek: %d\n", len(buffer))
		return
	}
	err = WriteBytes(g, buffer)
	if err != nil {
		fmt.Printf("Misslyckades med att skriva MBR: %v\n", err)
		return
	}

	// write the catalog header
	catalogue := Catalogue{
		Version:                  0x1,
		CatalogueLengthInSectors: 1, // TODO - assumes catalog is one sector long currently!
		CatalogueEntryCount:      uint32(len(description.Files)),
	}
	err = binary.Write(g, binary.LittleEndian, catalogue)
	if err != nil {
		fmt.Printf("Misslyckades med att skriva rubrik: %v", err)
		return
	}

	entries := make([]EntryData, len(description.Files))

	offset := uint64(1024) // TODO - assumes catalog is one sector long currently!
	for i, path := range description.Files {
		stats, err := os.Stat(path)
		if err != nil {
			fmt.Printf("Misslyckades läda %s data: %v\n", path, err)
			return
		}

		filename := filepath.Base(path)
		converted_filename := StringToHaverkaka(filename)
		meta := EntryData{
			Offset: offset,
			Length: uint64(stats.Size()),
		}
		meta.EntrySize = uint16(unsafe.Sizeof(meta)) + uint16(len(converted_filename))
		entries[i] = meta

		// round offset up to next sector size
		offset += uint64(stats.Size())
		diff := offset % SectorSize
		if diff != 0 {
			offset += (SectorSize - diff)
		}

		err = binary.Write(g, binary.LittleEndian, meta)
		if err != nil {
			fmt.Printf("Misslyckades läda %s data: %v\n", path, err)
			return
		}
		err = WriteBytes(g, converted_filename)
		if err != nil {
			fmt.Printf("Misslyckades läda %s namn: %v\n", path, err)
			return
		}
	}

	for i, path := range description.Files {
		meta := entries[i]

		current, err := g.Seek(0, 2)
		if err != nil {
			fmt.Printf("Mysslyckades läda storlek: %v", err)
			return
		}
		if current > int64(meta.Offset) {
			fmt.Printf("%d > %d\n", current, meta.Offset)
			return
		}

		packing := make([]byte, meta.Offset-uint64(current))
		err = WriteBytes(g, packing)
		if err != nil {
			fmt.Printf("%v", err)
			return
		}

		f, err := os.Open(path)
		if err != nil {
			fmt.Printf("Misslyckades med att öppna MBR: %v\n", err)
			return
		}
		defer f.Close()
		buffer, err := ioutil.ReadAll(f)
		if err != nil {
			fmt.Printf("Misslyckade läda %s: %v\n", path, err)
			return
		}
		err = WriteBytes(g, buffer)
		if err != nil {
			fmt.Printf("Misslyckades med att skriva %s: %v\n", path, err)
			return
		}
	}

	// finally we make the image size up to a 1.44 MB FDD image size
	current, err := g.Seek(0, 2)
	if err != nil {
		fmt.Printf("Mysslyckades läda storlek: %v", err)
		return
	}
	remaining := (1440 * 1024) - current
	if remaining < 0 {
		fmt.Printf("Bilden är för stor! %d", remaining)
		return
	}
	if remaining > 0 {
		empty := make([]byte, remaining)
		err := WriteBytes(g, empty)
		if err != nil {
			fmt.Printf("Misslyckades med att skriva: %v", err)
			return
		}
	}
}
