#!/bin/bash

DIRECTORY=$(dirname "$0")
SCRIPT_NAME=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")" | sed -e "s/.sh//g")
ERR_FILE_NAME=err_"${SCRIPT_NAME}".log
rm -rf "${ERR_FILE_NAME}"
mkdir -p result

LIST_DEB_RPM_PACKAGES_PATH+=($(find . \
    -path "*dds-proxy" -prune \
    -o -path "*fte_cub_hmi_custom" -prune \
    -o -path "*test" -prune \
    -o -path "*tests" -prune \
    -o -path "*Skeletons" -prune \
    -o -path "*TMP_MANAGER" -prune \
    -o -name changelog -print \
    -o -name *.spec -print))

list_app=()
for deb_rpm_package_path in ${LIST_DEB_RPM_PACKAGES_PATH[@]}; do
    if [[ $deb_rpm_package_path == *"debian/changelog"* ]]; then
        deb_rpm_package_name=$(dpkg-parsechangelog -l $deb_rpm_package_path -S Source)
        deb_rpm_package_version=$(dpkg-parsechangelog -l $deb_rpm_package_path -S Version)
        deb_rpm_package_path="${deb_rpm_package_name} ${deb_rpm_package_version}"
        list_app+=("${deb_rpm_package_path}")
    fi
    if [[ $deb_rpm_package_path == *".spec"* ]]; then
        deb_rpm_package_path=$(rpmspec -q --qf "%{name} %{version}-%{release}\n" $deb_rpm_package_path)
        list_app+=("${deb_rpm_package_path}")
    fi
done

IFS=$'\n' sorted=($(sort -u <<<"${list_app[*]}"))
unset IFS

python3 "${DIRECTORY}"/export_package_name_version.py -i $(find . -name "*SequencerConfig.xml") -o sequencer_xml.txt
IFS=$'\n' sorted_sequencer_list_app=($(sort -u <<<"$(cat sequencer_xml.txt)"))
unset IFS

LIST_APP_TO_IGNORED=(airbus-mands-fw-ed247_adapter-0.7.1
    google-chrome-stable
    python3-colorama
    python3-haversine
    python3-icecream
    python3-protobuf
    python3-six
    python3-setuptools)

echo "### ${SCRIPT_NAME}" >>"${ERR_FILE_NAME}"
echo "|Status|Comments|" >>"${ERR_FILE_NAME}"
echo "|:-:|:-:|" >>"${ERR_FILE_NAME}"
for package_name_sequencer in "${sorted_sequencer_list_app[@]}"; do
    IFS=$' ' name_version=(${package_name_sequencer})
    unset IFS
    if [[ "${LIST_APP_TO_IGNORED[@]}" == *"${name_version[0]}"* ]]; then
        echo "|\${\color{orange}Warning}\$|${package_name_sequencer} is in sequencer but not exist in ours repository|" >>"${ERR_FILE_NAME}"
    elif [[ "${sorted[@]}" != *"${package_name_sequencer}"* ]]; then
        echo "|\${\color{red}Error}\$|${package_name_sequencer} is in sequencer but not in last changelog|" >>"${ERR_FILE_NAME}"
    fi
done

CAT_ERR_FILE_NAME=$(cat "${ERR_FILE_NAME}")
if [[ "${CAT_ERR_FILE_NAME}" == *"Error"* || "${CAT_ERR_FILE_NAME}" == *"cat"* ]]; then
    echo "${CAT_ERR_FILE_NAME}"
    exit 1
fi

echo "Finished"
exit 0
