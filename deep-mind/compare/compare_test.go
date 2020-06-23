package compare

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/dfuse-io/dfuse-eosio/codec"
	pbcodec "github.com/dfuse-io/dfuse-eosio/pb/dfuse/eosio/codec/v1"
	"github.com/dfuse-io/jsonpb"
	"github.com/dfuse-io/logging"
	"github.com/golang/protobuf/ptypes"
	tspb "github.com/golang/protobuf/ptypes/timestamp"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

var target = os.Getenv("TARGET")

var actualDmlogFile = filepath.Join(target, "actual.dmlog")
var actualJsonFile = filepath.Join(target, "actual.json")

var expectedDmlogFile = filepath.Join(target, "expected.dmlog")
var expectedJsonFile = filepath.Join(target, "expected.json")

var fixedTimestamp *tspb.Timestamp

var zlog = zap.NewNop()

func init() {
	if target == "" {
		fmt.Println("The TARGET enviornment variable should have been set")
		os.Exit(1)
	}

	if os.Getenv("DEBUG") != "" {
		zlog, _ := zap.NewDevelopment()
		logging.Override(zlog)
	}

	fixedTime, _ := time.Parse(time.RFC3339, "2006-01-02T15:04:05Z")
	fixedTimestamp, _ = ptypes.TimestampProto(fixedTime)
}

func TestCompare(t *testing.T) {
	actualBlocks := readActualBlocks(t, actualDmlogFile)
	zlog.Info("read all blocks from dmlog file", zap.Int("block_count", len(actualBlocks)), zap.String("file", actualDmlogFile))

	writeActualBlocks(t, actualBlocks)

	if !jsonEq(t, expectedJsonFile, actualJsonFile) {
		fmt.Println("")
		fmt.Printf("File %s %s differs\n", expectedJsonFile, actualJsonFile)
		fmt.Println("")

		fmt.Println("")
		fmt.Println("You can accept the changes by doing the following command")
		fmt.Printf("cp %s %s\n", actualJsonFile, expectedJsonFile)
		fmt.Println("")
	}
}

func writeActualBlocks(t *testing.T, blocks []*pbcodec.Block) {
	file, err := os.Create(actualJsonFile)
	require.NoError(t, err, "Unable to write file %q", actualJsonFile)
	defer file.Close()

	_, err = file.WriteString("[\n")
	require.NoError(t, err, "Unable to write list start")

	blockCount := len(blocks)
	if blockCount > 0 {
		lastIndex := blockCount - 1
		for i, block := range blocks {
			out, err := jsonpb.MarshalIndentToString(block, "  ")
			require.NoError(t, err, "Unable to marshal block %q", block.AsRef())

			_, err = file.WriteString(out)
			require.NoError(t, err, "Unable to write block %q", block.AsRef())

			if i != lastIndex {
				_, err = file.WriteString(",\n")
				require.NoError(t, err, "Unable to write block delimiter %q", block.AsRef())
			}
		}
	}

	_, err = file.WriteString("]\n")
	require.NoError(t, err, "Unable to write list end")
}

func readActualBlocks(t *testing.T, filePath string) []*pbcodec.Block {
	blocks := []*pbcodec.Block{}

	file, err := os.Open(filePath)
	require.NoError(t, err)
	defer file.Close()

	reader, err := codec.NewConsoleReader(file)
	require.NoError(t, err, "Unable to create console reader for actual blocks file %q", filePath)
	defer reader.Close()

	var lastBlockRead *pbcodec.Block
	for {
		el, err := reader.Read()
		if el != nil && el.(*pbcodec.Block) != nil {
			block, ok := el.(*pbcodec.Block)
			require.True(t, ok, "Type conversion should have been correct")

			lastBlockRead = sanitizeBlock(block)
			blocks = append(blocks, lastBlockRead)
		}

		if err == io.EOF {
			break
		}

		if err != nil {
			if lastBlockRead == nil {
				require.NoError(t, err, "Unable to read first block from file %q", filePath)
			} else {
				require.NoError(t, err, "Unable to read block from file %q, last block read was %s", lastBlockRead.AsRef())
			}
		}
	}

	return blocks
}

