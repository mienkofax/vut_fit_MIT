#!/bin/bash

INTERPRET=php
FLAGS='-d open_basedir=""'
FILE=cls2.php

JEXAMXML_INTERPRET="java -jar jexamxml.jar"
JEXAMXML_OPTIONS=cls_options
JEXAMXML_INPUT=output.xml
JEXAMXML_DELTA=delta.xml

TEST_DIR="testy-cls"
REF_INPUT_DIR=$TEST_DIR
REF_OUTPUT_DIR=$TEST_DIR"/ref-out"
ERROR=0
SEPARATOR="-------------------------------------------"

MERLIN_TEST=0
HOSTNAME="merlin.fit.vutbr.cz"
ACT_HOSTNAME=hostname
if [ "$HOSTNAME" == "$ACT_HOSTNAME" ] ; then
	MERLIN_TEST=1
fi

INPUT_FILE=input.test
OUTPUT_FILE=output.test
TMP_FILE=tmp.f

touch $INPUT_FILE
touch $OUTPUT_FILE

echoTest() {
	echo -n -e "\e[36m"
	echo "$1"
	echo -n -e "\e[39m"
}

check () {
	ERR=$?
	OK=0

	#zistenie ci je vysledok programu Ok/ERR
	if [ $ERR -eq 0 ] ; then
		OK=1
	fi

	#zelenou sa potvrdi spravny exit code
	#cercenou je chybny navratovy kod
	if [ "$1" == "OK"  ] && [  $OK -eq 1 ] ; then
		echo -ne "\e[92m"
	elif  [ "$1" == "ERR"  ] && [  $OK -eq 0 ] ; then
		echo -ne "\e[92m"
	else
		echo -ne "\e[31m"
		ERROR=$((ERROR + 1)) #pocet chyb
	fi

	#vypis vysledku
	if [ $ERR -eq 0 ] ; then
		echo "OK"
	else
		echo "ERR: $ERR"
	fi

	#reset farby
	echo -n -e "\e[39m"
}

echo $SEPARATOR

##################################
# Test argumentov

echoTest "TEST-ARG: 01/OK - zobrazenie help spravy"
$INTERPRET $FLAGS $FILE --help
check "OK"
echo $SEPARATOR

echoTest "TEST-ARG: 02/ERR - opakovanie help prepinaca "
$INTERPRET $FLAGS $FILE --help --help
check "ERR"
echo $SEPARATOR

echoTest "TEST-ARG: 03/OK - prepinac input s platnym nazvom suboru"
$INTERPRET $FLAGS $FILE --input=$INPUT_FILE
check "OK"
echo $SEPARATOR

echoTest "TEST-ARG: 04/ERR - prepinac input s neplatnym nazvom suboru"
$INTERPRET $FLAGS $FILE --input=asdfhjsdfsdafsafds
check "ERR"
echo $SEPARATOR

if [ $MERLIN_TEST -eq 0 ] ; then
echoTest "TEST-ARG: 05/ERR - prepinac input s platnym suborom ale nedostatocnym opravnenim na citanie"
sudo touch $TMP_FILE
sudo chmod o-r $TMP_FILE
$INTERPRET $FLAGS $FILE --input=$TMP_FILE
check "ERR"
echo $SEPARATOR
sudo rm $TMP_FILE
fi

echoTest "TEST-ARG: 06/ERR - nezmami prepinac "
$INTERPRET $FLAGS $FILE --unknown
check "ERR"
echo $SEPARATOR

echoTest "TEST-ARG: 07/OK - prepinac output s platnym nazvom suboru"
$INTERPRET $FLAGS $FILE --output=$OUTPUT_FILE --input=$INPUT_FILE
check "OK"
echo $SEPARATOR

if [ $MERLIN_TEST -eq 0 ] ; then
echoTest "TEST-ARG: 08/ERR - prepinac output s platnym suborom ale nedostatocnym opravnenim na zapis"
sudo touch $TMP_FILE
sudo chmod o-r $TMP_FILE
$INTERPRET $FLAGS $FILE --output=$TMP_FILE
check "ERR"
echo $SEPARATOR
sudo rm $TMP_FILE
fi

echoTest "TEST-ARG: 09/OK - prepinac pretty-xml s platnym cislom"
$INTERPRET $FLAGS $FILE --pretty-xml=5 --input=$INPUT_FILE
check "OK"
echo $SEPARATOR

echoTest "TEST-ARG: 10/ERR - prepinac pretty-xml so zapornym cislom"
$INTERPRET $FLAGS $FILE --pretty-xml=-5
check "ERR"
echo $SEPARATOR

