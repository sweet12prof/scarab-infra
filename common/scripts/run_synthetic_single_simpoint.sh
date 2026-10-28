#!/bin/bash
source utilities.sh

# 1. Map the 20 arguments passed from utilities.py
WORKLOAD_HOME="$1"
SCENARIO="$2"
SCARABPARAMS="$3"
SEGSIZE="$4"
SCARABARCH="$5"
WARMUP="$6"
SCARABHOME="$7"
SEGMENT_ID="$8"
SCARAB_BIN="$9"
SYNTH_TARGET_POOL_SIZE="$10"
SYNTH_TARGET_SAMPLING_STRATEGY="$11"
SYNTH_T_NT_RATIO="$12"
SYNTH_MEM_HIERACHY_LEVEL="$13"
SYNTH_DEPENDENCE_CHAIN_COUNT="$14"
SYNTH_INST_SIZE="$15"
SYNTH_DIRECTION_SAMPLING_STRATEGY="$16"
SYNTH_WORKLOAD_LENGTH="$17 "
SYNTH_NOP_SIZE="$18" 
SYNTH_STARTING_TARGET="$19"
SYNTH_TARGET_STRIDE="$20"

# 2. Locate the correct PARAMS file (preserves the git-hash matching logic)
PARAMS_FILE="$SCARABHOME/src/PARAMS.$SCARABARCH"
if [[ "$SCARAB_BIN" =~ ^scarab_([0-9a-fA-F]+) ]]; then
  HASH="${BASH_REMATCH[1]}"
  PARAMS_BY_HASH="$SCARABHOME/src/PARAMS.$SCARABARCH.$HASH"
  if [ -f "$PARAMS_BY_HASH" ]; then
    PARAMS_FILE="$PARAMS_BY_HASH"
  fi
fi

# 3. Set up the isolated output directory for this run
SIMHOME=$SCENARIO/$WORKLOAD_HOME
mkdir -p $SIMHOME
OUTDIR=$SIMHOME

segID=$SEGMENT_ID
mkdir -p $OUTDIR/$segID
cp "$PARAMS_FILE" "$OUTDIR/$segID/PARAMS.in"
cd $OUTDIR/$segID

instLimit=$(( $SEGSIZE + $WARMUP ))

# 4. Construct the Scarab command with explicit warmup and instruction limit
scarabCmd="$SCARABHOME/src/$SCARAB_BIN \
  --frontend synthetic \
  --full_warmup=$WARMUP \
  --inst_limit $instLimit \
  --target_pool_size ${SYNTH_TARGET_POOL_SIZE} \
  --target_sampling_strategy ${SYNTH_TARGET_SAMPLING_STRATEGY} \ 
  --t_nt_ratio ${SYNTH_T_NT_RATIO}
  --mem_hierachy_level ${SYNTH_MEM_HIERACHY_LEVEL}
  --dependence_chain_count ${SYNTH_DEPENDENCE_CHAIN_COUNT}
  --inst_size ${SYNTH_INST_SIZE}
  --direction_sampling_strategy ${SYNTH_DIRECTION_SAMPLING_STRATEGY}
  --workload_length ${SYNTH_WORKLOAD_LENGTH}
  --nop_size ${SYNTH_NOP_SIZE}
  --starting_target ${SYNTH_STARTING_TARGET}
  --target_stride ${SYNTH_TARGET_STRIDE}
  $SCARABPARAMS &> sim.log"

# 5. Execute using the infra's perf_stat wrapper for overhead tracking
PERF_PREFIX=$(perf_stat_prefix "$OUTDIR/$segID/perf_stat.txt")
eval $PERF_PREFIX $scarabCmd &
wait $!