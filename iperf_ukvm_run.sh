#! /bin/bash

# Parameters
BUFSIZE="64 128 256 512 1024 2048"
OCAMLVER="4.03.0"
ITERATIONS="10"
C_TAP="tap1"
S_TAP="tap0"

# The followings should not be modified
GUEST="Mirage"
NET="--net="
PLATFORM="ukvm"

PROTO=${1}
# Check a selected protocol
case ${PROTO} in
        "tcp" )
				APP="iperf";
        ;;
        "udp" )
				APP="iperf_udp";
        ;;
        * ) echo "Invalid protocol selected"; exit
esac

CURRENT_DIR=${PWD}
CLIENTPATH="./${APP}_client"
SERVERPATH="./${APP}_server"
CLIENTBIN="${APP}_client.${PLATFORM}"
SERVERBIN="${APP}_server.${PLATFORM}"

# Check the arguments provided
case ${PLATFORM} in
        "ukvm" )
                CMD_C="./${CLIENTPATH}/ukvm-bin ${NET}${C_TAP} ./${CLIENTPATH}/${CLIENTBIN}";
                CMD_S="./${SERVERPATH}/ukvm-bin ${NET}${S_TAP} ./${SERVERPATH}/${SERVERBIN}";
        ;;
        * ) echo "Invalid hypervisor selected"; exit
esac

COMPILER="OCaml ${OCAMLVER}"

# switch an OCaml compiler version to be used
opam switch ${OCAMLVER}
eval `opam config env`

# Build and dispatch a server application
cd ${SERVERPATH}
make clean
mirage configure -t ${PLATFORM}
make
cd ${CURRENT_DIR}
${CMD_S} &

# Dispatch a client side MirageOS VM repeatedly
JSONLOG="./${OCAMLVER}_${PLATFORM}_${APP}.json"
echo -n "{
  \"guest\": \"${GUEST}\",
  \"platform\": \"${PLATFORM}\",
  \"compiler\": \"${COMPILER}\",
  \"records\": [
" > ./${JSONLOG}

CLIENTLOG="${OCAMLVER}_${PLATFORM}_${APP}_client.log"
echo -n '' > ./${CLIENTLOG}

cd ${CLIENTPATH}
make clean
mirage configure -t ${PLATFORM}
cd ${CURRENT_DIR}

for BUF in ${BUFSIZE}
do
        cd ${CLIENTPATH}
        sed -i -e "s/let\ blen\ =\ [0-9]*/let blen = ${BUF}/" ./unikernel.ml
        make
        cd ${CURRENT_DIR}

        echo -n "{ \"bufsize\": ${BUF}, \"throughput\": [" >> ./${JSONLOG}
        for i in $(seq 1 ${ITERATIONS});
        do
                echo "***** Testing iperf: Buffer size ${BUF}, ${i}/${ITERATIONS} *****"
				echo "${CURRENT_DIR}/${CLIENTPATH}"
                ${CMD_C} >> ${CLIENTLOG}
                TP=`sed -e 's/^M/\n/g' ./${CLIENTLOG} | grep Throughput | tail -n 1 | cut -d' ' -f 10`
                echo -n "${TP}," >> ./${JSONLOG}
        done
        echo -n "]}," >> ./${JSONLOG}
done

# Correct the generated JSON file
echo -n "]}" >> ./${JSONLOG}
sed -i -e 's/,\]/]/g' ${JSONLOG}
cat ./${JSONLOG} | jq

# Destroy the server application
killall ukvm-bin