echoTest "TEST-ARG: 11/ERR - prepinac pretty-xml s retazcom"
$INTERPRET $FLAGS $FILE --pretty-xml=number
check "ERR"
echo $SEPARATOR

echoTest "TEST-ARG: 12/ERR - prepinac pretty-xml s opakovanym prepinacom"
$INTERPRET $FLAGS $FILE --pretty-xml=5 --pretty-xml=5
check "ERR"
echo $SEPARATOR

echoTest "TEST-ARG: 13/OK - prepinac pretty-xml bez parametra"
$INTERPRET $FLAGS $FILE --pretty-xml --input=$INPUT_FILE
check "OK"
echo $SEPARATOR

echoTest "TEST-ARG: 14/ERR - duplikovanie kratkeho a dlheho prepinaca - output"
$INTERPRET $FLAGS $FILE -o=file --output=file
check "ERR"
echo $SEPARATOR

echoTest "TEST-ARG: 15/ERR - help s inymi prepinacmi"
$INTERPRET $FLAGS $FILE -o=file  --help
check "ERR"
echo $SEPARATOR

echoTest "TEST-ARG: 16/OK - kratky prepinac -o"
$INTERPRET $FLAGS $FILE -o=file --input=$INPUT_FILE
check "OK"
echo $SEPARATOR

echoTest "TEST-ARG: 17/OK - kratky prepinac -h"
$INTERPRET $FLAGS $FILE -h --input=$INPUT_FILE
check "OK"
echo $SEPARATOR

echoTest "TEST-ARG: 18/OK - kratky prepinac -p"
$INTERPRET $FLAGS $FILE -o=file --input=$INPUT_FILE
check "OK"
echo $SEPARATOR

echoTest "TEST-ARG: 19/ERR - kratky prepinac -hxxxx"
$INTERPRET $FLAGS $FILE -hxxxx
check "ERR"
echo $SEPARATOR

echoTest "TEST-ARG: 20/ERR - dlhy prepinac input bez ="
$INTERPRET $FLAGS $FILE --output $OUTPUT_FILE
check "ERR"
echo $SEPARATOR

# Koniec testov argumentov
##################################

##################################
# Zaciatok testu XML parsoanie


echoTest "TEST-XML: 01/OK - ${REF_OUTPUT_DIR}/test01.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test01.in -o=$JEXAMXML_INPUT
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test01.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 02/OK - ${REF_OUTPUT_DIR}/test02.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test02.in -o=$JEXAMXML_INPUT --details=A
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test02.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 03/OK - ${REF_OUTPUT_DIR}/test03.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test03.in -o=$JEXAMXML_INPUT --details=D
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test03.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 04/OK - ${REF_OUTPUT_DIR}/test04.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test04.in -o=$JEXAMXML_INPUT
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test04.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 05/OK - ${REF_OUTPUT_DIR}/test05.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test05.in -o=$JEXAMXML_INPUT
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test05.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 06/OK - ${REF_OUTPUT_DIR}/test06.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test06.in -o=$JEXAMXML_INPUT --details=D
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test06.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 07/OK - ${REF_OUTPUT_DIR}/test07.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test07.in -o=$JEXAMXML_INPUT --details=D
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test07.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 08/OK - ${REF_OUTPUT_DIR}/test08.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test08.in -o=$JEXAMXML_INPUT --details=C
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test08.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 09/OK - ${REF_OUTPUT_DIR}/test09.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test09.in -o=$JEXAMXML_INPUT
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test09.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 10/OK - ${REF_OUTPUT_DIR}/test10.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test10.in -o=$JEXAMXML_INPUT --details
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test10.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 11/OK - ${REF_OUTPUT_DIR}/test11.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test11.in -o=$JEXAMXML_INPUT --details --search="/model/class[*/attributes/attribute/@name='var']/@name"
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test11.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR

echoTest "TEST-XML: 12/OK - ${REF_OUTPUT_DIR}/test12.in"
$INTERPRET $FLAGS $FILE --input=$REF_INPUT_DIR/test12.in -o=$JEXAMXML_INPUT  --details=C --conflicts
check "OK"
$JEXAMXML_INTERPRET $JEXAMXML_INPUT ${REF_OUTPUT_DIR}/test12.out $JEXAMXML_DELTA  $JEXAMXML_OPTIONS
check "OK"
echo $SEPARATOR


# Koniec testov XML parsovania
##################################


################################
if [ $ERROR -eq 0 ] ; then
	echo -ne "\e[92m"
else
	echo -ne "\e[31m"
fi

#pocet chyb
echo "POCET CHYB: $ERROR"
echo -n -e "\e[39m" #reset farby

echo $SEPARATOR

rm $INPUT_FILE
rm $OUTPUT_FILE
