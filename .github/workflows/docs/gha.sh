#!/bin/bash

mapfile -t gldt < <(git log --format='%cs' --grep=^docs -i | uniq)
GHA_FP=.github/workflows/docs/preamble
TMP_FP=/tmp/Changelog.md
cat $GHA_FP > $TMP_FP
for dt in "${gldt[@]}"; do
  echo "## $dt" >> $TMP_FP
  docs=$(git log --format='- %s by %an (%h)' --date=short --grep=^docs --since="${dt} 00:00:00" --until="${dt} 23:59:59")
  echo -e "$docs" >> $TMP_FP; 
done
