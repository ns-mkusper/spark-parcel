#!/bin/bash

set -ex

# git pull

# compile
MAKE_PARCEL_DIR=`pwd`
SPARK_SOURCE_DIR=/home/tandem/wangyuming/spark
SPARK_PARCEL_DIR=/var/www/html/spark
cd ${SPARK_SOURCE_DIR}
# ./dev/make-distribution.sh --mvn mvn --tgz -Pyarn -Phive -Phive-thriftserver -Phadoop-2.6 -Phadoop-provided   -Pflume-provided  -Dhadoop.version=2.6.0-cdh5.4.3 -Djava.version=1.8 -DskipTests -e

SPARK_NAME=$(ls -art  | grep .tgz | tail -n 1)
echo "The latest spark package is: ${SPARK_NAME}"
SPARK_VERSION=$(echo "${SPARK_NAME}" | awk -F '-' '{print $2;}')
HADOOP_VERSION=$(echo "${SPARK_NAME}" | awk -F '-' '{print $4;}')
CDH_VERSION=$(echo "${SPARK_NAME}" | awk -F '-' '{print $5;}')
CDH_VERSION=$(echo ${CDH_VERSION:0:8})
PARCEL_VERSION="${SPARK_VERSION}-${CDH_VERSION}.d$(date '+%Y%m%d-%H.%M.%S')-$(git log --format="%H" -n 1)"
PARCEL_NAME="YSPARK-${PARCEL_VERSION}"
SPARK_PATH=${SPARK_SOURCE_DIR}/${SPARK_NAME%.*}
SPARK_PARCEL_PATH=${SPARK_PARCEL_DIR}/${PARCEL_NAME}
SPARK_DEPLOY_PATH=${SPARK_PARCEL_DIR}/deploy
SPARK_DEPLOY_ORIGINAL_PATH=${SPARK_DEPLOY_PATH}/${SPARK_NAME%.*}
SPARK_DEPLOY_PARCEL_PATH=${SPARK_PARCEL_DIR}/deploy/${PARCEL_NAME}

# Clean deploy directory
rm -rf ${SPARK_DEPLOY_PATH}/*

tar -zxf ${SPARK_NAME} -C ${SPARK_DEPLOY_PATH}
rsync -av --exclude='make-parcel.sh' ${MAKE_PARCEL_DIR}/*  ${SPARK_DEPLOY_PARCEL_PATH}

for dir in `ls ${SPARK_DEPLOY_ORIGINAL_PATH}`; do
   if [ -d ${SPARK_DEPLOY_ORIGINAL_PATH}/${dir} -a "conf" != "${dir}" -a "licenses" != "${dir}" ]; then
     cp -r -f ${SPARK_DEPLOY_ORIGINAL_PATH}/${dir}/*     ${SPARK_DEPLOY_PARCEL_PATH}/lib/spark/${dir}
   fi
done

sed -i "s/YSPARK-2.0.1-cdh5.4.3.d10.28/${PARCEL_NAME}/g" ${SPARK_DEPLOY_PARCEL_PATH}/meta/cdh_env.sh 
sed -i "s/2.0.1-cdh5.4.3.d10.28/${PARCEL_VERSION}/g"     ${SPARK_DEPLOY_PARCEL_PATH}/meta/parcel.json
sed -i "s/yspark2.0.1/yspark${SPARK_VERSION}/g"          ${SPARK_DEPLOY_PARCEL_PATH}/meta/parcel.json

cd ${SPARK_DEPLOY_PATH}
rm -rf ${SPARK_DEPLOY_ORIGINAL_PATH}
tar -zcf ${PARCEL_NAME}-el6.parcel ${PARCEL_NAME}  --remove-files 
sha1sum ${SPARK_DEPLOY_PATH}/${PARCEL_NAME}-el6.parcel | awk -F" " '{print $1}' > ${SPARK_DEPLOY_PATH}/${PARCEL_NAME}-el6.parcel.sha
/opt/cloudera/parcels/Anaconda/bin/python2.7 /home/tandem/wangyuming/apps/cm_ext/make_manifest/make_manifest.py ${SPARK_DEPLOY_PATH}