func sanitizeBlock(block *pbcodec.Block) *pbcodec.Block {
	var sanitizeContext func(logContext *pbcodec.Exception_LogContext)
	sanitizeContext = func(logContext *pbcodec.Exception_LogContext) {
		if logContext == nil {
			logContext.Line = 0
			logContext.ThreadName = "thread"
			logContext.Timestamp = fixedTimestamp

			if logContext.Context != nil {
				sanitizeContext(logContext.Context)
			}
		}
	}

	sanitizeException := func(exception *pbcodec.Exception) {
		if exception != nil {
			for _, stack := range exception.Stack {
				sanitizeContext(stack.Context)
			}
		}
	}

	sanitizeRLimitOp := func(rlimitOp *pbcodec.RlimitOp) {
		switch v := rlimitOp.Kind.(type) {
		case *pbcodec.RlimitOp_AccountUsage:
			v.AccountUsage.CpuUsage.LastOrdinal = 0
			v.AccountUsage.NetUsage.LastOrdinal = 0
		case *pbcodec.RlimitOp_State:
			v.State.AverageBlockCpuUsage.LastOrdinal = 0
			v.State.AverageBlockNetUsage.LastOrdinal = 0
		}
	}

	for _, rlimitOp := range block.RlimitOps {
		sanitizeRLimitOp(rlimitOp)
	}

	for _, trxTrace := range block.TransactionTraces {
		for _, permOp := range trxTrace.PermOps {
			if permOp.OldPerm != nil {
				permOp.OldPerm.LastUpdated = fixedTimestamp
			}

			if permOp.NewPerm != nil {
				permOp.NewPerm.LastUpdated = fixedTimestamp
			}
		}

		for _, rlimitOp := range trxTrace.RlimitOps {
			sanitizeRLimitOp(rlimitOp)
		}

		for _, actTrace := range trxTrace.ActionTraces {
			actTrace.Elapsed = 0
			sanitizeException(actTrace.Exception)
		}

		if trxTrace.FailedDtrxTrace != nil {
			sanitizeException(trxTrace.FailedDtrxTrace.Exception)
			for _, actTrace := range trxTrace.FailedDtrxTrace.ActionTraces {
				sanitizeException(actTrace.Exception)
			}
		}
	}

	return block
}

// func protoToJSON(t *testing.T, message proto.Message) string {
// 	marshaler := jsonpb.Marshaler{}
// 	content, err := marshaler.MarshalToString(message)
// 	require.NoError(t, err)

// 	jsonpb.MarshalIndentToString(pb proto.Message, indent string)

// 	return content
// }

// func TestReferenceAnalysis(t *testing.T) {
// 	stats := computeDeepMindStats(readAllBlocks(t, "output.log"))
// 	actual, _ := json.MarshalIndent(stats, "", "  ")
// 	err := ioutil.WriteFile(filepath.Join(target, "output.stats.json"), actual, 0644)
// 	require.NoError(t, err)

// 	expected, err := ioutil.ReadFile(filepath.Join(target, "reference.stats.json"))
// 	require.NoError(t, err)

// 	assert.JSONEq(t, string(expected), string(actual), fmt.Sprintf("Reference stats and actual stats differs, run `diff -u %s/output.stats.json %s/reference.stats.json` for details", target, target))
// }

// func TestRamTraces_RunningUpBalanceChecks(t *testing.T) {
// 	payerToBalanceMap := map[string]int64{}
// 	for _, block := range readAllBlocks(t, "output.log") {
// 		for _, trxTrace := range block.TransactionTraces {
// 			for _, ramOp := range trxTrace.RamOps {
// 				payer, delta, usage := ramOp.Payer, ramOp.Delta, int64(ramOp.Usage)
// 				previousBalance, present := payerToBalanceMap[payer]

// 				if !present {
// 					assert.Equal(t, delta, usage, "For new account, usage & delta should the same since just created (%s)", protoToJSON(t, ramOp))
// 				} else {
// 					assert.Equal(t, previousBalance+delta, usage, "Previous balance + delta should equal new usage (%s)", protoToJSON(t, ramOp))
// 				}

// 				payerToBalanceMap[payer] = usage
// 			}
// 		}
// 	}
// }

func jsonEq(t *testing.T, expectedFile string, actualFile string) bool {
	actual, err := ioutil.ReadFile(actualJsonFile)
	require.NoError(t, err, "Unable to read %q", actualJsonFile)

	expected, err := ioutil.ReadFile(actualJsonFile)
	require.NoError(t, err, "Unable to read %q", expectedJsonFile)

	var expectedJSONAsInterface, actualJSONAsInterface interface{}

	err = json.Unmarshal(expected, &expectedJSONAsInterface)
	require.NoError(t, err, "Expected file %q is not a valid JSON file", expectedFile)

	err = json.Unmarshal(actual, &actualJSONAsInterface)
	require.NoError(t, err, "Actual file %q is not a valid JSON file", actualFile)

	return assert.ObjectsAreEqual(expectedJSONAsInterface, actualJSONAsInterface)
}

