#!/bin/sh

TOP_DIR=`cd \`echo "$0" | sed -n '/\//{s/\/[^\/]*$//;p;}'\`;pwd`
SELF_NAME=`basename "$0" .sh`
PKG=`echo ${SELF_NAME} | sed -e 's/\-[^\-]*\-[^\-]*$//'`
VER=`echo ${SELF_NAME} | sed -e 's/^[^\-]*\-//' -e 's/\-[^\-]*$//'`
REL=`echo ${SELF_NAME} | sed -e 's/^[^\-]*\-[^\-]*\-//'`
FULLPKG=${PKG}-${VER}-${REL}

SOURCE_DIR="${TOP_DIR}/${PKG}-${VER}"
BINARY_DIR=${SOURCE_DIR}/.build
INSTALL_DIR=${SOURCE_DIR}/.inst
SPKG_DIR=${SOURCE_DIR}/.sinst
SOURCE_PACKAGE="${TOP_DIR}/${FULLPKG}-src.tar.bz2"
SOURCE_TARBALL="${TOP_DIR}/${PKG}-${VER}.tar.bz2"
SOURCE_PATCH="${TOP_DIR}/${FULLPKG}.patch"
PREFIX="/usr"

BINARY_PACKAGE="${TOP_DIR}/${FULLPKG}.tar.bz2"

mkdirs()
{
  (
  mkdir -p "${BINARY_DIR}" "${INSTALL_DIR}" "${SPKG_DIR}"
  )
}

prep()
{
  (
  cd ${TOP_DIR} &&
  tar xvjf "${SOURCE_TARBALL}" &&
  patch -p0 < "${SOURCE_PATCH}" &&
  mkdirs
  )
}

conf()
{
  (
  cd ${BINARY_DIR} &&
  ${SOURCE_DIR}/configure --prefix=${PREFIX}
  )
}

build()
{
  (
  cd ${BINARY_DIR} &&
  make
  )
}

install()
{
  (
  cd ${BINARY_DIR} &&
  make install DESTDIR="${INSTALL_DIR}" &&
  mkdir -p ${INSTALL_DIR}${PREFIX}/doc/Cygwin &&
  mkdir -p ${INSTALL_DIR}${PREFIX}/doc/${PKG}-${VER} &&
  cp ${SOURCE_DIR}/CMake.pdf     ${INSTALL_DIR}${PREFIX}/doc/${PKG}-${VER} &&
  cp ${SOURCE_DIR}/CMake.rtf     ${INSTALL_DIR}${PREFIX}/doc/${PKG}-${VER} &&
  cp ${SOURCE_DIR}/Copyright.txt ${INSTALL_DIR}${PREFIX}/doc/${PKG}-${VER} &&
  cp ${SOURCE_DIR}/CYGWIN-PATCHES/cmake.README \
     ${INSTALL_DIR}${PREFIX}/doc/Cygwin/${FULLPKG}.README &&
  touch ${INSTALL_DIR}${PREFIX}/doc/${PKG}-${VER}/MANIFEST &&
  cd ${INSTALL_DIR} &&
  FILES=`/usr/bin/find .${PREFIX} -type f |sed 's/^\.\//\//'` &&
(
cat >> ${INSTALL_DIR}${PREFIX}/doc/${PKG}-${VER}/MANIFEST <<EOF
${FILES}
EOF
)
  )
}

strip()
{
  (
  cd ${INSTALL_DIR} &&
  /usr/bin/find . -name "*.dll" | xargs strip >/dev/null 2>&1
  /usr/bin/find . -name "*.exe" | xargs strip >/dev/null 2>&1
  true
  )
}

clean()
{
  (
  cd ${BINARY_DIR} &&
  make clean
  )
}

pkg()
{
  (
  cd ${INSTALL_DIR} &&
  tar cvjf "${BINARY_PACKAGE}" *
  )
}

mkpatch()
{
  (
  cd ${SOURCE_DIR} &&
  tar xvjf "${SOURCE_TARBALL}" &&
  mv ${PKG}-${VER} ../${PKG}-${VER}-orig &&
  cd ${TOP_DIR} &&
  diff -urN -x '.build' -x '.inst' -x '.sinst' \
       "${PKG}-${VER}-orig" "${PKG}-${VER}" > "${SPKG_DIR}/${FULLPKG}.patch" ;
  rm -rf "${TOP_DIR}/${PKG}-${VER}-orig"
  )
}

spkg()
{
  (
  mkpatch &&
  cp ${SOURCE_TARBALL} ${SPKG_DIR} &&
  cp "$0" ${SPKG_DIR} &&
  cd ${SPKG_DIR} &&
  tar cvjf ${SOURCE_PACKAGE} *
  )
}

finish()
{
  (
  rm -rf "${SOURCE_DIR}"
  )
}

case $1 in
  prep)         prep    ; STATUS=$? ;;
  mkdirs)       mkdirs  ; STATUS=$? ;;
  conf)         conf    ; STATUS=$? ;;
  build)        build   ; STATUS=$? ;;
  check)        check   ; STATUS=$? ;;
  clean)        clean   ; STATUS=$? ;;
  install)      install ; STATUS=$? ;;
  strip)        strip   ; STATUS=$? ;;
  package)      pkg     ; STATUS=$? ;;
  pkg)          pkg     ; STATUS=$? ;;
  mkpatch)      mkpatch ; STATUS=$? ;;
  src-package)  spkg    ; STATUS=$? ;;
  spkg)         spkg    ; STATUS=$? ;;
  finish)       finish  ; STATUS=$? ;;
  all) (
       prep && conf && build && install && strip && pkg && spkg && finish ;
       STATUS=$?
       ) ;;
  *) echo "Error: bad arguments" ; exit 1 ;;
esac
exit ${STATUS}
