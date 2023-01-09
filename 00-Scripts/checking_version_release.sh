#!/bin/bash

if [[ "${LIST_DEB_RPM_PACKAGES_PATH}" == "" ]]; then
    echo "Error: package path not found"
    exit 1
fi

SCRIPT_NAME=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")" | sed -e "s/.sh//g")
ERR_FILE_NAME=err_"${SCRIPT_NAME}".log
rm -rf "${ERR_FILE_NAME}"

echo "### ${SCRIPT_NAME}" >>"${ERR_FILE_NAME}"
echo "|Status|Comments|" >>"${ERR_FILE_NAME}"
echo "|:-:|:-:|" >>"${ERR_FILE_NAME}"
for deb_rpm_package_path in ${LIST_DEB_RPM_PACKAGES_PATH[@]}; do
    if [[ $deb_rpm_package_path == *".spec"* ]]; then

        echo "$deb_rpm_package_path"
        NAME_VERSION_RELEASE=("$(rpmspec -q --qf "%{name} %{version}-%{release}\n" $deb_rpm_package_path)")
        CHANGELOG_VERSION_RELEASE=$(rpmspec -P $deb_rpm_package_path | grep -A 1 "%changelog" | grep -E "[0-9]+\.[0-9]+(.[0-9]+)?\-[0-9]+" | sed -e "s|.* \([0-9]*.[0-9]*\(.[0-9]*\)-[0-9]*\)|\1|g")
        IFS=$'\n' packages=(${NAME_VERSION_RELEASE})
        unset IFS

        # Check if debian/changelog exists
        path=$(echo "$deb_rpm_package_path" | sed -e 's|rpmbuild/SPECS/.*||')
        changelogFile=$(find $path -path "*python_tools*" -prune -o -path "*BUILD*" -prune -o -name changelog -print)

        # Check spec file version equal to debian/changelog version
        for package in "${packages[@]}"; do
            IFS=$' ' name_version=(${package})
            unset IFS
            if [[ "${name_version[1]}" != "${CHANGELOG_VERSION_RELEASE}" ]]; then
                echo "|\${\color{red}Error}\$|spec file ${package} != ${CHANGELOG_VERSION_RELEASE} from changelog|" >>"${ERR_FILE_NAME}"
            fi
            if [ "${changelogFile}" != "" ]; then
                name_changelog=$(dpkg-parsechangelog -l $changelogFile -S Source)
                version_changelog=$(dpkg-parsechangelog -l $changelogFile -S Version)
                if [[ "${version_changelog}" != "${CHANGELOG_VERSION_RELEASE}" ]]; then
                    echo "|\${\color{red}Error}\$|debian/changelog ${name_changelog} ${version_changelog} != ${name_version[0]} ${CHANGELOG_VERSION_RELEASE} from spec file|" >>"${ERR_FILE_NAME}"
                fi
            fi
        done
    fi
done

CAT_ERR_FILE_NAME=$(cat "${ERR_FILE_NAME}")
if [[ "${CAT_ERR_FILE_NAME}" == *"Error"* ]]; then
    echo "${CAT_ERR_FILE_NAME}"
    exit 1
fi

echo "Finished"
exit 0
