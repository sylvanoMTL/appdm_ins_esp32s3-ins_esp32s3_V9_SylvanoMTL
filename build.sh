#!/bin/bash

if [ "$1" = "ci" ]; then
  echo "Hello running compilation for ci"
  repo init -u https://gitlab-ci-token:$runner_ci_token@git.sysrox.com/code/manifests/manifest_ins.git 
  # Replace runner ci token in manifest:
  python3 tools/ci_set_token_manifest.py .repo/manifests/lib_ci.xml
  # Replace revision if triggering job from upstream branch:
  echo "Hello, CI_PIPELINE_SOURCE = $CI_PIPELINE_SOURCE"
  if [ "$CI_PIPELINE_SOURCE" == "pipeline" ] && [ "$STAY_ON_MAIN" != "true" ]; then
    echo "Upstream triggering detected, compiling with $UPSTREAM_COMMIT_REF_NAME for $UPSTREAM_PROJECT_NAME"
    python3 tools/ci_set_revision_manifest.py .repo/manifests/lib_ci.xml $UPSTREAM_PROJECT_NAME $UPSTREAM_COMMIT_REF_NAME
  else
    echo "No upstream branch indicated, no substitution, compiling with main revision"
  fi
  repo sync --no-clone-bundle -m lib_ci.xml

   # Remove cpp files from static lib libraries
  echo "Removing cpp files libDM_SRX_INS_10_DOF"
  rm lib/libDM_SRX_INS_10_DOF/src/*.cpp
  rm -rf lib/libDM_SRX_INS_10_DOF/src/model

  pio run -c conf/conf.ini -e lolin_s3
  exit_code=$?
  rm -rf .repo .pio lib
  exit $exit_code
else
  echo "Running compilation for user"
  # Avoid the use of parent repo if detected
  repo_displaced=0
  if [ -d ../../.repo ]; then
    repo_displaced=1
    echo "Parent repo detected, displacing it"
    if [ ! -d temp ]; then
      mkdir temp
    fi
    mv ../../.repo temp/.repo
  fi

  repo init -u ssh://git@git.sysrox.com:2224/code/manifests/manifest_ins.git 
  repo sync -m lib.xml

  # Remove cpp files from static lib libraries
  echo "Removing cpp files libDM_SRX_INS_10_DOF"
  rm lib/libDM_SRX_INS_10_DOF/src/*.cpp
  rm -rf lib/libDM_SRX_INS_10_DOF/src/model

  pio run -c conf/conf.ini -e lolin_s3

  rm -rf .repo .pio lib

  if [ "$repo_displaced" -eq 1 ]; then
    echo "Restoring parent repo"
    mv temp/.repo ../../.repo
  fi

  rm -rf temp
fi