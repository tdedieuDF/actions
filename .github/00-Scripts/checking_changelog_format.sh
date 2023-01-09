#!/bin/bash

SCRIPT_NAME=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")" | sed -e "s/.sh//g")
ERR_FILE_NAME=err_"${SCRIPT_NAME}".log
rm -rf "${ERR_FILE_NAME}"
rm -rf /tmp/Error

LIST_DEB_RPM_PACKAGES_PATH+=($(find . \
    -path "*dds-proxy" -prune \
    -o -path "*fte_cub_hmi_custom" -prune \
    -o -path "*test" -prune \
    -o -path "*tests" -prune \
    -o -path "*Skeletons" -prune \
    -o -path "*TMP_MANAGER" -prune \
    -o -name changelog -print \
    -o -name *.spec -print))

echo "### ${SCRIPT_NAME}" >>"${ERR_FILE_NAME}"
echo "|Status|Files|Comments|" >>"${ERR_FILE_NAME}"
echo "|:-:|:-:|:-|" >>"${ERR_FILE_NAME}"
for deb_rpm_package_path in "${LIST_DEB_RPM_PACKAGES_PATH[@]}"; do
    output_err=""
    # Check deb
    if [[ $deb_rpm_package_path == *"debian/changelog"* ]]; then
        deb_rpm_package_name=$(dpkg-parsechangelog -l $deb_rpm_package_path -S Source 2>"/tmp/Error")
        output_err="\"$(</tmp/Error)\""
        if [[ "${output_err}" != "\"\"" ]]; then

            output_err=$(echo "${output_err}" | sed -e "s|${deb_rpm_package_path}||g")
            output_err=$(echo "${output_err}" | sed -e ":a;N;\$!ba;s/\n/\t/g")
            output_err=$(echo "${output_err}" | sed -e "s|\"dpkg-parsechangelog: warning: ||g" -e "s|dpkg-parsechangelog: warning: |<br />|g" -e "s|\"||g")
            echo "|\${\color{red}Error}\$|${deb_rpm_package_path}|${output_err}|" >>"${ERR_FILE_NAME}"
        fi
        deb_rpm_package_version=$(dpkg-parsechangelog -l $deb_rpm_package_path -S Version 2>"/tmp/Error")
    fi
    # Check rpm
    if [[ $deb_rpm_package_path == *".spec"* ]]; then
        deb_rpm_package_name=$(rpmspec -q --qf "%{name} %{version}-%{release}\n" $deb_rpm_package_path 2>"/tmp/Error")
        output_err="\"$(</tmp/Error)\""
        if [[ "${output_err}" != "\"\"" ]]; then
            echo "error equal => ${output_err}"
            output_err=$(echo "${output_err}" | sed -e "s|warning:|error:|g" -e "s|\"error:||g" -e "s|error:|<br />|g")
            output_err=$(echo "${output_err}" | sed -e ":a;N;\$!ba;s/\n/\t/g")
            output_err=$(echo "${output_err}" | sed -e "s|query of specfile .* failed, can't parse||g" -e "s|\"||g")
            echo "|\${\color{red}Error}\$|${deb_rpm_package_path}|${output_err}|" >>"${ERR_FILE_NAME}"
        fi
    fi
    echo "${deb_rpm_package_path} checked"
done

CAT_ERR_FILE_NAME=$(cat "${ERR_FILE_NAME}")
if [[ "${CAT_ERR_FILE_NAME}" == *"Error"* ]]; then
    echo "${CAT_ERR_FILE_NAME}"
    exit 1
fi

echo "Finished"
exit 0
