package main

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

func main() {

	for {
		time.Sleep(time.Millisecond * 500)
		fmt.Printf("Generating a new UUID -- %s", uuid.New())
		fmt.Println()
	}
}
