#!/bin/bash
source utilities.sh

# 1. Map the 7 arguments we added to utilities.py
WORKLOAD_HOME="$1"
SCENARIO="$2"
SCARABPARAMS="$3"
SCARABARCH="$4"
SCARABHOME="$5"
SEGMENT_ID="$6"
SCARAB_BIN="$7"

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

# 4. Construct the Scarab command for the synthetic kernel
# (Assuming ctype_pin_inst is your target frontend based on your previous note)
scarabCmd="$SCARABHOME/src/$SCARAB_BIN \
  --frontend ctype_pin_inst \
  $SCARABPARAMS &> sim.log"

# 5. Execute using the infra's perf_stat wrapper for overhead tracking
PERF_PREFIX=$(perf_stat_prefix "$OUTDIR/$segID/perf_stat.txt")
eval $PERF_PREFIX $scarabCmd &
wait $!
