################################################################################
#
# helloworld
#
################################################################################

HELLOWORLD_VERSION = 7d967f11cc00d98da3b4a5a698dd3fc12171c8ea
HELLOWORLD_SITE = $(call github,jmlamare,autotools-helloworld-cpp,$(HELLOWORLD_VERSION))
HELLOWORLD_AUTORECONF = YES

$(eval $(autotools-package))

