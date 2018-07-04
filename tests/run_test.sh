#!/bin/bash

# Script to test the LATTE program.

MY_PATH=`pwd`                                   # Capturing the local path of the folder where we are running.

RUN="./LATTE_DOUBLE"  # LATTE program executable

echo ""
echo "Reference elapsed CPU time"
echo "=========================="
echo ""

( cd tests; make; cd .. ) &> /dev/null

echo -en "   Testing for reference ... "
timeRef=`( /usr/bin/time -f "%S" ./tests/timer_cpu_time > out ) 2>&1 > /dev/null`

relativeTime=`echo "$timeRef/$timeRef" | bc -l | awk '{printf("%.3f",$1)}'`
echo "(${timeRef}s,$relativeTime) PASSED"

echo ""
echo "Testing LATTE with new (latte.in) input files"
echo "============================================="
echo ""

mv latte.in latte.in.tmp

set -e                                          # This will exit the script if there is any error

# Testing for single point calculations:

for name in single.point single.point.noelec single.point.rspace ; do

  INLATTEFILE="latte."$name".in"
  REF="energy."$name".out"
  COORDS=$name".dat"

  cp  ./tests/$INLATTEFILE latte.in
  cp  ./tests/$REF .
  cp  ./tests/$COORDS ./bl/inputblock.dat

  echo -en "   Testing for "$name" ... "

  time=`( /usr/bin/time -f "%S" $RUN > out ) 2>&1 > /dev/null`
  ENERG=`grep -e "FREE ENERGY" out | awk 'NF>1{print $5}'`
  echo $ENERG > energy.out

  relativeTime=`echo "$time/$timeRef" | bc -l | awk '{printf("%.3f",$1)}'`
  echo -n "(${time}s,$relativeTime) "
  python ./tests/test-energy.py --reference $REF --current energy.out --reltol 0.00001

  rm $REF out

done

# Testing geometry optimizations:

for name in opt opt.cg opt_cons dorbitals; do

  INLATTEFILE="latte."$name".in"
  REF="monitorrelax."$name".xyz"
  COORDS=$name".dat"

  cp  ./tests/$INLATTEFILE latte.in
  cp  ./tests/$REF .
  cp  ./tests/$COORDS ./bl/inputblock.dat
  if [ $name == "opt_cons" ]; then
    cp ./tests/freeze.in .
  fi

  echo -en "   Testing for "$name" ... "

  time=`( /usr/bin/time -f "%S" $RUN > out ) 2>&1 > /dev/null`

  relativeTime=`echo "$time/$timeRef" | bc -l | awk '{printf("%.3f",$1)}'`
  echo -n "(${time}s,$relativeTime) "
  python ./tests/test-optim.py --reference $REF --current monitorrelax.xyz --reltol 0.00001

  #rm $REF monitorrelax.xyz out
done

# Testing for MD simulations:

for name in tableread 0scf 2scf fullscf fullscf.etemp sp2 sp2.sparse fullscf.nvt \
       	fullscf.npt fullscf.vdw fullscf.spin fullscf.kon fullscf.rspace ; do

  INLATTEFILE="latte."$name".in"
  REF="energy."$name".out"
  COORDS=$name".dat"

  cp  ./tests/$INLATTEFILE latte.in
  cp  ./tests/$REF .
  cp  ./tests/$COORDS ./bl/inputblock.dat

  echo -en "   Testing for "$name" ... "

  time=`( /usr/bin/time -f "%S" $RUN > out ) 2>&1 > /dev/null`
  
  grep "Data" out | sed 's/Data/ /g' | awk 'NF>1{print $2}' > energy.out

  relativeTime=`echo "$time/$timeRef" | bc -l | awk '{printf("%.3f",$1)}'`
  echo -n "(${time}s,$relativeTime) "
  python ./tests/test-energy.py --reference $REF --current energy.out --reltol 0.00001

  rm $REF energy.out out

done

# Testing exact output files

for name in fittingoutput.dat ; do

  INLATTEFILE="latte."$name".in"
  REF="ref."$name
  COORDS=$name".dat"

  cp  ./tests/$INLATTEFILE latte.in
  cp  ./tests/$REF .
  cp  ./tests/$COORDS ./bl/inputblock.dat

  echo -en "   Testing for "$name" ... "

  time=`( /usr/bin/time -f "%S" $RUN > out ) 2>&1 > /dev/null`
  
  tol=0.0001
  
  check=`
    awk '
      BEGIN{
        loc=0
      }
      {
        getline value < "'$name'"
        split(value,arr)
        
        for(i=1;i<=NF;i++){
          # Here is possible to include a filter to compare only numbers in case the files are more complex
          if( sqrt((arr[i]-$i)**2)>'$tol' ){
            print 1
            loc=1
            exit
          }
        }
      }
      END{
        if(loc==0)
          print 0
      }
    ' $REF`
  
  relativeTime=`echo "$time/$timeRef" | bc -l | awk '{printf("%.3f",$1)}'`
  echo -n "(${time}s,$relativeTime) "
  if [ "$check" -eq 0 ]
  then
    echo "PASSED"
  else
    echo ""
    diff $REF $name
    exit -1
  fi

  rm $REF out

done

# Testing with the usual latte input method:

rm latte.in

echo ""
echo "Testing LATTE with original input files"
echo "======================================="
echo ""

for name in 0scf fullscf sp2 ; do

  CONTROL="control."$name".in"
  MDCONTROLLER="MDcontroller."$name
  REF="energy."$name".out"
  COORDS=$name".dat"

  cp  ./tests/$CONTROL ./TBparam/control.in
  cp  ./tests/$MDCONTROLLER MDcontroller
  cp  ./tests/$REF .
  cp  ./tests/$COORDS ./bl/inputblock.dat

  echo -en "   Testing for "$name" ... "

  time=`( /usr/bin/time -f "%S" $RUN > out ) 2>&1 > /dev/null`
  
  grep "Data" out | sed 's/Data/ /g' | awk 'NF>1{print $2}' > energy.out
  grep Energy out | sed -e s/"PAR"/$STRR/g  >  input_tmp.in
  
  relativeTime=`echo "$time/$timeRef" | bc -l | awk '{printf("%.3f",$1)}'`
  echo -n "(${time}s,$relativeTime) "
  python ./tests/test-energy.py --reference $REF --current energy.out --reltol 0.00001

  rm $REF energy.out input_tmp.in

done

mv latte.in.tmp latte.in
rm out *.dat mylastLATTEcalc *.cfg

echo -e "\nEnd of run and test"
