#!/bin/bash

echo "Starting surface projection: $(date)"

# Run the MGH to SamSrf .mat conversion script
matlab -nodisplay -nosplash -nodesktop -r "try; run('retinotopy/FS_SurfaceProjection_MGHtoMAT'); catch e; disp(getReport(e)); exit(1); end; exit" \
  > logs/FS_SurfaceProjection_MGHtoMAT.log 2>&1

echo "Finished surface projection: $(date)"