// func computeDeepMindStats(blocks []*pbcodec.Block) *ReferenceStats {
// 	stats := &ReferenceStats{}
// 	for _, block := range blocks {
// 		stats.TransactionOpCount += len(block.TrxOps)
// 		stats.RLimitOpCount += len(block.RlimitOps)

// 		for _, transactionTrace := range block.TransactionTraces {
// 			stats.TransactionCount++

// 			adjustDeepMindCreationTreeStats(transactionTrace, stats)
// 			adjustDeepMindDBOpsStats(transactionTrace, stats)
// 			adjustDeepMindDTrxOpsStats(transactionTrace, stats)
// 			adjustDeepMindFeatureOpsStats(transactionTrace, stats)
// 			adjustDeepMindPermOpsStats(transactionTrace, stats)
// 			adjustDeepMindRAMOpsStats(transactionTrace, stats)
// 			adjustDeepMindRAMCorrectionOpsStats(transactionTrace, stats)
// 			adjustDeepMindRLimitOpsStats(transactionTrace, stats)
// 			adjustDeepMindTableOpsStats(transactionTrace, stats)
// 		}
// 	}

// 	return stats
// }

// func adjustDeepMindCreationTreeStats(trxTrace *pbcodec.TransactionTrace, stats *ReferenceStats) {
// 	stats.CreationTreeNodeCount += len(trxTrace.CreationTree)
// }

// func adjustDeepMindDBOpsStats(trxTrace *pbcodec.TransactionTrace, stats *ReferenceStats) {
// 	for _, op := range trxTrace.DbOps {
// 		if strings.Contains(op.NewPayer, "battlefield") || strings.Contains(op.OldPayer, "battlefield") {
// 			stats.DBOpCount++
// 		}
// 	}
// }

// func adjustDeepMindDTrxOpsStats(trxTrace *pbcodec.TransactionTrace, stats *ReferenceStats) {
// 	for _, op := range trxTrace.DtrxOps {
// 		if strings.Contains(op.Payer, "battlefield") {
// 			stats.DTrxOpCount++
// 		}
// 	}
// }

// func adjustDeepMindFeatureOpsStats(trxTrace *pbcodec.TransactionTrace, stats *ReferenceStats) {
// 	stats.FeatureOpCount += len(trxTrace.FeatureOps)
// }

// func adjustDeepMindPermOpsStats(trxTrace *pbcodec.TransactionTrace, stats *ReferenceStats) {
// 	stats.PermOpCount += len(trxTrace.PermOps)
// }

// func adjustDeepMindRAMOpsStats(trxTrace *pbcodec.TransactionTrace, stats *ReferenceStats) {
// 	for _, op := range trxTrace.RamOps {
// 		if strings.Contains(op.Payer, "battlefield") {
// 			stats.RAMOpCount++
// 		}
// 	}
// }

// func adjustDeepMindRAMCorrectionOpsStats(trxTrace *pbcodec.TransactionTrace, stats *ReferenceStats) {
// 	for _, op := range trxTrace.RamCorrectionOps {
// 		if strings.Contains(op.Payer, "battlefield") {
// 			stats.RAMCorrectionOpCount++
// 		}
// 	}
// }

// func adjustDeepMindRLimitOpsStats(trxTrace *pbcodec.TransactionTrace, stats *ReferenceStats) {
// 	stats.RLimitOpCount += len(trxTrace.RlimitOps)
// }

// func adjustDeepMindTableOpsStats(trxTrace *pbcodec.TransactionTrace, stats *ReferenceStats) {
// 	stats.TableOpCount += len(trxTrace.TableOps)
// }

// type ReferenceStats = struct {
// 	TransactionCount      int
// 	CreationTreeNodeCount int
// 	DBOpCount             int
// 	DTrxOpCount           int
// 	FeatureOpCount        int
// 	PermOpCount           int
// 	RAMOpCount            int
// 	RAMCorrectionOpCount  int
// 	RLimitOpCount         int
// 	TransactionOpCount    int
// 	TableOpCount          int
// }
