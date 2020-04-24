package compare

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/eoscanada/bstream/codecs/deos"
	pbdeos "github.com/eoscanada/bstream/pb/dfuse/codecs/deos"
	"github.com/eoscanada/jsonpb"
	"github.com/gogo/protobuf/proto"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var target = os.Getenv("TARGET")

func init() {
	if target == "" {
		fmt.Println("The TARGET enviornment variable should have been set")
		os.Exit(1)
	}
}

func TestReferenceAnalysis_AcceptedBlocks(t *testing.T) {
	f, err := os.Create(filepath.Join(target, "output.jsonl"))
	require.NoError(t, err)
	defer f.Close()

	for _, block := range readAllBlocks(t, "output.log") {
		f.Write([]byte(protoToJSON(t, block) + "\n"))
	}
	f.Close()

	assertJsonContentEqual(t, "reference.jsonl", "output.jsonl")
}

func TestReferenceAnalysis(t *testing.T) {
	stats := computeDeepMindStats(readAllBlocks(t, "output.log"))
	actual, _ := json.MarshalIndent(stats, "", "  ")
	err := ioutil.WriteFile(filepath.Join(target, "output.stats.json"), actual, 0644)
	require.NoError(t, err)

	expected, err := ioutil.ReadFile(filepath.Join(target, "reference.stats.json"))
	require.NoError(t, err)

	assert.JSONEq(t, string(expected), string(actual), "Reference stats and actual stats differs, run `diff -u output.stats.json reference.stats.json` for details")
}

func TestRamTraces_RunningUpBalanceChecks(t *testing.T) {
	payerToBalanceMap := map[string]int64{}
	for _, block := range readAllBlocks(t, "output.log") {
		for _, trxTrace := range block.TransactionTraces {
			for _, ramOp := range trxTrace.RamOps {
				payer, delta, usage := ramOp.Payer, ramOp.Delta, int64(ramOp.Usage)
				previousBalance, present := payerToBalanceMap[payer]

				if !present {
					assert.Equal(t, delta, usage, "For new account, usage & delta should the same since just created (%s)", protoToJSON(t, ramOp))
				} else {
					assert.Equal(t, previousBalance+delta, usage, "Previous balance + delta should equal new usage (%s)", protoToJSON(t, ramOp))
				}

				payerToBalanceMap[payer] = usage
			}
		}
	}
}

func protoToJSON(t *testing.T, message proto.Message) string {
	marshaler := jsonpb.Marshaler{}
	content, err := marshaler.MarshalToString(message)
	require.NoError(t, err)

	return content
}

func assertJsonContentEqual(t *testing.T, expectedFile string, actualFile string) {
	expected, err := ioutil.ReadFile(filepath.Join(target, expectedFile))
	require.NoError(t, err)
	actual, err := ioutil.ReadFile(filepath.Join(target, actualFile))
	require.NoError(t, err)

	actualString := strings.TrimSpace(string(actual))
	expectedString := strings.TrimSpace(string(expected))

	actualLines := strings.Split(actualString, "\n")
	expectedLines := strings.Split(expectedString, "\n")

	for i, expectedLine := range expectedLines {
		assert.JSONEq(t, expectedLine, actualLines[i], "line #%d differs", i)
	}

	// We have it at the end to make it more discoverable by being the last failure emitted after (possibily) a long blob of text
	assert.Equal(t, len(expectedLines), len(actualLines), "lines length differs")
}

func readAllBlocks(t *testing.T, nodeosLogFile string) []*pbdeos.Block {
	blocks := []*pbdeos.Block{}

	file, err := os.Open(filepath.Join(target, nodeosLogFile))
	require.NoError(t, err)
	defer file.Close()

	reader, err := deos.NewConsoleReader(file)
	require.NoError(t, err)
	defer reader.Close()

	for {
		el, err := reader.Read()
		if el != nil && el.(*pbdeos.Block) != nil {
			block, ok := el.(*pbdeos.Block)
			require.True(t, ok, "Type conversion should have been correct")

			blocks = append(blocks, block)
		}

		if err == io.EOF {
			break
		}

		require.NoError(t, err)
	}

	return blocks
}

