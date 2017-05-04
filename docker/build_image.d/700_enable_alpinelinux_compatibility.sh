#!/bin/sh

cd $WORKDIR

# FIXME //TRANSLIT isn't supported with musl-libc (used by alpine linux), by intension!
# see https://github.com/akrennmair/newsbeuter/issues/364#issuecomment-250208235
# and http://wiki.musl-libc.org/wiki/Functional_differences_from_glibc#iconv
sed -i 's#//TRANSLIT##g'  /data/shop/vendor/spryker/util-text/src/Spryker/Service/UtilText/Model/Slug.php
