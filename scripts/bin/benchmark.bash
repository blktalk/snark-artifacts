#!/bin/bash

dl() {
  local cdn="$1"
  local artifact="$2"
  local version=${cdn/*github.com*/1.0.0}
  version=${version//*/latest}

  local url="$cdn/$artifact"
  curl -s -o /dev/null "$url"
}

dl_all() {
  local cdn="$1"
  # poseidon is the package that has the most artifacts
  # so using it for testing
  # deliberately download sequentially as this is what is taking so long
  # and causing issues in zk-kit ci atm
  start=$(date +%s)
  for artifact in poseidon-{1..16}.{wasm,zkey}; do
    dl "$cdn" "$artifact"
  done
  end=$(date +%s)
  cdn=${cdn/*github.com*/github}
  cdn=${cdn/*unpkg.com*/unpkg}
  cdn=${cdn/*jsdelivr.net*/jsdelivr}
  echo "$cdn,$((end - start))"
}

average() {
  local log="$1"
  awk -F',' '
/unpkg/ { unpkg_sum += $2; unpkg_count += 1 }
/jsdelivr/ { jsdelivr_sum += $2; jsdelivr_count += 1 }
/github/ { github_sum += $2; github_count += 1 }
END {
  print "download time average (s)"
  print "  unpkg", unpkg_sum/unpkg_count
  print "  jsdelivr", jsdelivr_sum/jsdelivr_count
  print "  github", github_sum/github_count
}
' "$log"
}

main() {
  local log
  log=$(mktemp)

  for cdn in "https://cdn.jsdelivr.net/npm/@zk-kit/poseidon-artifacts@latest" \
    "https://unpkg.com/@zk-kit/poseidon-artifacts@latest" \
    "https://github.com/privacy-scaling-explorations/snark-artifacts/raw/@zk-kit/semaphore-artifacts@1.0.0/packages/poseidon"; do
    for _ in {1..10}; do
      dl_all "$cdn" | tee -a "$log" &
    done
  done

  wait
  echo "done, results are in $log"
  average "$log"
}

main
