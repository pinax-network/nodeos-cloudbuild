package consolelog

import (
	"bytes"
	"encoding/json"
	"io"
	"io/ioutil"
	"os"
	"testing"

	"github.com/eoscanada/capture/hlog"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestReferenceAnalysis(t *testing.T) {
	reader, err := hlog.NewFileConsoleReader("output.log")
	require.NoError(t, err)
	defer reader.Close()

	f, err := os.Create("output.jsonl")
	require.NoError(t, err)
	defer f.Close()

	enc := json.NewEncoder(f)
	enc.SetIndent("", " ")
	for {
		el, err := reader.Read()
		if err == io.EOF {
			break
		}
		require.NoError(t, err)
		enc.Encode(el)
	}
	f.Close()

	ref, err := ioutil.ReadFile("reference.jsonl")
	require.NoError(t, err)
	out, err := ioutil.ReadFile("output.jsonl")
	require.NoError(t, err)

	assert.True(t, bytes.Compare(ref, out) == 0, "reference.jsonl and output.jsonl differ, run 'diff -u output.jsonl reference.jsonl")
}
