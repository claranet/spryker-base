

set_nodejs_packages

install_packages $BASE_PACKAGES $NODEJS_PKG
install_packages --build $BUILD_PACKAGES $NPM_DEPENDENCIES
