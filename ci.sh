#!/usr/bin/env bash

# running GAP tests suite

set -e

SRCDIR=${SRCDIR:-$PWD}

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

echo -e "${CYAN}"
echo "SRCDIR   : $SRCDIR"
echo "PKG_NAME : $PKG_NAME"
echo -e "${RESET}"

cd ${GAP_HOME}

make testpackage PKGNAME=$PKG_NAME

echo -e "${CYAN}"
echo "######################################################################"
echo "#"
echo "# TEST WITHOUT PACKAGES, EXCEPT REQUIRED BY GAP (using -A option)"
echo "#"
echo "######################################################################"
echo -e "${RESET}"
cat dev/log/testpackage1*.${PKG_NAME}

echo -e "${CYAN}"
echo "######################################################################"
echo "#"
echo "# TEST WITH ALL PACKAGES LOADED (using LoadAllPackages() command)"
echo "#"
echo "######################################################################"
echo -e "${RESET}"
cat dev/log/testpackage2*.${PKG_NAME}

echo -e "${CYAN}"
echo "######################################################################"
echo "#"
echo "# TEST WITH DEFAULT PACKAGES, LOADED AT GAP STARTUP"
echo "#"
echo "######################################################################"
echo -e "${RESET}"
cat dev/log/testpackageA*.${PKG_NAME}

for TESTCASE in A 1 2
do
    TESTRESULT=$(cat dev/log/testpackage${TESTCASE}*.$PKG_NAME | grep -c "#I  No errors detected while testing")
    if [ $TESTRESULT = '1' ]
    then
        # info message is there - this is a clear PASS
        result="PASS"
        color="${GREEN}"
    else
        color="${RED}"
        NUMFAILS=$(cat dev/log/testpackage${TESTCASE}*.$PKG_NAME | grep -c "########> Diff")
        if [ $NUMFAILS = '0' ]
        then
            # zero diffs, but no info message - what could that mean?
            TESTCOMPLETED=$(cat dev/log/testpackage${TESTCASE}*.$PKG_NAME | grep -c "#I  RunPackageTests")
            if [ $TESTCOMPLETED = '2' ]
            then
                # still there are two "RunPackageTests" (one at the beginning of the test, one at the end)
                # This means that at least the test did not crash
                result="UNCLEAR"
                color="${YELLOW}"
            elif [ $TESTCOMPLETED = '1' ]
            # only one "RunPackageTests": either a crash or LoadPackage returned 'fail'
            then
                if [ $(cat dev/log/testpackage${TESTCASE}*.$PKG_NAME | grep "#I  RunPackageTests" | grep -c "not loadable") = '1' ]
                then
                    # if LoadPackage returned fail, this will be clearly indicated in the log
                    result="NOT LOADED"
                else
                    # otherwise, log has initial RunPackageTests, package was loaded and then crashed
                    result="CRASH"
                fi
            else
                # The log does not contain "RunPackageTests" at all
                result="NOT STARTED"
            fi
        else
            # one of more diffs - this is a clear FAIL
            result="${NUMFAILS} DIFFS"
        fi
    fi
    export PASS$TESTCASE="${color}${result}${RESET}"
done

echo ""
echo "######################################################################"
echo "#"
echo "# TESTS SUMMARY"
echo "#"
echo "######################################################################"
echo ""
echo 'Package name                                         : ' $PKG_NAME 
echo -e 'With no packages loaded (GAP started with -r option) : ' $PASS1
echo -e 'With all packages loaded with LoadAllPackages()      : ' $PASS2
echo -e 'With default packages loaded at GAP startup          : ' $PASSA
echo ""

if [ "${PASS1}" != 'PASS' ] || [ "${PASS2}" != 'PASS' ] || [ "${PASSA}" != 'PASS' ]
then
  echo "######################################################################"
  echo ""
  cat /home/gap/travis/HELP.md
  echo "######################################################################"
  echo ""
  exit 1
fi
