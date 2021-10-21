pkg_origin="ryanwoodsmall"
pkg_name="zulu8musl"
pkg_maintainer="ryanwoodsmall <rwoodsmall@gmail.com>"
ver1="8.0.312"
ver2="8.58.0.13"
pkg_version="${ver1}.${ver2}"
pkg_dirname="zulu${ver2}-ca-jdk${ver1}-linux_musl_x64"
pkg_filename="${pkg_dirname}.tar.gz"
pkg_source="https://cdn.azul.com/zulu/bin/${pkg_filename}"
pkg_shasum="defdb7336fd83cde094c5f971832c0ba378f6dc7443b224bb60afe10640dd466"
pkg_license=( "GPL-2.0-only WITH Classpath-exception-2.0" )
pkg_description=( 'Zulu is a build of the Open Java Development Kit (OpenJDK) on musl libc with long-term support from Azul' )
pkg_upstream_url="https://www.azul.com/downloads/zulu-community/"
pkg_deps=(
  core/musl
  core/zlib-musl
)
pkg_build_deps=(
  core/gawk
  core/file
  core/findutils
  core/patchelf
)
pkg_bin_dirs=( bin )
pkg_lib_dirs=( lib )
pkg_include_dirs=( include )

do_build() {
  return 0
}

do_default_unpack() {
  return 0
}

do_strip() {
  return 0
}

do_setup_environment() {
 set_runtime_env JAVA_HOME "${pkg_prefix}"
}

do_unpack() {
  local t="${pkg_prefix}"
  local f="${HAB_CACHE_SRC_PATH}/${pkg_filename}"
  build_line "Extracting '${f}' to '${t}'"
  mkdir -p "${t}"
  tar -C "${t}/" -zxf "${f}"
  pushd "${t}/" >/dev/null 2>&1 || exit 1
  cd "${pkg_dirname}"
  for i in $(find . -mindepth 1 -maxdepth 1) ; do
    mv "${i}" ..
  done
  cd ..
  rmdir "${pkg_dirname}"
  popd >/dev/null 2>&1 || exit 1
}

do_install() {
  pushd "${pkg_prefix}" >/dev/null 2>&1 || exit 1

  # rpath - where shared libs are found
  export LD_RUN_PATH="${LD_RUN_PATH}"
  build_line "Adding '${LD_RUN_PATH}' to rpath for all libraries and executables"

  # interpreter - dynamic linker
  local interp="$(pkg_path_for core/musl)/lib/ld-musl-x86_64.so.1"
  build_line "Setting interpreter for all executables to '${interp}'"

  for i in $($(pkg_path_for core/findutils)/bin/find "${pkg_prefix}" -exec $(pkg_path_for core/file)/bin/file {} + | $(pkg_path_for core/gawk)/bin/awk -F: '/:.*ELF/{print $1}') ; do
    local orpath="$(patchelf --print-rpath ${i})"
    local nrpath="${LD_RUN_PATH}:${orpath}"
    nrpath="${nrpath//::/:}"
    build_line "Setting '${i}' rpath to '${nrpath}'"
    $(pkg_path_for core/patchelf)/bin/patchelf --set-rpath "${nrpath}" "${i}"
    if ! $(echo "${i}" | grep -q '\.so') ; then
      build_line "Setting '${i}' interpreter to '${interp}'"
      $(pkg_path_for core/patchelf)/bin/patchelf --set-interpreter "${interp}" "${i}"
    fi
  done

  popd >/dev/null 2>&1 || exit 1
}
