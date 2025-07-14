#!/bin/bash
# Run from analysis/ folder

echo "Starting map_to_fsaverage projection: $(date)"

# Run the SamSrf map-to-fsaverage script
matlab -nodisplay -nosplash -nodesktop -r "try; run('retinotopy/generate_avgmap'); catch e; disp(getReport(e)); exit(1); end; exit" \
  > logs/generate_avgmap.log 2>&1

echo "Finished map_to_fsaverage projection: $(date)"
