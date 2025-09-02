. .github/scripts/logging.functions.sh

echonotice singleline test

test_string="Line 1: starting test
Line 2: still testing
Line 3: almost done
Line 4: finished test"

echonotice "$test_string"
