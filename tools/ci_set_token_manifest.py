import os
import sys

manifest_path = sys.argv[1]
ci_token = os.environ['runner_ci_token']
print("Hello, substituting ci token in manifest ", manifest_path)

# Read in the file
with open(manifest_path, 'r') as file :
  filedata = file.read()

  # Replace the target string
filedata = filedata.replace("{runner_ci_token}", ci_token)

# Write the file out again
with open(manifest_path, 'w') as file:
  file.write(filedata)

