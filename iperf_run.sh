#! /bin/bash

# Parameters (can be modified)
GUEST="Mirage" # used for a JSON output file
OCAMLVER="4.03.0+flambda" # used for a JSON output file
CLIENTADDR="localhost" # a client side Libvirt IP where the iperf client program runs
SERVERADDR="localhost" # a server side Libvirt IP where the iperf server program runs
USER="root" # a user name to execute programs
BUFSIZE="64 128 256 512 1024 2048" # a list of sender buffer size to be tested in this script
ITERATIONS=10 # the number of iterations for each buffer size

# Parameters (should not be modified)
APP="iperf"
PLATFORM=${1}
BASEDIR=${2}

CLIENTPATH="./${APP}/${APP}_client"
SERVERPATH="./${APP}/${APP}_server"
CLIENTXML="${PLATFORM}_client.xml"
SERVERXML="${PLATFORM}_server.xml"
CLIENTBIN="${APP}_client.${PLATFORM}"
SERVERBIN="${APP}_server.${PLATFORM}"

# Check the arguments provided
case ${PLATFORM} in
        "xen" )
                VIRSH_C="virsh -c xen+ssh://${CLIENTADDR}";
                VIRSH_S="virsh -c xen+ssh://${SERVERADDR}";
        ;;
        "virtio" )
                VIRSH_C="virsh -c qemu+ssh://${CLIENTADDR}/system";
                VIRSH_S="virsh -c qemu+ssh://${SERVERADDR}/system";
        ;;
        * ) echo "Invalid hypervisor selected"; exit
esac

COMPILER="OCaml ${OCAMLVER}"

# switch an OCaml compiler version to be used
opam switch ${OCAMLVER}
eval `opam config env`

# Build and dispatch a server application
cd ./${SERVERPATH}
make clean
mirage configure --interface 0 -t ${PLATFORM}
make
cd ../../

sed -e s@KERNELPATH@${BASEDIR}/${SERVERBIN}@ ./template/${SERVERXML} > ./${SERVERXML}
scp ./${SERVERPATH}/${SERVERBIN} ${USER}@${SERVERADDR}:${BASEDIR}/
SERVERLOG="${OCAMLVER}_${PLATFORM}_${APP}_server.log"
${VIRSH_S} create ./${SERVERXML}

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

sed -e s@KERNELPATH@${BASEDIR}/${CLIENTBIN}@ ./template/${CLIENTXML} > ./${CLIENTXML}

cd ${CLIENTPATH}
make clean
mirage configure --interface 0 -t ${PLATFORM}
cd ../../

for BUF in ${BUFSIZE}
do
        cd ${CLIENTPATH}
        sed -i -e "s/let\ blen\ =\ [0-9]*/let blen = ${BUF}/" ./unikernel.ml
        make
        cd ../../
        scp ./${CLIENTPATH}/${CLIENTBIN} ${USER}@${CLIENTADDR}:${BASEDIR}/

        echo -n "{ \"bufsize\": ${BUF}, \"throughput\": [" >> ./${JSONLOG}
        for i in $(seq 1 ${ITERATIONS});
        do
                echo "***** Testing iperf: Buffer size ${BUF}, ${i}/${ITERATIONS} *****"
                ${VIRSH_C} create ./${CLIENTXML} --console >> ${CLIENTLOG}
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
${VIRSH_S} destroy server

