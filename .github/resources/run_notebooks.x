#!/usr/bin/env bash
set -eu
export REPOROOT="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )/../../" && pwd )"
CODCACHE_SRC="${REPOROOT}/.github/resources/codcache"
test -d $CODCACHE_SRC

export LOCALWHEELCACHE="$REPOROOT/tmptests/local_wheel_cache"
if [ "x${NCNOTEBOOKS_USE_NCRYSTAL_REPO:-}" != "x" ]; then
    python3 -mvenv create "$REPOROOT/tmptests/venv_ncbld"
    . "$REPOROOT/tmptests/venv_ncbld/bin/activate"
    mkdir "$LOCALWHEELCACHE"
    python -mpip install build
    time python -m build --wheel -o "$LOCALWHEELCACHE" "${NCNOTEBOOKS_USE_NCRYSTAL_REPO}/ncrystal_core"
    time python -m build --wheel -o "$LOCALWHEELCACHE" "${NCNOTEBOOKS_USE_NCRYSTAL_REPO}/ncrystal_python"
    time python -m build --wheel -o "$LOCALWHEELCACHE" "${NCNOTEBOOKS_USE_NCRYSTAL_REPO}/ncrystal_metapkg"
    ls -l "$LOCALWHEELCACHE"
    deactivate
fi

for notebookfile in `find "${REPOROOT}"/notebooks/ -name '*.ipynb'`; do
    echo
    echo '------------------------------------------------------'
    bn=$(basename "${notebookfile}")
    echo "Testing ${bn}"
    echo "${notebookfile}"
    #if [[ -v VIRTUAL_ENV ]]; then
    #    type -t deactivate && deactivate
    #fi
    rm -rf "${REPOROOT}/test_tmp_rundir"
    mkdir "${REPOROOT}/test_tmp_rundir"
    cd "${REPOROOT}/test_tmp_rundir"
    cp -rp "${CODCACHE_SRC}" ./ncrystal_onlinedb_filecache
    python3 -mvenv create ./venv
    . ./venv/bin/activate
    if [ -d "$LOCALWHEELCACHE" ]; then
        export PIP_FIND_LINKS="$LOCALWHEELCACHE"
    fi

    python3 -mpip install jupyter ipython
    echo "   .. converting to script"
    cat "${notebookfile}" | \
        sed 's#always_do_pip_installs = False#always_do_pip_installs = True#' \
        > ./thenotebook.ipynb
    jupyter nbconvert --to script ./thenotebook.ipynb --output="${PWD}/thenotebook_converted"
    test -f ./thenotebook_converted.py
    if [ "x${bn}" == "xNEUWAVE_12_Examples_Transmission_with_NCrystal_and_McStas.ipynb" ]; then
        echo
        echo
        echo "WARNING: SKIPPING CONDA BASED NOTEBOOK!!!"
        echo
        echo
    elif [ "x${bn}" == "xND2025_OpenMC_NCrystal.ipynb" ]; then
        echo
        echo
        echo "WARNING: SKIPPING CONDA BASED NOTEBOOK!!!"
        echo
        echo
    elif [ "x${bn}" == "xND2025_ncmat2endf.ipynb" ]; then
        echo
        echo
        echo "WARNING: SKIPPING CONDA BASED NOTEBOOK!!!"
        echo
        echo
    elif [ "x${bn}" == "xND2025_Extinction_ENDF_library.ipynb" ]; then
        echo
        echo
        echo "WARNING: SKIPPING CONDA BASED NOTEBOOK!!!"
        echo
        echo
    else
        echo "   .. executing script"
        time ipython ./thenotebook_converted.py | cat
        if [ ${PIPESTATUS[0]} != 0 ]; then
            echo "DETECTED ERROR IN: ${bn}"
            exit 1
        fi
    fi
    deactivate
done
