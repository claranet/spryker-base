#!/bin/sh

# FIXME //TRANSLIT isn't supported with musl-libc (used by alpine linux), by intension!
# see https://github.com/akrennmair/newsbeuter/issues/364#issuecomment-250208235
# and http://wiki.musl-libc.org/wiki/Functional_differences_from_glibc#iconv
remove_iconv_translit_usage() {
  sectionNote "disable //TRANSLIT iconv flag usage, musl-libc does not support it!"
  
  local FILE_LIST="$WORKDIR/vendor/spryker/util-text/src/Spryker/Service/UtilText/Model/Slug.php"
  for f in $FILE_LIST; do
    if [ -e "$f" ]; then
      sectionNote "doing it for: $f"
      sed -i 's#//TRANSLIT##g' $f
    fi
  done
}

remove_iconv_translit_usage