func computeDeepMindStats(blocks []*pbdeos.Block) *ReferenceStats {
	stats := &ReferenceStats{}
	for _, block := range blocks {
		stats.TransactionOpCount += len(block.TrxOps)
		stats.RLimitOpCount += len(block.RlimitOps)

		for _, transactionTrace := range block.TransactionTraces {
			stats.TransactionCount++

			adjustDeepMindCreationTreeStats(transactionTrace, stats)
			adjustDeepMindDBOpsStats(transactionTrace, stats)
			adjustDeepMindDTrxOpsStats(transactionTrace, stats)
			adjustDeepMindFeatureOpsStats(transactionTrace, stats)
			adjustDeepMindPermOpsStats(transactionTrace, stats)
			adjustDeepMindRAMOpsStats(transactionTrace, stats)
			adjustDeepMindRAMCorrectionOpsStats(transactionTrace, stats)
			adjustDeepMindRLimitOpsStats(transactionTrace, stats)
			adjustDeepMindTableOpsStats(transactionTrace, stats)
		}
	}

	return stats
}

func adjustDeepMindCreationTreeStats(trxTrace *pbdeos.TransactionTrace, stats *ReferenceStats) {
	stats.CreationTreeNodeCount += len(trxTrace.CreationTree)
}

func adjustDeepMindDBOpsStats(trxTrace *pbdeos.TransactionTrace, stats *ReferenceStats) {
	for _, op := range trxTrace.DbOps {
		if strings.Contains(op.NewPayer, "battlefield") || strings.Contains(op.OldPayer, "battlefield") {
			stats.DBOpCount++
		}
	}
}

func adjustDeepMindDTrxOpsStats(trxTrace *pbdeos.TransactionTrace, stats *ReferenceStats) {
	for _, op := range trxTrace.DtrxOps {
		if strings.Contains(op.Payer, "battlefield") {
			stats.DTrxOpCount++
		}
	}
}

func adjustDeepMindFeatureOpsStats(trxTrace *pbdeos.TransactionTrace, stats *ReferenceStats) {
	stats.FeatureOpCount += len(trxTrace.FeatureOps)
}

func adjustDeepMindPermOpsStats(trxTrace *pbdeos.TransactionTrace, stats *ReferenceStats) {
	stats.PermOpCount += len(trxTrace.PermOps)
}

func adjustDeepMindRAMOpsStats(trxTrace *pbdeos.TransactionTrace, stats *ReferenceStats) {
	for _, op := range trxTrace.RamOps {
		if strings.Contains(op.Payer, "battlefield") {
			stats.RAMOpCount++
		}
	}
}

func adjustDeepMindRAMCorrectionOpsStats(trxTrace *pbdeos.TransactionTrace, stats *ReferenceStats) {
	for _, op := range trxTrace.RamCorrectionOps {
		if strings.Contains(op.Payer, "battlefield") {
			stats.RAMCorrectionOpCount++
		}
	}
}

func adjustDeepMindRLimitOpsStats(trxTrace *pbdeos.TransactionTrace, stats *ReferenceStats) {
	stats.RLimitOpCount += len(trxTrace.RlimitOps)
}

func adjustDeepMindTableOpsStats(trxTrace *pbdeos.TransactionTrace, stats *ReferenceStats) {
	stats.TableOpCount += len(trxTrace.TableOps)
}

type ReferenceStats = struct {
	TransactionCount      int
	CreationTreeNodeCount int
	DBOpCount             int
	DTrxOpCount           int
	FeatureOpCount        int
	PermOpCount           int
	RAMOpCount            int
	RAMCorrectionOpCount  int
	RLimitOpCount         int
	TransactionOpCount    int
	TableOpCount          int
}
